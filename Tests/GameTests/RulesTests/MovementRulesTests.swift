import Testing
@testable import ChineseChessKit

/// Movement Rules Tests
/// Tests for the movement rules of all piece types
@Suite("Movement Rules Tests")
struct MovementRulesTests {

    // MARK: - King Movement Tests

    @Test("King can move within palace")
    func testKingMoveInPalace() {
        var board = Board.empty()
        let king = Piece(type: .king, player: .red)
        let pos = Position(x: 4, y: 0)
        board.placePiece(king, at: pos)

        // Can move horizontally
        #expect(MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 3, y: 0), on: board))
        #expect(MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 5, y: 0), on: board))

        // Can move vertically
        #expect(MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 4, y: 1), on: board))
    }

    @Test("King cannot move outside palace")
    func testKingCannotLeavePalace() {
        var board = Board.empty()
        let king = Piece(type: .king, player: .red)
        let pos = Position(x: 4, y: 0)
        board.placePiece(king, at: pos)

        // Cannot move outside palace
        #expect(!MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 4, y: 3), on: board))
        #expect(!MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 0, y: 0), on: board))
        #expect(!MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 8, y: 0), on: board))
    }

    @Test("King cannot move diagonally")
    func testKingCannotMoveDiagonally() {
        var board = Board.empty()
        let king = Piece(type: .king, player: .red)
        let pos = Position(x: 4, y: 0)
        board.placePiece(king, at: pos)

        // Cannot move diagonally
        #expect(!MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 3, y: 1), on: board))
        #expect(!MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 5, y: 1), on: board))
    }

    @Test("King cannot move more than one square")
    func testKingCannotMoveMultipleSquares() {
        var board = Board.empty()
        let king = Piece(type: .king, player: .red)
        let pos = Position(x: 4, y: 0)
        board.placePiece(king, at: pos)

        // Cannot move more than one square
        #expect(!MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 2, y: 0), on: board))
        #expect(!MovementRules.isMoveLegal(piece: king, from: pos, to: Position(x: 6, y: 0), on: board))
    }

    // MARK: - Advisor Movement Tests

    @Test("Advisor can move diagonally in palace")
    func testAdvisorMoveInPalace() {
        var board = Board.empty()
        let advisor = Piece(type: .advisor, player: .red)
        let pos = Position(x: 3, y: 0)
        board.placePiece(advisor, at: pos)

        // Can move diagonally one square
        #expect(MovementRules.isMoveLegal(piece: advisor, from: pos, to: Position(x: 4, y: 1), on: board))
        #expect(MovementRules.isMoveLegal(piece: advisor, from: pos, to: Position(x: 2, y: 1), on: board))
    }

    @Test("Advisor cannot move outside palace")
    func testAdvisorCannotLeavePalace() {
        var board = Board.empty()
        let advisor = Piece(type: .advisor, player: .red)
        let pos = Position(x: 3, y: 0)
        board.placePiece(advisor, at: pos)

        // Cannot move outside palace
        #expect(!MovementRules.isMoveLegal(piece: advisor, from: pos, to: Position(x: 5, y: 2), on: board))
    }

    @Test("Advisor cannot move orthogonally")
    func testAdvisorCannotMoveOrthogonally() {
        var board = Board.empty()
        let advisor = Piece(type: .advisor, player: .red)
        let pos = Position(x: 3, y: 0)
        board.placePiece(advisor, at: pos)

        // Cannot move orthogonally
        #expect(!MovementRules.isMoveLegal(piece: advisor, from: pos, to: Position(x: 3, y: 1), on: board))
        #expect(!MovementRules.isMoveLegal(piece: advisor, from: pos, to: Position(x: 4, y: 0), on: board))
    }

    // MARK: - Elephant Movement Tests

    @Test("Elephant can move diagonally two squares")
    func testElephantMove() {
        var board = Board.empty()
        let elephant = Piece(type: .elephant, player: .red)
        let pos = Position(x: 2, y: 0)
        board.placePiece(elephant, at: pos)

        // Can move diagonally two squares
        #expect(MovementRules.isMoveLegal(piece: elephant, from: pos, to: Position(x: 4, y: 2), on: board))
        #expect(MovementRules.isMoveLegal(piece: elephant, from: pos, to: Position(x: 0, y: 2), on: board))
    }

    @Test("Elephant cannot cross river")
    func testElephantCannotCrossRiver() {
        var board = Board.empty()
        let elephant = Piece(type: .elephant, player: .red)
        let pos = Position(x: 2, y: 0)
        board.placePiece(elephant, at: pos)

        // Cannot cross river (y >= 5 for red)
        #expect(!MovementRules.isMoveLegal(piece: elephant, from: pos, to: Position(x: 4, y: 6), on: board))
    }

    @Test("Elephant cannot be blocked")
    func testElephantCannotBeBlocked() {
        var board = Board.empty()
        let elephant = Piece(type: .elephant, player: .red)
        let pos = Position(x: 2, y: 0)
        board.placePiece(elephant, at: pos)

        // Place blocking piece at the "eye" position
        let blockingPiece = Piece(type: .pawn, player: .red)
        board.placePiece(blockingPiece, at: Position(x: 3, y: 1))

        // Cannot move when blocked
        #expect(!MovementRules.isMoveLegal(piece: elephant, from: pos, to: Position(x: 4, y: 2), on: board))
    }

    // MARK: - Horse Movement Tests

    @Test("Horse can move in L shape")
    func testHorseMove() {
        var board = Board.empty()
        let horse = Piece(type: .horse, player: .red)
        let pos = Position(x: 1, y: 0)
        board.placePiece(horse, at: pos)

        // Can move in L shape
        #expect(MovementRules.isMoveLegal(piece: horse, from: pos, to: Position(x: 0, y: 2), on: board))
        #expect(MovementRules.isMoveLegal(piece: horse, from: pos, to: Position(x: 2, y: 2), on: board))
        #expect(MovementRules.isMoveLegal(piece: horse, from: pos, to: Position(x: 3, y: 1), on: board))
    }

    @Test("Horse cannot move when blocked")
    func testHorseBlocked() {
        var board = Board.empty()
        let horse = Piece(type: .horse, player: .red)
        let pos = Position(x: 1, y: 0)
        board.placePiece(horse, at: pos)

        // Place blocking piece at the leg position
        let blockingPiece = Piece(type: .pawn, player: .red)
        board.placePiece(blockingPiece, at: Position(x: 1, y: 1))

        // Cannot move when blocked
        #expect(!MovementRules.isMoveLegal(piece: horse, from: pos, to: Position(x: 0, y: 2), on: board))
        #expect(!MovementRules.isMoveLegal(piece: horse, from: pos, to: Position(x: 2, y: 2), on: board))
    }

    // MARK: - Rook Movement Tests

    @Test("Rook can move horizontally and vertically")
    func testRookMove() {
        var board = Board.empty()
        let rook = Piece(type: .rook, player: .red)
        let pos = Position(x: 0, y: 0)
        board.placePiece(rook, at: pos)

        // Can move horizontally
        #expect(MovementRules.isMoveLegal(piece: rook, from: pos, to: Position(x: 8, y: 0), on: board))

        // Can move vertically
        #expect(MovementRules.isMoveLegal(piece: rook, from: pos, to: Position(x: 0, y: 9), on: board))
    }

    @Test("Rook cannot move diagonally")
    func testRookCannotMoveDiagonally() {
        var board = Board.empty()
        let rook = Piece(type: .rook, player: .red)
        let pos = Position(x: 0, y: 0)
        board.placePiece(rook, at: pos)

        // Cannot move diagonally
        #expect(!MovementRules.isMoveLegal(piece: rook, from: pos, to: Position(x: 1, y: 1), on: board))
    }

    @Test("Rook cannot jump over pieces")
    func testRookCannotJump() {
        var board = Board.empty()
        let rook = Piece(type: .rook, player: .red)
        let pos = Position(x: 0, y: 0)
        board.placePiece(rook, at: pos)

        // Place blocking piece
        let blockingPiece = Piece(type: .pawn, player: .red)
        board.placePiece(blockingPiece, at: Position(x: 4, y: 0))

        // Cannot move past blocking piece
        #expect(!MovementRules.isMoveLegal(piece: rook, from: pos, to: Position(x: 8, y: 0), on: board))
        // But can move to just before blocking piece
        #expect(MovementRules.isMoveLegal(piece: rook, from: pos, to: Position(x: 3, y: 0), on: board))
    }

    @Test("Rook can capture enemy piece")
    func testRookCanCapture() {
        var board = Board.empty()
        let rook = Piece(type: .rook, player: .red)
        let pos = Position(x: 0, y: 0)
        board.placePiece(rook, at: pos)

        // Place enemy piece
        let enemyPiece = Piece(type: .pawn, player: .black)
        board.placePiece(enemyPiece, at: Position(x: 4, y: 0))

        // Can capture enemy piece
        #expect(MovementRules.isMoveLegal(piece: rook, from: pos, to: Position(x: 4, y: 0), on: board))
    }

    // MARK: - Cannon Movement Tests

    @Test("Cannon can move horizontally and vertically without jumping")
    func testCannonMove() {
        var board = Board.empty()
        let cannon = Piece(type: .cannon, player: .red)
        let pos = Position(x: 1, y: 2)
        board.placePiece(cannon, at: pos)

        // Can move horizontally
        #expect(MovementRules.isMoveLegal(piece: cannon, from: pos, to: Position(x: 8, y: 2), on: board))

        // Can move vertically
        #expect(MovementRules.isMoveLegal(piece: cannon, from: pos, to: Position(x: 1, y: 9), on: board))
    }

    @Test("Cannon captures by jumping over one piece")
    func testCannonCapture() {
        var board = Board.empty()
        let cannon = Piece(type: .cannon, player: .red)
        let pos = Position(x: 1, y: 2)
        board.placePiece(cannon, at: pos)

        // Place one piece to jump over
        let platform = Piece(type: .pawn, player: .red)
        board.placePiece(platform, at: Position(x: 4, y: 2))

        // Place enemy piece to capture
        let enemy = Piece(type: .pawn, player: .black)
        board.placePiece(enemy, at: Position(x: 7, y: 2))

        // Can capture by jumping
        #expect(MovementRules.isMoveLegal(piece: cannon, from: pos, to: Position(x: 7, y: 2), on: board))

        // Cannot land on empty square after jumping
        #expect(!MovementRules.isMoveLegal(piece: cannon, from: pos, to: Position(x: 6, y: 2), on: board))
    }

    @Test("Cannon cannot capture without platform")
    func testCannonCannotCaptureWithoutPlatform() {
        var board = Board.empty()
        let cannon = Piece(type: .cannon, player: .red)
        let pos = Position(x: 1, y: 2)
        board.placePiece(cannon, at: pos)

        // Place enemy piece without platform
        let enemy = Piece(type: .pawn, player: .black)
        board.placePiece(enemy, at: Position(x: 4, y: 2))

        // Cannot capture without jumping over a piece
        #expect(!MovementRules.isMoveLegal(piece: cannon, from: pos, to: Position(x: 4, y: 2), on: board))
    }

    @Test("Cannon cannot jump over two pieces")
    func testCannonCannotJumpTwoPieces() {
        var board = Board.empty()
        let cannon = Piece(type: .cannon, player: .red)
        let pos = Position(x: 1, y: 2)
        board.placePiece(cannon, at: pos)

        // Place two pieces to jump over
        let platform1 = Piece(type: .pawn, player: .red)
        let platform2 = Piece(type: .pawn, player: .red)
        board.placePiece(platform1, at: Position(x: 3, y: 2))
        board.placePiece(platform2, at: Position(x: 5, y: 2))

        // Place enemy piece
        let enemy = Piece(type: .pawn, player: .black)
        board.placePiece(enemy, at: Position(x: 7, y: 2))

        // Cannot capture when two platforms
        #expect(!MovementRules.isMoveLegal(piece: cannon, from: pos, to: Position(x: 7, y: 2), on: board))
    }

    // MARK: - Pawn Movement Tests

    @Test("Pawn can move forward before crossing river")
    func testPawnMoveBeforeCrossingRiver() {
        var board = Board.empty()
        let pawn = Piece(type: .pawn, player: .red)
        let pos = Position(x: 4, y: 3)
        board.placePiece(pawn, at: pos)

        // Can move forward (up for red)
        #expect(MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 4, y: 4), on: board))

        // Cannot move sideways or backward
        #expect(!MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 3, y: 3), on: board))
        #expect(!MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 5, y: 3), on: board))
        #expect(!MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 4, y: 2), on: board))
    }

    @Test("Pawn can move forward and sideways after crossing river")
    func testPawnMoveAfterCrossingRiver() {
        var board = Board.empty()
        let pawn = Piece(type: .pawn, player: .red)
        let pos = Position(x: 4, y: 6) // Crossed river
        board.placePiece(pawn, at: pos)

        // Can move forward
        #expect(MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 4, y: 7), on: board))

        // Can move sideways
        #expect(MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 3, y: 6), on: board))
        #expect(MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 5, y: 6), on: board))

        // Cannot move backward
        #expect(!MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 4, y: 5), on: board))
    }

    @Test("Black pawn moves down")
    func testBlackPawnMovesDown() {
        var board = Board.empty()
        let pawn = Piece(type: .pawn, player: .black)
        let pos = Position(x: 4, y: 6)
        board.placePiece(pawn, at: pos)

        // Can move forward (down for black)
        #expect(MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 4, y: 5), on: board))

        // Cannot move up
        #expect(!MovementRules.isMoveLegal(piece: pawn, from: pos, to: Position(x: 4, y: 7), on: board))
    }

    // MARK: - General Movement Validation Tests

    @Test("Cannot move to same position")
    func testCannotMoveToSamePosition() {
        var board = Board.empty()
        let piece = Piece(type: .rook, player: .red)
        let pos = Position(x: 4, y: 4)
        board.placePiece(piece, at: pos)

        #expect(!MovementRules.isMoveLegal(piece: piece, from: pos, to: pos, on: board))
    }

    @Test("Cannot capture own piece")
    func testCannotCaptureOwnPiece() {
        var board = Board.empty()
        let rook = Piece(type: .rook, player: .red)
        let friendly = Piece(type: .pawn, player: .red)
        let pos = Position(x: 0, y: 0)
        board.placePiece(rook, at: pos)
        board.placePiece(friendly, at: Position(x: 0, y: 2))

        #expect(!MovementRules.isMoveLegal(piece: rook, from: pos, to: Position(x: 0, y: 2), on: board))
    }

    @Test("Can capture enemy piece")
    func testCanCaptureEnemyPiece() {
        var board = Board.empty()
        let rook = Piece(type: .rook, player: .red)
        let enemy = Piece(type: .pawn, player: .black)
        let pos = Position(x: 0, y: 0)
        board.placePiece(rook, at: pos)
        board.placePiece(enemy, at: Position(x: 0, y: 2))

        #expect(MovementRules.isMoveLegal(piece: rook, from: pos, to: Position(x: 0, y: 2), on: board))
    }
}
