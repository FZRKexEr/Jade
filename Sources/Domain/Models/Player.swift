import Foundation

/// 玩家 (红方先行)
enum Player: Int, Codable, CaseIterable, Sendable {
    case red = 0    // 红方
    case black = 1  // 黑方

    var displayName: String {
        switch self {
        case .red: return "红方"
        case .black: return "黑方"
        }
    }

    var isRed: Bool { self == .red }
    var isBlack: Bool { self == .black }

    var opponent: Player {
        self == .red ? .black : .red
    }
}
