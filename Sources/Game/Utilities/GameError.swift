import Foundation

// MARK: - GameError

/// 游戏错误类型
/// 定义游戏中可能出现的各种错误情况
public enum GameError: Error, CustomStringConvertible, Equatable, Sendable {
    // 游戏状态错误
    case gameNotStarted
    case gameAlreadyEnded
    case gameInProgress
    case invalidGameState

    // 走棋错误
    case invalidMove
    case illegalMove(reason: String)
    case moveNotFound
    case notYourTurn
    case noPieceAtSource
    case cannotCaptureOwnPiece
    case wouldLeaveKingInCheck

    // 位置错误
    case invalidPosition
    case positionOutOfBounds
    case pieceNotFound

    // FEN相关错误
    case invalidFEN
    case fenParsingError(reason: String)

    // 历史记录错误
    case noMovesToUndo
    case noMovesToRedo
    case historyCorrupted

    // 引擎通信错误
    case engineNotAvailable
    case engineError(reason: String)
    case invalidUCIMove

    // 其他错误
    case unknown
    case notImplemented
    case internalError(reason: String)

    public var description: String {
        switch self {
        case .gameNotStarted:
            return "游戏尚未开始"
        case .gameAlreadyEnded:
            return "游戏已结束"
        case .gameInProgress:
            return "游戏正在进行中"
        case .invalidGameState:
            return "无效的游戏状态"

        case .invalidMove:
            return "无效的移动"
        case .illegalMove(let reason):
            return "非法移动: \(reason)"
        case .moveNotFound:
            return "未找到指定的移动"
        case .notYourTurn:
            return "现在不是轮到你走棋"
        case .noPieceAtSource:
            return "起始位置没有棋子"
        case .cannotCaptureOwnPiece:
            return "不能吃自己的棋子"
        case .wouldLeaveKingInCheck:
            return "会导致己方被将军"

        case .invalidPosition:
            return "无效的位置"
        case .positionOutOfBounds:
            return "位置超出棋盘范围"
        case .pieceNotFound:
            return "未找到棋子"

        case .invalidFEN:
            return "无效的FEN字符串"
        case .fenParsingError(let reason):
            return "FEN解析错误: \(reason)"

        case .noMovesToUndo:
            return "没有可以悔棋的步数"
        case .noMovesToRedo:
            return "没有可以重做的步数"
        case .historyCorrupted:
            return "历史记录已损坏"

        case .engineNotAvailable:
            return "引擎不可用"
        case .engineError(let reason):
            return "引擎错误: \(reason)"
        case .invalidUCIMove:
            return "无效的UCI移动格式"

        case .unknown:
            return "未知错误"
        case .notImplemented:
            return "功能尚未实现"
        case .internalError(let reason):
            return "内部错误: \(reason)"
        }
    }

    /// 是否是致命错误
    public var isFatal: Bool {
        switch self {
        case .gameAlreadyEnded,
             .historyCorrupted,
             .internalError:
            return true
        default:
            return false
        }
    }

    /// 是否是用户可恢复的错误
    public var isRecoverable: Bool {
        switch self {
        case .invalidMove,
             .notYourTurn,
             .wouldLeaveKingInCheck,
             .invalidPosition:
            return true
        default:
            return false
        }
    }
}

// MARK: - GameError Extensions

extension GameError {
    /// 从NSError创建GameError
    public init?(from error: Error) {
        // 尝试转换常见的NSError
        let nsError = error as NSError

        switch nsError.domain {
        case "GameController":
            // 假设有特定的错误码映射
            self = .internalError(reason: nsError.localizedDescription)
        default:
            // 无法识别的错误
            return nil
        }
    }

    /// 转换为NSError
    public var asNSError: NSError {
        NSError(
            domain: "GameController",
            code: hashValue,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}

// MARK: - Error Recovery

/// 错误恢复建议
public struct ErrorRecoverySuggestion: Sendable, CustomStringConvertible {
    public let suggestion: String
    public let action: (() -> Void)?

    public init(suggestion: String, action: (() -> Void)? = nil) {
        self.suggestion = suggestion
        self.action = action
    }

    public var description: String {
        suggestion
    }

    /// 执行恢复操作
    public func recover() {
        action?()
    }
}

extension GameError {
    /// 获取恢复建议
    public var recoverySuggestion: ErrorRecoverySuggestion? {
        switch self {
        case .invalidMove, .illegalMove:
            return ErrorRecoverySuggestion(suggestion: "请选择一个合法的移动目标")

        case .notYourTurn:
            return ErrorRecoverySuggestion(suggestion: "请等待对手走棋")

        case .wouldLeaveKingInCheck:
            return ErrorRecoverySuggestion(suggestion: "您的将/帅正被将军，请先应将")

        case .noMovesToUndo:
            return ErrorRecoverySuggestion(suggestion: "还没有走棋，无法悔棋")

        case .gameAlreadyEnded:
            return ErrorRecoverySuggestion(suggestion: "游戏已结束，可以重新开始新游戏", action: nil)

        default:
            return nil
        }
    }
}
