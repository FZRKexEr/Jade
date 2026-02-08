import Foundation
import Combine

// MARK: - GameController

/// 游戏控制器
/// 管理完整的对局流程，包括局面追踪、走子历史、悔棋功能等
@MainActor
public final class GameController: ObservableObject, Sendable {

    // MARK: - Published Properties

    /// 当前棋盘状态
    @Published public private(set) var currentBoard: Board

    /// 当前轮到谁走棋
    @Published public private(set) var currentPlayer: Player

    /// 游戏状态
    @Published public private(set) var gameState: GameState

    /// 走棋历史
    @Published public private(set) var moveHistory: MoveHistory

    /// 最后一步走棋
    @Published public private(set) var lastMove: Move?

    /// 选中的位置
    @Published public var selectedPosition: Position?

    /// 当前位置的所有合法移动
    @Published public private(set) var validMoves: [Position] = []

    /// 是否正在处理引擎移动
    @Published public private(set) var isProcessingEngineMove: Bool = false

    // MARK: - Private Properties

    /// 循环历史记录
    private var repetitionHistory = SpecialRules.RepetitionHistory()

    /// 半回合计数 (50步规则)
    private var halfMoveClock: Int = 0

    /// 完整回合数
    private var fullMoveNumber: Int = 1

    /// 游戏开始的日期
    private let gameStartDate: Date

    /// 用于发布事件的Subject
    private let moveSubject = PassthroughSubject<Move, Never>()
    private let gameStateSubject = PassthroughSubject<GameState, Never>()

    /// 取消令牌存储
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Properties

    /// 走棋事件发布者
    public var movePublisher: AnyPublisher<Move, Never> {
        moveSubject.eraseToAnyPublisher()
    }

    /// 游戏状态发布者
    public var gameStatePublisher: AnyPublisher<GameState, Never> {
        gameStateSubject.eraseToAnyPublisher()
    }

    /// 是否可以悔棋
    public var canUndo: Bool {
        moveHistory.canUndo
    }

    /// 是否可以重做
    public var canRedo: Bool {
        moveHistory.canRedo
    }

    /// 总步数
    public var moveCount: Int {
        moveHistory.count
    }

    /// 当前FEN字符串
    public var currentFEN: String {
        FENParser.toFEN(
            board: currentBoard,
            halfMoveClock: halfMoveClock,
            fullMoveNumber: fullMoveNumber
        )
    }

    /// 游戏是否已结束
    public var isGameEnded: Bool {
        switch gameState {
        case .ongoing, .check:
            return false
        default:
            return true
        }
    }

    // MARK: - Initialization

    /// 创建新的游戏控制器
    /// - Parameter initialBoard: 初始棋盘，默认为标准开局
    public init(initialBoard: Board = Board.initial()) {
        self.currentBoard = initialBoard
        self.currentPlayer = .red
        self.gameState = .ongoing(currentPlayer: .red)
        self.moveHistory = MoveHistory()
        self.gameStartDate = Date()

        // 记录初始局面
        let initialHash = SpecialRules.hashPosition(initialBoard)
        repetitionHistory.addEntry(SpecialRules.RepetitionEntry(
            positionHash: initialHash,
            sideToMove: .red
        ))
    }

    // MARK: - Game Operations

    /// 执行走棋
    /// - Parameters:
    ///   - from: 起始位置
    ///   - to: 目标位置
    /// - Returns: 走棋结果
    @discardableResult
    public func makeMove(from: Position, to: Position) -> Result<Move, GameError> {
        // 1. 验证游戏是否进行中
        guard !isGameEnded else {
            return .failure(.gameAlreadyEnded)
        }

        // 2. 验证位置有效
        guard currentBoard.isValidPosition(from), currentBoard.isValidPosition(to) else {
            return .failure(.invalidMove)
        }

        // 3. 获取棋子
        guard let piece = currentBoard.piece(at: from) else {
            return .failure(.noPieceAtSource)
        }

        // 4. 验证是否轮到该方走棋
        guard piece.player == currentPlayer else {
            return .failure(.notYourTurn)
        }

        // 5. 验证移动合法性
        guard MovementRules.isMoveLegal(piece: piece, from: from, to: to, on: currentBoard) else {
            return .failure(.invalidMove)
        }

        // 6. 检查是否会导致自己被将军
        if MovementRules.wouldResultInSelfCheck(from: from, to: to, on: currentBoard) {
            return .failure(.wouldLeaveKingInCheck)
        }

        // 7. 执行移动
        let capturedPiece = currentBoard.piece(at: to)
        var newBoard = currentBoard.copy()
        newBoard.movePiece(from: from, to: to)
        newBoard.switchTurn()

        // 8. 检查是否将军/将死
        let opponent = currentPlayer.opponent
        let isCheck = MovementRules.isKingInCheck(for: opponent, on: newBoard)
        let isCheckmate = isCheck && MovementRules.isCheckmate(for: opponent, on: newBoard)

        // 9. 创建走棋记录
        let move = Move(
            from: from,
            to: to,
            piece: piece,
            capturedPiece: capturedPiece,
            isCheck: isCheck,
            isCheckmate: isCheckmate,
            timestamp: Date()
        )

        // 10. 更新游戏状态
        currentBoard = newBoard
        lastMove = move
        moveHistory.addMove(move)
        selectedPosition = nil
        validMoves = []

        // 11. 更新回合计数
        if currentPlayer == .black {
            fullMoveNumber += 1
        }
        currentPlayer = opponent

        // 12. 更新半回合计数
        if capturedPiece != nil || piece.type == .pawn {
            halfMoveClock = 0
        } else {
            halfMoveClock += 1
        }

        // 13. 更新游戏状态
        updateGameState()

        // 14. 记录循环历史
        let hash = SpecialRules.hashPosition(currentBoard)
        repetitionHistory.addEntry(SpecialRules.RepetitionEntry(
            positionHash: hash,
            sideToMove: currentPlayer,
            lastMove: move
        ))

        // 15. 发布事件
        moveSubject.send(move)

        return .success(move)
    }

    /// 选择位置 (用于UI交互)
    /// - Parameter position: 要选择的位置
    public func selectPosition(_ position: Position?) {
        selectedPosition = position

        if let pos = position,
           let piece = currentBoard.piece(at: pos),
           piece.player == currentPlayer {
            // 计算所有合法移动
            validMoves = PositionAnalyzer.getLegalMoves(from: pos, on: currentBoard)
        } else {
            validMoves = []
        }
    }

    /// 悔棋
    /// - Returns: 是否成功
    @discardableResult
    public func undo() -> Bool {
        guard moveHistory.canUndo else { return false }

        guard let lastMove = moveHistory.undo() else { return false }

        // 恢复棋盘
        var newBoard = currentBoard.copy()

        // 1. 将棋子移回原位
        newBoard.movePiece(from: lastMove.to, to: lastMove.from)

        // 2. 恢复被吃的棋子
        if let captured = lastMove.capturedPiece {
            newBoard.placePiece(captured, at: lastMove.to)
        }

        // 3. 切换回原来的行棋方
        newBoard = Board(
            pieces: newBoard.pieces,
            currentPlayer: lastMove.piece.player,
            moveCount: max(0, newBoard.moveCount - 1),
            halfMoveClock: halfMoveClock
        )

        currentBoard = newBoard
        currentPlayer = lastMove.piece.player
        self.lastMove = moveHistory.lastMove

        // 更新回合数
        if currentPlayer == .black {
            fullMoveNumber = max(1, fullMoveNumber - 1)
        }

        // 更新游戏状态
        updateGameState()

        // 清除选择
        selectedPosition = nil
        validMoves = []

        return true
    }

    /// 重做
    /// - Returns: 是否成功
    @discardableResult
    public func redo() -> Bool {
        guard moveHistory.canRedo else { return false }

        // 简化的重做实现，实际上需要重新执行走棋
        // 这里需要更复杂的实现来支持完全重做功能
        return false
    }

    /// 重新开始游戏
    public func restartGame() {
        currentBoard = Board.initial()
        currentPlayer = .red
        gameState = .ongoing(currentPlayer: .red)
        moveHistory = MoveHistory()
        lastMove = nil
        selectedPosition = nil
        validMoves = []
        halfMoveClock = 0
        fullMoveNumber = 1

        repetitionHistory.clear()

        // 记录初始局面
        let initialHash = SpecialRules.hashPosition(currentBoard)
        repetitionHistory.addEntry(SpecialRules.RepetitionEntry(
            positionHash: initialHash,
            sideToMove: .red
        ))
    }

    /// 从FEN加载局面
    /// - Parameter fen: FEN字符串
    /// - Returns: 是否成功
    @discardableResult
    public func loadFromFEN(_ fen: String) -> Bool {
        do {
            let result = try FENParser.parse(fen)

            currentBoard = result.board
            currentPlayer = result.currentPlayer
            halfMoveClock = result.halfMoveClock
            fullMoveNumber = result.fullMoveNumber

            gameState = .ongoing(currentPlayer: currentPlayer)
            moveHistory = MoveHistory()
            lastMove = nil
            selectedPosition = nil
            validMoves = []

            updateGameState()

            return true
        } catch {
            return false
        }
    }

    /// 导出为FEN字符串
    public func exportToFEN() -> String {
        FENParser.toFEN(
            board: currentBoard,
            halfMoveClock: halfMoveClock,
            fullMoveNumber: fullMoveNumber
        )
    }

    /// 获取当前局面信息
    public func getPositionInfo() -> PositionInfo {
        PositionInfo(
            fen: exportToFEN(),
            currentPlayer: currentPlayer,
            gameState: gameState,
            moveCount: moveHistory.count,
            lastMove: lastMove,
            isCheck: isInCheck,
            isCheckmate: isCheckmate,
            isStalemate: isStalemate
        )
    }

    // MARK: - Private Methods

    /// 更新游戏状态
    private func updateGameState() {
        // 检查是否被将军
        let isCheck = PositionAnalyzer.isInCheck(player: currentPlayer, on: currentBoard)

        // 检查是否将死
        if isCheck && PositionAnalyzer.isCheckmate(player: currentPlayer, on: currentBoard) {
            let winner = currentPlayer.opponent
            gameState = .checkmate(winner: winner)
            return
        }

        // 检查是否困毙
        if !isCheck && PositionAnalyzer.isStalemate(player: currentPlayer, on: currentBoard) {
            gameState = .stalemate(stalematedPlayer: currentPlayer)
            return
        }

        // 检查是否被将军
        if isCheck {
            if let kingPos = currentBoard.findKing(for: currentPlayer) {
                gameState = .check(attacker: currentPlayer.opponent, kingPosition: kingPos)
                return
            }
        }

        // 正常进行
        gameState = .ongoing(currentPlayer: currentPlayer)
    }

    // MARK: - Computed Properties

    private var isInCheck: Bool {
        PositionAnalyzer.isInCheck(player: currentPlayer, on: currentBoard)
    }

    private var isCheckmate: Bool {
        PositionAnalyzer.isCheckmate(player: currentPlayer, on: currentBoard)
    }

    private var isStalemate: Bool {
        PositionAnalyzer.isStalemate(player: currentPlayer, on: currentBoard)
    }
}

// MARK: - PositionInfo

/// 局面信息
public struct PositionInfo: Sendable, CustomStringConvertible {
    public let fen: String
    public let currentPlayer: Player
    public let gameState: GameState
    public let moveCount: Int
    public let lastMove: Move?
    public let isCheck: Bool
    public let isCheckmate: Bool
    public let isStalemate: Bool

    public init(
        fen: String,
        currentPlayer: Player,
        gameState: GameState,
        moveCount: Int,
        lastMove: Move?,
        isCheck: Bool,
        isCheckmate: Bool,
        isStalemate: Bool
    ) {
        self.fen = fen
        self.currentPlayer = currentPlayer
        self.gameState = gameState
        self.moveCount = moveCount
        self.lastMove = lastMove
        self.isCheck = isCheck
        self.isCheckmate = isCheckmate
        self.isStalemate = isStalemate
    }

    public var description: String {
        """
        Position Info:
        FEN: \(fen)
        Current Player: \(currentPlayer)
        Game State: \(gameState)
        Move Count: \(moveCount)
        Is Check: \(isCheck)
        Is Checkmate: \(isCheckmate)
        Is Stalemate: \(isStalemate)
        """
    }
}

// MARK: - GameError

/// 游戏错误
public enum GameError: Error, CustomStringConvertible, Equatable {
    case gameAlreadyEnded
    case notYourTurn
    case invalidMove
    case noPieceAtSource
    case wouldLeaveKingInCheck

    public var description: String {
        switch self {
        case .gameAlreadyEnded: return "游戏已结束"
        case .notYourTurn: return "现在不是轮到你走棋"
        case .invalidMove: return "无效的移动"
        case .noPieceAtSource: return "起始位置没有棋子"
        case .wouldLeaveKingInCheck: return "会导致己方被将军"
        }
    }
}

// MARK: - UCI Extension

extension GameController {
    /// 生成UCI协议的position命令
    /// - Returns: UCI position命令字符串
    public func generateUCIPositionCommand() -> String {
        let fen = exportToFEN()
        let moves = moveHistory.allMoves.map { $0.uciNotation }

        if moves.isEmpty {
            return "position fen \(fen)"
        } else {
            return "position fen \(fen) moves \(moves.joined(separator: " "))"
        }
    }

    /// 从UCI移动格式执行走棋
    /// - Parameter uciMove: UCI格式的移动字符串 (如 "e2e4")
    /// - Returns: 是否成功
    @discardableResult
    public func makeMoveFromUCI(_ uciMove: String) -> Bool {
        // UCI格式: 起始位置代数记谱 + 目标位置代数记谱
        // 例如: e2e4, a7a8q (兵升变，中国象棋通常不用)

        guard uciMove.count >= 4 else { return false }

        let fromStr = String(uciMove.prefix(2))
        let toStr = String(uciMove.dropFirst(2).prefix(2))

        guard let from = Position.from(string: fromStr),
              let to = Position.from(string: toStr) else {
            return false
        }

        let result = makeMove(from: from, to: to)
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
