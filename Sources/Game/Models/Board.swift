import Foundation

// MARK: - Board

/// 中国象棋棋盘
/// 9列×10行的网格，存储棋子位置和当前游戏状态
public struct Board: Codable, Equatable, Sendable, CustomStringConvertible {
    public static let width = 9
    public static let height = 10

    /// 棋子存储 (10行 x 9列)
    private var pieces: [[Piece?]]

    /// 当前行棋方
    public private(set) var currentPlayer: Player

    /// 总步数
    public private(set) var moveCount: Int

    /// 半回合计数 (用于50步规则)
    public private(set) var halfMoveClock: Int

    // MARK: - Initialization

    /// 创建空棋盘
    public init() {
        self.pieces = Array(repeating: Array(repeating: nil, count: Board.width), count: Board.height)
        self.currentPlayer = .red
        self.moveCount = 0
        self.halfMoveClock = 0
    }

    /// 使用给定的棋子数组创建棋盘
    public init(pieces: [[Piece?]], currentPlayer: Player = .red, moveCount: Int = 0, halfMoveClock: Int = 0) {
        self.pieces = pieces
        self.currentPlayer = currentPlayer
        self.moveCount = moveCount
        self.halfMoveClock = halfMoveClock
    }

    /// 创建空棋盘 (类方法)
    public static func empty() -> Board {
        Board()
    }

    /// 创建初始棋盘布局
    public static func initial() -> Board {
        var board = Board.empty()

        // 红方棋子 (下方, y=0-4)
        let redPieces: [(PieceType, Int, Int)] = [
            (.rook, 0, 0), (.rook, 8, 0),           // 车
            (.horse, 1, 0), (.horse, 7, 0),         // 马
            (.elephant, 2, 0), (.elephant, 6, 0),  // 相
            (.advisor, 3, 0), (.advisor, 5, 0),    // 仕
            (.king, 4, 0),                          // 帅
            (.cannon, 1, 2), (.cannon, 7, 2),       // 炮
            (.pawn, 0, 3), (.pawn, 2, 3), (.pawn, 4, 3), (.pawn, 6, 3), (.pawn, 8, 3)  // 兵
        ]

        // 黑方棋子 (上方, y=5-9)
        let blackPieces: [(PieceType, Int, Int)] = [
            (.rook, 0, 9), (.rook, 8, 9),           // 车
            (.horse, 1, 9), (.horse, 7, 9),         // 马
            (.elephant, 2, 9), (.elephant, 6, 9),   // 象
            (.advisor, 3, 9), (.advisor, 5, 9),     // 士
            (.king, 4, 9),                          // 将
            (.cannon, 1, 7), (.cannon, 7, 7),       // 砲
            (.pawn, 0, 6), (.pawn, 2, 6), (.pawn, 4, 6), (.pawn, 6, 6), (.pawn, 8, 6)   // 卒
        ]

        for (type, x, y) in redPieces {
            board.placePiece(Piece(type: type, player: .red), at: Position(x: x, y: y))
        }

        for (type, x, y) in blackPieces {
            board.placePiece(Piece(type: type, player: .black), at: Position(x: x, y: y))
        }

        return board
    }

    // MARK: - Accessors

    /// 获取指定位置的棋子
    public func piece(at position: Position) -> Piece? {
        guard isValidPosition(position) else { return nil }
        return pieces[position.y][position.x]
    }

    /// 获取指定坐标的棋子
    public func piece(atX x: Int, y: Int) -> Piece? {
        piece(at: Position(x: x, y: y))
    }

    /// 检查位置是否在有效范围内
    public func isValidPosition(_ position: Position) -> Bool {
        position.x >= 0 && position.x < Board.width &&
        position.y >= 0 && position.y < Board.height
    }

    /// 获取某方所有棋子的位置
    public func pieces(for player: Player) -> [(position: Position, piece: Piece)] {
        var result: [(Position, Piece)] = []
        for y in 0..<Board.height {
            for x in 0..<Board.width {
                if let piece = pieces[y][x], piece.player == player {
                    result.append((Position(x: x, y: y), piece))
                }
            }
        }
        return result
    }

    /// 查找某方指定类型的棋子位置
    public func findPiece(type: PieceType, for player: Player) -> [Position] {
        pieces(for: player)
            .filter { $0.piece.type == type }
            .map { $0.position }
    }

    /// 查找将帅位置
    public func findKing(for player: Player) -> Position? {
        findPiece(type: .king, for: player).first
    }

    // MARK: - Mutations

    /// 在指定位置放置棋子
    public mutating func placePiece(_ piece: Piece?, at position: Position) {
        guard isValidPosition(position) else { return }
        pieces[position.y][position.x] = piece
    }

    /// 移动棋子
    public mutating func movePiece(from: Position, to: Position) {
        guard isValidPosition(from), isValidPosition(to) else { return }
        pieces[to.y][to.x] = pieces[from.y][from.x]
        pieces[from.y][from.x] = nil
    }

    /// 移除棋子
    @discardableResult
    public mutating func removePiece(at position: Position) -> Piece? {
        guard isValidPosition(position) else { return nil }
        let piece = pieces[position.y][position.x]
        pieces[position.y][position.x] = nil
        return piece
    }

    /// 交换行棋方
    public mutating func switchTurn() {
        currentPlayer = currentPlayer.opponent
        moveCount += 1
    }

    /// 增加半回合计数 (用于50步规则)
    public mutating func incrementHalfMoveClock() {
        halfMoveClock += 1
    }

    /// 重置半回合计数 (有吃子或兵移动时)
    public mutating func resetHalfMoveClock() {
        halfMoveClock = 0
    }

    /// 清空棋盘
    public mutating func clear() {
        pieces = Array(repeating: Array(repeating: nil, count: Board.width), count: Board.height)
        currentPlayer = .red
        moveCount = 0
        halfMoveClock = 0
    }

    // MARK: - Board Copy

    /// 创建棋盘的深拷贝
    public func copy() -> Board {
        Board(
            pieces: pieces,
            currentPlayer: currentPlayer,
            moveCount: moveCount,
            halfMoveClock: halfMoveClock
        )
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        var result = "  a b c d e f g h i\n"
        for row in (0..<Board.height).reversed() {
            result += "\(row) "
            for col in 0..<Board.width {
                if let piece = pieces[row][col] {
                    result += piece.character
                } else {
                    result += "."
                }
                result += " "
            }
            result += "\(row)\n"
        }
        result += "  a b c d e f g h i"
        return result
    }

    /// 文本格式的棋盘表示 (带行号)
    public var asciiDiagram: String {
        var lines: [String] = []
        lines.append("  九 八 七 六 五 四 三 二 一")

        let rowLabels = ["", "１", "２", "３", "４", "５", "６", "７", "８", "９", "１０"]

        for y in (0..<Board.height).reversed() {
            var line = rowLabels[y + 1] + " "
            for x in (0..<Board.width).reversed() {
                if let piece = pieces[y][x] {
                    line += piece.character
                } else {
                    line += "　"
                }
                line += " "
            }
            lines.append(line)
        }

        lines.append("  九 八 七 六 五 四 三 二 一")
        return lines.joined(separator: "\n")
    }
}
