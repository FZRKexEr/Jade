import Foundation

// MARK: - Move

/// 走棋记录
/// 记录一步完整的走棋信息，包括起始位置、目标位置、吃子信息等
public struct Move: Codable, Equatable, Hashable, Sendable, Identifiable, CustomStringConvertible {
    public let id: UUID
    public let from: Position
    public let to: Position
    public let piece: Piece
    public let capturedPiece: Piece?
    public let promotion: PieceType?        // 升变（中国象棋中一般没有）
    public let isCheck: Bool
    public let isCheckmate: Bool
    public let notation: String?            // 代数记谱法
    public let timestamp: Date

    /// 创建走棋记录
    public init(
        id: UUID = UUID(),
        from: Position,
        to: Position,
        piece: Piece,
        capturedPiece: Piece? = nil,
        promotion: PieceType? = nil,
        isCheck: Bool = false,
        isCheckmate: Bool = false,
        notation: String? = nil,
        timestamp: Date = Date()
    ) {
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

    /// 简化的描述字符串
    public var description: String {
        let capture = capturedPiece != nil ? "x" : "-"
        return "\(piece.character)\(from)\(capture)\(to)"
    }

    /// UCI 格式表示 (如 "e2e4")
    public var uciNotation: String {
        "\(from.algebraic)\(to.algebraic)"
    }

    /// 中国象棋代数记谱
    /// 格式: [棋子][原列][动作][目标列/距离]
    /// 如: 炮二平五, 马八进七, 车9进1
    public var chineseNotation: String {
        // 简化的记谱实现
        let pieceChar = piece.character
        let fromFile = from.x
        let toFile = to.x
        let fromRank = from.y
        let toRank = to.y

        // 红黑方分别用数字和中文数字表示列
        let redFiles = ["一", "二", "三", "四", "五", "六", "七", "八", "九"]
        let blackFiles = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

        let files = piece.player == .red ? redFiles : blackFiles

        var action: String
        if fromFile == toFile {
            // 平移 (进/退)
            let distance = abs(toRank - fromRank)
            let direction = (piece.player == .red && toRank > fromRank) ||
                           (piece.player == .black && toRank < fromRank) ? "进" : "退"
            action = "\(direction)\(distance)"
        } else {
            // 平移
            action = "平\(files[toFile])"
        }

        return "\(pieceChar)\(files[fromFile])\(action)"
    }

    /// 是否吃子
    public var isCapture: Bool {
        capturedPiece != nil
    }

    /// 移动的列差
    public var deltaX: Int {
        to.x - from.x
    }

    /// 移动的行差
    public var deltaY: Int {
        to.y - from.y
    }

    /// 移动的绝对列差
    public var absDeltaX: Int {
        abs(deltaX)
    }

    /// 移动的绝对行差
    public var absDeltaY: Int {
        abs(deltaY)
    }

    /// 移动的路径上的所有位置 (不包括起点和终点)
    public func pathPositions() -> [Position] {
        // 直线移动
        if from.x == to.x {
            // 垂直移动
            let minY = min(from.y, to.y)
            let maxY = max(from.y, to.y)
            return (minY + 1..<maxY).map { Position(x: from.x, y: $0) }
        } else if from.y == to.y {
            // 水平移动
            let minX = min(from.x, to.x)
            let maxX = max(from.x, to.x)
            return (minX + 1..<maxX).map { Position(x: $0, y: from.y) }
        }
        return []
    }
}

// MARK: - Move History

/// 走棋历史记录
/// 管理走棋历史和悔棋功能
public struct MoveHistory: Codable, Equatable, Sendable, CustomStringConvertible {
    private var moves: [Move] = []
    private var redoStack: [Move] = []

    public init() {}

    /// 添加走棋记录
    public mutating func addMove(_ move: Move) {
        moves.append(move)
        redoStack.removeAll()  // 清除重做栈
    }

    /// 悔棋 (撤销最后一步)
    @discardableResult
    public mutating func undo() -> Move? {
        guard let lastMove = moves.popLast() else { return nil }
        redoStack.append(lastMove)
        return lastMove
    }

    /// 重做 (恢复悔棋)
    @discardableResult
    public mutating func redo() -> Move? {
        guard let move = redoStack.popLast() else { return nil }
        moves.append(move)
        return move
    }

    /// 是否可以悔棋
    public var canUndo: Bool {
        !moves.isEmpty
    }

    /// 是否可以重做
    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// 走棋总数
    public var count: Int {
        moves.count
    }

    /// 所有走棋记录
    public var allMoves: [Move] {
        moves
    }

    /// 最后一步走棋
    public var lastMove: Move? {
        moves.last
    }

    /// 指定索引的走棋
    public subscript(index: Int) -> Move {
        moves[index]
    }

    /// 清除所有历史
    public mutating func clear() {
        moves.removeAll()
        redoStack.removeAll()
    }

    /// 获取到指定步数的FEN字符串数组
    public func fensUpTo(step: Int) -> [String] {
        // 这需要与 Board 类协作实现
        // 简化实现，返回空数组
        []
    }

    public var description: String {
        moves.enumerated().map { index, move in
            "\(index + 1). \(move)"
        }.joined(separator: "\n")
    }
}
