import Foundation
import OSLog

// MARK: - EnginePoolError

/// 引擎池错误
public enum EnginePoolError: Error, CustomStringConvertible {
    case poolExhausted
    case engineNotFound(UUID)
    case engineAlreadyExists(UUID)
    case failedToInitializeEngine(UUID, Error)
    case invalidConfiguration

    public var description: String {
        switch self {
        case .poolExhausted:
            return "引擎池已耗尽，没有可用的引擎实例"
        case .engineNotFound(let id):
            return "找不到ID为 \(id) 的引擎实例"
        case .engineAlreadyExists(let id):
            return "ID为 \(id) 的引擎实例已存在"
        case .failedToInitializeEngine(let id, let error):
            return "初始化引擎 \(id) 失败: \(error.localizedDescription)"
        case .invalidConfiguration:
            return "无效的引擎配置"
        }
    }
}

// MARK: - PooledEngine

/// 引擎池中的引擎实例包装
public actor PooledEngine {

    /// 引擎实例ID
    public let id: UUID

    /// 引擎配置
    public let configuration: EngineConfiguration

    /// 引擎管理器
    public private(set) var engineManager: EngineManager?

    /// 是否正在使用
    public private(set) var isInUse: Bool = false

    /// 最后使用时间
    public private(set) var lastUsedAt: Date?

    /// 创建时间
    public let createdAt: Date

    /// 引擎状态
    public var state: EngineState {
        get async {
            await engineManager?.state ?? .idle
        }
    }

    // MARK: - Initialization

    public init(
        configuration: EngineConfiguration,
        id: UUID = UUID()
    ) {
        self.id = id
        self.configuration = configuration
        self.createdAt = Date()
    }

    // MARK: - Public Methods

    /// 初始化引擎
    public func initialize() async throws {
        guard engineManager == nil else {
            return // 已经初始化
        }

        let manager = EngineManager(configuration: configuration)
        self.engineManager = manager

        do {
            try await manager.initialize()
        } catch {
            self.engineManager = nil
            throw EnginePoolError.failedToInitializeEngine(id, error)
        }
    }

    /// 关闭引擎
    public func shutdown() async {
        if let manager = engineManager {
            await manager.shutdown()
            engineManager = nil
        }
        isInUse = false
    }

    /// 标记为使用中
    public func markInUse() {
        isInUse = true
        lastUsedAt = Date()
    }

    /// 标记为空闲
    public func markIdle() {
        isInUse = false
        lastUsedAt = Date()
    }

    /// 重启引擎
    public func restart() async throws {
        if let manager = engineManager {
            try await manager.restart()
        } else {
            try await initialize()
        }
    }

    /// 获取引擎能力信息
    public func getCapabilities() async -> EngineCapabilities? {
        await engineManager?.capabilities
    }

    /// 设置UCI选项
    public func setOption(name: String, value: String) async throws {
        guard let manager = engineManager else {
            throw EnginePoolError.engineNotFound(id)
        }
        try await manager.setOption(name: name, value: value)
    }

    /// 开始搜索
    public func startSearch(parameters: GoParameters) async throws {
        guard let manager = engineManager else {
            throw EnginePoolError.engineNotFound(id)
        }
        try await manager.startSearch(parameters: parameters)
    }

    /// 停止搜索
    public func stopSearch() async throws {
        guard let manager = engineManager else {
            throw EnginePoolError.engineNotFound(id)
        }
        try await manager.stopSearch()
    }

    /// 等待最佳着法
    public func waitForBestMove(timeout: Duration = .seconds(30)) async throws -> SearchResult? {
        guard let manager = engineManager else {
            throw EnginePoolError.engineNotFound(id)
        }

        // 等待 bestmove 响应
        let response = try await manager.waitForResponse(
            timeout: timeout,
            predicate: { response in
                if case .bestmove = response {
                    return true
                }
                return false
            }
        )

        if case .bestmove(let move, let ponder) = response {
            return SearchResult(bestMove: move, ponderMove: ponder)
        }

        return nil
    }
}

// MARK: - EnginePool

/// 引擎池
/// 管理多个引擎实例，支持引擎的复用和负载均衡
@MainActor
public final class EnginePool: ObservableObject {

    // MARK: - Published Properties

    /// 池中的所有引擎
    @Published public private(set) var engines: [PooledEngine] = []

    /// 可用引擎数量
    @Published public private(set) var availableCount: Int = 0

    /// 正在使用的引擎数量
    @Published public private(set) var inUseCount: Int = 0

    /// 池是否已满
    @Published public private(set) var isFull: Bool = false

    // MARK: - Configuration

    /// 最大引擎数量
    public let maxPoolSize: Int

    /// 引擎配置模板
    public let configurationTemplate: EngineConfiguration

    /// 是否自动扩展
    public let autoExpand: Bool

    /// 空闲超时时间 (秒)
    public let idleTimeoutSeconds: TimeInterval

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.chinesechess", category: "EnginePool")
    private var idleCheckTimer: Timer?

    // MARK: - Initialization

    public init(
        configuration: EngineConfiguration,
        maxPoolSize: Int = 4,
        autoExpand: Bool = true,
        idleTimeoutSeconds: TimeInterval = 300
    ) {
        self.configurationTemplate = configuration
        self.maxPoolSize = maxPoolSize
        self.autoExpand = autoExpand
        self.idleTimeoutSeconds = idleTimeoutSeconds

        startIdleCheckTimer()
    }

    deinit {
        idleCheckTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// 从池中获取一个可用引擎
    public func acquire() async throws -> PooledEngine {
        // 首先查找可用的现有引擎
        if let availableEngine = engines.first(where: { !$0.isInUse }) {
            await availableEngine.markInUse()
            updateStats()
            return availableEngine
        }

        // 如果池未满，创建新引擎
        if engines.count < maxPoolSize && autoExpand {
            let newEngine = try await createNewEngine()
            await newEngine.markInUse()
            engines.append(newEngine)
            updateStats()
            return newEngine
        }

        // 池已满且没有可用引擎
        throw EnginePoolError.poolExhausted
    }

    /// 释放引擎回池中
    public func release(_ engine: PooledEngine) async {
        await engine.markIdle()
        updateStats()
    }

    /// 释放所有引擎
    public func releaseAll() async {
        for engine in engines {
            await engine.markIdle()
        }
        updateStats()
    }

    /// 关闭指定引擎
    public func shutdownEngine(_ engine: PooledEngine) async {
        await engine.shutdown()
        engines.removeAll { $0.id == engine.id }
        updateStats()
    }

    /// 关闭所有引擎
    public func shutdownAll() async {
        for engine in engines {
            await engine.shutdown()
        }
        engines.removeAll()
        updateStats()
    }

    /// 根据ID查找引擎
    public func findEngine(byId id: UUID) -> PooledEngine? {
        engines.first { $0.id == id }
    }

    /// 获取可用引擎列表
    public func getAvailableEngines() -> [PooledEngine] {
        engines.filter { !$0.isInUse }
    }

    /// 获取正在使用的引擎列表
    public func getInUseEngines() -> [PooledEngine] {
        engines.filter { $0.isInUse }
    }

    /// 预创建指定数量的引擎实例
    public func prewarm(count: Int) async -> [PooledEngine] {
        let targetCount = min(count, maxPoolSize)
        var prewarmedEngines: [PooledEngine] = []

        for _ in 0..<(targetCount - engines.count) {
            do {
                let engine = try await createNewEngine()
                engines.append(engine)
                prewarmedEngines.append(engine)
            } catch {
                logger.error("Failed to prewarm engine: \(error.localizedDescription)")
            }
        }

        updateStats()
        return prewarmedEngines
    }

    // MARK: - Private Methods

    private func createNewEngine() async throws -> PooledEngine {
        let engine = PooledEngine(configuration: configurationTemplate)
        try await engine.initialize()
        return engine
    }

    private func updateStats() {
        availableCount = engines.filter { !$0.isInUse }.count
        inUseCount = engines.filter { $0.isInUse }.count
        isFull = engines.count >= maxPoolSize && inUseCount == engines.count
    }

    private func startIdleCheckTimer() {
        idleCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkIdleEngines()
            }
        }
    }

    private func checkIdleEngines() async {
        let now = Date()
        let enginesToShutdown: [PooledEngine] = engines.filter { engine in
            guard !engine.isInUse else { return false }

            if let lastUsed = await engine.lastUsedAt {
                let idleTime = now.timeIntervalSince(lastUsed)
                return idleTime > idleTimeoutSeconds
            }

            return false
        }

        for engine in enginesToShutdown {
            logger.info("Shutting down idle engine: \(engine.id)")
            await shutdownEngine(engine)
        }
    }
}
