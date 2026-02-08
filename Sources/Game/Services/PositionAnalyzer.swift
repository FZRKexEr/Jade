import Foundation

// MARK: - PositionAnalyzer

/// 局面分析器
/// 负责分析当前局面状态，包括将军检测、将死检测、合法移动生成等
public struct PositionAnalyzer: Sendable {

    /// 移动验证结果
    public struct MoveValidationResult: Equatable, Sendable {
        public let isValid: Bool
        public let reason: InvalidMoveReason?

        public init(isValid: Bool, reason: InvalidMoveReason? = nil) {
            self.isValid = isValid
            self.reason = reason
        }

        public static let valid = MoveValidationResult(isValid: true)
    }

    /// 非法移动原因
    public enum InvalidMoveReason: Equatable, Sendable, CustomStringConvertible {
        case invalidPosition           // 位置无效
        case noPieceAtSource         // 起始位置没有棋子
        case wrongPieceColor         // 移动了对方的棋子
        case pieceCannotMoveToTarget // 棋子不能移动到目标位置
        case blockedByPiece          // 被其他棋子阻挡
        case wouldLeaveKingInCheck   // 会导致自己被将军
        case notYourTurn             // 不是轮到你走棋
        case gameAlreadyEnded        // 游戏已结束

        public var description: String {
            switch self {
            case .invalidPosition: return "位置无效"
            case .noPieceAtSource: return "起始位置没有棋子"
            case .wrongPieceColor: return "不能移动对方的棋子"
            case .pieceCannotMoveToTarget: return "棋子不能移动到该位置"
            case .blockedByPiece: return "被其他棋子阻挡"
            case .wouldLeaveKingInCheck: return "会导致己方被将军"
            case .notYourTurn: return "现在不是轮到你走棋"
            case .gameAlreadyEnded: return "游戏已经结束"
            }
        }
    }

    /// 合法移动信息
    public struct LegalMove: Equatable, Sendable {
        public let from: Position
        public let to: Position
        public let piece: Piece
        public let capturedPiece: Piece?
        public let isCheck: Bool
        public let isCheckmate: Bool
        public let isCapture: Bool

        public init(
            from: Position,
            to: Position,
            piece: Piece,
            capturedPiece: Piece? = nil,
            isCheck: Bool = false,
            isCheckmate: Bool = false,
            isCapture: Bool = false
        ) {
            self.from = from
            self.to = to
            self.piece = piece
            self.capturedPiece = capturedPiece
            self.isCheck = isCheck
            self.isCheckmate = isCheckmate
            self.isCapture = isCapture
        }
    }

    // MARK: - Public Methods

    /// 检查是否被将军
    /// - Parameters:
    ///   - player: 要检查的阵营
    ///   - board: 棋盘状态
    /// - Returns: 是否被将军
    public static func isInCheck(player: Player, on board: Board) -> Bool {
        MovementRules.isKingInCheck(for: player, on: board)
    }

    /// 检查是否被将死
    /// - Parameters:
    ///   - player: 要检查的阵营
    ///   - board: 棋盘状态
    /// - Returns: 是否被将死
    public static func isCheckmate(player: Player, on board: Board) -> Bool {
        MovementRules.isCheckmate(for: player, on: board)
    }

    /// 检查是否被困毙
    /// - Parameters:
    ///   - player: 要检查的阵营
    ///   - board: 棋盘状态
    /// - Returns: 是否被困毙
    public static func isStalemate(player: Player, on board: Board) -> Bool {
        MovementRules.isStalemate(for: player, on: board)
    }

    /// 检查将帅是否照面
    /// - Parameter board: 棋盘状态
    /// - Returns: 是否照面
    public static func areKingsFacing(on board: Board) -> Bool {
        MovementRules.areKingsFacing(on: board)
    }

    /// 验证移动是否合法
    /// - Parameters:
    ///   - from: 起始位置
    ///   - to: 目标位置
    ///   - board: 棋盘状态
    ///   - validateTurn: 是否验证轮到谁走棋
    /// - Returns: 验证结果
    public static func validateMove(
        from: Position,
        to: Position,
        on board: Board,
        validateTurn: Bool = true
    ) -> MoveValidationResult {
        // 1. 检查位置有效性
        guard board.isValidPosition(from), board.isValidPosition(to) else {
            return MoveValidationResult(isValid: false, reason: .invalidPosition)
        }

        // 2. 检查起始位置是否有棋子
        guard let piece = board.piece(at: from) else {
            return MoveValidationResult(isValid: false, reason: .noPieceAtSource)
        }

        // 3. 检查是否轮到该方走棋
        if validateTurn && piece.player != board.currentPlayer {
            return MoveValidationResult(isValid: false, reason: .notYourTurn)
        }

        // 4. 检查目标位置是否是己方棋子
        if let targetPiece = board.piece(at: to), targetPiece.player == piece.player {
            return MoveValidationResult(isValid: false, reason: .pieceCannotMoveToTarget)
        }

        // 5. 检查棋子移动规则
        guard MovementRules.isMoveLegal(piece: piece, from: from, to: to, on: board) else {
            return MoveValidationResult(isValid: false, reason: .pieceCannotMoveToTarget)
        }

        // 6. 检查移动后是否会导致自己被将军
        if MovementRules.wouldResultInSelfCheck(from: from, to: to, on: board) {
            return MoveValidationResult(isValid: false, reason: .wouldLeaveKingInCheck)
        }

        return .valid
    }

    /// 生成某方所有合法移动
    /// - Parameters:
    ///   - player: 要生成移动的阵营
    ///   - board: 棋盘状态
    ///   - includeCheckInfo: 是否包含将军/将死信息 (会增加计算量)
    /// - Returns: 所有合法移动
    public static func generateAllLegalMoves(
        for player: Player,
        on board: Board,
        includeCheckInfo: Bool = false
    ) -> [LegalMove] {
        var legalMoves: [LegalMove] = []

        let pieces = board.pieces(for: player)

        for (position, piece) in pieces {
            let moves = MovementRules.getLegalMoves(for: piece, at: position, on: board)

            for target in moves {
                let capturedPiece = board.piece(at: target)

                var isCheck = false
                var isCheckmate = false

                if includeCheckInfo {
                    // 模拟移动后检查是否将军
                    var tempBoard = board.copy()
                    tempBoard.movePiece(from: position, to: target)
                    tempBoard.switchTurn()

                    let opponent = player.opponent
                    isCheck = MovementRules.isKingInCheck(for: opponent, on: tempBoard)
                    isCheckmate = isCheck && MovementRules.isCheckmate(for: opponent, on: tempBoard)
                }

                legalMoves.append(LegalMove(
                    from: position,
                    to: target,
                    piece: piece,
                    capturedPiece: capturedPiece,
                    isCheck: isCheck,
                    isCheckmate: isCheckmate,
                    isCapture: capturedPiece != nil
                ))
            }
        }

        return legalMoves
    }

    /// 获取指定位置棋子的所有合法移动目标
    /// - Parameters:
    ///   - position: 棋子位置
    ///   - board: 棋盘状态
    /// - Returns: 所有合法目标位置
    public static func getLegalMoves(from position: Position, on board: Board) -> [Position] {
        guard let piece = board.piece(at: position) else { return [] }
        return MovementRules.getLegalMoves(for: piece, at: position, on: board)
    }

    /// 评估局面 (简化的局面评估)
    /// - Parameter board: 棋盘状态
    /// - Returns: 评分 (正值对红方有利，负值对黑方有利)
    public static func evaluatePosition(_ board: Board) -> Int {
        // 简化实现：基于子力价值评估
        let pieceValues: [PieceType: Int] = [
            .king: 10000,
            .rook: 900,
            .horse: 400,
            .cannon: 450,
            .elephant: 200,
            .advisor: 200,
            .pawn: 100
        ]

        var score = 0

        for y in 0..<Board.height {
            for x in 0..<Board.width {
                if let piece = board.piece(at: Position(x: x, y: y)) {
                    let value = pieceValues[piece.type] ?? 0
                    if piece.player == .red {
                        score += value
                    } else {
                        score -= value
                    }
                }
            }
        }

        return score
    }
}

// MARK: - Position Extension

extension Position {
    /// 计算两个位置之间的路径位置
    fileprivate func pathPositions(to destination: Position) -> [Position] {
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
