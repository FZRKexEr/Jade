import Foundation

// MARK: - PlayerType

/// 玩家类型
public enum PlayerType: String, CaseIterable, Sendable, CustomStringConvertible, Identifiable, Codable {
    case human = "human"
    case engine = "engine"

    public var id: String { rawValue }

    public var description: String {
        displayName
    }

    public var displayName: String {
        switch self {
        case .human:
            return "人类"
        case .engine:
            return "引擎"
        }
    }

    public var iconName: String {
        switch self {
        case .human:
            return "person.fill"
        case .engine:
            return "cpu.fill"
        }
    }
}

// MARK: - GameModeConfiguration

/// 游戏模式配置
/// 定义对弈模式的具体配置，包括执棋方、引擎设置等
public struct GameModeConfiguration: Sendable, CustomStringConvertible, Codable, Equatable {

    /// 当前游戏模式
    public var mode: GameMode

    /// 红方玩家类型
    public var redPlayerType: PlayerType

    /// 黑方玩家类型
    public var blackPlayerType: PlayerType

    /// 红方引擎配置ID (如果是引擎对弈)
    public var redEngineConfigurationID: UUID?

    /// 黑方引擎配置ID (如果是引擎对弈)
    public var blackEngineConfigurationID: UUID?

    /// 时间控制配置
    public var timeControl: TimeControlConfiguration

    /// 红方初始时间 (毫秒)
    public var redInitialTimeMs: Int

    /// 黑方初始时间 (毫秒)
    public var blackInitialTimeMs: Int

    /// 每步增量时间 (毫秒)
    public var incrementMs: Int

    /// 是否启用思考时间限制
    public var enableThinkingTimeLimit: Bool

    /// 思考时间限制 (毫秒)
    public var thinkingTimeLimitMs: Int?

    /// 搜索深度限制 (用于固定深度模式)
    public var searchDepth: Int?

    /// 是否允许多线分析
    public var enableMultiPV: Bool

    /// 多线分析数量
    public var multiPVCount: Int

    /// 是否显示引擎思考信息
    public var showThinkingInfo: Bool

    /// 创建时间戳
    public let createdAt: Date

    /// 创建者用户ID (如果是本地创建则为nil)
    public var createdBy: String?

    // MARK: - Initialization

    public init(
        mode: GameMode = .humanVsEngine,
        redPlayerType: PlayerType = .human,
        blackPlayerType: PlayerType = .engine,
        redEngineConfigurationID: UUID? = nil,
        blackEngineConfigurationID: UUID? = nil,
        timeControl: TimeControlConfiguration = .standard,
        redInitialTimeMs: Int = 600_000,  // 10分钟
        blackInitialTimeMs: Int = 600_000,
        incrementMs: Int = 0,
        enableThinkingTimeLimit: Bool = false,
        thinkingTimeLimitMs: Int? = nil,
        searchDepth: Int? = nil,
        enableMultiPV: Bool = false,
        multiPVCount: Int = 3,
        showThinkingInfo: Bool = true,
        createdAt: Date = Date(),
        createdBy: String? = nil
    ) {
        self.mode = mode
        self.redPlayerType = redPlayerType
        self.blackPlayerType = blackPlayerType
        self.redEngineConfigurationID = redEngineConfigurationID
        self.blackEngineConfigurationID = blackEngineConfigurationID
        self.timeControl = timeControl
        self.redInitialTimeMs = redInitialTimeMs
        self.blackInitialTimeMs = blackInitialTimeMs
        self.incrementMs = incrementMs
        self.enableThinkingTimeLimit = enableThinkingTimeLimit
        self.thinkingTimeLimitMs = thinkingTimeLimitMs
        self.searchDepth = searchDepth
        self.enableMultiPV = enableMultiPV
        self.multiPVCount = multiPVCount
        self.showThinkingInfo = showThinkingInfo
        self.createdAt = createdAt
        self.createdBy = createdBy
    }

    // MARK: - Factory Methods

    /// 创建人机对弈配置
    public static func humanVsEngine(
        humanColor: Player = .red,
        engineConfigurationID: UUID? = nil,
        timeControl: TimeControlConfiguration = .standard
    ) -> GameModeConfiguration {
        let redType: PlayerType = humanColor == .red ? .human : .engine
        let blackType: PlayerType = humanColor == .black ? .human : .engine

        return GameModeConfiguration(
            mode: .humanVsEngine,
            redPlayerType: redType,
            blackPlayerType: blackType,
            redEngineConfigurationID: humanColor == .black ? engineConfigurationID : nil,
            blackEngineConfigurationID: humanColor == .red ? engineConfigurationID : nil,
            timeControl: timeControl
        )
    }

    /// 创建人人对弈配置
    public static func humanVsHuman(
        timeControl: TimeControlConfiguration = .standard
    ) -> GameModeConfiguration {
        GameModeConfiguration(
            mode: .humanVsHuman,
            redPlayerType: .human,
            blackPlayerType: .human,
            timeControl: timeControl
        )
    }

    /// 创建机机对弈配置
    public static func engineVsEngine(
        redEngineConfigurationID: UUID? = nil,
        blackEngineConfigurationID: UUID? = nil,
        timeControl: TimeControlConfiguration = .standard
    ) -> GameModeConfiguration {
        GameModeConfiguration(
            mode: .engineVsEngine,
            redPlayerType: .engine,
            blackPlayerType: .engine,
            redEngineConfigurationID: redEngineConfigurationID,
            blackEngineConfigurationID: blackEngineConfigurationID,
            timeControl: timeControl
        )
    }

    /// 创建分析模式配置
    public static func analysis(
        engineConfigurationID: UUID? = nil
    ) -> GameModeConfiguration {
        GameModeConfiguration(
            mode: .analysis,
            redPlayerType: .human,
            blackPlayerType: .human,
            redEngineConfigurationID: engineConfigurationID,
            timeControl: .infinite,
            enableMultiPV: true,
            multiPVCount: 3,
            showThinkingInfo: true
        )
    }

    // MARK: - Computed Properties

    /// 当前轮到哪个玩家类型
    public func currentPlayerType(_ currentPlayer: Player) -> PlayerType {
        currentPlayer == .red ? redPlayerType : blackPlayerType
    }

    /// 指定玩家类型的引擎配置ID
    public func engineConfigurationID(for player: Player) -> UUID? {
        player == .red ? redEngineConfigurationID : blackEngineConfigurationID
    }

    /// 是否需要引擎参与
    public var requiresEngine: Bool {
        redPlayerType == .engine || blackPlayerType == .engine
    }

    /// 当前是否为分析模式
    public var isAnalysisMode: Bool {
        mode == .analysis
    }

    /// 获取指定方的时间控制参数
    public func getTimeControl(for player: Player) -> (initialTimeMs: Int, incrementMs: Int) {
        let initialTime = player == .red ? redInitialTimeMs : blackInitialTimeMs
        return (initialTimeMs: initialTime, incrementMs: incrementMs)
    }

    public var description: String {
        """
        GameModeConfiguration:
        Mode: \(mode.displayName)
        Red: \(redPlayerType.displayName)
        Black: \(blackPlayerType.displayName)
        Time Control: \(timeControl.displayName)
        """
    }
}

// MARK: - TimeControlConfiguration

/// 时间控制配置类型
public enum TimeControlConfiguration: String, CaseIterable, Sendable, CustomStringConvertible, Identifiable, Codable {
    case fixedDepth = "fixedDepth"
    case fixedTime = "fixedTime"
    case standard = "standard"
    case blitz = "blitz"
    case rapid = "rapid"
    case classical = "classical"
    case infinite = "infinite"

    public var id: String { rawValue }

    public var description: String {
        displayName
    }

    public var displayName: String {
        switch self {
        case .fixedDepth:
            return "固定深度"
        case .fixedTime:
            return "固定时间"
        case .standard:
            return "标准"
        case .blitz:
            return "快棋"
        case .rapid:
            return "超快棋"
        case .classical:
            return "慢棋"
        case .infinite:
            return "无限时间"
        }
    }

    /// 默认初始时间 (毫秒)
    public var defaultInitialTimeMs: Int? {
        switch self {
        case .fixedDepth, .fixedTime, .infinite:
            return nil
        case .blitz:
            return 180_000  // 3分钟
        case .rapid:
            return 60_000   // 1分钟
        case .standard:
            return 600_000  // 10分钟
        case .classical:
            return 1_800_000 // 30分钟
        }
    }

    /// 默认增量时间 (毫秒)
    public var defaultIncrementMs: Int {
        switch self {
        case .fixedDepth, .fixedTime, .infinite:
            return 0
        case .blitz:
            return 2_000   // 2秒
        case .rapid:
            return 1_000   // 1秒
        case .standard:
            return 5_000   // 5秒
        case .classical:
            return 10_000  // 10秒
        }
    }

    /// 默认搜索深度
    public var defaultSearchDepth: Int? {
        switch self {
        case .fixedDepth:
            return 15
        default:
            return nil
        }
    }

    /// 默认固定思考时间 (毫秒)
    public var defaultFixedTimeMs: Int? {
        switch self {
        case .fixedTime:
            return 5_000  // 5秒
        default:
            return nil
        }
    }
}
