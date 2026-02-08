import Foundation
import Combine
import OSLog

// MARK: - EngineGameState

/// 引擎对弈状态
public enum EngineGameState: CustomStringConvertible, Sendable, Equatable {
    case idle           // 空闲
    case initializing // 正在初始化引擎
    case ready        // 引擎已就绪
    case waitingForHumanMove // 等待人类走棋
    case engineThinking // 引擎正在思考
    case engineMoving   // 引擎正在执行走棋
    case paused         // 已暂停
    case gameOver(GameResult) // 游戏结束
    case error(String)  // 错误

    public var description: String {
        switch self {
        case .idle:
            return "空闲"
        case .initializing:
            return "正在初始化引擎..."
        case .ready:
            return "引擎已就绪"
        case .waitingForHumanMove:
            return "等待走棋"
        case .engineThinking:
            return "引擎正在思考..."
        case .engineMoving:
            return "引擎正在走棋..."
        case .paused:
            return "已暂停"
        case .gameOver(let result):
            return "游戏结束: \(result.description)"
        case .error(let message):
            return "错误: \(message)"
        }
    }

    public var isActive: Bool {
        switch self {
        case .initializing, .ready, .waitingForHumanMove, .engineThinking, .engineMoving:
            return true
        default:
            return false
        }
    }

    public var canStart: Bool {
        switch self {
        case .idle, .ready, .paused:
            return true
        default:
            return false
        }
    }

    public var canPause: Bool {
        switch self {
        case .ready, .waitingForHumanMove, .engineThinking:
            return true
        default:
            return false
        }
    }

    public var isEngineThinking: Bool {
        if case .engineThinking = self {
            return true
        }
        return false
    }
}

// MARK: - EngineThinkingInfo

/// 引擎思考信息
public struct EngineThinkingInfo: Sendable, Equatable {
    public let depth: Int
    public let selDepth: Int
    public let score: EvaluationScore
    public let nodes: Int
    public let nps: Int
    public let timeMs: Int
    public let hashfull: Int
    public let currentMove: String?
    public let pv: [String]

    public init(
        depth: Int = 0,
        selDepth: Int = 0,
        score: EvaluationScore = .unknown,
        nodes: Int = 0,
        nps: Int = 0,
        timeMs: Int = 0,
        hashfull: Int = 0,
        currentMove: String? = nil,
        pv: [String] = []
    ) {
        self.depth = depth
        self.selDepth = selDepth
        self.score = score
        self.nodes = nodes
        self.nps = nps
        self.timeMs = timeMs
        self.hashfull = hashfull
        self.currentMove = currentMove
        self.pv = pv
    }

    /// 从 InfoData 创建
    public init(from infoData: InfoData) {
        self.depth = infoData.depth ?? 0
        self.selDepth = infoData.seldepth ?? 0
        self.score = infoData.score.map { EvaluationScore(from: $0) } ?? .unknown
        self.nodes = infoData.nodes ?? 0
        self.nps = infoData.nps ?? 0
        self.timeMs = infoData.time ?? 0
        self.hashfull = infoData.hashfull ?? 0
        self.currentMove = infoData.currmove
        self.pv = infoData.pv ?? []
    }
}

// MARK: - EngineGameController

/// 引擎对弈控制器
/// 管理人机和引擎之间的对弈流程
@MainActor
public final class EngineGameController: ObservableObject {

    // MARK: - Published Properties

    /// 当前对弈状态
    @Published public private(set) var state: EngineGameState = .idle

    /// 游戏模式配置
    @Published public var gameConfiguration: GameModeConfiguration

    /// 引擎思考信息
    @Published public private(set) var thinkingInfo: EngineThinkingInfo?

    /// 引擎最佳着法
    @Published public private(set) var engineBestMove: String?

    /// 引擎预思考着法
    @Published public private(set) var enginePonderMove: String?

    /// 是否正在等待人类走棋
    @Published public private(set) var isWaitingForHuman: Bool = false

    /// 是否正在思考
    @Published public private(set) var isThinking: Bool = false

    /// 引擎连接状态
    @Published public private(set) var isEngineConnected: Bool = false

    /// 当前局面FEN
    @Published public private(set) var currentFEN: String?

    /// 当前轮到谁走棋
    @Published public private(set) var currentPlayer: Player = .red

    // MARK: - Private Properties

    private var engine: PooledEngine?
    private var gameClock: GameClock?
    private var timeManager: TimeManager?
    private var enginePool: EnginePool?

    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private let logger = Logger(subsystem: "com.chinesechess", category: "EngineGameController")

    // MARK: - Callbacks

    public var onEngineMove: ((String, String?) -> Void)?
    public var onStateChanged: ((EngineGameState) -> Void)?
    public var onThinkingInfo: ((EngineThinkingInfo) -> Void)?
    public var onError: ((Error) -> Void)?

    // MARK: - Initialization

    public init(
        configuration: GameModeConfiguration = .humanVsEngine(),
        enginePool: EnginePool? = nil
    ) {
        self.gameConfiguration = configuration
        self.enginePool = enginePool
    }

    deinit {
        searchTask?.cancel()
    }

    // MARK: - Public Methods

    /// 初始化引擎
    public func initializeEngine() async throws {
        guard state == .idle else {
            throw EngineGameControllerError.invalidState("只能在空闲状态下初始化引擎")
        }

        state = .initializing

        do {
            // 从池中获取引擎或创建新引擎
            if let pool = enginePool {
                engine = try await pool.acquire()
            } else {
                // 创建独立引擎
                let config = getEngineConfiguration()
                let newEngine = PooledEngine(configuration: config)
                try await newEngine.initialize()
                engine = newEngine
            }

            // 应用引擎设置
            try await configureEngineSettings()

            isEngineConnected = true
            state = .ready

        } catch {
            state = .error("初始化引擎失败: \(error.localizedDescription)")
            isEngineConnected = false
            throw error
        }
    }

    /// 开始新游戏
    public func startNewGame(initialFEN: String? = nil) async {
        guard state.canStart || state == .ready else {
            logger.warning("Cannot start game from state: \(state)")
            return
        }

        // 确保引擎已连接
        if !isEngineConnected {
            do {
                try await initializeEngine()
            } catch {
                state = .error("无法初始化引擎: \(error.localizedDescription)")
                return
            }
        }

        // 重置游戏状态
        currentFEN = initialFEN ?? Board.initial().toFEN()
        currentPlayer = .red
        engineBestMove = nil
        enginePonderMove = nil
        thinkingInfo = nil

        // 通知引擎新游戏
        do {
            try await engine?.newGame()
        } catch {
            logger.warning("Failed to send ucinewgame: \(error.localizedDescription)")
        }

        // 设置初始局面
        if let fen = currentFEN {
            do {
                try await engine?.setPosition(fen: fen, moves: [])
            } catch {
                state = .error("设置局面失败: \(error.localizedDescription)")
                return
            }
        }

        // 检查是否需要引擎先走
        if shouldEngineMoveNow() {
            await startEngineThinking()
        } else {
            state = .waitingForHumanMove
            isWaitingForHuman = true
        }
    }

    /// 人类玩家走棋
    public func humanMove(_ move: String) async {
        guard state == .waitingForHumanMove || state == .ready else {
            logger.warning("Cannot make human move from state: \(state)")
            return
        }

        // 执行人类走棋
        // 这里应该通知游戏控制器执行走棋并更新局面

        // 检查游戏是否结束
        // 如果未结束，切换到引擎思考
        if shouldEngineMoveNow() {
            await startEngineThinking()
        }
    }

    /// 暂停对弈
    public func pauseGame() async {
        guard state.canPause else { return }

        if state == .engineThinking {
            // 停止引擎思考
            try? await engine?.stopSearch()
            searchTask?.cancel()
        }

        state = .paused
    }

    /// 恢复对弈
    public func resumeGame() async {
        guard state == .paused else { return }

        // 恢复当前状态
        if shouldEngineMoveNow() {
            await startEngineThinking()
        } else {
            state = .waitingForHumanMove
        }
    }

    /// 结束对弈
    public func stopGame() async {
        searchTask?.cancel()

        if let engine = engine {
            try? await engine.stopSearch()
        }

        state = .idle
        isWaitingForHuman = false
        isThinking = false
        thinkingInfo = nil
    }

    /// 关闭引擎
    public func shutdown() async {
        await stopGame()

        if let engine = engine {
            if let pool = enginePool {
                await pool.release(engine)
            } else {
                await engine.shutdown()
            }
            self.engine = nil
        }

        isEngineConnected = false
        state = .idle
    }

    // MARK: - Private Methods

    private func getEngineConfiguration() -> EngineConfiguration {
        // 从游戏配置获取引擎配置
        let engineId = gameConfiguration.redPlayerType == .engine
            ? gameConfiguration.redEngineConfigurationID
            : gameConfiguration.blackEngineConfigurationID

        // 这里应该从 EngineProfileManager 获取配置
        // 临时返回默认配置
        return EngineConfiguration.pikafishDefault
    }

    private func configureEngineSettings() async throws {
        guard let engine = engine else { return }

        // 设置哈希表大小
        try await engine.setOption(name: "Hash", value: "256")

        // 设置线程数
        try await engine.setOption(name: "Threads", value: "4")

        // 设置MultiPV
        let multiPV = gameConfiguration.enableMultiPV ? gameConfiguration.multiPVCount : 1
        try await engine.setOption(name: "MultiPV", value: String(multiPV))
    }

    private func shouldEngineMoveNow() -> Bool {
        // 检查当前轮到谁走棋
        let currentPlayerType = currentPlayer == .red
            ? gameConfiguration.redPlayerType
            : gameConfiguration.blackPlayerType

        return currentPlayerType == .engine
    }

    private func startEngineThinking() async {
        guard let engine = engine, let fen = currentFEN else {
            logger.error("Cannot start engine thinking: engine or FEN is nil")
            return
        }

        state = .engineThinking
        isThinking = true
        isWaitingForHuman = false
        thinkingInfo = nil

        // 设置当前局面
        do {
            try await engine.setPosition(fen: fen, moves: [])
        } catch {
            state = .error("设置局面失败: \(error.localizedDescription)")
            return
        }

        // 计算思考时间
        let goParams = calculateGoParameters()

        // 开始搜索任务
        searchTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                try await engine.startSearch(parameters: goParams)

                // 等待引擎返回最佳着法
                let result = try await engine.waitForBestMove(
                    timeout: .seconds(600) // 10分钟超时
                )

                guard !Task.isCancelled else { return }

                if let result = result {
                    await self.handleEngineMove(
                        bestMove: result.bestMove,
                        ponder: result.ponderMove
                    )
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.state = .error("搜索错误: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func calculateGoParameters() -> GoParameters {
        var params = GoParameters()

        // 根据时间控制设置参数
        switch gameConfiguration.timeControl {
        case .fixedDepth:
            if let depth = gameConfiguration.searchDepth {
                params.depth = depth
            }

        case .fixedTime:
            if let time = gameConfiguration.thinkingTimeLimitMs {
                params.movetime = time
            }

        case .standard:
            // 使用时间管理器计算时间
            let (initialTime, increment) = gameConfiguration.getTimeControl(for: currentPlayer)

            if currentPlayer == .red {
                params.wtime = initialTime
                params.winc = increment
            } else {
                params.btime = initialTime
                params.binc = increment
            }

        case .infinite:
            params.infinite = true
        }

        return params
    }

    private func handleEngineMove(bestMove: String, ponder: String?) async {
        engineBestMove = bestMove
        enginePonderMove = ponder

        state = .engineMoving
        isThinking = false

        // 通知外部引擎已经选择着法
        onEngineMove?(bestMove, ponder)

        // 状态将在外部执行着法后更新
    }
}

// MARK: - EngineGameControllerError

public enum EngineGameControllerError: Error, CustomStringConvertible {
    case invalidState(String)
    case engineNotInitialized
    case invalidMove(String)

    public var description: String {
        switch self {
        case .invalidState(let message):
            return "无效状态: \(message)"
        case .engineNotInitialized:
            return "引擎未初始化"
        case .invalidMove(let message):
            return "无效着法: \(message)"
        }
    }
}
