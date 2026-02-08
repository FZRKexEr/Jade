import Foundation

// MARK: - WXFParser

/// 王前易位记谱法 (WXF) 解析器和生成器
/// 支持中国象棋的中文数字坐标记谱法
/// 格式示例: 炮二平五, 马八进七, 车9进1
public struct WXFParser {

    // MARK: - Constants

    /// 红方数字 (从右到左)
    public static let redFiles = ["一", "二", "三", "四", "五", "六", "七", "八", "九"]

    /// 黑方数字 (从左到右)
    public static let blackFiles = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

    /// 棋子名称 (红方)
    public static let redPieces = [
        PieceType.king: "帅",
        PieceType.advisor: "仕",
        PieceType.elephant: "相",
        PieceType.horse: "马",
        PieceType.rook: "车",
        PieceType.cannon: "炮",
        PieceType.pawn: "兵"
    ]

    /// 棋子名称 (黑方)
    public static let blackPieces = [
        PieceType.king: "将",
        PieceType.advisor: "士",
        PieceType.elephant: "象",
        PieceType.horse: "马",
        PieceType.rook: "车",
        PieceType.cannon: "砲",
        PieceType.pawn: "卒"
    ]

    /// 动作字符
    public static let actions = [
        "平", // 平移
        "进", // 前进
        "退"  // 后退
    ]

    // MARK: - Parse Errors

    public enum ParseError: Error, CustomStringConvertible {
        case invalidFormat(String)
        case invalidPiece(String)
        case invalidFile(String)
        case invalidAction(String)
        case invalidPosition(String)
        case invalidMove(String)

        public var description: String {
            switch self {
            case .invalidFormat(let msg):
                return "格式错误: \(msg)"
            case .invalidPiece(let msg):
                return "棋子错误: \(msg)"
            case .invalidFile(let msg):
                return "纵线错误: \(msg)"
            case .invalidAction(let msg):
                return "动作错误: \(msg)"
            case .invalidPosition(let msg):
                return "位置错误: \(msg)"
            case .invalidMove(let msg):
                return "走法错误: \(msg)"
            }
        }
    }

    // MARK: - Parsing

    /// 解析单个 WX F记谱
    /// - Parameters:
    ///   - notation: 记谱字符串 (如 "炮二平五")
    ///   - board: 当前棋盘状态
    /// - Returns: 解析出的 Move
    public static func parse(
        notation: String,
        board: Board
    ) throws -> (from: Position, to: Position) {

        let trimmed = notation.trimmingCharacters(in: .whitespaces)

        // 解析基本格式: [棋子][纵线][动作][目标]
        guard trimmed.count >= 3 && trimmed.count <= 5 else {
            throw ParseError.invalidFormat("记谱长度应在3-5个字符之间: \(trimmed)")
        }

        // 提取各部分
        var chars = Array(trimmed)
        let pieceChar = String(chars[0])

        // 判断是红方还是黑方走棋（根据当前轮次）
        let isRedTurn = board.currentPlayer == .red

        // 解析棋子类型
        let pieceType = try parsePiece(pieceChar, isRed: isRedTurn)

        // 解析纵线（第2个字符）
        let fileChar = String(chars[1])
        let fromFile = try parseFile(fileChar, isRed: isRedTurn)

        // 解析动作（第3个字符）
        let actionChar = String(chars[2])
        let action = try parseAction(actionChar)

        // 解析目标（第4个字符，可能省略）
        let targetChar = chars.count > 3 ? String(chars[3]) : nil

        // 根据动作和棋子类型计算目标位置
        let (from, to) = try calculateMove(
            pieceType: pieceType,
            fromFile: fromFile,
            action: action,
            targetChar: targetChar,
            isRed: isRedTurn,
            board: board
        )

        return (from, to)
    }

    /// 解析棋子字符
    private static func parsePiece(_ char: String, isRed: Bool) throws -> PieceType {
        let pieces = isRed ? redPieces : blackPieces

        for (type, name) in pieces {
            if name == char {
                return type
            }
        }

        // 尝试反向查找（黑方棋子名称用于红方情况）
        let otherPieces = isRed ? blackPieces : redPieces
        for (type, name) in otherPieces {
            if name == char {
                return type
            }
        }

        throw ParseError.invalidPiece("无法识别棋子: \(char)")
    }

    /// 解析纵线
    private static func parseFile(_ char: String, isRed: Bool) throws -> Int {
        let files = isRed ? redFiles : blackFiles

        for (index, file) in files.enumerated() {
            if file == char {
                return index
            }
        }

        // 尝试解析为数字
        if let num = Int(char), num >= 1 && num <= 9 {
            return isRed ? 9 - num : num - 1
        }

        throw ParseError.invalidFile("无法识别纵线: \(char)")
    }

    /// 解析动作
    private static func parseAction(_ char: String) throws -> MoveAction {
        switch char {
        case "平":
            return .level
        case "进":
            return .forward
        case "退":
            return .backward
        default:
            throw ParseError.invalidAction("无法识别动作: \(char)")
        }
    }

    /// 计算走法
    private static func calculateMove(
        pieceType: PieceType,
        fromFile: Int,
        action: MoveAction,
        targetChar: String?,
        isRed: Bool,
        board: Board
    ) throws -> (from: Position, to: Position) {

        // 找到该纵线上该类型的棋子
        let candidates = findPieces(
            type: pieceType,
            file: fromFile,
            isRed: isRed,
            board: board
        )

        guard !candidates.isEmpty else {
            throw ParseError.invalidPosition("在纵线\(fromFile + 1)上找不到\(pieceType)")
        }

        // 对于多个候选棋子的情况，需要根据目标位置进一步判断
        // 这里简化处理，选择第一个
        let from = candidates[0]

        // 计算目标位置
        let to: Position

        switch action {
        case .level:
            // 平移：水平移动到目标纵线
            guard let targetFile = targetChar.flatMap({
                try? parseFile($0, isRed: isRed)
            }) else {
                throw ParseError.invalidMove("平移需要指定目标纵线")
            }
            to = Position(x: targetFile, y: from.y)

        case .forward:
            // 前进
            let steps: Int
            if let target = targetChar {
                steps = try parseSteps(target)
            } else {
                steps = 1
            }
            to = Position(
                x: from.x,
                y: isRed ? from.y + steps : from.y - steps
            )

        case .backward:
            // 后退
            let steps: Int
            if let target = targetChar {
                steps = try parseSteps(target)
            } else {
                steps = 1
            }
            to = Position(
                x: from.x,
                y: isRed ? from.y - steps : from.y + steps
            )
        }

        guard to.isValid else {
            throw ParseError.invalidPosition("目标位置无效: \(to)")
        }

        return (from, to)
    }

    /// 查找指定类型的棋子在指定纵线上的位置
    private static func findPieces(
        type: PieceType,
        file: Int,
        isRed: Bool,
        board: Board
    ) -> [Position] {
        var positions: [Position] = []

        for y in 0..<Board.height {
            if let piece = board.piece(atX: file, y: y),
               piece.type == type,
               piece.player == (isRed ? .red : .black) {
                positions.append(Position(x: file, y: y))
            }
        }

        return positions
    }

    /// 解析步数
    private static func parseSteps(_ char: String) throws -> Int {
        if let num = Int(char) {
            return num
        }

        // 中文数字
        let chineseNumbers = [
            "一": 1, "二": 2, "三": 3, "四": 4, "五": 5,
            "六": 6, "七": 7, "八": 8, "九": 9, "十": 10
        ]

        if let num = chineseNumbers[char] {
            return num
        }

        throw ParseError.invalidMove("无法解析步数: \(char)")
    }

    // MARK: - Generation

    /// 将走法转换为 WXF 记谱
    public static func generate(
        move: Move,
        board: Board
    ) -> String {
        let piece = move.piece
        let isRed = piece.player == .red
        let pieceName = pieceNameFor(piece)

        // 计算纵线（从右往左数）
        let file = isRed ? move.from.x : 8 - move.from.x
        let fileString = isRed ? redFiles[file] : blackFiles[file]

        // 判断动作类型
        let action: String
        let target: String

        if move.from.x == move.to.x {
            // 竖直移动
            let distance = abs(move.to.y - move.from.y)
            let direction = isRed
                ? (move.to.y > move.from.y ? "进" : "退")
                : (move.to.y < move.from.y ? "进" : "退")
            action = direction
            target = isRed ? redFiles[distance - 1] : blackFiles[distance - 1]
        } else if move.from.y == move.to.y {
            // 水平移动（平）
            action = "平"
            let targetFile = isRed ? move.to.x : 8 - move.to.x
            target = isRed ? redFiles[targetFile] : blackFiles[targetFile]
        } else {
            // 斜线移动（马、象）
            let distance = max(abs(move.to.x - move.from.x), abs(move.to.y - move.from.y))
            let direction = isRed
                ? (move.to.y > move.from.y ? "进" : "退")
                : (move.to.y < move.from.y ? "进" : "退")
            action = direction
            target = isRed ? redFiles[distance - 1] : blackFiles[distance - 1]
        }

        return "\(pieceName)\(fileString)\(action)\(target)"
    }

    /// 获取棋子名称
    private static func pieceNameFor(_ piece: Piece) -> String {
        let names = piece.player == .red ? redPieces : blackPieces
        return names[piece.type] ?? "?"
    }

    /// 批量解析 WXF 记谱序列
    public static func parseSequence(
        notations: [String],
        board: Board
    ) -> [(notation: String, from: Position, to: Position)] {
        var results: [(notation: String, from: Position, to: Position)] = []
        var mutableBoard = board

        for notation in notations {
            do {
                let (from, to) = try parse(notation: notation, board: mutableBoard)
                results.append((notation, from, to))

                // 模拟走棋更新棋盘状态
                mutableBoard.movePiece(from: from, to: to)
                mutableBoard.switchTurn()
            } catch {
                print("解析失败: \(notation) - \(error)")
            }
        }

        return results
    }
}

// MARK: - MoveAction

/// 移动动作类型
public enum MoveAction {
    /// 平移（水平移动）
    case level

    /// 前进
    case forward

    /// 后退
    case backward
}