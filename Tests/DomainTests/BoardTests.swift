import Testing
@testable import ChineseChessKit

/// Board Tests
/// Tests for the Board domain model
@Suite("Board Tests")
struct BoardTests {

    // MARK: - Initialization Tests

    @Test("Create empty board")
    func testEmptyBoard() {
        let board = Board.empty()

        // Check dimensions
        #expect(board.width == 9)
        #expect(board.height == 10)

        // Check all positions are empty
        for x in 0..<9 {
            for y in 0..<10 {
                #expect(board.piece(at: Position(x: x, y: y)) == nil)
            }
        }
    }

    @Test("Create initial board")
    func testInitialBoard() {
        let board = Board.initial()

        // Check current player is red
        #expect(board.currentPlayer == .red)

        // Check move count is 0
        #expect(board.moveCount == 0)

        // Check half move clock is 0
        #expect(board.halfMoveClock == 0)

        // Verify red pieces (bottom row)
        #expect(board.piece(at: Position(x: 0, y: 0))?.type == .rook)
        #expect(board.piece(at: Position(x: 0, y: 0))?.player == .red)
        #expect(board.piece(at: Position(x: 1, y: 0))?.type == .horse)
        #expect(board.piece(at: Position(x: 2, y: 0))?.type == .elephant)
        #expect(board.piece(at: Position(x: 3, y: 0))?.type == .advisor)
        #expect(board.piece(at: Position(x: 4, y: 0))?.type == .king)
        #expect(board.piece(at: Position(x: 5, y: 0))?.type == .advisor)
        #expect(board.piece(at: Position(x: 6, y: 0))?.type == .elephant)
        #expect(board.piece(at: Position(x: 7, y: 0))?.type == .horse)
        #expect(board.piece(at: Position(x: 8, y: 0))?.type == .rook)

        // Verify black pieces (top row)
        #expect(board.piece(at: Position(x: 0, y: 9))?.type == .rook)
        #expect(board.piece(at: Position(x: 0, y: 9))?.player == .black)
        #expect(board.piece(at: Position(x: 4, y: 9))?.type == .king)
        #expect(board.piece(at: Position(x: 4, y: 9))?.player == .black)
    }

    // MARK: - Piece Placement Tests

    @Test("Place piece on board")
    func testPlacePiece() {
        var board = Board.empty()
        let piece = Piece(type: .king, player: .red)
        let position = Position(x: 4, y: 0)

        board.placePiece(piece, at: position)

        #expect(board.piece(at: position) == piece)
    }

    @Test("Remove piece from board")
    func testRemovePiece() {
        var board = Board.initial()
        let position = Position(x: 4, y: 0)

        // Verify piece exists
        #expect(board.piece(at: position) != nil)

        // Remove piece
        board.placePiece(nil, at: position)

        // Verify piece is removed
        #expect(board.piece(at: position) == nil)
    }

    @Test("Place piece outside bounds does nothing")
    func testPlacePieceOutOfBounds() {
        var board = Board.empty()
        let piece = Piece(type: .king, player: .red)

        // Try to place at invalid positions
        board.placePiece(piece, at: Position(x: -1, y: 0))
        board.placePiece(piece, at: Position(x: 0, y: -1))
        board.placePiece(piece, at: Position(x: 9, y: 0))
        board.placePiece(piece, at: Position(x: 0, y: 10))

        // Verify board is still empty
        for x in 0..<9 {
            for y in 0..<10 {
                #expect(board.piece(at: Position(x: x, y: y)) == nil)
            }
        }
    }

    // MARK: - Move Piece Tests

    @Test("Move piece on board")
    func testMovePiece() {
        var board = Board.initial()
        let from = Position(x: 0, y: 0)
        let to = Position(x: 0, y: 1)

        let piece = board.piece(at: from)
        #expect(piece != nil)

        board.movePiece(from: from, to: to)

        #expect(board.piece(at: from) == nil)
        #expect(board.piece(at: to) == piece)
    }

    @Test("Move piece out of bounds does nothing")
    func testMovePieceOutOfBounds() {
        var board = Board.initial()
        let piece = board.piece(at: Position(x: 4, y: 0))

        // Try invalid moves
        board.movePiece(from: Position(x: -1, y: 0), to: Position(x: 0, y: 0))
        board.movePiece(from: Position(x: 0, y: 0), to: Position(x: -1, y: 0))
        board.movePiece(from: Position(x: 9, y: 0), to: Position(x: 0, y: 0))
        board.movePiece(from: Position(x: 0, y: 0), to: Position(x: 0, y: 10))

        // Verify board is unchanged
        #expect(board.piece(at: Position(x: 4, y: 0)) == piece)
    }

    // MARK: - Turn Switching Tests

    @Test("Switch turn updates current player")
    func testSwitchTurn() {
        var board = Board.initial()

        #expect(board.currentPlayer == .red)
        #expect(board.moveCount == 0)

        board.switchTurn()

        #expect(board.currentPlayer == .black)
        #expect(board.moveCount == 1)

        board.switchTurn()

        #expect(board.currentPlayer == .red)
        #expect(board.moveCount == 2)
    }

    // MARK: - FEN Tests

    @Test("Convert initial board to FEN")
    func testToFENInitial() {
        let board = Board.initial()
        let fen = board.toFEN()

        // Expected initial FEN for Chinese chess
        let expectedFEN = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1"

        #expect(fen == expectedFEN)
    }

    @Test("Parse initial FEN")
    func testFromFENInitial() throws {
        let fen = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1"
        let result = try FENParser.parse(fen)

        // Verify board state
        #expect(result.currentPlayer == .red)
        #expect(result.halfMoveClock == 0)
        #expect(result.fullMoveNumber == 1)

        // Verify some pieces
        #expect(result.board.piece(at: Position(x: 4, y: 0))?.type == .king)
        #expect(result.board.piece(at: Position(x: 4, y: 0))?.player == .red)
        #expect(result.board.piece(at: Position(x: 4, y: 9))?.type == .king)
        #expect(result.board.piece(at: Position(x: 4, y: 9))?.player == .black)
    }

    @Test("FEN roundtrip preserves board state")
    func testFENRoundtrip() throws {
        let originalBoard = Board.initial()
        let fen = originalBoard.toFEN()
        let result = try FENParser.parse(fen)

        // Compare piece positions
        for x in 0..<9 {
            for y in 0..<10 {
                let pos = Position(x: x, y: y)
                #expect(result.board.piece(at: pos) == originalBoard.piece(at: pos))
            }
        }
    }

    @Test("Invalid FEN throws error")
    func testInvalidFEN() {
        // Invalid: too few rows
        #expect(throws: FENParser.FENError.self) {
            _ = try FENParser.parse("rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9")
        }

        // Invalid: invalid piece character
        #expect(throws: FENParser.FENError.self) {
            _ = try FENParser.parse("xnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1")
        }
    }

    // MARK: - Helper Tests

    @Test("Find king returns correct position")
    func testFindKing() {
        let board = Board.initial()

        let redKingPos = board.findKing(for: .red)
        #expect(redKingPos == Position(x: 4, y: 0))

        let blackKingPos = board.findKing(for: .black)
        #expect(blackKingPos == Position(x: 4, y: 9))
    }

    @Test("Find king on empty board returns nil")
    func testFindKingEmptyBoard() {
        let board = Board.empty()

        #expect(board.findKing(for: .red) == nil)
        #expect(board.findKing(for: .black) == nil)
    }

    @Test("Pieces for player returns correct count")
    func testPiecesForPlayer() {
        let board = Board.initial()

        let redPieces = board.pieces(for: .red)
        let blackPieces = board.pieces(for: .black)

        // Each side has 16 pieces in initial setup
        #expect(redPieces.count == 16)
        #expect(blackPieces.count == 16)
    }

    @Test("Copy creates independent board")
    func testCopy() {
        let original = Board.initial()
        var copy = original.copy()

        // Modify copy
        copy.placePiece(nil, at: Position(x: 4, y: 0))

        // Original should be unchanged
        #expect(original.piece(at: Position(x: 4, y: 0)) != nil)
        #expect(copy.piece(at: Position(x: 4, y: 0)) == nil)
    }
}
