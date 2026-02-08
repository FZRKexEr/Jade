import Testing
@testable import ChineseChessKit

/// Win Condition Tests
/// Tests for checkmate, stalemate, and other win/loss conditions
@Suite("Win Condition Tests")
struct WinConditionTests {

    // MARK: - Checkmate Detection Tests

    @Test("Simple rook checkmate")
    func testSimpleRookCheckmate() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackRook1 = Piece(type: .rook, player: .black)
        let blackRook2 = Piece(type: .rook, player: .black)

        // Set up back rank mate
        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackRook1, at: Position(x: 3, y: 0))
        board.placePiece(blackRook2, at: Position(x: 5, y: 0))

        #expect(MovementRules.isCheckmate(for: .red, on: board))
    }

    @Test("Rook and king checkmate")
    func testRookKingCheckmate() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackKing = Piece(type: .king, player: .black)
        let blackRook = Piece(type: .rook, player: .black)

        // Classic king and rook mate
        board.placePiece(redKing, at: Position(x: 0, y: 0))
        board.placePiece(blackKing, at: Position(x: 2, y: 0))
        board.placePiece(blackRook, at: Position(x: 0, y: 7))

        #expect(MovementRules.isCheckmate(for: .red, on: board))
    }

    @Test("Not checkmate when king can capture attacker")
    func testNotCheckmateWhenKingCanCapture() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackRook = Piece(type: .rook, player: .black)

        // Rook gives check but is adjacent to king
        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackRook, at: Position(x: 4, y: 1))

        // King can capture the rook
        #expect(!MovementRules.isCheckmate(for: .red, on: board))
        #expect(MovementRules.isKingInCheck(for: .red, on: board))
    }

    @Test("Not checkmate when check can be blocked")
    func testNotCheckmateWhenCheckCanBeBlocked() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let redAdvisor = Piece(type: .advisor, player: .red)
        let blackRook = Piece(type: .rook, player: .black)

        // Rook gives check from distance
        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(redAdvisor, at: Position(x: 3, y: 0))
        board.placePiece(blackRook, at: Position(x: 4, y: 8))

        // Advisor can block the check
        #expect(!MovementRules.isCheckmate(for: .red, on: board))
    }

    // MARK: - Stalemate Detection Tests

    @Test("Stalemate when no legal moves")
    func testStalemateWhenNoLegalMoves() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackKing = Piece(type: .king, player: .black)
        let blackAdvisor1 = Piece(type: .advisor, player: .black)
        let blackAdvisor2 = Piece(type: .advisor, player: .black)

        // Stalemate position
        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackKing, at: Position(x: 4, y: 9))
        board.placePiece(blackAdvisor1, at: Position(x: 3, y: 0))
        board.placePiece(blackAdvisor2, at: Position(x: 5, y: 0))

        #expect(MovementRules.isStalemate(for: .red, on: board))
    }

    @Test("Not stalemate when in check")
    func testNotStalemateWhenInCheck() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackRook = Piece(type: .rook, player: .black)

        // In check but has moves
        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackRook, at: Position(x: 4, y: 5))

        #expect(!MovementRules.isStalemate(for: .red, on: board))
        #expect(MovementRules.isKingInCheck(for: .red, on: board))
    }

    // MARK: - Kings Facing Test

    @Test("Detect kings facing")
    func testKingsFacing() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackKing = Piece(type: .king, player: .black)

        // Kings facing each other on same file
        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackKing, at: Position(x: 4, y: 9))

        #expect(SpecialRules.areKingsFacing(on: board))
    }

    @Test("Kings not facing when blocked")
    func testKingsNotFacingWhenBlocked() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackKing = Piece(type: .king, player: .black)
        let blocker = Piece(type: .pawn, player: .red)

        // Kings blocked by piece
        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackKing, at: Position(x: 4, y: 9))
        board.placePiece(blocker, at: Position(x: 4, y: 4))

        #expect(!SpecialRules.areKingsFacing(on: board))
    }

    // MARK: - Legal Moves Tests

    @Test("Get legal moves filters out illegal moves")
    func testGetLegalMoves() {
        var board = Board.empty()
        let rook = Piece(type: .rook, player: .red)
        let pos = Position(x: 4, y: 4)
        board.placePiece(rook, at: pos)

        let legalMoves = MovementRules.getLegalMoves(for: rook, at: pos, on: board)

        // Rook can move to any square in same rank or file
        #expect(legalMoves.count == 16) // 4 + 5 + 4 + 3 = 16
    }

    @Test("Legal moves respect blocking pieces")
    func testLegalMovesWithBlockingPieces() {
        var board = Board.empty()
        let rook = Piece(type: .rook, player: .red)
        let blocker = Piece(type: .pawn, player: .red)
        let pos = Position(x: 4, y: 4)
        board.placePiece(rook, at: pos)
        board.placePiece(blocker, at: Position(x: 4, y: 6))

        let legalMoves = MovementRules.getLegalMoves(for: rook, at: pos, on: board)

        // Cannot move past or to blocker's position
        #expect(!legalMoves.contains(Position(x: 4, y: 7)))
        #expect(!legalMoves.contains(Position(x: 4, y: 8)))
    }
}
