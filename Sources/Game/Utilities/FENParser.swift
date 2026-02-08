import Foundation

// MARK: - FENParser

/// FEN (Forsyth-Edwards Notation) 解析器
/// 用于中国象棋局面记谱的解析和生成
///
/// 中国象棋FEN格式:
/// [棋子布局] [轮到谁走] [-] [-] [半回合计数] [回合数]
///
/// 例: rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1
public struct FENParser: Sendable {

    /// FEN解析错误
    public enum FENError: Error, CustomStringConvertible {
        case invalidFormat
        case invalidPieceCharacter(character: Character)
        case invalidRowCount(expected: Int, actual: Int)
        case invalidColumnCount(row: Int, expected: Int, actual: Int)
        case invalidSideToMove
        case invalidHalfMoveClock
        case invalidFullMoveNumber

        public var description: String {
            switch self {
            case .invalidFormat:
                return "FEN格式无效"
            case .invalidPieceCharacter(let char):
                return "无效的棋子字符: \(char)"
            case .invalidRowCount(let expected, let actual):
                return "行数错误，期望 \(expected)，实际 \(actual)"
            case .invalidColumnCount(let row, let expected, let actual):
                return "第 \(row) 行列数错误，期望 \(expected)，实际 \(actual)"
            case .invalidSideToMove:
                return "无效的轮到谁走"
            case .invalidHalfMoveClock:
                return "无效的半回合计数"
            case .invalidFullMoveNumber:
                return "无效的回合数"
            }
        }
    }

    /// FEN解析结果
    public struct FENResult: Sendable {
        public let board: Board
        public let currentPlayer: Player
        public let halfMoveClock: Int
        public let fullMoveNumber: Int

        public init(
            board: Board,
            currentPlayer: Player,
            halfMoveClock: Int,
            fullMoveNumber: Int
        ) {
            self.board = board
            self.currentPlayer = currentPlayer
            self.halfMoveClock = halfMoveClock
            self.fullMoveNumber = fullMoveNumber
        }
    }

    // MARK: - Public Methods

    /// 解析FEN字符串
    /// - Parameter fen: FEN字符串
    /// - Returns: 解析结果
    /// - Throws: FENError
    public static func parse(_ fen: String) throws -> FENResult {
        let parts = fen.trimmingCharacters(in: .whitespaces)
            .split(separator: " ", omittingEmptySubsequences: true)
            .map { String($0) }

        guard parts.count >= 4 else {
            throw FENError.invalidFormat
        }

        // 1. 解析棋子布局
        let board = try parsePiecePlacement(parts[0])

        // 2. 解析轮到谁走
        let currentPlayer: Player
        switch parts[1].lowercased() {
        case "w", "r", "red":
            currentPlayer = .red
        case "b", "k", "black":
            currentPlayer = .black
        default:
            throw FENError.invalidSideToMove
        }

        // 3. 解析半回合计数 (50步规则)
        let halfMoveClock: Int
        if parts.count >= 5, let value = Int(parts[4]) {
            halfMoveClock = value
        } else {
            halfMoveClock = 0
        }

        // 4. 解析回合数
        let fullMoveNumber: Int
        if parts.count >= 6, let value = Int(parts[5]) {
            fullMoveNumber = value
        } else {
            fullMoveNumber = 1
        }

        var finalBoard = board
        finalBoard = Board(
            pieces: board.pieces,
            currentPlayer: currentPlayer,
            moveCount: (fullMoveNumber - 1) * 2 + (currentPlayer == .black ? 1 : 0),
            halfMoveClock: halfMoveClock
        )

        return FENResult(
            board: finalBoard,
            currentPlayer: currentPlayer,
            halfMoveClock: halfMoveClock,
            fullMoveNumber: fullMoveNumber
        )
    }

    /// 将棋盘转换为FEN字符串
    /// - Parameters:
    ///   - board: 棋盘状态
    ///   - halfMoveClock: 半回合计数
    ///   - fullMoveNumber: 回合数
    /// - Returns: FEN字符串
    public static func toFEN(
        board: Board,
        halfMoveClock: Int = 0,
        fullMoveNumber: Int? = nil
    ) -> String {
        var fen = ""

        // 1. 棋子位置 (从第9行到第0行)
        for row in (0..<Board.height).reversed() {
            var emptyCount = 0
            for col in 0..<Board.width {
                if let piece = board.piece(at: Position(x: col, y: row)) {
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

        // 2. 轮到谁走
        fen += " \(board.currentPlayer.fenCharacter)"

        // 3. 中国象棋没有王车易位和吃过路兵，用 - 表示
        fen += " - -"

        // 4. 半回合计数
        fen += " \(halfMoveClock)"

        // 5. 回合数
        let moveNumber = fullMoveNumber ?? (board.moveCount / 2 + 1)
        fen += " \(moveNumber)"

        return fen
    }

    // MARK: - Private Methods

    /// 解析棋子布局部分
    private static func parsePiecePlacement(_ placement: String) throws -> Board {
        var pieces: [[Piece?]] = Array(
            repeating: Array(repeating: nil, count: Board.width),
            count: Board.height
        )

        let rows = placement.split(separator: "/", omittingEmptySubsequences: false)

        guard rows.count == Board.height else {
            throw FENError.invalidRowCount(expected: Board.height, actual: rows.count)
        }

        for (rowIndex, row) in rows.enumerated() {
            let y = Board.height - 1 - rowIndex  // 转换为从下到上的坐标
            var col = 0

            for char in row {
                if let emptyCount = Int(String(char)) {
                    // 数字表示连续的空格数
                    col += emptyCount
                } else {
                    // 棋子字符
                    guard col < Board.width else {
                        throw FENError.invalidColumnCount(row: rowIndex, expected: Board.width, actual: col + 1)
                    }

                    guard let piece = pieceFromFENCharacter(char) else {
                        throw FENError.invalidPieceCharacter(character: char)
                    }

                    pieces[y][col] = piece
                    col += 1
                }
            }

            guard col == Board.width else {
                throw FENError.invalidColumnCount(row: rowIndex, expected: Board.width, actual: col)
            }
        }

        var board = Board()
        for y in 0..<Board.height {
            for x in 0..<Board.width {
                if let piece = pieces[y][x] {
                    board.placePiece(piece, at: Position(x: x, y: y))
                }
            }
        }

        return board
    }

    /// 从FEN字符解析棋子
    private static func pieceFromFENCharacter(_ char: Character) -> Piece? {
        let isRed = char.isUppercase
        let type: PieceType

        switch char.lowercased() {
        case "k": type = .king
        case "a": type = .advisor
        case "b", "e": type = .elephant
        case "n", "h": type = .horse
        case "r": type = .rook
        case "c": type = .cannon
        case "p": type = .pawn
        default: return nil
        }

        return Piece(type: type, player: isRed ? .red : .black)
    }
}

// MARK: - Piece Extension for FEN

extension Piece {
    /// FEN表示字符
    /// 红方用大写字母，黑方用小写字母
    public var fenCharacter: String {
        let char: String
        switch type {
        case .king: char = "k"
        case .advisor: char = "a"
        case .elephant: char = "b"
        case .horse: char = "n"
        case .rook: char = "r"
        case .cannon: char = "c"
        case .pawn: char = "p"
        }
        return player == .red ? char.uppercased() : char
    }
}

// MARK: - Board Extension for FEN

extension Board {
    /// 从FEN字符串创建棋盘
    public static func fromFEN(_ fen: String) -> Board? {
        do {
            let result = try FENParser.parse(fen)
            return result.board
        } catch {
            return nil
        }
    }

    /// 转换为FEN字符串
    public func toFEN(halfMoveClock: Int = 0, fullMoveNumber: Int? = nil) -> String {
        FENParser.toFEN(
            board: self,
            halfMoveClock: halfMoveClock,
            fullMoveNumber: fullMoveNumber
        )
    }
}
