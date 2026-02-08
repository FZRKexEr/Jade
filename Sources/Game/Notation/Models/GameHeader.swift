import Foundation

// MARK: - GameHeader

/// 对局头信息（七标签）
/// 遵循 PGN 标准的七个必需标签
public struct GameHeader: Codable, Equatable, Sendable, CustomStringConvertible {

    // MARK: - 必需标签 (七标签)

    /// 赛事名称 (Event)
    public var event: String

    /// 比赛地点 (Site)
    public var site: String

    /// 比赛日期 (Date)
    /// 格式: YYYY.MM.DD 或 YYYY.MM 或 YYYY
    public var date: String

    /// 比赛轮次 (Round)
    public var round: String

    /// 红方姓名 (Red/White)
    public var red: String

    /// 黑方姓名 (Black)
    public var black: String

    /// 对局结果 (Result)
    public var result: GameResultNotation

    // MARK: - 可选标签

    /// 红方等级分
    public var redElo: Int?

    /// 黑方等级分
    public var blackElo: Int?

    /// 对局类型
    public var gameType: String?

    /// 开局名称
    public var opening: String?

    /// 变例名称
    public var variation: String?

    /// 初始 FEN
    public var setUp: String?

    /// 时间控制
    public var timeControl: String?

    /// 比赛结束时间
    public var endTime: String?

    ///  annotator (评注者)
    public var annotator: String?

    /// 额外标签存储
    public var additionalTags: [String: String]

    // MARK: - Initialization

    /// 创建对局头信息
    public init(
        event: String = "?",
        site: String = "?",
        date: String = "????.??.??",
        round: String = "?",
        red: String = "?",
        black: String = "?",
        result: GameResultNotation = .ongoing,
        redElo: Int? = nil,
        blackElo: Int? = nil,
        gameType: String? = nil,
        opening: String? = nil,
        variation: String? = nil,
        setUp: String? = nil,
        timeControl: String? = nil,
        endTime: String? = nil,
        annotator: String? = nil,
        additionalTags: [String: String] = [:]
    ) {
        self.event = event
        self.site = site
        self.date = date
        self.round = round
        self.red = red
        self.black = black
        self.result = result
        self.redElo = redElo
        self.blackElo = blackElo
        self.gameType = gameType
        self.opening = opening
        self.variation = variation
        self.setUp = setUp
        self.timeControl = timeControl
        self.endTime = endTime
        self.annotator = annotator
        self.additionalTags = additionalTags
    }

    // MARK: - Computed Properties

    /// 是否包含初始局面 (非标准开局)
    public var hasSetup: Bool {
        setUp != nil && setUp != Board.initial().toFEN()
    }

    /// 当前对局年份 (从日期解析)
    public var year: Int? {
        let components = date.split(separator: ".")
        if let yearStr = components.first,
           let year = Int(yearStr),
           year > 1000 && year < 9999 {
            return year
        }
        return nil
    }

    /// 对局结果描述
    public var resultDescription: String {
        result.description
    }

    /// 简短的比赛标识
    public var shortDescription: String {
        "\(event): \(red) vs \(black) - \(resultDescription)"
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        var lines: [String] = []
        lines.append("[Event \"\(event)\"]")
        lines.append("[Site \"\(site)\"]")
        lines.append("[Date \"\(date)\"]")
        lines.append("[Round \"\(round)\"]")
        lines.append("[Red \"\(red)\"]")
        lines.append("[Black \"\(black)\"]")
        lines.append("[Result \"\(result.pgnString)\"]")

        if let redElo = redElo {
            lines.append("[RedElo \"\(redElo)\"]")
        }
        if let blackElo = blackElo {
            lines.append("[BlackElo \"\(blackElo)\"]")
        }
        if let opening = opening {
            lines.append("[Opening \"\(opening)\"]")
        }
        if let setUp = setUp {
            lines.append("[SetUp \"1\"]")
            lines.append("[FEN \"\(setUp)\"]")
        }

        for (key, value) in additionalTags {
            lines.append("[\(key) \"\(value)\"]")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Static Methods

    /// 创建当前日期的字符串
    public static func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }
}

// MARK: - GameResultNotation

/// 对局结果记谱表示
public enum GameResultNotation: String, Codable, Equatable, Sendable, CustomStringConvertible {
    /// 红胜
    case redWin = "1-0"

    /// 黑胜
    case blackWin = "0-1"

    /// 和棋
    case draw = "1/2-1/2"

    /// 进行中/结果未知
    case ongoing = "*"

    /// 未知结果
    case unknown = "?"

    /// 初始化从游戏结果
    public init(from gameResult: GameResult) {
        switch gameResult {
        case .win(let player, _):
            self = player == .red ? .redWin : .blackWin
        case .draw:
            self = .draw
        case .ongoing:
            self = .ongoing
        }
    }

    /// 转换为游戏结果
    public var gameResult: GameResult {
        switch self {
        case .redWin:
            return .win(.red, .checkmate)
        case .blackWin:
            return .win(.black, .checkmate)
        case .draw:
            return .draw(.agreement)
        case .ongoing, .unknown:
            return .ongoing
        }
    }

    /// PGN格式字符串
    public var pgnString: String {
        rawValue
    }

    public var description: String {
        switch self {
        case .redWin:
            return "红胜"
        case .blackWin:
            return "黑胜"
        case .draw:
            return "和棋"
        case .ongoing:
            return "进行中"
        case .unknown:
            return "未知"
        }
    }

    /// 获胜方 (如果有)
    public var winner: Player? {
        switch self {
        case .redWin:
            return .red
        case .blackWin:
            return .black
        default:
            return nil
        }
    }

    /// 是否已结束
    public var isEnded: Bool {
        self != .ongoing && self != .unknown
    }
}