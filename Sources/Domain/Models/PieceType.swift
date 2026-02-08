import Foundation

/// 棋子类型
enum PieceType: Int, Codable, CaseIterable, Sendable {
    case king = 0       // 将/帅
    case advisor = 1    // 士/仕
    case elephant = 2   // 象/相
    case horse = 3      // 马/傌
    case rook = 4       // 车/俥
    case cannon = 5     // 炮/砲
    case pawn = 6       // 卒/兵

    var displayName: String {
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

    var englishName: String {
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
}
