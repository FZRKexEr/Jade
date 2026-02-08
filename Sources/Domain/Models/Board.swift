import Foundation

/// 棋盘
struct Board: Codable, Equatable, Sendable, CustomStringConvertible {
    static let width = 9
    static let height = 10

    private var pieces: [[Piece?]]  // 10行 x 9列
    private(set) var currentPlayer: Player
    private(set) var moveCount: Int
    private(set) var halfMoveClock: Int  // 用于50步规则

    // MARK: - Initialization

    init(pieces: [[Piece?]], currentPlayer: Player = .red, moveCount: Int = 0, halfMoveClock: Int = 0) {
        self.pieces = pieces
        self.currentPlayer = currentPlayer
        self.moveCount = moveCount
        self.halfMoveClock = halfMoveClock
    }

    static func empty() -> Board {
        let emptyPieces: [[Piece?]] = Array(repeating: Array(repeating: nil, count: width), count: height)
        return Board(pieces: emptyPieces)
    }

    static func initial() -> Board {
        var board = empty()

        // 红方 (下方, y=0-4)
        let redPieces: [(PieceType, Int, Int)] = [
            (.rook, 0, 0), (.rook, 8, 0),
            (.horse, 1, 0), (.horse, 7, 0),
            (.elephant, 2, 0), (.elephant, 6, 0),
            (.advisor, 3, 0), (.advisor, 5, 0),
            (.king, 4, 0),
            (.cannon, 1, 2), (.cannon, 7, 2),
            (.pawn, 0, 3), (.pawn, 2, 3), (.pawn, 4, 3), (.pawn, 6, 3), (.pawn, 8, 3)
        ]

        // 黑方 (上方, y=5-9)
        let blackPieces: [(PieceType, Int, Int)] = [
            (.rook, 0, 9), (.rook, 8, 9),
            (.horse, 1, 9), (.horse, 7, 9),
            (.elephant, 2, 9), (.elephant, 6, 9),
            (.advisor, 3, 9), (.advisor, 5, 9),
            (.king, 4, 9),
            (.cannon, 1, 7), (.cannon, 7, 7),
            (.pawn, 0, 6), (.pawn, 2, 6), (.pawn, 4, 6), (.pawn, 6, 6), (.pawn, 8, 6)
        ]

        for (type, x, y) in redPieces {
            board.pieces[y][x] = Piece(type: type, player: .red)
        }

        for (type, x, y) in blackPieces {
            board.pieces[y][x] = Piece(type: type, player: .black)
        }

        return board
    }

    // MARK: - Accessors

    func piece(at position: Position) -> Piece? {
        guard isValidPosition(position) else { return nil }
        return pieces[position.y][position.x]
    }

    func piece(atX x: Int, y: Int) -> Piece? {
        piece(at: Position(x: x, y: y))
    }

    func isValidPosition(_ position: Position) -> Bool {
        position.x >= 0 && position.x < Board.width &&
        position.y >= 0 && position.y < Board.height
    }

    // MARK: - Mutations

    mutating func placePiece(_ piece: Piece?, at position: Position) {
        guard isValidPosition(position) else { return }
        pieces[position.y][position.x] = piece
    }

    mutating func movePiece(from: Position, to: Position) {
        guard isValidPosition(from), isValidPosition(to) else { return }
        pieces[to.y][to.x] = pieces[from.y][from.x]
        pieces[from.y][from.x] = nil
    }

    mutating func switchTurn() {
        currentPlayer = currentPlayer.opponent
        moveCount += 1
    }

    // MARK: - FEN

    func toFEN() -> String {
        var fen = ""

        // 棋子位置 (从第9行到第0行)
        for row in (0..<Board.height).reversed() {
            var emptyCount = 0
            for col in 0..<Board.width {
                if let piece = pieces[row][col] {
                    if emptyCount > 0 {
                        fen += String(emptyCount)
                        emptyCount = 0
                    }
                    fen += piece.fenCharacter
                } else {
                    emptyCount += 1
                }
            }
            if emptyCount > 0 {
                fen += String(emptyCount)
            }
            if row > 0 {
                fen += "/"
            }
        }

        // 当前行棋方
        fen += " \(currentPlayer == .red ? "w" : "b")"

        // 中国象棋没有王车易位和吃过路兵，用 - 表示
        fen += " - -"

        // 半回合计数 (用于50步规则)
        fen += " \(halfMoveClock)"

        // 回合数
        fen += " \(moveCount / 2 + 1)"

        return fen
    }

    static func fromFEN(_ fen: String) -> Board? {
        // 解析FEN字符串创建棋盘
        // 实现细节省略
        nil
    }

    // MARK: - CustomStringConvertible

    var description: String {
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
}
