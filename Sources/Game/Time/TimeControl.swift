import Foundation

// MARK: - TimeControlType

/// 时间控制类型
public enum TimeControlType: String, CaseIterable, Sendable, CustomStringConvertible, Identifiable, Codable {
    case fixedDepth = "fixedDepth"
    case fixedTime = "fixedTime"
    case standard = "standard"
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
            return "标准计时"
        case .infinite:
            return "无限时间"
        }
    }
}

// MARK: - TimeControlSettings

/// 时间控制设置
public struct TimeControlSettings: Sendable, CustomStringConvertible, Codable, Equatable {

    /// 时间控制类型
    public var type: TimeControlType

    /// 固定深度 (用于 fixedDepth 模式)
    public var fixedDepth: Int?

    /// 固定时间毫秒数 (用于 fixedTime 模式)
    public var fixedTimeMs: Int?

    /// 红方初始时间毫秒数 (用于 standard 模式)
    public var redInitialTimeMs: Int

    /// 黑方初始时间毫秒数 (用于 standard 模式)
    public var blackInitialTimeMs: Int

    /// 每步增量毫秒数
    public var incrementMs: Int

    /// 剩余步数限制 (用于 movestogo 模式)
    public var movesToGo: Int?

    /// 创建时间控制设置
    public init(
        type: TimeControlType = .standard,
        fixedDepth: Int? = nil,
        fixedTimeMs: Int? = nil,
        redInitialTimeMs: Int = 600_000,
        blackInitialTimeMs: Int = 600_000,
        incrementMs: Int = 0,
        movesToGo: Int? = nil
    ) {
        self.type = type
        self.fixedDepth = fixedDepth
        self.fixedTimeMs = fixedTimeMs
        self.redInitialTimeMs = redInitialTimeMs
        self.blackInitialTimeMs = blackInitialTimeMs
        self.incrementMs = incrementMs
        self.movesToGo = movesToGo
    }

    public var description: String {
        switch type {
        case .fixedDepth:
            if let depth = fixedDepth {
                return "固定深度: \(depth)"
            }
            return "固定深度"
        case .fixedTime:
            if let timeMs = fixedTimeMs {
                let seconds = Double(timeMs) / 1000.0
                return "固定时间: \(seconds, specifier: "%.1f")秒"
            }
            return "固定时间"
        case .standard:
            let redMinutes = redInitialTimeMs / 60_000
            let blackMinutes = blackInitialTimeMs / 60_000
            let incrementSeconds = Double(incrementMs) / 1000.0
            if incrementSeconds > 0 {
                return "红:\(redMinutes)分钟 黑:\(blackMinutes)分钟 +\(incrementSeconds, specifier: "%.1f")秒/步"
            }
            return "红:\(redMinutes)分钟 黑:\(blackMinutes)分钟"
        case .infinite:
            return "无限时间"
        }
    }

    // MARK: - Factory Methods

    /// 创建固定深度时间控制
    public static func fixedDepth(_ depth: Int) -> TimeControlSettings {
        TimeControlSettings(
            type: .fixedDepth,
            fixedDepth: depth
        )
    }

    /// 创建固定时间控制
    public static func fixedTime(milliseconds: Int) -> TimeControlSettings {
        TimeControlSettings(
            type: .fixedTime,
            fixedTimeMs: milliseconds
        )
    }

    /// 创建标准计时控制
    public static func standard(
        initialTimeMs: Int,
        incrementMs: Int = 0
    ) -> TimeControlSettings {
        TimeControlSettings(
            type: .standard,
            redInitialTimeMs: initialTimeMs,
            blackInitialTimeMs: initialTimeMs,
            incrementMs: incrementMs
        )
    }

    /// 创建非对称计时控制
    public static func asymmetric(
        redInitialTimeMs: Int,
        blackInitialTimeMs: Int,
        incrementMs: Int = 0
    ) -> TimeControlSettings {
        TimeControlSettings(
            type: .standard,
            redInitialTimeMs: redInitialTimeMs,
            blackInitialTimeMs: blackInitialTimeMs,
            incrementMs: incrementMs
        )
    }

    /// 创建无限时间控制
    public static var infinite: TimeControlSettings {
        TimeControlSettings(type: .infinite)
    }

    // MARK: - Predefined Settings

    /// 闪电战 (1+0)
    public static var bullet1Plus0: TimeControlSettings {
        standard(initialTimeMs: 60_000, incrementMs: 0)
    }

    /// 闪电战 (1+1)
    public static var bullet1Plus1: TimeControlSettings {
        standard(initialTimeMs: 60_000, incrementMs: 1_000)
    }

    /// 快棋 (3+0)
    public static var blitz3Plus0: TimeControlSettings {
        standard(initialTimeMs: 180_000, incrementMs: 0)
    }

    /// 快棋 (3+2)
    public static var blitz3Plus2: TimeControlSettings {
        standard(initialTimeMs: 180_000, incrementMs: 2_000)
    }

    /// 快棋 (5+0)
    public static var blitz5Plus0: TimeControlSettings {
        standard(initialTimeMs: 300_000, incrementMs: 0)
    }

    /// 快棋 (5+3)
    public static var blitz5Plus3: TimeControlSettings {
        standard(initialTimeMs: 300_000, incrementMs: 3_000)
    }

    /// 标准 (10+0)
    public static var standard10Plus0: TimeControlSettings {
        standard(initialTimeMs: 600_000, incrementMs: 0)
    }

    /// 标准 (15+10)
    public static var standard15Plus10: TimeControlSettings {
        standard(initialTimeMs: 900_000, incrementMs: 10_000)
    }

    /// 慢棋 (30+0)
    public static var classical30Plus0: TimeControlSettings {
        standard(initialTimeMs: 1_800_000, incrementMs: 0)
    }
}
