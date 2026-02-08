import Testing
@testable import ChineseChessKit

/// Move Tests
/// Tests for the Move domain model
@Suite("Move Tests")
struct MoveTests {

    // MARK: - Creation Tests

    @Test("Create basic move")
    func testCreateBasicMove() {
        let from = Position(x: 0, y: 0)
        let to = Position(x: 0, y: 1)
        let piece = Piece(type: .rook, player: .red)

        let move = Move(from: from, to: to, piece: piece)

        #expect(move.from == from)
        #expect(move.to == to)
        #expect(move.piece == piece)
        #expect(move.capturedPiece == nil)
        #expect(move.isCheck == false)
        #expect(move.isCheckmate == false)
        #expect(move.notation == nil)
    }

    @Test("Create capture move")
    func testCreateCaptureMove() {
        let from = Position(x: 0, y: 0)
        let to = Position(x: 0, y: 1)
        let piece = Piece(type: .rook, player: .red)
        let captured = Piece(type: .pawn, player: .black)

        let move = Move(
            from: from,
            to: to,
            piece: piece,
            capturedPiece: captured
        )

        #expect(move.capturedPiece == captured)
    }

    @Test("Create check move")
    func testCreateCheckMove() {
        let from = Position(x: 0, y: 0)
        let to = Position(x: 4, y: 9)
        let piece = Piece(type: .rook, player: .red)

        let move = Move(
            from: from,
            to: to,
            piece: piece,
            isCheck: true
        )

        #expect(move.isCheck == true)
        #expect(move.isCheckmate == false)
    }

    @Test("Create checkmate move")
    func testCreateCheckmateMove() {
        let from = Position(x: 0, y: 0)
        let to = Position(x: 4, y: 9)
        let piece = Piece(type: .rook, player: .red)

        let move = Move(
            from: from,
            to: to,
            piece: piece,
            isCheck: true,
            isCheckmate: true
        )

        #expect(move.isCheck == true)
        #expect(move.isCheckmate == true)
    }

    @Test("Create move with notation")
    func testCreateMoveWithNotation() {
        let from = Position(x: 0, y: 0)
        let to = Position(x: 0, y: 1)
        let piece = Piece(type: .rook, player: .red)

        let move = Move(
            from: from,
            to: to,
            piece: piece,
            notation: "车九进一"
        )

        #expect(move.notation == "车九进一")
    }

    @Test("Create move with custom ID and timestamp")
    func testCreateMoveWithCustomID() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1000)
        let from = Position(x: 0, y: 0)
        let to = Position(x: 0, y: 1)
        let piece = Piece(type: .rook, player: .red)

        let move = Move(
            id: id,
            from: from,
            to: to,
            piece: piece,
            timestamp: timestamp
        )

        #expect(move.id == id)
        #expect(move.timestamp == timestamp)
    }

    // MARK: - Description Tests

    @Test("Move description format")
    func testDescription() {
        let from = Position(x: 0, y: 0)
        let to = Position(x: 0, y: 1)
        let piece = Piece(type: .rook, player: .red)

        let move = Move(from: from, to: to, piece: piece)

        // Description should be in format: piece character + from + (-|x) + to
        #expect(move.description.contains("俥"))
    }

    @Test("Move description with capture")
    func testDescriptionWithCapture() {
        let from = Position(x: 0, y: 0)
        let to = Position(x: 0, y: 1)
        let piece = Piece(type: .rook, player: .red)
        let captured = Piece(type: .pawn, player: .black)

        let move = Move(from: from, to: to, piece: piece, capturedPiece: captured)

        // Description should contain x for capture
        #expect(move.description.contains("x"))
    }

    // MARK: - UCI Notation Tests

    @Test("UCI notation format")
    func testUCINotation() {
        let from = Position(x: 4, y: 6)
        let to = Position(x: 4, y: 4)
        let piece = Piece(type: .cannon, player: .red)

        let move = Move(from: from, to: to, piece: piece)

        // UCI notation: from.x from.y to.x to.y
        #expect(move.uciNotation == "4644")
    }

    // MARK: - Equatable Tests

    @Test("Move equality")
    func testEquality() {
        let id = UUID()
        let from = Position(x: 0, y: 0)
        let to = Position(x: 0, y: 1)
        let piece = Piece(type: .rook, player: .red)

        let move1 = Move(id: id, from: from, to: to, piece: piece)
        let move2 = Move(id: id, from: from, to: to, piece: piece)
        let move3 = Move(from: from, to: to, piece: piece) // Different ID

        #expect(move1 == move2)
        #expect(move1 != move3)
    }

    // MARK: - Hashable Tests

    @Test("Move hashing")
    func testHashing() {
        let move = Move(from: Position(x: 0, y: 0), to: Position(x: 0, y: 1), piece: Piece(type: .rook, player: .red))

        var dict: [Move: String] = [:]
        dict[move] = "test"

        #expect(dict[move] == "test")
    }

    // MARK: - Sendable Tests

    @Test("Move is Sendable")
    func testSendable() async {
        let move = Move(from: Position(x: 0, y: 0), to: Position(x: 0, y: 1), piece: Piece(type: .rook, player: .red))

        let result = await Task {
            move.from.x + move.to.x
        }.value

        #expect(result == 0)
    }
}
