import Foundation

// MARK: - TimeManagerError

/// 时间管理器错误
public enum TimeManagerError: Error, CustomStringConvertible {
    case invalidTimeControl
    case engineNotAvailable
    case gameNotStarted

    public var description: String {
        switch self {
        case .invalidTimeControl:
            return "无效的时间控制设置"
        case .engineNotAvailable:
            return "引擎不可用"
        case .gameNotStarted:
            return "游戏尚未开始"
        }
    }
}

// MARK: - TimeManager

/// 时间管理器
/// 自动计算引擎思考时间，管理保留时间策略
@MainActor
public final class TimeManager: ObservableObject {

    // MARK: - Published Properties

    /// 建议的思考时间 (毫秒)
    @Published public private(set) var suggestedThinkingTimeMs: Int = 0

    /// 最大思考时间 (毫秒)
    @Published public private(set) var maxThinkingTimeMs: Int = 0

    /// 剩余时间紧急度 (0.0 - 1.0)
    @Published public private(set) var timePressureLevel: Double = 0.0

    /// 当前使用的搜索深度 (如果适用)
    @Published public private(set) var currentSearchDepth: Int?

    /// 是否使用固定深度模式
    @Published public private(set) var isFixedDepth: Bool = false

    // MARK: - Configuration

    /// 保留时间比例 (0.0 - 1.0)
    public var reserveTimeRatio: Double = 0.1

    /// 最小思考时间 (毫秒)
    public var minThinkingTimeMs: Int = 1_000

    /// 最大思考时间比例 (相对于剩余时间)
    public var maxThinkingTimeRatio: Double = 0.2

    /// 低时间阈值比例 (剩余时间低于此比例时进入紧急模式)
    public var lowTimeThresholdRatio: Double = 0.15

    /// 复杂局面的额外思考时间比例
    public var complexPositionExtraTimeRatio: Double = 0.3

    // MARK: - Private Properties

    private var gameClock: GameClock?
    private var timeControlSettings: TimeControlSettings?

    // MARK: - Initialization

    public init(
        reserveTimeRatio: Double = 0.1,
        minThinkingTimeMs: Int = 1_000
    ) {
        self.reserveTimeRatio = reserveTimeRatio
        self.minThinkingTimeMs = minThinkingTimeMs
    }

    // MARK: - Public Methods

    /// 设置游戏时钟引用
    public func setGameClock(_ clock: GameClock) {
        self.gameClock = clock
    }

    /// 设置时间控制设置
    public func setTimeControlSettings(_ settings: TimeControlSettings) {
        self.timeControlSettings = settings

        // 检查是否为固定深度模式
        isFixedDepth = settings.type == .fixedDepth
        currentSearchDepth = settings.fixedDepth
    }

    /// 计算建议的思考时间
    /// - Parameters:
    ///   - player: 当前玩家
    ///   - moveNumber: 当前步数
    ///   - complexity: 局面复杂度评估 (0.0 - 1.0)
    /// - Returns: 建议的思考时间 (毫秒)
    public func calculateThinkingTime(
        for player: Player,
        moveNumber: Int,
        complexity: Double = 0.5
    ) -> Int {
        // 检查是否为固定深度或固定时间模式
        if let settings = timeControlSettings {
            switch settings.type {
            case .fixedDepth:
                // 固定深度模式，不限制时间
                return 0

            case .fixedTime:
                // 固定时间模式
                if let fixedTime = settings.fixedTimeMs {
                    return fixedTime
                }

            case .infinite:
                // 无限时间模式
                return 0

            case .standard:
                // 标准计时模式，继续计算
                break
            }
        }

        guard let clock = gameClock else {
            // 没有时钟时返回默认时间
            return minThinkingTimeMs
        }

        // 获取剩余时间
        let remainingTimeMs = clock.getTime(for: player)

        // 计算时间压力级别 (0.0 - 1.0)
        let initialTimeMs = player == .red
            ? (clock.redTimeRemainingMs > 0 ? clock.redTimeRemainingMs : remainingTimeMs)
            : (clock.blackTimeRemainingMs > 0 ? clock.blackTimeRemainingMs : remainingTimeMs)

        let pressureLevel = initialTimeMs > 0
            ? 1.0 - (Double(remainingTimeMs) / Double(initialTimeMs))
            : 0.0

        timePressureLevel = min(max(pressureLevel, 0.0), 1.0)

        // 检查是否处于低时间紧急状态
        let isLowTime = Double(remainingTimeMs) < Double(initialTimeMs) * lowTimeThresholdRatio

        // 计算基础思考时间
        var baseTimeMs: Int

        if isLowTime {
            // 低时间紧急状态：使用更少的时间
            baseTimeMs = max(minThinkingTimeMs, remainingTimeMs / 20)
        } else {
            // 正常状态：使用剩余时间的一定比例
            let targetMovesRemaining = max(20, 40 - moveNumber)
            let timePerMove = remainingTimeMs / targetMovesRemaining

            // 应用保留时间策略
            let reserveTime = Int(Double(remainingTimeMs) * reserveTimeRatio)
            let usableTime = remainingTimeMs - reserveTime
            let usableTimePerMove = usableTime / targetMovesRemaining

            baseTimeMs = max(timePerMove, usableTimePerMove)
        }

        // 根据局面复杂度调整
        let complexityMultiplier = 1.0 + (complexity * complexPositionExtraTimeRatio)
        let adjustedTimeMs = Int(Double(baseTimeMs) * complexityMultiplier)

        // 应用最大时间限制
        let maxTimeMs = Int(Double(remainingTimeMs) * maxThinkingTimeRatio)
        let finalTimeMs = min(adjustedTimeMs, maxTimeMs)

        // 确保不低于最小思考时间
        suggestedThinkingTimeMs = max(finalTimeMs, minThinkingTimeMs)
        maxThinkingTimeMs = max(maxTimeMs, minThinkingTimeMs)

        return suggestedThinkingTimeMs
    }

    /// 获取当前时间的UCI go 命令参数
    public func getGoParameters(for player: Player) -> GoParameters {
        // 如果是固定深度模式
        if isFixedDepth, let depth = currentSearchDepth {
            return GoParameters(depth: depth)
        }

        // 如果是固定时间模式
        if let settings = timeControlSettings,
           settings.type == .fixedTime,
           let fixedTime = settings.fixedTimeMs {
            return GoParameters(movetime: fixedTime)
        }

        // 如果是无限时间模式
        if let settings = timeControlSettings,
           settings.type == .infinite {
            return GoParameters(infinite: true)
        }

        // 标准计时模式
        guard let clock = gameClock else {
            return GoParameters(infinite: true)
        }

        let wtime = clock.getTime(for: .red)
        let btime = clock.getTime(for: .black)

        let settings = timeControlSettings
        let winc = settings?.incrementMs ?? 0
        let binc = settings?.incrementMs ?? 0

        return GoParameters(
            wtime: wtime,
            btime: btime,
            winc: winc,
            binc: binc
        )
    }

    /// 重置时间管理器
    public func reset() {
        suggestedThinkingTimeMs = 0
        maxThinkingTimeMs = 0
        timePressureLevel = 0.0
        currentSearchDepth = nil
        isFixedDepth = false
    }
}

// MARK: - TimeControl Presets

/// 时间控制预设
public enum TimeControlPreset: String, CaseIterable, Sendable, Identifiable, CustomStringConvertible {
    case bullet1Plus0 = "1+0"
    case bullet1Plus1 = "1+1"
    case bullet2Plus1 = "2+1"
    case blitz3Plus0 = "3+0"
    case blitz3Plus2 = "3+2"
    case blitz5Plus0 = "5+0"
    case blitz5Plus3 = "5+3"
    case rapid10Plus0 = "10+0"
    case rapid10Plus5 = "10+5"
    case rapid15Plus10 = "15+10"
    case classical30Plus0 = "30+0"
    case classical30Plus20 = "30+20"
    case custom = "custom"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .custom:
            return "自定义"
        default:
            return rawValue
        }
    }

    /// 完整显示名称
    public var displayName: String {
        switch self {
        case .bullet1Plus0:
            return "闪电战 (1+0)"
        case .bullet1Plus1:
            return "闪电战 (1+1)"
        case .bullet2Plus1:
            return "闪电战 (2+1)"
        case .blitz3Plus0:
            return "快棋 (3+0)"
        case .blitz3Plus2:
            return "快棋 (3+2)"
        case .blitz5Plus0:
            return "快棋 (5+0)"
        case .blitz5Plus3:
            return "快棋 (5+3)"
        case .rapid10Plus0:
            return "标准 (10+0)"
        case .rapid10Plus5:
            return "标准 (10+5)"
        case .rapid15Plus10:
            return "标准 (15+10)"
        case .classical30Plus0:
            return "慢棋 (30+0)"
        case .classical30Plus20:
            return "慢棋 (30+20)"
        case .custom:
            return "自定义设置"
        }
    }

    /// 初始时间 (毫秒)
    public var initialTimeMs: Int {
        switch self {
        case .bullet1Plus0, .bullet1Plus1:
            return 60_000
        case .bullet2Plus1:
            return 120_000
        case .blitz3Plus0, .blitz3Plus2:
            return 180_000
        case .blitz5Plus0, .blitz5Plus3:
            return 300_000
        case .rapid10Plus0, .rapid10Plus5:
            return 600_000
        case .rapid15Plus10:
            return 900_000
        case .classical30Plus0, .classical30Plus20:
            return 1_800_000
        case .custom:
            return 600_000
        }
    }

    /// 每步增量 (毫秒)
    public var incrementMs: Int {
        switch self {
        case .bullet1Plus0:
            return 0
        case .bullet1Plus1, .bullet2Plus1:
            return 1_000
        case .blitz3Plus0:
            return 0
        case .blitz3Plus2:
            return 2_000
        case .blitz5Plus0:
            return 0
        case .blitz5Plus3:
            return 3_000
        case .rapid10Plus0:
            return 0
        case .rapid10Plus5:
            return 5_000
        case .rapid15Plus10:
            return 10_000
        case .classical30Plus0:
            return 0
        case .classical30Plus20:
            return 20_000
        case .custom:
            return 0
        }
    }

    /// 转换为时间控制设置
    public func toTimeControlSettings() -> TimeControlSettings {
        TimeControlSettings.standard(
            initialTimeMs: initialTimeMs,
            incrementMs: incrementMs
        )
    }
}
