import Foundation
import Combine

// MARK: - GameRecorder

/// 对局记录器
/// 负责记录走棋、创建变着、添加评注、悔棋等功能
@MainActor
public final class GameRecorder: ObservableObject {

    // MARK: - Properties

    /// 当前对局记录
    @Published public private(set) var record: GameRecord

    /// 当前棋盘状态（用于验证走法）
    @Published public private(set) var currentBoard: Board

    /// 当前位置节点
    public var currentNode: MoveNode {
        record.currentNode
    }

    /// 当前步数
    public var currentMoveNumber: Int {
        record.currentMoveNumber
    }

    /// 是否可以悔棋
    public var canUndo: Bool {
        record.currentNode.parent != nil
    }

    /// 是否可以重做
    public var canRedo: Bool {
        record.currentNode.mainVariation != nil
    }

    /// 是否处于变着中
    public var isInVariation: Bool {
        record.currentNode.parent?.variations.contains {
            $0.id == record.currentNode.id
        } ?? false
    }

    /// 历史管理器
    private var moveHistory = MoveHistoryManager()

    /// 订阅
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// 创建新的对局记录器
    public init(
        record: GameRecord? = nil,
        initialBoard: Board? = nil
    ) {
        self.record = record ?? GameRecord()
        self.currentBoard = initialBoard ?? Board.initial()

        // 如果有初始 FEN，设置棋盘
        if let fen = self.record.initialFEN {
            // 这里应该解析 FEN，简化处理
            self.currentBoard = Board.initial()
        }

        self.setupBindings()
    }

    /// 从对局记录创建记录器
    public convenience init(record: GameRecord) {
        self.init(record: record, initialBoard: Board.initial())
    }

    // MARK: - Setup

    private func setupBindings() {
        // 监听记录变化
        record.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Move Recording

    /// 记录一步走棋
    /// - Parameters:
    ///   - move: 走棋记录
    ///   - addVariation: 是否添加为变着
    /// - Returns: 是否成功
    @discardableResult
    public func recordMove(_ move: Move, asVariation: Bool = false) -> Bool {
        // 验证走法是否合法
        guard isMoveValid(move) else {
            print("无效的走法: \(move)")
            return false
        }

        // 保存历史状态
        moveHistory.saveState(
            node: record.currentNode,
            board: currentBoard
        )

        if asVariation {
            // 添加为变着
            let newNode = record.currentNode.parent?.addVariation(
                MoveNode(move: move, moveNumber: record.currentMoveNumber)
            )
            if let newNode = newNode {
                record.currentNode = newNode
            }
        } else {
            // 添加为主变
            let newNode = MoveNode(move: move, moveNumber: record.currentMoveNumber + 1)
            record.addMove(move)
        }

        // 更新棋盘状态
        currentBoard.movePiece(from: move.from, to: move.to)
        currentBoard.switchTurn()

        // 生成记谱
        if let notation = move.chineseNotation {
            print("记录走法: \(notation)")
        }

        record.isModified = true
        return true
    }

    /// 记录从位置到位置的走棋
    @discardableResult
    public func recordMove(from: Position, to: Position, piece: Piece, capturedPiece: Piece? = nil) -> Bool {
        let move = Move(
            from: from,
            to: to,
            piece: piece,
            capturedPiece: capturedPiece,
            timestamp: Date()
        )
        return recordMove(move)
    }

    /// 验证走法是否合法（简化验证）
    private func isMoveValid(_ move: Move) -> Bool {
        // 检查起始位置是否有棋子
        guard currentBoard.piece(at: move.from)?.id == move.piece.id else {
            return false
        }

        // 检查是否在棋盘范围内
        guard move.from.isValid && move.to.isValid else {
            return false
        }

        // 更多验证可以在上层调用方实现
        return true
    }

    // MARK: - Variation Operations

    /// 添加变着
    @discardableResult
    public func addVariation(move: Move) -> MoveNode? {
        moveHistory.saveState(node: record.currentNode, board: currentBoard)

        let variationNode = record.addVariation(move)
        record.isModified = true

        // 更新棋盘状态
        currentBoard.movePiece(from: move.from, to: move.to)
        currentBoard.switchTurn()

        return variationNode
    }

    /// 提升当前变着为主变
    @discardableResult
    public func promoteCurrentVariation() -> Bool {
        guard let currentNode = record.currentNode.parent?.variations.first(where: {
            $0.id == record.currentNode.id
        }) else {
            return false
        }

        let success = record.currentNode.parent?.promoteMainVariation(currentNode) != nil
        if success {
            record.isModified = true
        }
        return success
    }

    /// 删除当前节点
    @discardableResult
    public func deleteCurrentNode() -> Bool {
        let success = record.deleteCurrentNode()
        if success {
            record.isModified = true
        }
        return success
    }

    // MARK: - Comment Operations

    /// 添加前评注
    public func addPreComment(_ comment: String) {
        record.addPreComment(comment)
        record.isModified = true
    }

    /// 添加后评注
    public func addPostComment(_ comment: String) {
        record.addPostComment(comment)
        record.isModified = true
    }

    /// 设置评价符号
    public func setEvaluationSymbol(_ symbol: EvaluationSymbol) {
        record.setEvaluationSymbol(symbol)
        record.isModified = true
    }

    // MARK: - Undo/Redo

    /// 悔棋（撤销）
    @discardableResult
    public func undo() -> Bool {
        guard let state = moveHistory.undo() else {
            // 从历史栈撤销
            return record.goBackward()
        }

        record.currentNode = state.node
        currentBoard = state.board
        record.isModified = true
        return true
    }

    /// 重做
    @discardableResult
    public func redo() -> Bool {
        guard let state = moveHistory.redo() else {
            // 从历史栈重做
            return record.goForward()
        }

        record.currentNode = state.node
        currentBoard = state.board
        record.isModified = true
        return true
    }

    /// 悔棋 N 步
    @discardableResult
    public func undo(steps: Int) -> Bool {
        var success = true
        for _ in 0..<steps {
            if !undo() {
                success = false
                break
            }
        }
        return success
    }

    /// 清除历史
    public func clearHistory() {
        moveHistory.clear()
    }

    // MARK: - Navigation

    /// 跳转到指定步数
    public func goToMove(_ moveNumber: Int) {
        record.goToMove(moveNumber)
    }

    /// 跳到开始
    public func goToStart() {
        record.goToStart()
    }

    /// 跳到结束
    public func goToEnd() {
        record.goToEnd()
    }

    /// 前进
    @discardableResult
    public func goForward() -> Bool {
        record.goForward()
    }

    /// 后退
    @discardableResult
    public func goBackward() -> Bool {
        record.goBackward()
    }

    // MARK: - Export/Import

    /// 导出为 PGN 格式
    public func exportToPGN() -> String {
        return PGNParser.generate(record)
    }

    /// 从 PGN 导入
    public static func importFromPGN(_ pgn: String) throws -> GameRecorder {
        let record = try PGNParser.parse(pgn)
        return GameRecorder(record: record)
    }
}

// MARK: - MoveHistoryManager

/// 走棋历史管理器
private struct MoveHistoryManager {

    struct State {
        let node: MoveNode
        let board: Board
    }

    private var undoStack: [State] = []
    private var redoStack: [State] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    mutating func saveState(node: MoveNode, board: Board) {
        let state = State(
            node: node,
            board: board.copy()
        )
        undoStack.append(state)
        redoStack.removeAll()
    }

    mutating func undo() -> State? {
        guard let state = undoStack.popLast() else { return nil }
        redoStack.append(state)
        return state
    }

    mutating func redo() -> State? {
        guard let state = redoStack.popLast() else { return nil }
        undoStack.append(state)
        return state
    }

    mutating func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}

// MARK: - MoveNode Extension

extension MoveNode {

    /// 将指定的变着提升为主变
    @discardableResult
    fileprivate func promoteMainVariation(_ variation: MoveNode) -> Bool {
        guard let currentMain = self.mainVariation else { return false }
        guard let variationIndex = self.variations.firstIndex(where: { $0.id == variation.id }) else {
            return false
        }

        // 交换
        self.variations[variationIndex] = currentMain
        self.mainVariation = variation

        return true
    }
}