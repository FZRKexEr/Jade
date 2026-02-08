import Foundation
import Combine
import OSLog

// MARK: - EngineMatchResult

/// 引擎对战结果
public struct EngineMatchResult: CustomStringConvertible, Sendable, Codable {
    public let id: UUID
    public let redEngineId: UUID
    public let blackEngineId: UUID
    public let redEngineName: String
    public let blackEngineName: String
    public let winner: Player?
    public let result: GameResult
    public let totalMoves: Int
    public let redTimeRemainingMs: Int
    public let blackTimeRemainingMs: Int
    public let startTime: Date
    public let endTime: Date
    public let isReversed: Bool  // 是否是交换先后手的对局

    public init(
        id: UUID = UUID(),
        redEngineId: UUID,
        blackEngineId: UUID,
        redEngineName: String,
        blackEngineName: String,
        winner: Player?,
        result: GameResult,
        totalMoves: Int,
        redTimeRemainingMs: Int,
        blackTimeRemainingMs: Int,
        startTime: Date,
        endTime: Date,
        isReversed: Bool = false
    ) {
        self.id = id
        self.redEngineId = redEngineId
        self.blackEngineId = blackEngineId
        self.redEngineName = redEngineName
        self.blackEngineName = blackEngineName
        self.winner = winner
        self.result = result
        self.totalMoves = totalMoves
        self.redTimeRemainingMs = redTimeRemainingMs
        self.blackTimeRemainingMs = blackTimeRemainingMs
        self.startTime = startTime
        self.endTime = endTime
        self.isReversed = isReversed
    }

    public var description: String {
        let resultStr: String
        switch result {
        case .win(let player, _):
            resultStr = "\(player == .red ? "红方" : "黑方")胜"
        case .draw(_):
            resultStr = "和棋"
        case .ongoing:
            resultStr = "进行中"
        }

        return "\(redEngineName)(红) vs \(blackEngineName)(黑) - \(resultStr) (\(totalMoves)步)"
    }

    /// 对局时长 (秒)
    public var durationSeconds: Int {
        Int(endTime.timeIntervalSince(startTime))
    }

    /// 格式化时长
    public var durationFormatted: String {
        let seconds = durationSeconds
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - EngineMatchStatistics

/// 引擎对战统计
public struct EngineMatchStatistics: CustomStringConvertible, Sendable, Codable {
    public let engineAId: UUID
    public let engineBId: UUID
    public let engineAName: String
    public let engineBName: String

    public var totalGames: Int = 0
    public var engineAWins: Int = 0
    public var engineBWins: Int = 0
    public var draws: Int = 0

    public var engineAWinsAsRed: Int = 0
    public var engineAWinsAsBlack: Int = 0
    public var engineBWinsAsRed: Int = 0
    public var engineBWinsAsBlack: Int = 0

    public init(engineAId: UUID, engineBId: UUID, engineAName: String, engineBName: String) {
        self.engineAId = engineAId
        self.engineBId = engineBId
        self.engineAName = engineAName
        self.engineBName = engineBName
    }

    public var description: String {
        """
        \(engineAName) vs \(engineBName)
        总对局: \(totalGames)
        \(engineAName): 胜\(engineAWins) 负\(engineBWins) 和\(draws) (胜率: \(engineAWinRate, specifier: "%.1f")%)
        \(engineBName): 胜\(engineBWins) 负\(engineAWins) 和\(draws) (胜率: \(engineBWinRate, specifier: "%.1f")%)
        """
    }

    public var engineAWinRate: Double {
        guard totalGames > 0 else { return 0.0 }
        return Double(engineAWins) / Double(totalGames) * 100.0
    }

    public var engineBWinRate: Double {
        guard totalGames > 0 else { return 0.0 }
        return Double(engineBWins) / Double(totalGames) * 100.0
    }

    public var drawRate: Double {
        guard totalGames > 0 else { return 0.0 }
        return Double(draws) / Double(totalGames) * 100.0
    }

    /// 记录对局结果
    public mutating func recordGame(_ result: EngineMatchResult) {
        totalGames += 1

        let isAasRed = result.redEngineId == engineAId

        switch result.result {
        case .win(let winner, _):
            if winner == .red {
                if isAasRed {
                    engineAWins += 1
                    engineAWinsAsRed += 1
                } else {
                    engineBWins += 1
                    engineBWinsAsRed += 1
                }
            } else {
                if isAasRed {
                    engineBWins += 1
                    engineBWinsAsBlack += 1
                } else {
                    engineAWins += 1
                    engineAWinsAsBlack += 1
                }
            }
        case .draw(_):
            draws += 1
        case .ongoing:
            break
        }
    }
}

// MARK: - EngineMatchController

/// 引擎对战控制器
/// 管理两个引擎之间的对战，支持多轮对战、交换先后手、统计等
@MainActor
public final class EngineMatchController: ObservableObject {

    // MARK: - Published Properties

    /// 当前对战状态
    @Published public private(set) var state: EngineGameState = .idle

    /// 引擎A配置
    @Published public var engineAProfile: EngineProfile

    /// 引擎B配置
    @Published public var engineBProfile: EngineProfile

    /// 当前对局结果列表
    @Published public private(set) var matchResults: [EngineMatchResult] = []

    /// 对战统计
    @Published public private(set) var statistics: EngineMatchStatistics?

    /// 当前对局序号
    @Published public private(set) var currentGameNumber: Int = 0

    /// 计划对局总数
    @Published public var totalPlannedGames: Int = 10

    /// 是否交换先后手
    @Published public var swapSides: Bool = true

    /// 当前是否引擎A执红
    @Published public private(set) var isAasRed: Bool = true

    /// 时间控制设置
    @Published public var timeControl: TimeControlSettings

    // MARK: - Private Properties

    private var gameController: EngineGameController?
    private var enginePool: EnginePool?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.chinesechess", category: "EngineMatchController")

    // MARK: - Initialization

    public init(
        engineAProfile: EngineProfile,
        engineBProfile: EngineProfile,
        timeControl: TimeControlSettings = .standard(initialTimeMs: 600_000),
        totalGames: Int = 10,
        swapSides: Bool = true
    ) {
        self.engineAProfile = engineAProfile
        self.engineBProfile = engineBProfile
        self.timeControl = timeControl
        self.totalPlannedGames = totalGames
        self.swapSides = swapSides

        // 初始化统计
        self.statistics = EngineMatchStatistics(
            engineAId: engineAProfile.id,
            engineBId: engineBProfile.id,
            engineAName: engineAProfile.name,
            engineBName: engineBProfile.name
        )
    }

    deinit {
        Task { [weak self] in
            await self?.cleanup()
        }
    }

    // MARK: - Public Methods

    /// 开始对战
    public func startMatch() async {
        guard state == .idle || state == .ready else {
            logger.warning("Cannot start match from state: \(state)")
            return
        }

        // 重置状态
        matchResults = []
        currentGameNumber = 0
        isAasRed = true

        // 更新统计
        statistics = EngineMatchStatistics(
            engineAId: engineAProfile.id,
            engineBId: engineBProfile.id,
            engineAName: engineAProfile.name,
            engineBName: engineBProfile.name
        )

        // 开始第一局
        await startNextGame()
    }

    /// 停止对战
    public func stopMatch() async {
        await cleanup()
        state = .idle
    }

    /// 获取当前对局摘要
    public func getCurrentGameSummary() -> String {
        let redName = isAasRed ? engineAProfile.name : engineBProfile.name
        let blackName = isAasRed ? engineBProfile.name : engineAProfile.name
        return "第\(currentGameNumber)/\(totalPlannedGames)局: \(redName)(红) vs \(blackName)(黑)"
    }

    /// 导出对战报告
    public func exportMatchReport() -> String {
        var report = ""
        report += "=== 引擎对战报告 ===\n"
        report += "引擎A: \(engineAProfile.name)\n"
        report += "引擎B: \(engineBProfile.name)\n"
        report += "对局总数: \(matchResults.count)\n"
        report += "\n"

        if let stats = statistics {
            report += "=== 统计 ===\n"
            report += "\(stats)\n"
            report += "\n"
        }

        report += "=== 对局详情 ===\n"
        for (index, result) in matchResults.enumerated() {
            report += "\(index + 1). \(result)\n"
        }

        return report
    }

    // MARK: - Private Methods

    private func startNextGame() async {
        guard currentGameNumber < totalPlannedGames else {
            // 所有对局完成
            state = .gameOver(.win(.red, .checkmate)) // 虚拟结果，实际应从统计计算
            logger.info("Match completed. Total games: \(matchResults.count)")
            return
        }

        currentGameNumber += 1

        // 确定先后手
        if swapSides && currentGameNumber > 1 {
            isAasRed.toggle()
        }

        // 创建游戏配置
        let redProfile = isAasRed ? engineAProfile : engineBProfile
        let blackProfile = isAasRed ? engineBProfile : engineAProfile

        let config = GameModeConfiguration.engineVsEngine(
            redEngineConfigurationID: redProfile.id,
            blackEngineConfigurationID: blackProfile.id,
            timeControl: timeControl.toConfiguration()
        )

        // 创建游戏控制器
        let gameController = EngineGameController(
            configuration: config,
            enginePool: enginePool
        )

        // 设置回调
        gameController.onEngineMove = { [weak self] bestMove, ponder in
            Task { @MainActor [weak self] in
                await self?.handleEngineMove(bestMove: bestMove, ponder: ponder)
            }
        }

        gameController.onStateChanged = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.state = state
            }
        }

        self.gameController = gameController

        // 初始化并启动游戏
        do {
            try await gameController.initializeEngine()
            await gameController.startNewGame()
        } catch {
            logger.error("Failed to start game: \(error.localizedDescription)")
            state = .error("启动对局失败: \(error.localizedDescription)")
        }
    }

    private func handleEngineMove(bestMove: String, ponder: String?) async {
        // 记录对局结果（如果对局结束）
        // 这里简化处理，实际应该监听游戏结束事件
    }

    private func recordGameResult(_ result: EngineMatchResult) {
        matchResults.append(result)
        statistics?.recordGame(result)
    }

    private func cleanup() async {
        if let gameController = gameController {
            await gameController.shutdown()
            self.gameController = nil
        }
    }
}

// MARK: - TimeControlSettings Extension

private extension TimeControlSettings {
    func toConfiguration() -> TimeControlConfiguration {
        switch type {
        case .fixedDepth:
            return .fixedDepth
        case .fixedTime:
            return .fixedTime
        case .standard:
            return .standard
        case .infinite:
            return .infinite
        }
    }
}
