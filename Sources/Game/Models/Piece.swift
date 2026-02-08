import Foundation

// MARK: - PieceType

/// 棋子类型
/// 中国象棋共7种棋子：将帅、士仕、象相、马傌、车俥、炮砲、兵卒
public enum PieceType: Int, Codable, CaseIterable, Sendable, CustomStringConvertible {
    case king = 0       // 将/帅 (King)
    case advisor = 1    // 士/仕 (Advisor)
    case elephant = 2   // 象/相 (Elephant)
    case horse = 3      // 马/傌 (Horse)
    case rook = 4       // 车/俥 (Rook)
    case cannon = 5     // 炮/砲 (Cannon)
    case pawn = 6       // 卒/兵 (Pawn)

    /// 黑方棋子显示名称
    public var displayName: String {
        switch self {
        case .king: return "将"
        case .advisor: return "士"
        case .elephant: return "象"
        case .horse: return "马"
        case .rook: return "车"
        case .cannon: return "炮"
        case .pawn: return "卒"
        }
    }

    /// 英文名称
    public var englishName: String {
        switch self {
        case .king: return "King"
        case .advisor: return "Advisor"
        case .elephant: return "Elephant"
        case .horse: return "Horse"
        case .rook: return "Rook"
        case .cannon: return "Cannon"
        case .pawn: return "Pawn"
        }
    }

    /// 简写字符 (用于代数记谱)
    public var notationCharacter: String {
        switch self {
        case .king: return "K"
        case .advisor: return "A"
        case .elephant: return "B"  // Bishop (象)
        case .horse: return "N"      // Knight
        case .rook: return "R"
        case .cannon: return "C"
        case .pawn: return "P"
        }
    }

    public var description: String {
        displayName
    }
}

// MARK: - Piece

/// 棋子
/// 每个棋子有唯一ID、类型和所属阵营
public struct Piece: Codable, Equatable, Hashable, Sendable, Identifiable, CustomStringConvertible {
    public let id: UUID
    public let type: PieceType
    public let player: Player

    public init(id: UUID = UUID(), type: PieceType, player: Player) {
        self.id = id
        self.type = type
        self.player = player
    }

    /// 棋子显示字符
    /// 红方使用繁体/特殊字形：帅、仕、相、傌、俥、炮、兵
    /// 黑方使用：将、士、象、马、车、砲、卒
    public var character: String {
        let redChars = ["帅", "仕", "相", "傌", "俥", "炮", "兵"]
        let blackChars = ["将", "士", "象", "马", "车", "砲", "卒"]

        let chars = player == .red ? redChars : blackChars
        return chars[type.rawValue]
    }

    /// FEN 表示字符
    /// 红方用大写字母，黑方用小写字母
    public var fenCharacter: String {
        let char: String
        switch type {
        case .king: char = "k"
        case .advisor: char = "a"
        case .elephant: char = "b"
        case .horse: char = "n"
        case .rook: char = "r"
        case .cannon: char = "c"
        case .pawn: char = "p"
        }
        return player == .red ? char.uppercased() : char
    }

    /// 是否是对方的棋子
    public func isOpponent(of other: Piece) -> Bool {
        self.player != other.player
    }

    /// 是否是己方的棋子
    public func isAlly(of other: Piece) -> Bool {
        self.player == other.player
    }

    public var description: String {
        "\(player)\(type)(\(character))"
    }
}
