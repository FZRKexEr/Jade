import Foundation

// MARK: - GameState

/// 游戏状态枚举
/// 表示当前对局的状态：进行中、将军、将死、困毙、和棋等
public enum GameState: Equatable, Sendable, CustomStringConvertible {
    /// 游戏进行中，轮到某方走棋
    case ongoing(currentPlayer: Player)

    /// 将军状态 (某方的将帅正在被攻击)
    case check(attacker: Player, kingPosition: Position)

    /// 将死 (被将军方无法应将)
    case checkmate(winner: Player)

    /// 困毙 (某方无合法移动但未处于将军状态)
    case stalemate(stalematedPlayer: Player)

    /// 和棋
    case draw(reason: DrawReason)

    /// 游戏结束 (某方获胜)
    case ended(winner: Player, reason: WinReason)

    public var description: String {
        switch self {
        case .ongoing(let player):
            return "轮到\(player.displayName)走棋"
        case .check(let attacker, _):
            return "\(attacker.opponent.displayName)被将军！"
        case .checkmate(let winner):
            return "\(winner.displayName)获胜（将杀）"
        case .stalemate(let player):
            return "\(player.displayName)被困毙，和棋"
        case .draw(let reason):
            return "和棋 (\(reason.description))"
        case .ended(let winner, let reason):
            return "\(winner.displayName)获胜 (\(reason.rawValue))"
        }
    }
}

// MARK: - WinReason

/// 获胜原因
public enum WinReason: String, Sendable, CustomStringConvertible {
    case checkmate = "将杀"
    case timeout = "超时"
    case resignation = "认输"
    case illegalMove = "违规"
    case engineCrash = "引擎崩溃"

    public var description: String {
        rawValue
    }
}

// MARK: - DrawReason

/// 和棋原因
public enum DrawReason: String, Sendable, CustomStringConvertible {
    case stalemate = "困毙"
    case fiftyMoveRule = "50步规则"
    case threefoldRepetition = "三次重复局面"
    case insufficientMaterial = "子力不足"
    case agreement = "协议和棋"
    case perpetualCheck = "长将"
    case perpetualChase = "长捉"

    public var description: String {
        rawValue
    }
}

// MARK: - GameResult

/// 游戏结果
/// 简化的游戏结果表示
public enum GameResult: Equatable, Sendable, CustomStringConvertible {
    case win(Player, WinReason)
    case draw(DrawReason)
    case ongoing

    public var description: String {
        switch self {
        case .win(let player, let reason):
            return "\(player.displayName)获胜 (\(reason.rawValue))"
        case .draw(let reason):
            return "和棋 (\(reason.rawValue))"
        case .ongoing:
            return "进行中"
        }
    }

    /// 是否已结束
    public var isEnded: Bool {
        if case .ongoing = self {
            return false
        }
        return true
    }

    /// 获胜方 (如果有)
    public var winner: Player? {
        if case .win(let player, _) = self {
            return player
        }
        return nil
    }
}

// MARK: - GameStateSnapshot

/// 游戏状态快照
/// 用于保存某一时刻的完整游戏状态，支持悔棋等功能
public struct GameStateSnapshot: Codable, Equatable, Sendable, CustomStringConvertible {
    public let board: Board
    public let currentPlayer: Player
    public let moveHistory: [Move]
    public let gameState: GameState
    public let halfMoveClock: Int  // 用于50步规则
    public let timestamp: Date

    public init(
        board: Board,
        currentPlayer: Player,
        moveHistory: [Move],
        gameState: GameState,
        halfMoveClock: Int = 0,
        timestamp: Date = Date()
    ) {
        self.board = board
        self.currentPlayer = currentPlayer
        self.moveHistory = moveHistory
        self.gameState = gameState
        self.halfMoveClock = halfMoveClock
        self.timestamp = timestamp
    }

    public var description: String {
        "Snapshot: \(gameState), \(moveHistory.count) moves, at \(timestamp)"
    }

    /// 导出为FEN字符串
    public func toFEN() -> String {
        board.toFEN()
    }
}
