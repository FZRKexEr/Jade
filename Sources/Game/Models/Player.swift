import Foundation

// MARK: - Player

/// 玩家阵营 (红方先行)
/// 中国象棋中，红方先走，双方轮流走棋
public enum Player: Int, Codable, CaseIterable, Sendable, CustomStringConvertible {
    case red = 0    // 红方
    case black = 1  // 黑方

    public var displayName: String {
        switch self {
        case .red: return "红方"
        case .black: return "黑方"
        }
    }

    public var description: String {
        displayName
    }

    public var isRed: Bool { self == .red }
    public var isBlack: Bool { self == .black }

    /// 对手阵营
    public var opponent: Player {
        self == .red ? .black : .red
    }

    /// FEN 格式表示 (w = 红方, b = 黑方)
    public var fenCharacter: String {
        self == .red ? "w" : "b"
    }
}
