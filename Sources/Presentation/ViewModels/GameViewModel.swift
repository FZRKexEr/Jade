import Foundation
import Combine

/// 游戏视图模型 - 管理游戏状态
@MainActor
@Observable
final class GameViewModel {
    // MARK: - 游戏状态
    var board: Board
    var selectedPosition: Position?
    var validMoves: [Position] = []
    var lastMove: Move?
    var isBoardFlipped: Bool = false
    var gameResult: GameResult = .ongoing
    var moveHistory: [Move] = []
    var redoStack: [Move] = []
    var currentTurn: Player = .red

    // MARK: - 棋盘配置
    var boardScale: CGFloat = 1.0
    var showCoordinates: Bool = true
    var showLastMove: Bool = true
    var showValidMoves: Bool = true

    // MARK: - 回调
    var onMoveMade: ((Move) -> Void)?
    var onGameEnded: ((GameResult) -> Void)?

    init(initialBoard: Board = Board.initial()) {
        self.board = initialBoard
        self.currentTurn = initialBoard.currentPlayer
    }

    // MARK: - 棋子选择
    func selectPiece(at position: Position) {
        // 如果已经选中了一个棋子，尝试移动
        if let selected = selectedPosition {
            if validMoves.contains(where: { $0 == position }) {
                // 执行移动
                Task {
                    await executeMove(from: selected, to: position)
                }
                return
            }
        }

        // 选择新棋子
        guard let piece = board.piece(at: position) else {
            clearSelection()
            return
        }

        // 只能选当前回合的棋子
        guard piece.player == currentTurn else {
            return
        }

        selectedPosition = position
        // 计算有效移动位置（简化实现，实际需要规则引擎）
        calculateValidMoves(for: piece, at: position)
    }

    func clearSelection() {
        selectedPosition = nil
        validMoves = []
    }

    private func calculateValidMoves(for piece: Piece, at position: Position) {
        // 简化实现：这里应该调用规则引擎
        // 临时返回一些示例位置
        validMoves = []

        // 根据棋子类型计算可移动位置（简化版）
        switch piece.type {
        case .king:
            // 将/帅只能在九宫内移动一格
            let moves = [(0, 1), (0, -1), (1, 0), (-1, 0)]
            for (dx, dy) in moves {
                let newPos = Position(x: position.x + dx, y: position.y + dy)
                if isValidKingPosition(newPos, for: piece.player) {
                    validMoves.append(newPos)
                }
            }
        case .advisor:
            // 士/仕斜向移动一格
            let moves = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
            for (dx, dy) in moves {
                let newPos = Position(x: position.x + dx, y: position.y + dy)
                if isValidAdvisorPosition(newPos) {
                    validMoves.append(newPos)
                }
            }
        case .elephant:
            // 象/相走田字
            let moves = [(2, 2), (2, -2), (-2, 2), (-2, -2)]
            for (dx, dy) in moves {
                let newPos = Position(x: position.x + dx, y: position.y + dy)
                if isValidElephantPosition(newPos, from: position) {
                    validMoves.append(newPos)
                }
            }
        case .horse:
            // 马走日
            let moves = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)]
            for (dx, dy) in moves {
                let newPos = Position(x: position.x + dx, y: position.y + dy)
                if newPos.isValid() {
                    validMoves.append(newPos)
                }
            }
        case .rook:
            // 车横竖走
            for i in 0..<Board.width {
                if i != position.x {
                    validMoves.append(Position(x: i, y: position.y))
                }
            }
            for i in 0..<Board.height {
                if i != position.y {
                    validMoves.append(Position(x: position.x, y: i))
                }
            }
        case .cannon:
            // 炮横竖走（需要隔一个子才能吃）
            for i in 0..<Board.width {
                if i != position.x {
                    validMoves.append(Position(x: i, y: position.y))
                }
            }
            for i in 0..<Board.height {
                if i != position.y {
                    validMoves.append(Position(x: position.x, y: i))
                }
            }
        case .pawn:
            // 卒/兵向前走，过河后可以横走
            let direction = piece.player == .red ? 1 : -1
            let forwardPos = Position(x: position.x, y: position.y + direction)
            if forwardPos.isValid() {
                validMoves.append(forwardPos)
            }
            // 过河后检查横走（简化实现）
            if (piece.player == .red && position.y >= 5) ||
               (piece.player == .black && position.y <= 4) {
                let leftPos = Position(x: position.x - 1, y: position.y)
                let rightPos = Position(x: position.x + 1, y: position.y)
                if leftPos.isValid() { validMoves.append(leftPos) }
                if rightPos.isValid() { validMoves.append(rightPos) }
            }
        }
    }

    // 辅助函数：检查将/帅位置是否有效
    private func isValidKingPosition(_ pos: Position, for player: Player) -> Bool {
        // 九宫格范围
        let xRange = 3...5
        let yRange = player == .red ? 0...2 : 7...9
        return xRange.contains(pos.x) && yRange.contains(pos.y)
    }

    // 辅助函数：检查士/仕位置是否有效
    private func isValidAdvisorPosition(_ pos: Position) -> Bool {
        let validPositions: [(Int, Int)] = [(3, 0), (5, 0), (4, 1), (3, 2), (5, 2),
                                            (3, 9), (5, 9), (4, 8), (3, 7), (5, 7)]
        return validPositions.contains { $0 == (pos.x, pos.y) }
    }

    // 辅助函数：检查象/相位置是否有效
    private func isValidElephantPosition(_ pos: Position, from: Position) -> Bool {
        // 不能过河
        let redSide = pos.y <= 4
        let fromRedSide = from.y <= 4
        guard redSide == fromRedSide else { return false }

        // 检查象眼是否被塞
        let eyeX = (from.x + pos.x) / 2
        let eyeY = (from.y + pos.y) / 2
        let eyePos = Position(x: eyeX, y: eyeY)
        return board.piece(at: eyePos) == nil
    }

    // MARK: - 走棋执行

    func executeMove(from: Position, to: Position) async {
        guard let piece = board.piece(at: from) else { return }

        let capturedPiece = board.piece(at: to)

        let move = Move(
            from: from,
            to: to,
            piece: piece,
            capturedPiece: capturedPiece,
            isCheck: false,  // 简化实现
            isCheckmate: false,
            timestamp: Date()
        )

        // 更新棋盘
        var newBoard = board
        newBoard.movePiece(from: from, to: to)
        newBoard.switchTurn()

        board = newBoard
        currentTurn = newBoard.currentPlayer
        moveHistory.append(move)
        lastMove = move
        redoStack.removeAll()

        clearSelection()

        onMoveMade?(move)
    }

    // MARK: - 悔棋与重做

    func undoMove() {
        guard let lastMove = moveHistory.last else { return }

        var newBoard = board
        newBoard.switchTurn()

        // 恢复棋子位置
        newBoard.placePiece(lastMove.piece, at: lastMove.from)
        newBoard.placePiece(lastMove.capturedPiece, at: lastMove.to)

        board = newBoard
        currentTurn = newBoard.currentPlayer
        moveHistory.removeLast()
        redoStack.append(lastMove)

        lastMove = moveHistory.last
        clearSelection()
    }

    func redoMove() {
        guard let move = redoStack.last else { return }

        Task {
            await executeMove(from: move.from, to: move.to)
            redoStack.removeLast()
        }
    }

    func canUndo() -> Bool {
        !moveHistory.isEmpty
    }

    func canRedo() -> Bool {
        !redoStack.isEmpty
    }

    // MARK: - 新游戏

    func newGame() {
        board = Board.initial()
        currentTurn = .red
        moveHistory.removeAll()
        redoStack.removeAll()
        lastMove = nil
        gameResult = .ongoing
        clearSelection()
    }

    // MARK: - 旋转棋盘

    func flipBoard() {
        isBoardFlipped.toggle()
    }

    // MARK: - 缩放控制

    func zoomIn() {
        boardScale = min(boardScale + 0.1, 1.5)
    }

    func zoomOut() {
        boardScale = max(boardScale - 0.1, 0.5)
    }

    func resetZoom() {
        boardScale = 1.0
    }
}
