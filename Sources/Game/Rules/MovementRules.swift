import Foundation

// MARK: - MovementRules

/// 中国象棋移动规则引擎
/// 负责验证各类棋子的移动是否合法
public struct MovementRules: Sendable {

    // MARK: - Public Methods

    /// 获取某棋子在指定位置的所有合法移动目标
    /// - Parameters:
    ///   - piece: 要移动的棋子
    ///   - position: 当前位置
    ///   - board: 棋盘状态
    /// - Returns: 所有合法的目标位置
    public static func getLegalMoves(for piece: Piece, at position: Position, on board: Board) -> [Position] {
        let potentialMoves = getPotentialMoves(for: piece, at: position, on: board)
        return potentialMoves.filter { target in
            isMoveLegal(piece: piece, from: position, to: target, on: board)
        }
    }

    /// 检查移动是否合法
    /// - Parameters:
    ///   - piece: 要移动的棋子
    ///   - from: 起始位置
    ///   - to: 目标位置
    ///   - board: 棋盘状态
    /// - Returns: 是否合法
    public static func isMoveLegal(piece: Piece, from: Position, to: Position, on board: Board) -> Bool {
        // 1. 目标位置必须在棋盘内
        guard board.isValidPosition(to) else { return false }

        // 2. 不能吃掉己方棋子
        if let targetPiece = board.piece(at: to), targetPiece.player == piece.player {
            return false
        }

        // 3. 根据棋子类型检查移动规则
        switch piece.type {
        case .king:
            return isValidKingMove(from: from, to: to, for: piece.player)
        case .advisor:
            return isValidAdvisorMove(from: from, to: to, for: piece.player)
        case .elephant:
            return isValidElephantMove(from: from, to: to, for: piece.player, on: board)
        case .horse:
            return isValidHorseMove(from: from, to: to, on: board)
        case .rook:
            return isValidRookMove(from: from, to: to, on: board)
        case .cannon:
            return isValidCannonMove(from: from, to: to, on: board)
        case .pawn:
            return isValidPawnMove(from: from, to: to, for: piece.player)
        }
    }

    /// 检查移动是否会导致自己被将军 (需要在Board级别检查)
    /// 注意：这个检查需要知道移动后的棋盘状态，通常在更高层处理
    public static func wouldResultInSelfCheck(from: Position, to: Position, on board: Board) -> Bool {
        // 创建临时棋盘模拟移动
        var tempBoard = board.copy()
        let piece = tempBoard.piece(at: from)!

        // 执行移动
        tempBoard.movePiece(from: from, to: to)

        // 检查移动方是否被将军
        return isKingInCheck(for: piece.player, on: tempBoard)
    }

    /// 检查某方是否被将军
    public static func isKingInCheck(for player: Player, on board: Board) -> Bool {
        guard let kingPosition = board.findKing(for: player) else {
            return false  // 没将帅了？这种情况不应该发生
        }

        let opponent = player.opponent
        let opponentPieces = board.pieces(for: opponent)

        for (position, piece) in opponentPieces {
            if isThreatening(from: position, to: kingPosition, piece: piece, on: board) {
                return true
            }
        }

        return false
    }

    /// 检查是否被将死
    public static func isCheckmate(for player: Player, on board: Board) -> Bool {
        // 1. 必须正在被将军
        guard isKingInCheck(for: player, on: board) else {
            return false
        }

        // 2. 没有合法移动可以应将
        let playerPieces = board.pieces(for: player)
        for (position, piece) in playerPieces {
            let moves = getLegalMoves(for: piece, at: position, on: board)
            if !moves.isEmpty {
                return false  // 有合法移动，不是将死
            }
        }

        return true
    }

    /// 检查是否被困毙 (无合法移动但未处于将军状态)
    public static func isStalemate(for player: Player, on board: Board) -> Bool {
        // 1. 不能被将军
        guard !isKingInCheck(for: player, on: board) else {
            return false
        }

        // 2. 没有合法移动
        let playerPieces = board.pieces(for: player)
        for (position, piece) in playerPieces {
            let moves = getLegalMoves(for: piece, at: position, on: board)
            if !moves.isEmpty {
                return false
            }
        }

        return true
    }

    // MARK: - Private Methods

    /// 获取潜在移动目标 (不考虑将军)
    private static func getPotentialMoves(for piece: Piece, at position: Position, on board: Board) -> [Position] {
        var moves: [Position] = []

        // 对于复杂移动的棋子，使用特殊规则计算
        switch piece.type {
        case .king:
            moves = position.orthogonalPositions.filter { target in
                target.isInPalace(for: piece.player)
            }
        case .advisor:
            moves = position.diagonalPositions.filter { target in
                target.isInPalace(for: piece.player)
            }
        case .elephant:
            moves = position.elephantPositions.filter { target in
                target.isInOwnHalf(for: piece.player)
            }
        case .horse:
            moves = position.horsePositions
        case .rook:
            // 车和炮需要沿着直线扫描
            moves = getLineMoves(from: position, on: board)
        case .cannon:
            moves = getCannonMoves(from: position, on: board)
        case .pawn:
            // 兵卒
            moves = getPawnMoves(for: piece.player, from: position, on: board)
        }

        return moves
    }

    /// 获取直线移动目标 (用于车和炮)
    private static func getLineMoves(from position: Position, on board: Board) -> [Position] {
        var moves: [Position] = []

        // 四个方向
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]

        for (dx, dy) in directions {
            var x = position.x + dx
            var y = position.y + dy

            while x >= 0 && x < Board.width && y >= 0 && y < Board.height {
                moves.append(Position(x: x, y: y))

                // 遇到棋子就停止
                if board.piece(at: Position(x: x, y: y)) != nil {
                    break
                }

                x += dx
                y += dy
            }
        }

        return moves
    }

    /// 获取炮的移动目标
    private static func getCannonMoves(from position: Position, on board: Board) -> [Position] {
        var moves: [Position] = []

        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]

        for (dx, dy) in directions {
            var x = position.x + dx
            var y = position.y + dy
            var jumped = false  // 是否已经跳过一个棋子

            while x >= 0 && x < Board.width && y >= 0 && y < Board.height {
                let pos = Position(x: x, y: y)
                let piece = board.piece(at: pos)

                if !jumped {
                    // 还没跳过棋子时
                    if piece == nil {
                        moves.append(pos)  // 空格可以走
                    } else {
                        jumped = true  // 遇到第一个棋子，标记为已跳过
                    }
                } else {
                    // 已经跳过一个棋子后
                    if piece != nil {
                        moves.append(pos)  // 可以吃子
                        break  // 吃子后就停止
                    }
                    // 继续往后看，直到出界
                }

                x += dx
                y += dy
            }
        }

        return moves
    }

    /// 获取兵卒的移动目标
    private static func getPawnMoves(for player: Player, from position: Position, on board: Board) -> [Position] {
        var moves: [Position] = []

        let forwardY = player == .red ? 1 : -1  // 红方向前是y增加，黑方向前是y减少

        // 1. 向前走一格
        let forward = Position(x: position.x, y: position.y + forwardY)
        if forward.isValid {
            moves.append(forward)
        }

        // 2. 过河后可以左右移动
        if position.hasCrossedRiver(for: player) {
            let left = Position(x: position.x - 1, y: position.y)
            let right = Position(x: position.x + 1, y: position.y)

            if left.isValid { moves.append(left) }
            if right.isValid { moves.append(right) }
        }

        return moves
    }

    // MARK: - Piece-Specific Validation

    /// 将/帅移动规则
    /// - 只能在九宫格内移动
    /// - 只能上下左右移动一格
    private static func isValidKingMove(from: Position, to: Position, for player: Player) -> Bool {
        // 必须在九宫格内
        guard to.isInPalace(for: player) else { return false }

        // 只能移动一格 (上下左右)
        let dx = abs(to.x - from.x)
        let dy = abs(to.y - from.y)

        // 只能横向或纵向移动一格
        return (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    }

    /// 士/仕移动规则
    /// - 只能在九宫格内移动
    /// - 只能斜向移动一格
    private static func isValidAdvisorMove(from: Position, to: Position, for player: Player) -> Bool {
        // 必须在九宫格内
        guard to.isInPalace(for: player) else { return false }

        // 必须斜向移动一格
        let dx = abs(to.x - from.x)
        let dy = abs(to.y - from.y)

        return dx == 1 && dy == 1
    }

    /// 象/相移动规则
    /// - 不能过河
    /// - 走"田"字 (对角两格)
    /// - 不能被"塞象眼"
    private static func isValidElephantMove(from: Position, to: Position, for player: Player, on board: Board) -> Bool {
        // 不能过河
        guard to.isInOwnHalf(for: player) else { return false }

        // 必须走"田"字
        let dx = abs(to.x - from.x)
        let dy = abs(to.y - from.y)

        guard dx == 2 && dy == 2 else { return false }

        // 检查"象眼"是否被塞
        let elephantEye = Position(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
        return board.piece(at: elephantEye) == nil
    }

    /// 马/傌移动规则
    /// - 走"日"字
    /// - 不能被"蹩马腿"
    private static func isValidHorseMove(from: Position, to: Position, on board: Board) -> Bool {
        // 必须走"日"字
        let dx = abs(to.x - from.x)
        let dy = abs(to.y - from.y)

        guard (dx == 1 && dy == 2) || (dx == 2 && dy == 1) else { return false }

        // 检查"马腿"
        let leg: Position
        if dx == 2 {
            // 横向两格，纵向一格，马腿在横向中间
            leg = Position(x: (from.x + to.x) / 2, y: from.y)
        } else {
            // 纵向两格，横向一格，马腿在纵向中间
            leg = Position(x: from.x, y: (from.y + to.y) / 2)
        }

        return board.piece(at: leg) == nil
    }

    /// 车/俥移动规则
    /// - 直线移动
    /// - 路径上不能有棋子 (除了目标位置)
    private static func isValidRookMove(from: Position, to: Position, on board: Board) -> Bool {
        // 必须在同一行或同一列
        guard from.x == to.x || from.y == to.y else { return false }

        // 检查路径上是否有其他棋子
        let pathPositions = from.pathPositions(to: to)
        for pos in pathPositions {
            if board.piece(at: pos) != nil {
                return false
            }
        }

        return true
    }

    /// 炮/砲移动规则
    /// - 直线移动
    /// - 吃子时需要隔一个棋子 (炮架)
    /// - 不吃子时路径上不能有棋子
    private static func isValidCannonMove(from: Position, to: Position, on board: Board) -> Bool {
        // 必须在同一行或同一列
        guard from.x == to.x || from.y == to.y else { return false }

        let pathPositions = from.pathPositions(to: to)
        let targetPiece = board.piece(at: to)

        if targetPiece == nil {
            // 不吃子：路径上必须全空
            for pos in pathPositions {
                if board.piece(at: pos) != nil {
                    return false
                }
            }
            return true
        } else {
            // 吃子：路径上必须恰好有一个棋子作为炮架
            var pieceCount = 0
            for pos in pathPositions {
                if board.piece(at: pos) != nil {
                    pieceCount += 1
                }
            }
            // 不能吃己方棋子已在 isMoveLegal 中检查
            return pieceCount == 1
        }
    }

    /// 兵/卒移动规则
    /// - 未过河只能向前走
    /// - 过河后可以左右移动
    private static func isValidPawnMove(from: Position, to: Position, for player: Player) -> Bool {
        let forwardY = player == .red ? 1 : -1
        let dx = to.x - from.x
        let dy = to.y - from.y

        // 是否已过河
        let hasCrossedRiver = from.hasCrossedRiver(for: player)

        if !hasCrossedRiver {
            // 未过河：只能向前走一格
            return dx == 0 && dy == forwardY
        } else {
            // 已过河：可以向前走，也可以左右移动
            if dx == 0 && dy == forwardY {
                return true  // 向前走
            }
            if abs(dx) == 1 && dy == 0 {
                return true  // 左右移动
            }
            return false
        }
    }

    /// 检查将帅是否照面
    /// 即双方的将帅在同一列且中间无棋子
    public static func areKingsFacing(on board: Board) -> Bool {
        guard let redKingPos = board.findKing(for: .red),
              let blackKingPos = board.findKing(for: .black) else {
            return false
        }

        // 检查是否在同一列
        guard redKingPos.x == blackKingPos.x else {
            return false
        }

        // 检查中间是否有棋子
        let minY = min(redKingPos.y, blackKingPos.y)
        let maxY = max(redKingPos.y, blackKingPos.y)

        for y in (minY + 1)..<maxY {
            if board.piece(at: Position(x: redKingPos.x, y: y)) != nil {
                return false
            }
        }

        return true
    }

    // MARK: - Helper Methods

    /// 检查某个位置是否威胁另一个位置
    private static func isThreatening(from: Position, to: Position, piece: Piece, on board: Board) -> Bool {
        isMoveLegal(piece: piece, from: from, to: to, on: board)
    }

    /// 计算两个位置之间的路径位置
    private static func getPathPositions(from: Position, to: Position) -> [Position] {
        from.pathPositions(to: to)
    }
}

// MARK: - Position Extensions

extension Position {
    /// 计算到目标位置的路径位置 (不包括起点和终点)
    fileprivate func pathPositions(to destination: Position) -> [Position] {
        // 必须在同一行或同一列
        guard x == destination.x || y == destination.y else { return [] }

        var positions: [Position] = []

        if x == destination.x {
            // 垂直移动
            let minY = min(y, destination.y)
            let maxY = max(y, destination.y)
            for row in (minY + 1)..<maxY {
                positions.append(Position(x: x, y: row))
            }
        } else {
            // 水平移动
            let minX = min(x, destination.x)
            let maxX = max(x, destination.x)
            for col in (minX + 1)..<maxX {
                positions.append(Position(x: col, y: y))
            }
        }

        return positions
    }
}
