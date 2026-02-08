import Foundation
import Combine
import OSLog

// MARK: - AnalysisState

/// 分析状态
public enum AnalysisState: CustomStringConvertible, Sendable, Equatable {
    case idle           // 空闲
    case initializing // 正在初始化
    case analyzing    // 正在分析
    case paused       // 已暂停
    case completed    // 已完成
    case error(String) // 错误

    public var description: String {
        switch self {
        case .idle:
            return "空闲"
        case .initializing:
            return "正在初始化..."
        case .analyzing:
            return "正在分析..."
        case .paused:
            return "已暂停"
        case .completed:
            return "已完成"
        case .error(let message):
            return "错误: \(message)"
        }
    }

    public var isAnalyzing: Bool {
        if case .analyzing = self {
            return true
        }
        return false
    }

    public var canStart: Bool {
        switch self {
        case .idle, .paused, .completed, .error:
            return true
        case .initializing, .analyzing:
            return false
        }
    }

    public var canStop: Bool {
        switch self {
        case .analyzing, .paused:
            return true
        default:
            return false
        }
    }
}

// MARK: - AnalysisSettings

/// 分析设置
public struct AnalysisSettings: Sendable, Equatable, Codable {

    /// 多线分析数量
    public var multiPV: Int

    /// 搜索深度限制 (0表示无限制)
    public var maxDepth: Int

    /// 最大分析时间 (毫秒, 0表示无限制)
    public var maxTimeMs: Int

    /// 是否显示当前正在分析的着法
    public var showCurrentMove: Bool

    /// 是否显示搜索统计
    public var showSearchStats: Bool

    /// 是否自动开始分析
    public var autoStart: Bool

    /// 哈希表大小 (MB)
    public var hashSizeMB: Int

    /// 线程数
    public var threads: Int

    public init(
        multiPV: Int = 3,
        maxDepth: Int = 0,
        maxTimeMs: Int = 0,
        showCurrentMove: Bool = true,
        showSearchStats: Bool = true,
        autoStart: Bool = false,
        hashSizeMB: Int = 256,
        threads: Int = 4
    ) {
        self.multiPV = max(1, min(multiPV, 10))
        self.maxDepth = max(0, maxDepth)
        self.maxTimeMs = max(0, maxTimeMs)
        self.showCurrentMove = showCurrentMove
        self.showSearchStats = showSearchStats
        self.autoStart = autoStart
        self.hashSizeMB = max(1, hashSizeMB)
        self.threads = max(1, threads)
    }

    /// 默认设置
    public static let `default` = AnalysisSettings()

    /// 深度优先设置
    public static let depthFirst = AnalysisSettings(
        multiPV: 1,
        maxDepth: 20,
        showCurrentMove: false
    )

    /// 时间优先设置
    public static let timeFirst = AnalysisSettings(
        multiPV: 3,
        maxTimeMs: 10_000
    )

    /// 快速分析设置
    public static let quick = AnalysisSettings(
        multiPV: 1,
        maxDepth: 15,
        maxTimeMs: 5_000
    )

    /// 深入分析设置
    public static let deep = AnalysisSettings(
        multiPV: 5,
        maxDepth: 30,
        showSearchStats: true,
        hashSizeMB: 512
    )
}

// MARK: - AnalysisController

/// 分析控制器
/// 管理局面分析流程，支持多线分析、评估分数展示等
@MainActor
public final class AnalysisController: ObservableObject {

    // MARK: - Published Properties

    /// 当前分析状态
    @Published public private(set) var state: AnalysisState = .idle

    /// 当前分析的FEN
    @Published public private(set) var currentFEN: String?

    /// 分析变例列表
    @Published public private(set) var variations: [Variation] = []

    /// 最佳着法
    @Published public private(set) var bestMove: String?

    /// 当前正在分析的着法
    @Published public private(set) var currentMove: String?

    /// 当前分析的着法序号
    @Published public private(set) var currentMoveNumber: Int?

    /// 搜索深度
    @Published public private(set) var searchDepth: Int = 0

    /// 选择性搜索深度
    @Published public private(set) var selDepth: Int = 0

    /// 搜索节点数
    @Published public private(set) var nodes: Int = 0

    /// 每秒节点数 (NPS)
    @Published public private(set) var nps: Int = 0

    /// 哈希表填充率 (0-1000)
    @Published public private(set) var hashfull: Int = 0

    /// 搜索时间 (毫秒)
    @Published public private(set) var searchTimeMs: Int = 0

    /// 分析设置
    @Published public var settings: AnalysisSettings

    // MARK: - Private Properties

    private var engine: PooledEngine?
    private var startTime: Date?
    private var searchTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.chinesechess", category: "AnalysisController")

    // MARK: - Initialization

    public init(settings: AnalysisSettings = .default) {
        self.settings = settings
    }

    deinit {
        searchTask?.cancel()
    }

    // MARK: - Public Methods

    /// 设置引擎
    public func setEngine(_ engine: PooledEngine) {
        self.engine = engine
    }

    /// 开始分析局面
    public func startAnalysis(fen: String) async {
        guard state.canStart else {
            logger.warning("Cannot start analysis from state: \(state)")
            return
        }

        // 停止当前分析
        if state.isAnalyzing {
            await stopAnalysis()
        }

        guard let engine = engine else {
            state = .error("未设置分析引擎")
            return
        }

        state = .initializing
        currentFEN = fen
        resetStats()

        // 配置引擎
        do {
            try await configureEngine(engine)
        } catch {
            state = .error("配置引擎失败: \(error.localizedDescription)")
            return
        }

        // 设置局面
        do {
            try await engine.setPosition(fen: fen, moves: [])
        } catch {
            state = .error("设置局面失败: \(error.localizedDescription)")
            return
        }

        // 开始搜索
        state = .analyzing
        startTime = Date()

        searchTask = Task { [weak self] in
            await self?.runSearch(engine: engine)
        }
    }

    /// 停止分析
    public func stopAnalysis() async {
        guard state.canStop else { return }

        searchTask?.cancel()

        if let engine = engine {
            try? await engine.stopSearch()
        }

        state = .idle
        startTime = nil
    }

    /// 暂停分析
    public func pauseAnalysis() async {
        guard state == .analyzing else { return }

        if let engine = engine {
            try? await engine.stopSearch()
        }

        state = .paused
    }

    /// 恢复分析
    public func resumeAnalysis() async {
        guard state == .paused, let fen = currentFEN else { return }

        await startAnalysis(fen: fen)
    }

    /// 清除分析结果
    public func clearResults() {
        variations = []
        bestMove = nil
        currentMove = nil
        searchDepth = 0
        nodes = 0
        nps = 0
    }

    // MARK: - Private Methods

    private func configureEngine(_ engine: PooledEngine) async throws {
        // 设置哈希表大小
        if settings.hashSizeMB > 0 {
            try await engine.setOption(name: "Hash", value: String(settings.hashSizeMB))
        }

        // 设置线程数
        if settings.threads > 0 {
            try await engine.setOption(name: "Threads", value: String(settings.threads))
        }

        // 设置MultiPV
        if settings.multiPV > 1 {
            try await engine.setOption(name: "MultiPV", value: String(settings.multiPV))
        }
    }

    private func runSearch(engine: PooledEngine) async {
        // 构建go命令参数
        var goParams = GoParameters()

        if settings.maxDepth > 0 {
            goParams.depth = settings.maxDepth
        }

        if settings.maxTimeMs > 0 {
            goParams.movetime = settings.maxTimeMs
        }

        // 如果既没有深度限制也没有时间限制，使用无限模式
        if goParams.depth == nil && goParams.movetime == nil {
            goParams.infinite = true
        }

        // 开始搜索
        do {
            try await engine.startSearch(parameters: goParams)

            // 监听搜索结果
            try await listenForResults(engine: engine)
        } catch {
            if !Task.isCancelled {
                logger.error("Search error: \(error.localizedDescription)")
                state = .error(error.localizedDescription)
            }
        }
    }

    private func listenForResults(engine: PooledEngine) async throws {
        // 这里应该监听引擎的输出并更新UI
        // 实际实现需要与具体的引擎管理器集成

        // 等待搜索完成
        _ = try await engine.waitForBestMove(timeout: .seconds(3600))

        if !Task.isCancelled {
            state = .completed
        }
    }

    private func resetStats() {
        variations = []
        bestMove = nil
        currentMove = nil
        currentMoveNumber = nil
        searchDepth = 0
        selDepth = 0
        nodes = 0
        nps = 0
        hashfull = 0
        searchTimeMs = 0
    }

    // MARK: - Update Methods (called from external info parsing)

    /// 更新分析信息 (从引擎输出解析后调用)
    public func updateInfo(_ info: InfoData) {
        // 更新深度
        if let depth = info.depth {
            searchDepth = depth
        }

        if let seldepth = info.seldepth {
            selDepth = seldepth
        }

        // 更新节点信息
        if let nodes = info.nodes {
            self.nodes = nodes
        }

        if let nps = info.nps {
            self.nps = nps
        }

        if let hashfull = info.hashfull {
            self.hashfull = hashfull
        }

        // 更新时间
        if let time = info.time {
            searchTimeMs = time
        } else if let startTime = startTime {
            searchTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)
        }

        // 更新当前着法
        if let currmove = info.currmove {
            currentMove = currmove
        }

        if let currmovenumber = info.currmovenumber {
            currentMoveNumber = currmovenumber
        }

        // 更新变例 (如果有PV和分数)
        if let score = info.score, let pv = info.pv, !pv.isEmpty {
            let variation = Variation(
                multipv: info.multipv ?? 1,
                score: EvaluationScore(from: score),
                depth: info.depth ?? searchDepth,
                seldepth: info.seldepth,
                moves: pv,
                nodes: info.nodes,
                nps: info.nps,
                hashfull: info.hashfull
            )

            updateOrAddVariation(variation)
        }
    }

    /// 更新最佳着法 (从 bestmove 响应调用)
    public func setBestMove(_ move: String, ponder: String? = nil) {
        bestMove = move

        // 如果最佳着法不在变例中，添加一个
        if !variations.contains(where: { $0.moves.first == move }) {
            let variation = Variation(
                multipv: variations.count + 1,
                score: .unknown,
                depth: searchDepth,
                moves: [move] + (ponder.map { [$0] } ?? [])
            )
            variations.append(variation)
        }
    }

    // MARK: - Private Methods

    private func updateOrAddVariation(_ newVariation: Variation) {
        if let index = variations.firstIndex(where: { $0.multipv == newVariation.multipv }) {
            variations[index] = newVariation
        } else {
            variations.append(newVariation)
            variations.sort { $0.multipv < $1.multipv }
        }
    }
}
