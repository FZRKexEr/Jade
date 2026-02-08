import Foundation

/// 走棋
struct Move: Codable, Equatable, Hashable, Sendable, Identifiable, CustomStringConvertible {
    let id: UUID
    let from: Position
    let to: Position
    let piece: Piece
    let capturedPiece: Piece?
    let promotion: PieceType?        // 升变（中国象棋中一般没有）
    let isCheck: Bool
    let isCheckmate: Bool
    let notation: String?            // 代数记谱法
    let timestamp: Date

    init(id: UUID = UUID(),
         from: Position,
         to: Position,
         piece: Piece,
         capturedPiece: Piece? = nil,
         promotion: PieceType? = nil,
         isCheck: Bool = false,
         isCheckmate: Bool = false,
         notation: String? = nil,
         timestamp: Date = Date()) {
        self.id = id
        self.from = from
        self.to = to
        self.piece = piece
        self.capturedPiece = capturedPiece
        self.promotion = promotion
        self.isCheck = isCheck
        self.isCheckmate = isCheckmate
        self.notation = notation
        self.timestamp = timestamp
    }

    var description: String {
        let capture = capturedPiece != nil ? "x" : "-"
        return "\(piece.character)\(from)\(capture)\(to)"
    }

    var uciNotation: String {
        // UCI格式: e2e4, e1g1 (王车易位)
        "\(from.x)\(from.y)\(to.x)\(to.y)"
    }
}
