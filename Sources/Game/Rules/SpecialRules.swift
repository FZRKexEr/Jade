import Foundation

// MARK: - SpecialRules

/// 中国象棋特殊规则
/// 处理长将、长捉等循环检测，以及将帅照面等特殊情况
public struct SpecialRules: Sendable {

    /// 循环记录条目
    public struct RepetitionEntry: Codable, Equatable, Sendable {
        public let positionHash: String  // 局面哈希
        public let sideToMove: Player
        public let lastMove: Move?
        public let timestamp: Date

        public init(
            positionHash: String,
            sideToMove: Player,
            lastMove: Move? = nil,
            timestamp: Date = Date()
        ) {
            self.positionHash = positionHash
            self.sideToMove = sideToMove
            self.lastMove = lastMove
            self.timestamp = timestamp
        }
    }

    /// 循环类型
    public enum RepetitionType: Equatable, Sendable, CustomStringConvertible {
        case none
        case draw              // 三次重复，和棋
        case perpetualCheck    // 长将，违规方判负
        case perpetualChase     // 长捉，违规方判负

        public var description: String {
            switch self {
            case .none: return "无循环"
            case .draw: return "三次重复和棋"
            case .perpetualCheck: return "长将判负"
            case .perpetualChase: return "长捉判负"
            }
        }
    }

    /// 循环历史记录
    public final class RepetitionHistory: @unchecked Sendable {
        private var entries: [RepetitionEntry] = []
        private let lock = NSLock()

        public init() {}

        /// 添加局面记录
        public func addEntry(_ entry: RepetitionEntry) {
            lock.lock()
            defer { lock.unlock() }
            entries.append(entry)
        }

        /// 获取某局面的重复次数
        public func countRepetitions(of hash: String, for player: Player) -> Int {
            lock.lock()
            defer { lock.unlock() }
            return entries.filter { $0.positionHash == hash && $0.sideToMove == player }.count
        }

        /// 检查是否三次重复
        public func isThreefoldRepetition(of hash: String, for player: Player) -> Bool {
            countRepetitions(of: hash, for: player) >= 3
        }

        /// 清空历史
        public func clear() {
            lock.lock()
            defer { lock.unlock() }
            entries.removeAll()
        }

        /// 获取所有记录
        public var allEntries: [RepetitionEntry] {
            lock.lock()
            defer { lock.unlock() }
            return entries
        }
    }

    // MARK: - Static Methods

    /// 检查将帅是否照面 (将帅在同一列且中间无棋子)
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

    /// 检查是否长将
    /// 同一方连续将军超过一定次数判定为长将
    public static func isPerpetualCheck(
        in history: [Move],
        for player: Player,
        threshold: Int = 3
    ) -> Bool {
        // 获取最近的连续将军记录
        var consecutiveChecks = 0

        // 从后往前检查
        for move in history.reversed() {
            guard move.piece.player == player else { break }

            if move.isCheck {
                consecutiveChecks += 1
            } else {
                break
            }
        }

        return consecutiveChecks >= threshold
    }

    /// 检查是否长捉
    /// 同一方连续捉子超过一定次数判定为长捉
    public static func isPerpetualChase(
        in history: [Move],
        for player: Player,
        threshold: Int = 3
    ) -> Bool {
        var consecutiveCaptures = 0

        for move in history.reversed() {
            guard move.piece.player == player else { break }

            // 捉子指攻击对方有保护的棋子
            // 简化实现：连续吃子判定为长捉
            if move.capturedPiece != nil {
                consecutiveCaptures += 1
            } else {
                break
            }
        }

        return consecutiveCaptures >= threshold
    }

    /// 计算局面的哈希值 (用于重复检测)
    public static func hashPosition(_ board: Board) -> String {
        var hash = ""

        // 1. 棋子位置
        for y in 0..<Board.height {
            for x in 0..<Board.width {
                if let piece = board.piece(at: Position(x: x, y: y)) {
                    hash += "\(x)\(y)\(piece.fenCharacter)"
                }
            }
        }

        // 2. 轮到谁走
        hash += "_\(board.currentPlayer.fenCharacter)"

        return hash
    }

    /// 检测循环类型
    public static func detectRepetition(
        history: RepetitionHistory,
        currentBoard: Board,
        moveHistory: [Move]
    ) -> RepetitionType {
        let hash = hashPosition(currentBoard)
        let player = currentBoard.currentPlayer

        // 检查是否三次重复
        guard history.isThreefoldRepetition(of: hash, for: player) else {
            return .none
        }

        // 检查长将
        if isPerpetualCheck(in: moveHistory, for: player) {
            return .perpetualCheck
        }

        // 检查长捉
        if isPerpetualChase(in: moveHistory, for: player) {
            return .perpetualChase
        }

        // 单纯的三次重复
        return .draw
    }
}
