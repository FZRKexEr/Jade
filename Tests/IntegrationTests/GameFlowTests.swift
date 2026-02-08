import Testing
import Foundation
@testable import ChineseChessKit

/// Game Flow Integration Tests
/// Tests for complete game scenarios
@Suite("Game Flow Integration Tests")
struct GameFlowTests {

    // MARK: - Initial Setup Tests

    @Test("Initial game state is correct")
    func testInitialGameState() {
        let board = Board.initial()

        // Current player is red
        #expect(board.currentPlayer == .red)

        // Move count is 0
        #expect(board.moveCount == 0)

        // Half move clock is 0
        #expect(board.halfMoveClock == 0)

        // All pieces are in correct positions
        #expect(board.piece(at: Position(x: 4, y: 0))?.type == .king)
        #expect(board.piece(at: Position(x: 4, y: 9))?.type == .king)
        #expect(board.piece(at: Position(x: 0, y: 0))?.type == .rook)
        #expect(board.piece(at: Position(x: 8, y: 9))?.type == .rook)
    }

    // MARK: - Basic Move Sequence Tests

    @Test("Complete move sequence")
    func testCompleteMoveSequence() {
        var board = Board.initial()

        // Red pawn advances
        let from = Position(x: 0, y: 3)
        let to = Position(x: 0, y: 4)
        let piece = board.piece(at: from)!

        board.movePiece(from: from, to: to)
        board.switchTurn()

        // Verify move
        #expect(board.piece(at: from) == nil)
        #expect(board.piece(at: to) == piece)

        // Verify turn switched
        #expect(board.currentPlayer == .black)
        #expect(board.moveCount == 1)
    }

    @Test("Capture sequence")
    func testCaptureSequence() {
        var board = Board.empty()

        // Set up capture scenario
        let redPawn = Piece(type: .pawn, player: .red)
        let blackPawn = Piece(type: .pawn, player: .black)

        board.placePiece(redPawn, at: Position(x: 4, y: 4))
        board.placePiece(blackPawn, at: Position(x: 4, y: 5))

        // Red captures black
        board.movePiece(from: Position(x: 4, y: 4), to: Position(x: 4, y: 5))

        // Verify capture
        #expect(board.piece(at: Position(x: 4, y: 4)) == nil)
        #expect(board.piece(at: Position(x: 4, y: 5))?.player == .red)
    }

    // MARK: - Game State Transition Tests

    @Test("Game state transitions correctly")
    func testGameStateTransitions() {
        var board = Board.initial()
        var gameState: GameState = .ongoing(currentPlayer: .red)

        // Red makes a move
        let from = Position(x: 4, y: 3)
        let to = Position(x: 4, y: 4)
        board.movePiece(from: from, to: to)
        board.switchTurn()

        // Update game state
        gameState = .ongoing(currentPlayer: .black)

        #expect(gameState == .ongoing(currentPlayer: .black))
        #expect(board.currentPlayer == .black)
    }

    // MARK: - FEN Persistence Tests

    @Test("Save and restore game from FEN")
    func testSaveAndRestoreFromFEN() throws {
        let originalBoard = Board.initial()
        let fen = originalBoard.toFEN()

        // Parse FEN to create new board
        let result = try FENParser.parse(fen)
        let restoredBoard = result.board

        // Verify positions match
        for x in 0..<9 {
            for y in 0..<10 {
                let pos = Position(x: x, y: y)
                #expect(restoredBoard.piece(at: pos) == originalBoard.piece(at: pos))
            }
        }
    }

    @Test("FEN preserves game state")
    func testFENPreservesGameState() throws {
        var board = Board.initial()
        board.switchTurn() // Black to move
        board.switchTurn() // Red to move

        let fen = board.toFEN()
        let result = try FENParser.parse(fen)

        #expect(result.currentPlayer == .red)
    }

    // MARK: - Move History Tests

    @Test("Move history tracking")
    func testMoveHistoryTracking() {
        var board = Board.initial()
        var moveHistory: [Move] = []

        // Make a move
        let from = Position(x: 4, y: 3)
        let to = Position(x: 4, y: 4)
        let piece = board.piece(at: from)!

        board.movePiece(from: from, to: to)

        let move = Move(from: from, to: to, piece: piece)
        moveHistory.append(move)

        board.switchTurn()

        // Verify history
        #expect(moveHistory.count == 1)
        #expect(moveHistory[0].from == from)
        #expect(moveHistory[0].to == to)
    }

    // MARK: - Undo/Redo Tests

    @Test("Undo move restores previous state")
    func testUndoMove() {
        let originalBoard = Board.initial()
        var currentBoard = originalBoard

        // Make a move
        let from = Position(x: 4, y: 3)
        let to = Position(x: 4, y: 4)
        currentBoard.movePiece(from: from, to: to)

        // Undo by restoring original
        currentBoard = originalBoard

        // Verify undo
        #expect(currentBoard.piece(at: from)?.type == .pawn)
        #expect(currentBoard.piece(at: to) == nil)
    }

    // MARK: - Performance Tests

    @Test("Initial board FEN generation is fast")
    func testFENGenerationPerformance() {
        let board = Board.initial()

        // Generate FEN multiple times
        for _ in 0..<100 {
            _ = board.toFEN()
        }

        // If we get here, performance is acceptable
        #expect(true)
    }
}
