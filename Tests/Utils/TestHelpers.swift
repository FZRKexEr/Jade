import Foundation
import Testing
@testable import ChineseChessKit

// MARK: - Test Helpers

/// Helper functions for testing
public enum TestHelpers {

    // MARK: - Board Helpers

    /// Creates an empty board for testing
    public static func emptyBoard() -> Board {
        Board.empty()
    }

    /// Creates an initial board for testing
    public static func initialBoard() -> Board {
        Board.initial()
    }

    /// Sets up a board with specific pieces
    public static func boardWithPieces(_ pieces: [(type: PieceType, player: Player, x: Int, y: Int)]) -> Board {
        var board = Board.empty()
        for piece in pieces {
            board.placePiece(
                Piece(type: piece.type, player: piece.player),
                at: Position(x: piece.x, y: piece.y)
            )
        }
        return board
    }

    // MARK: - Position Helpers

    /// Creates a position from coordinates
    public static func pos(_ x: Int, _ y: Int) -> Position {
        Position(x: x, y: y)
    }

    /// Creates a position from algebraic notation
    public static func pos(_ notation: String) -> Position? {
        Position.from(string: notation)
    }

    // MARK: - Piece Helpers

    /// Creates a red piece
    public static func redPiece(_ type: PieceType) -> Piece {
        Piece(type: type, player: .red)
    }

    /// Creates a black piece
    public static func blackPiece(_ type: PieceType) -> Piece {
        Piece(type: type, player: .black)
    }

    // MARK: - Move Helpers

    /// Creates a move
    public static func move(from: Position, to: Position, piece: Piece) -> Move {
        Move(from: from, to: to, piece: piece)
    }

    /// Creates a move with capture
    public static func capture(from: Position, to: Position, piece: Piece, captured: Piece) -> Move {
        Move(from: from, to: to, piece: piece, capturedPiece: captured)
    }

    // MARK: - Validation Helpers

    /// Asserts that a move is legal
    public static func assertMoveIsLegal(
        piece: Piece,
        from: Position,
        to: Position,
        on board: Board,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let isLegal = MovementRules.isMoveLegal(piece: piece, from: from, to: to, on: board)
        #expect(isLegal, "Expected move from \(from) to \(to) to be legal", sourceLocation: sourceLocation)
    }

    /// Asserts that a move is illegal
    public static func assertMoveIsIllegal(
        piece: Piece,
        from: Position,
        to: Position,
        on board: Board,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let isLegal = MovementRules.isMoveLegal(piece: piece, from: from, to: to, on: board)
        #expect(!isLegal, "Expected move from \(from) to \(to) to be illegal", sourceLocation: sourceLocation)
    }

    // MARK: - Board Comparison Helpers

    /// Asserts that two boards are equal
    public static func assertBoardsEqual(_ board1: Board, _ board2: Board, sourceLocation: SourceLocation = #_sourceLocation) {
        for x in 0..<9 {
            for y in 0..<10 {
                let pos = Position(x: x, y: y)
                let piece1 = board1.piece(at: pos)
                let piece2 = board2.piece(at: pos)
                #expect(piece1 == piece2, "Pieces differ at position \(pos)", sourceLocation: sourceLocation)
            }
        }
    }

    /// Asserts that a board matches expected pieces
    public static func assertBoardMatches(
        _ board: Board,
        expectedPieces: [(type: PieceType, player: Player, x: Int, y: Int)],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for expected in expectedPieces {
            let pos = Position(x: expected.x, y: expected.y)
            let actualPiece = board.piece(at: pos)

            #expect(actualPiece?.type == expected.type,
                    "Expected \(expected.player) \(expected.type) at \(pos), got \(String(describing: actualPiece?.type))",
                    sourceLocation: sourceLocation)
            #expect(actualPiece?.player == expected.player,
                    "Expected \(expected.player) at \(pos), got \(String(describing: actualPiece?.player))",
                    sourceLocation: sourceLocation)
        }
    }

    // MARK: - Performance Helpers

    /// Measures the execution time of an operation
    public static func measureExecutionTime(
        iterations: Int = 100,
        operation: () -> Void
    ) -> TimeInterval {
        let start = Date()
        for _ in 0..<iterations {
            operation()
        }
        return Date().timeIntervalSince(start)
    }

    /// Asserts that an operation completes within a time limit
    public static func assertPerformance(
        maxTime: TimeInterval,
        iterations: Int = 100,
        operation: () -> Void,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let time = measureExecutionTime(iterations: iterations, operation: operation)
        #expect(time < maxTime, "Operation took \(time)s, expected less than \(maxTime)s", sourceLocation: sourceLocation)
    }
}

// MARK: - Custom Expectations

extension TestHelpers {

    /// Expects that a piece can move to all specified positions
    public static func expectPieceCanMoveTo(
        piece: Piece,
        from: Position,
        to positions: [Position],
        on board: Board,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for to in positions {
            let isLegal = MovementRules.isMoveLegal(piece: piece, from: from, to: to, on: board)
            #expect(isLegal, "Expected \(piece.type) to move from \(from) to \(to)", sourceLocation: sourceLocation)
        }
    }

    /// Expects that a piece cannot move to any of the specified positions
    public static func expectPieceCannotMoveTo(
        piece: Piece,
        from: Position,
        to positions: [Position],
        on board: Board,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for to in positions {
            let isLegal = MovementRules.isMoveLegal(piece: piece, from: from, to: to, on: board)
            #expect(!isLegal, "Expected \(piece.type) NOT to move from \(from) to \(to)", sourceLocation: sourceLocation)
        }
    }
}
