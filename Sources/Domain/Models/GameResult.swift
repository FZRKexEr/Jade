import Foundation

/// 游戏结果
enum GameResult: Equatable {
    case win(Player, WinReason)
    case draw(DrawReason)
    case ongoing
}

enum WinReason: String {
    case checkmate = "将杀"
    case timeout = "超时"
    case resignation = "认输"
    case illegalMove = "违规"
}

enum DrawReason: String {
    case stalemate = "逼和"
    case fiftyMoveRule = "50步规则"
    case threefoldRepetition = "三次重复"
    case insufficientMaterial = "子力不足"
    case agreement = "协议和棋"
}

/// 游戏错误
enum GameError: Error {
    case gameAlreadyEnded
    case wrongTurn
    case invalidMove
    case noMovesToUndo
    case noMovesToRedo
    case invalidFEN
}
