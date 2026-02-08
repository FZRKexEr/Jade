import Foundation

/// 棋子
struct Piece: Codable, Equatable, Hashable, Sendable, Identifiable {
    let id: UUID
    let type: PieceType
    let player: Player

    init(id: UUID = UUID(), type: PieceType, player: Player) {
        self.id = id
        self.type = type
        self.player = player
    }

    /// 棋子显示字符 (简化的中文表示)
    var character: String {
        let redChars = ["帅", "仕", "相", "傌", "俥", "炮", "兵"]
        let blackChars = ["将", "士", "象", "马", "车", "砲", "卒"]

        let chars = player == .red ? redChars : blackChars
        return chars[type.rawValue]
    }

    var isEmpty: Bool { false }
}

// MARK: - FEN Support

extension Piece {
    /// FEN表示字符
    var fenCharacter: String {
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
}
