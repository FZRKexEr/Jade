import Foundation
import Combine
import Game

// MARK: - BoardViewModel

/// 棋盘视图模型 - 绑定 Board 模型和 UI
/// 处理用户输入（选子、移动），协调游戏逻辑，提供 UI 状态
@MainActor
@Observable
final class BoardViewModel {

    // MARK: - 依赖

    /// 游戏控制器（可选，用于执行移动验证）
    private let gameController: GameController?

    // MARK: - 状态

    /// 当前棋盘状态
    private(set) var board: Board

    /// 当前选中的位置
    private(set) var selectedPosition: Position?

    /// 当前选中的棋子可移动的位置
    private(set) var validMoves: [Position] = []

    /// 当前回合玩家
    private(set) var currentTurn: Player

    /// 最后一步移动
    private(set) var lastMove: Move?

    /// 是否将军
    private(set) var isKingInCheck: Bool = false

    /// 将军位置
    private(set) var checkPosition: Position?

    /// 棋盘缩放比例
    private(set) var zoomScale: CGFloat = 1.0

    /// 是否显示坐标
    var showCoordinates: Bool = true

    /// 是否显示最后一步
    var showLastMove: Bool = true

    /// 是否显示可移动位置
    var showValidMoves: Bool = true

    /// 走子历史
    private(set) var moveHistory: [Move] = []

    /// 重做栈
    private(set) var redoStack: [Move] = []

    // MARK: - 计算属性

    /// 棋子字典（用于快速查找）
    var pieces: [Position: Piece] {
        var dict: [Position: Piece] = [:]
        for y in 0..<Board.height {
            for x in 0..<Board.width {
                let pos = Position(x: x, y: y)
                if let piece = board.piece(at: pos) {
                    dict[pos] = piece
                }
            }
        }
        return dict
    }

    /// 是否可以悔棋
    var canUndo: Bool {
        !moveHistory.isEmpty
    }

    /// 是否可以重做
    var canRedo: Bool {
        !redoStack.isEmpty
    }

    // MARK: - 初始化

    init(
        board: Board = Board.initial(),
        gameController: GameController? = nil
    ) {
        self.board = board
        self.currentTurn = board.currentPlayer
        self.gameController = gameController
    }

    // MARK: - 选择处理

    /// 选择位置（点击处理）
    func selectPosition(_ position: Position) {
        // 如果已经选中了棋子
        if let selected = selectedPosition {
            // 检查是否点击了可移动位置
            if validMoves.contains(where: { $0 == position }) {
                // 执行移动
                Task {
                    await executeMove(from: selected, to: position)
                }
                return
            }

            // 如果点击了同一位置，取消选择
            if selected == position {
                clearSelection()
                return
            }
        }

        // 尝试选择新棋子
        guard let piece = board.piece(at: position) else {
            // 点击空位置，清除选择
            clearSelection()
            return
        }

        // 只能选当前回合的棋子
        guard piece.player == currentTurn else {
            return
        }

        // 选择棋子
        selectedPosition = position

        // 计算可移动位置
        calculateValidMoves(for: piece, at: position)
    }

    /// 处理拖拽移动
    func handleDrag(from: Position, to: Position) {
        // 检查是否可以移动到目标位置
        if validMoves.contains(where: { $0 == to }) {
            Task {
                await executeMove(from: from, to: to)
            }
        } else {
            // 如果移动无效，保持选择状态
        }
    }

    /// 清除选择
    func clearSelection() {
        selectedPosition = nil
        validMoves.removeAll()
    }

    /// 计算可移动位置
    private func calculateValidMoves(for piece: Piece, at position: Position) {
        // 使用位置分析器计算
        validMoves = PositionAnalyzer.getLegalMoves(from: position, on: board)
    }

    // MARK: - 移动执行

    /// 执行移动
    private func executeMove(from: Position, to: Position) async {
        guard let piece = board.piece(at: from) else { return }

        // 验证移动
        let validationResult = PositionAnalyzer.validateMove(from: from, to: to, on: board)
        guard validationResult.isValid else { return }

        let capturedPiece = board.piece(at: to)

        // 创建移动记录
        let move = Move(
            from: from,
            to: to,
            piece: piece,
            capturedPiece: capturedPiece,
            isCheck: false, // 简化实现
            isCheckmate: false,
            timestamp: Date()
        )

        // 更新棋盘
        var newBoard = board
        newBoard.movePiece(from: from, to: to)
        newBoard.switchTurn()

        // 更新状态
        board = newBoard
        currentTurn = newBoard.currentPlayer
        moveHistory.append(move)
        lastMove = move
        redoStack.removeAll()

        // 清除选择
        clearSelection()

        // 检查将军（简化实现）
        checkForCheck()
    }

    /// 检查将军状态
    private func checkForCheck() {
        // 简化实现，实际需要完整的规则引擎
        isKingInCheck = false
        checkPosition = nil
    }

    // MARK: - 悔棋与重做

    /// 悔棋
    func undoMove() {
        guard let lastMove = moveHistory.last else { return }

        // 恢复棋盘状态
        var newBoard = board
        newBoard.switchTurn()

        // 恢复棋子位置
        newBoard.placePiece(lastMove.piece, at: lastMove.from)
        newBoard.placePiece(lastMove.capturedPiece, at: lastMove.to)

        // 更新状态
        board = newBoard
        currentTurn = newBoard.currentPlayer
        moveHistory.removeLast()
        redoStack.append(lastMove)

        lastMove = moveHistory.last
        clearSelection()
    }

    /// 重做
    func redoMove() {
        guard let move = redoStack.last else { return }

        Task {
            await executeMove(from: move.from, to: move.to)
            redoStack.removeLast()
        }
    }

    // MARK: - 缩放控制

    /// 设置缩放比例
    func setZoomScale(_ scale: CGFloat) {
        zoomScale = max(0.5, min(2.0, scale))
    }

    /// 放大
    func zoomIn() {
        setZoomScale(zoomScale + 0.1)
    }

    /// 缩小
    func zoomOut() {
        setZoomScale(zoomScale - 0.1)
    }

    /// 重置缩放
    func resetZoom() {
        zoomScale = 1.0
    }

    // MARK: - 新游戏

    /// 开始新游戏
    func newGame() {
        board = Board.initial()
        currentTurn = .red
        moveHistory.removeAll()
        redoStack.removeAll()
        lastMove = nil
        clearSelection()
        isKingInCheck = false
        checkPosition = nil
    }
}

// MARK: - 辅助扩展

extension BoardViewModel {
    /// 获取指定位置的棋子
    func piece(at position: Position) -> Piece? {
        return board.piece(at: position)
    }

    /// 检查是否可以移动到指定位置
    func canMove(to position: Position) -> Bool {
        return validMoves.contains(where: { $0 == position })
    }

    /// 获取当前选中棋子
    var selectedPiece: Piece? {
        guard let position = selectedPosition else { return nil }
        return board.piece(at: position)
    }
}
