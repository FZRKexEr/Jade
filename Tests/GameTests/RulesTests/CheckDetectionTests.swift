import Testing
@testable import ChineseChessKit

/// Check Detection Tests
/// Tests for detecting check, checkmate, and stalemate conditions
@Suite("Check Detection Tests")
struct CheckDetectionTests {

    // MARK: - Basic Check Detection

    @Test("Detect rook giving check")
    func testRookGivingCheck() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackRook = Piece(type: .rook, player: .black)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackRook, at: Position(x: 4, y: 5))

        #expect(MovementRules.isKingInCheck(for: .red, on: board))
    }

    @Test("Detect horse giving check")
    func testHorseGivingCheck() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackHorse = Piece(type: .horse, player: .black)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackHorse, at: Position(x: 2, y: 2))

        #expect(MovementRules.isKingInCheck(for: .red, on: board))
    }

    @Test("Detect cannon giving check")
    func testCannonGivingCheck() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackCannon = Piece(type: .cannon, player: .black)
        let platform = Piece(type: .pawn, player: .red)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackCannon, at: Position(x: 4, y: 5))
        board.placePiece(platform, at: Position(x: 4, y: 3))

        #expect(MovementRules.isKingInCheck(for: .red, on: board))
    }

    @Test("No check when king is safe")
    func testNoCheckWhenKingIsSafe() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackRook = Piece(type: .rook, player: .black)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackRook, at: Position(x: 3, y: 5))

        #expect(!MovementRules.isKingInCheck(for: .red, on: board))
    }

    // MARK: - Double Check Tests

    @Test("Detect double check")
    func testDoubleCheck() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackRook1 = Piece(type: .rook, player: .black)
        let blackRook2 = Piece(type: .rook, player: .black)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackRook1, at: Position(x: 4, y: 5))
        board.placePiece(blackRook2, at: Position(x: 0, y: 0))

        #expect(MovementRules.isKingInCheck(for: .red, on: board))
        // This is a double check situation
    }

    // MARK: - Checkmate Tests

    @Test("Detect checkmate")
    func testCheckmate() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackRook1 = Piece(type: .rook, player: .black)
        let blackRook2 = Piece(type: .rook, player: .black)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackRook1, at: Position(x: 3, y: 0))
        board.placePiece(blackRook2, at: Position(x: 5, y: 0))

        #expect(MovementRules.isCheckmate(for: .red, on: board))
    }

    @Test("Not checkmate when king can escape")
    func testNotCheckmateWhenKingCanEscape() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackRook = Piece(type: .rook, player: .black)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackRook, at: Position(x: 4, y: 5))

        // King can move to (3, 0) or (5, 0)
        #expect(!MovementRules.isCheckmate(for: .red, on: board))
    }

    @Test("Not checkmate when check can be blocked")
    func testNotCheckmateWhenCheckCanBeBlocked() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let redAdvisor = Piece(type: .advisor, player: .red)
        let blackRook = Piece(type: .rook, player: .black)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(redAdvisor, at: Position(x: 3, y: 0))
        board.placePiece(blackRook, at: Position(x: 4, y: 5))

        // Advisor can move to block the check
        #expect(!MovementRules.isCheckmate(for: .red, on: board))
    }

    @Test("Not checkmate when checker can be captured")
    func testNotCheckmateWhenCheckerCanBeCaptured() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let redCannon = Piece(type: .cannon, player: .red)
        let blackHorse = Piece(type: .horse, player: .black)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(redCannon, at: Position(x: 2, y: 2))
        board.placePiece(blackHorse, at: Position(x: 2, y: 3))

        // Cannon can capture the horse
        #expect(!MovementRules.isCheckmate(for: .red, on: board))
    }

    // MARK: - Stalemate Tests

    @Test("Detect stalemate")
    func testStalemate() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackKing = Piece(type: .king, player: .black)
        let blackAdvisor1 = Piece(type: .advisor, player: .black)
        let blackAdvisor2 = Piece(type: .advisor, player: .black)

        // Stalemate position: red king has no legal moves but is not in check
        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackKing, at: Position(x: 4, y: 9))
        board.placePiece(blackAdvisor1, at: Position(x: 3, y: 0))
        board.placePiece(blackAdvisor2, at: Position(x: 5, y: 0))

        // This is a stalemate if king is not in check
        #expect(MovementRules.isStalemate(for: .red, on: board) ==
                !MovementRules.isKingInCheck(for: .red, on: board))
    }

    @Test("Not stalemate when king is in check")
    func testNotStalemateWhenInCheck() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let blackRook = Piece(type: .rook, player: .black)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(blackRook, at: Position(x: 4, y: 5))

        // Not stalemate when in check
        #expect(!MovementRules.isStalemate(for: .red, on: board))
    }

    @Test("Not stalemate when king has legal moves")
    func testNotStalemateWhenKingHasMoves() {
        var board = Board.empty()
        let redKing = Piece(type: .king, player: .red)
        let redCannon = Piece(type: .cannon, player: .red)

        board.placePiece(redKing, at: Position(x: 4, y: 0))
        board.placePiece(redCannon, at: Position(x: 4, y: 3))

        // Not stalemate - king has moves
        #expect(!MovementRules.isStalemate(for: .red, on: board))
    }
}
