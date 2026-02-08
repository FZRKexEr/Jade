import Foundation

// MARK: - Game Configuration

/// 游戏配置模型
public struct GameConfiguration: Codable, Equatable, Sendable {
    public var defaultTimeControl: TimeControl
    public var defaultGameMode: GameMode
    public var enginePlayerSide: PlayerSide
    public var engineSkillLevel: SkillLevel
    public var enableHints: Bool
    public var enableMoveConfirmation: Bool
    public var enablePremove: Bool
    public var showLegalMoves: Bool
    public var showLastMove: Bool
    public var showCoordinates: Bool
    public var autoFlipBoard: Bool
    public var soundEffects: SoundEffectsConfiguration
    public var notation: NotationConfiguration

    public init(
        defaultTimeControl: TimeControl = .classical,
        defaultGameMode: GameMode = .humanVsEngine,
        enginePlayerSide: PlayerSide = .black,
        engineSkillLevel: SkillLevel = .expert,
        enableHints: Bool = true,
        enableMoveConfirmation: Bool = false,
        enablePremove: Bool = false,
        showLegalMoves: Bool = true,
        showLastMove: Bool = true,
        showCoordinates: Bool = true,
        autoFlipBoard: Bool = false,
        soundEffects: SoundEffectsConfiguration = SoundEffectsConfiguration(),
        notation: NotationConfiguration = NotationConfiguration()
    ) {
        self.defaultTimeControl = defaultTimeControl
        self.defaultGameMode = defaultGameMode
        self.enginePlayerSide = enginePlayerSide
        self.engineSkillLevel = engineSkillLevel
        self.enableHints = enableHints
        self.enableMoveConfirmation = enableMoveConfirmation
        self.enablePremove = enablePremove
        self.showLegalMoves = showLegalMoves
        self.showLastMove = showLastMove
        self.showCoordinates = showCoordinates
        self.autoFlipBoard = autoFlipBoard
        self.soundEffects = soundEffects
        self.notation = notation
    }

    /// 默认配置
    public static let `default` = GameConfiguration()

    /// 快速游戏配置
    public static let quick = GameConfiguration(
        defaultTimeControl: .rapid,
        defaultGameMode: .humanVsEngine,
        engineSkillLevel: .intermediate,
        enableHints: false,
        showLegalMoves: false
    )

    /// 分析模式配置
    public static let analysis = GameConfiguration(
        defaultTimeControl: .unlimited,
        defaultGameMode: .analysis,
        enginePlayerSide: .none,
        engineSkillLevel: .master,
        enableHints: true,
        showLegalMoves: true,
        showLastMove: true
    )
}

// MARK: - Time Control

/// 时间控制
public enum TimeControl: Codable, Equatable, Sendable {
    case bullet          // 1分钟
    case blitz          // 3-5分钟
    case rapid          // 10-15分钟
    case classical      // 30分钟以上
    case unlimited      // 无限时间
    case custom(minutes: Int, increment: Int)

    public var displayName: String {
        switch self {
        case .bullet:
            return "超快棋"
        case .blitz:
            return "快棋"
        case .rapid:
            return "中速棋"
        case .classical:
            return "慢棋"
        case .unlimited:
            return "无限时间"
        case .custom(let minutes, let increment):
            if increment > 0 {
                return "自定义 (\(minutes)+\(increment)s)"
            } else {
                return "自定义 (\(minutes)分钟)"
            }
        }
    }

    public var timeInSeconds: Int {
        switch self {
        case .bullet:
            return 60
        case .blitz:
            return 180
        case .rapid:
            return 600
        case .classical:
            return 1800
        case .unlimited:
            return 0
        case .custom(let minutes, _):
            return minutes * 60
        }
    }

    public var incrementInSeconds: Int {
        switch self {
        case .custom(_, let increment):
            return increment
        default:
            return 0
        }
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case minutes
        case increment
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "bullet":
            self = .bullet
        case "blitz":
            self = .blitz
        case "rapid":
            self = .rapid
        case "classical":
            self = .classical
        case "unlimited":
            self = .unlimited
        case "custom":
            let minutes = try container.decode(Int.self, forKey: .minutes)
            let increment = try container.decode(Int.self, forKey: .increment)
            self = .custom(minutes: minutes, increment: increment)
        default:
            self = .classical
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .bullet:
            try container.encode("bullet", forKey: .type)
        case .blitz:
            try container.encode("blitz", forKey: .type)
        case .rapid:
            try container.encode("rapid", forKey: .type)
        case .classical:
            try container.encode("classical", forKey: .type)
        case .unlimited:
            try container.encode("unlimited", forKey: .type)
        case .custom(let minutes, let increment):
            try container.encode("custom", forKey: .type)
            try container.encode(minutes, forKey: .minutes)
            try container.encode(increment, forKey: .increment)
        }
    }
}

// MARK: - Game Mode

/// 游戏模式
public enum GameMode: String, Codable, CaseIterable, Sendable {
    case humanVsHuman = "humanVsHuman"
    case humanVsEngine = "humanVsEngine"
    case engineVsEngine = "engineVsEngine"
    case analysis = "analysis"
    case puzzle = "puzzle"

    public var displayName: String {
        switch self {
        case .humanVsHuman:
            return "人人对战"
        case .humanVsEngine:
            return "人机对战"
        case .engineVsEngine:
            return "引擎对战"
        case .analysis:
            return "分析模式"
        case .puzzle:
            return "残局练习"
        }
    }

    public var icon: String {
        switch self {
        case .humanVsHuman:
            return "person.2"
        case .humanVsEngine:
            return "person.fill"
        case .engineVsEngine:
            return "cpu"
        case .analysis:
            return "magnifyingglass"
        case .puzzle:
            return "puzzlepiece"
        }
    }
}

// MARK: - Player Side

/// 引擎执棋方
public enum PlayerSide: String, Codable, CaseIterable, Sendable {
    case red = "red"
    case black = "black"
    case both = "both"
    case none = "none"

    public var displayName: String {
        switch self {
        case .red:
            return "红方"
        case .black:
            return "黑方"
        case .both:
            return "双方"
        case .none:
            return "无"
        }
    }

    public var icon: String {
        switch self {
        case .red:
            return "circle.fill"
        case .black:
            return "circle"
        case .both:
            return "circle.dashed"
        case .none:
            return "xmark.circle"
        }
    }
}

// MARK: - Skill Level

/// 引擎技能等级
public enum SkillLevel: Int, Codable, CaseIterable, Sendable {
    case beginner = 1
    case novice = 3
    case intermediate = 5
    case advanced = 8
    case expert = 11
    case master = 14
    case grandmaster = 17
    case maximum = 20

    public var displayName: String {
        switch self {
        case .beginner:
            return "入门"
        case .novice:
            return "新手"
        case .intermediate:
            return "中级"
        case .advanced:
            return "高级"
        case .expert:
            return "专家"
        case .master:
            return "大师"
        case .grandmaster:
            return "特级大师"
        case .maximum:
            return "最强"
        }
    }

    public var uciEloValue: Int {
        // 映射到 UCI_Elo 值 (1000-3000)
        switch self {
        case .beginner: return 1000
        case .novice: return 1200
        case .intermediate: return 1500
        case .advanced: return 1800
        case .expert: return 2100
        case .master: return 2400
        case .grandmaster: return 2700
        case .maximum: return 3000
        }
    }

    public var depthLimit: Int? {
        // 某些等级的深度限制
        switch self {
        case .beginner:
            return 5
        case .novice:
            return 8
        case .intermediate:
            return 12
        default:
            return nil // 无限制
        }
    }

    public var searchTimeLimitMs: Int? {
        // 某些等级的搜索时间限制
        switch self {
        case .beginner:
            return 1000
        case .novice:
            return 2000
        case .intermediate:
            return 5000
        default:
            return nil // 无限制
        }
    }
}

// MARK: - Sound Effects Configuration

/// 音效配置
public struct SoundEffectsConfiguration: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var moveSoundVolume: Double
    public var captureSoundVolume: Double
    public var checkSoundVolume: Double
    public var gameEndSoundVolume: Double
    public var uiSoundVolume: Double

    public init(
        enabled: Bool = true,
        moveSoundVolume: Double = 0.7,
        captureSoundVolume: Double = 0.8,
        checkSoundVolume: Double = 0.9,
        gameEndSoundVolume: Double = 1.0,
        uiSoundVolume: Double = 0.5
    ) {
        self.enabled = enabled
        self.moveSoundVolume = max(0, min(1, moveSoundVolume))
        self.captureSoundVolume = max(0, min(1, captureSoundVolume))
        self.checkSoundVolume = max(0, min(1, checkSoundVolume))
        self.gameEndSoundVolume = max(0, min(1, gameEndSoundVolume))
        self.uiSoundVolume = max(0, min(1, uiSoundVolume))
    }
}

// MARK: - Notation Configuration

/// 记谱法配置
public struct NotationConfiguration: Codable, Equatable, Sendable {
    public var notationStyle: NotationStyle
    public var showPieceName: Bool
    public var useChineseNumbers: Bool
    public var showCoordinates: Bool

    public init(
        notationStyle: NotationStyle = .chinese,
        showPieceName: Bool = true,
        useChineseNumbers: Bool = true,
        showCoordinates: Bool = false
    ) {
        self.notationStyle = notationStyle
        self.showPieceName = showPieceName
        self.useChineseNumbers = useChineseNumbers
        self.showCoordinates = showCoordinates
    }
}

public enum NotationStyle: String, Codable, CaseIterable, Sendable {
    case chinese = "chinese"         // 中文记谱法 (炮二平五)
    case algebraic = "algebraic"   // 代数记谱法 (e2e4)
    case iccs = "iccs"             // ICCS 坐标
    case simple = "simple"           // 简化记谱法

    public var displayName: String {
        switch self {
        case .chinese:
            return "中文记谱"
        case .algebraic:
            return "代数记谱"
        case .iccs:
            return "ICCS 坐标"
        case .simple:
            return "简化记谱"
        }
    }
}

// MARK: - FileManager Extension

extension FileManager {
    func isExecutableFile(atPath path: String) -> Bool {
        guard fileExists(atPath: path) else { return false }

        let fm = FileManager.default
        do {
            let attributes = try fm.attributesOfItem(atPath: path)
            if let type = attributes[.type] as? FileAttributeType,
               type == .typeRegular {
                // 检查是否有可执行权限
                return isExecutableFile(atPath: path)
            }
        } catch {
            return false
        }
        return false
    }
}
