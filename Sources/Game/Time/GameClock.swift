import Foundation
import Combine

// MARK: - TimeControlResult

/// 时间控制结果
public enum TimeControlResult: Sendable {
    case normal           // 正常
    case timeUp           // 时间耗尽
    case lowTimeWarning   // 低时间警告
}

// MARK: - GameClock

/// 游戏时钟
/// 管理对局中红方和黑方的时间
@MainActor
public final class GameClock: ObservableObject, Sendable {

    // MARK: - Published Properties

    /// 红方剩余时间 (毫秒)
    @Published public private(set) var redTimeRemainingMs: Int

    /// 黑方剩余时间 (毫秒)
    @Published public private(set) var blackTimeRemainingMs: Int

    /// 当前正在计时的玩家
    @Published public private(set) var activePlayer: Player?

    /// 时钟是否正在运行
    @Published public private(set) var isRunning: Bool = false

    /// 红方是否处于低时间警告状态
    @Published public private(set) var isRedLowTime: Bool = false

    /// 黑方是否处于低时间警告状态
    @Published public private(set) var isBlackLowTime: Bool = false

    /// 低时间阈值 (毫秒) - 默认1分钟
    @Published public var lowTimeThresholdMs: Int = 60_000

    /// 总经过时间 (毫秒)
    @Published public private(set) var totalElapsedMs: Int = 0

    /// 当前回合开始时间
    @Published public private(set) var turnStartTime: Date?

    // MARK: - Private Properties

    private var timer: Timer?
    private let timerInterval: TimeInterval = 0.1  // 100ms 更新频率

    /// 时间事件回调
    public var onTimeUpdate: ((Player, Int) -> Void)?
    public var onTimeUp: ((Player) -> Void)?
    public var onLowTime: ((Player, Int) -> Void)?

    // MARK: - Initialization

    public init(
        redInitialTimeMs: Int = 600_000,  // 默认10分钟
        blackInitialTimeMs: Int = 600_000,
        incrementMs: Int = 0,
        lowTimeThresholdMs: Int = 60_000
    ) {
        self.redTimeRemainingMs = redInitialTimeMs
        self.blackTimeRemainingMs = blackInitialTimeMs
        self.lowTimeThresholdMs = lowTimeThresholdMs
        self.activePlayer = nil
        self.isRunning = false
    }

    // MARK: - Control Methods

    /// 开始计时
    public func start(for player: Player) {
        guard !isRunning || activePlayer != player else { return }

        // 如果正在给其他方计时，先停止
        if isRunning {
            pause()
        }

        activePlayer = player
        isRunning = true
        turnStartTime = Date()

        startTimer()
    }

    /// 暂停计时
    public func pause() {
        guard isRunning else { return }

        // 记录经过的时间
        if let startTime = turnStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime) * 1000)
            totalElapsedMs += elapsed
        }

        isRunning = false
        stopTimer()
    }

    /// 切换计时方
    public func switchTurn() {
        guard let currentPlayer = activePlayer else { return }

        // 先暂停当前计时
        pause()

        // 增加增量时间
        addIncrement(to: currentPlayer)

        // 开始对方计时
        let nextPlayer = currentPlayer.opponent
        start(for: nextPlayer)
    }

    /// 重置时钟
    public func reset(
        redTimeMs: Int? = nil,
        blackTimeMs: Int? = nil
    ) {
        pause()
        redTimeRemainingMs = redTimeMs ?? redTimeRemainingMs
        blackTimeRemainingMs = blackTimeMs ?? blackTimeRemainingMs
        activePlayer = nil
        totalElapsedMs = 0
        turnStartTime = nil
        isRedLowTime = false
        isBlackLowTime = false
    }

    /// 增加时间
    public func addTime(_ milliseconds: Int, to player: Player) {
        if player == .red {
            redTimeRemainingMs += milliseconds
        } else {
            blackTimeRemainingMs += milliseconds
        }
    }

    /// 减少时间
    public func deductTime(_ milliseconds: Int, from player: Player) {
        addTime(-milliseconds, to: player)
    }

    /// 设置时间
    public func setTime(_ milliseconds: Int, for player: Player) {
        if player == .red {
            redTimeRemainingMs = milliseconds
        } else {
            blackTimeRemainingMs = milliseconds
        }
    }

    // MARK: - Private Methods

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateTime()
            }
        }

        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTime() {
        guard let activePlayer = activePlayer else { return }

        let decrementMs = Int(timerInterval * 1000)

        if activePlayer == .red {
            redTimeRemainingMs -= decrementMs

            // 检查时间耗尽
            if redTimeRemainingMs <= 0 {
                redTimeRemainingMs = 0
                stopTimer()
                isRunning = false
                onTimeUp?(.red)
                return
            }

            // 检查低时间
            if !isRedLowTime && redTimeRemainingMs <= lowTimeThresholdMs {
                isRedLowTime = true
                onLowTime?(.red, redTimeRemainingMs)
            }

            onTimeUpdate?(.red, redTimeRemainingMs)

        } else {
            blackTimeRemainingMs -= decrementMs

            // 检查时间耗尽
            if blackTimeRemainingMs <= 0 {
                blackTimeRemainingMs = 0
                stopTimer()
                isRunning = false
                onTimeUp?(.black)
                return
            }

            // 检查低时间
            if !isBlackLowTime && blackTimeRemainingMs <= lowTimeThresholdMs {
                isBlackLowTime = true
                onLowTime?(.black, blackTimeRemainingMs)
            }

            onTimeUpdate?(.black, blackTimeRemainingMs)
        }
    }

    private func addIncrement(to player: Player) {
        // 增量时间在 switchTurn 时添加
        // 这里可以实现增量逻辑
    }

    // MARK: - Computed Properties

    /// 格式化后的红方时间
    public var redTimeFormatted: String {
        formatTime(redTimeRemainingMs)
    }

    /// 格式化后的黑方时间
    public var blackTimeFormatted: String {
        formatTime(blackTimeRemainingMs)
    }

    /// 红方是否超时
    public var isRedTimeUp: Bool {
        redTimeRemainingMs <= 0
    }

    /// 黑方是否超时
    public var isBlackTimeUp: Bool {
        blackTimeRemainingMs <= 0
    }

    // MARK: - Helper Methods

    /// 格式化时间为 mm:ss 或 mm:ss.ms
    public func formatTime(_ milliseconds: Int, includeMs: Bool = false) -> String {
        let totalSeconds = milliseconds / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if includeMs {
            let ms = (milliseconds % 1000) / 10
            return String(format: "%02d:%02d.%02d", minutes, seconds, ms)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// 获取指定玩家的时间
    public func getTime(for player: Player) -> Int {
        player == .red ? redTimeRemainingMs : blackTimeRemainingMs
    }

    /// 获取指定玩家的时间格式化字符串
    public func getTimeFormatted(for player: Player) -> String {
        player == .red ? redTimeFormatted : blackTimeFormatted
    }

    /// 检查指定玩家是否时间紧张
    public func isLowTime(for player: Player) -> Bool {
        let timeRemaining = getTime(for: player)
        return timeRemaining <= lowTimeThresholdMs
    }
}
