import Foundation
@testable import ChineseChessKit

// MARK: - Test Fixtures

/// Provides predefined board positions and game states for testing
public enum TestFixtures {

    // MARK: - Initial Position

    /// Returns a fresh initial board
    public static func initialBoard() -> Board {
        Board.initial()
    }

    // MARK: - Check Positions

    /// Rook giving check position
    /// Black rook at (4,5) checking red king at (4,0)
    public static func rookCheckPosition() -> Board {
        var board = Board.empty()
        board.placePiece(Piece(type: .king, player: .red), at: Position(x: 4, y: 0))
        board.placePiece(Piece(type: .king, player: .black), at: Position(x: 4, y: 9))
        board.placePiece(Piece(type: .rook, player: .black), at: Position(x: 4, y: 5))
        return board
    }

    /// Double rook checkmate position
    public static func doubleRookCheckmate() -> Board {
        var board = Board.empty()
        board.placePiece(Piece(type: .king, player: .red), at: Position(x: 4, y: 0))
        board.placePiece(Piece(type: .king, player: .black), at: Position(x: 4, y: 9))
        board.placePiece(Piece(type: .rook, player: .black), at: Position(x: 3, y: 0))
        board.placePiece(Piece(type: .rook, player: .black), at: Position(x: 5, y: 0))
        return board
    }

    // MARK: - Stalemate Positions

    /// Stalemate position (no legal moves but not in check)
    public static func stalematePosition() -> Board {
        var board = Board.empty()
        board.placePiece(Piece(type: .king, player: .red), at: Position(x: 4, y: 0))
        board.placePiece(Piece(type: .king, player: .black), at: Position(x: 4, y: 9))
        // Black pieces surround red king
        board.placePiece(Piece(type: .advisor, player: .black), at: Position(x: 3, y: 0))
        board.placePiece(Piece(type: .advisor, player: .black), at: Position(x: 5, y: 0))
        return board
    }

    // MARK: - Endgame Positions

    /// King and rook vs king
    public static func kingRookVsKing() -> Board {
        var board = Board.empty()
        board.placePiece(Piece(type: .king, player: .red), at: Position(x: 4, y: 0))
        board.placePiece(Piece(type: .rook, player: .red), at: Position(x: 0, y: 1))
        board.placePiece(Piece(type: .king, player: .black), at: Position(x: 4, y: 9))
        return board
    }

    // MARK: - Move Sequences

    /// Returns a sequence of moves for a typical opening
    public static func typicalOpeningMoves() -> [(from: Position, to: Position)] {
        [
            (Position(x: 1, y: 2), Position(x: 4, y: 2)), // Red cannon to center
            (Position(x: 1, y: 7), Position(x: 4, y: 7)), // Black cannon to center
            (Position(x: 4, y: 3), Position(x: 4, y: 4)), // Red pawn advances
        ]
    }

    // MARK: - FEN Strings

    /// Initial position FEN
    public static let initialFEN = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1"

    /// Empty board FEN
    public static let emptyFEN = "9/9/9/9/9/9/9/9/9/9 w - - 0 1"

    /// FEN with red to move
    public static let redToMoveFEN = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1"

    /// FEN with black to move
    public static let blackToMoveFEN = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR b - - 0 1"
}

// MARK: - Test Helpers

extension TestFixtures {

    /// Creates a board from a FEN string
    public static func boardFromFEN(_ fen: String) -> Board? {
        Board.fromFEN(fen)
    }

    /// Creates a game state snapshot from a board
    public static func snapshotFromBoard(_ board: Board) -> GameStateSnapshot {
        GameStateSnapshot(
            board: board,
            currentPlayer: board.currentPlayer,
            moveHistory: [],
            gameState: .ongoing(currentPlayer: board.currentPlayer),
            halfMoveClock: board.halfMoveClock
        )
    }

    /// Executes a sequence of moves on a board
    public static func executeMoveSequence(_ moves: [(from: Position, to: Position)], on board: inout Board) {
        for move in moves {
            board.movePiece(from: move.from, to: move.to)
            board.switchTurn()
        }
    }
}
