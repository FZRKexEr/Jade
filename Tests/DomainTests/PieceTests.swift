import Testing
@testable import ChineseChessKit

/// Piece Tests
/// Tests for the Piece domain model
@Suite("Piece Tests")
struct PieceTests {

    // MARK: - Creation Tests

    @Test("Create piece with all types for red")
    func testCreateRedPieces() {
        let king = Piece(type: .king, player: .red)
        #expect(king.type == .king)
        #expect(king.player == .red)

        let advisor = Piece(type: .advisor, player: .red)
        #expect(advisor.type == .advisor)
        #expect(advisor.player == .red)

        let elephant = Piece(type: .elephant, player: .red)
        #expect(elephant.type == .elephant)
        #expect(elephant.player == .red)

        let horse = Piece(type: .horse, player: .red)
        #expect(horse.type == .horse)
        #expect(horse.player == .red)

        let rook = Piece(type: .rook, player: .red)
        #expect(rook.type == .rook)
        #expect(rook.player == .red)

        let cannon = Piece(type: .cannon, player: .red)
        #expect(cannon.type == .cannon)
        #expect(cannon.player == .red)

        let pawn = Piece(type: .pawn, player: .red)
        #expect(pawn.type == .pawn)
        #expect(pawn.player == .red)
    }

    @Test("Create piece with all types for black")
    func testCreateBlackPieces() {
        let king = Piece(type: .king, player: .black)
        #expect(king.type == .king)
        #expect(king.player == .black)

        let advisor = Piece(type: .advisor, player: .black)
        #expect(advisor.type == .advisor)
        #expect(advisor.player == .black)

        let elephant = Piece(type: .elephant, player: .black)
        #expect(elephant.type == .elephant)
        #expect(elephant.player == .black)

        let horse = Piece(type: .horse, player: .black)
        #expect(horse.type == .horse)
        #expect(horse.player == .black)

        let rook = Piece(type: .rook, player: .black)
        #expect(rook.type == .rook)
        #expect(rook.player == .black)

        let cannon = Piece(type: .cannon, player: .black)
        #expect(cannon.type == .cannon)
        #expect(cannon.player == .black)

        let pawn = Piece(type: .pawn, player: .black)
        #expect(pawn.type == .pawn)
        #expect(pawn.player == .black)
    }

    // MARK: - Character Display Tests

    @Test("Red piece characters")
    func testRedPieceCharacters() {
        #expect(Piece(type: .king, player: .red).character == "帅")
        #expect(Piece(type: .advisor, player: .red).character == "仕")
        #expect(Piece(type: .elephant, player: .red).character == "相")
        #expect(Piece(type: .horse, player: .red).character == "傌")
        #expect(Piece(type: .rook, player: .red).character == "俥")
        #expect(Piece(type: .cannon, player: .red).character == "炮")
        #expect(Piece(type: .pawn, player: .red).character == "兵")
    }

    @Test("Black piece characters")
    func testBlackPieceCharacters() {
        #expect(Piece(type: .king, player: .black).character == "将")
        #expect(Piece(type: .advisor, player: .black).character == "士")
        #expect(Piece(type: .elephant, player: .black).character == "象")
        #expect(Piece(type: .horse, player: .black).character == "马")
        #expect(Piece(type: .rook, player: .black).character == "车")
        #expect(Piece(type: .cannon, player: .black).character == "砲")
        #expect(Piece(type: .pawn, player: .black).character == "卒")
    }

    // MARK: - FEN Character Tests

    @Test("Red piece FEN characters")
    func testRedPieceFENCharacters() {
        #expect(Piece(type: .king, player: .red).fenCharacter == "K")
        #expect(Piece(type: .advisor, player: .red).fenCharacter == "A")
        #expect(Piece(type: .elephant, player: .red).fenCharacter == "B")
        #expect(Piece(type: .horse, player: .red).fenCharacter == "N")
        #expect(Piece(type: .rook, player: .red).fenCharacter == "R")
        #expect(Piece(type: .cannon, player: .red).fenCharacter == "C")
        #expect(Piece(type: .pawn, player: .red).fenCharacter == "P")
    }

    @Test("Black piece FEN characters")
    func testBlackPieceFENCharacters() {
        #expect(Piece(type: .king, player: .black).fenCharacter == "k")
        #expect(Piece(type: .advisor, player: .black).fenCharacter == "a")
        #expect(Piece(type: .elephant, player: .black).fenCharacter == "b")
        #expect(Piece(type: .horse, player: .black).fenCharacter == "n")
        #expect(Piece(type: .rook, player: .black).fenCharacter == "r")
        #expect(Piece(type: .cannon, player: .black).fenCharacter == "c")
        #expect(Piece(type: .pawn, player: .black).fenCharacter == "p")
    }

    // MARK: - Equality Tests

    @Test("Piece equality")
    func testPieceEquality() {
        let piece1 = Piece(id: UUID(), type: .king, player: .red)
        let piece2 = Piece(id: piece1.id, type: .king, player: .red)
        let piece3 = Piece(id: UUID(), type: .king, player: .red)
        let piece4 = Piece(id: UUID(), type: .advisor, player: .red)

        #expect(piece1 == piece2)
        #expect(piece1 != piece3) // Different ID
        #expect(piece1 != piece4) // Different type
    }

    // MARK: - Hash Tests

    @Test("Piece hashing")
    func testPieceHashing() {
        let piece = Piece(type: .king, player: .red)
        var dict: [Piece: String] = [:]

        dict[piece] = "test"

        #expect(dict[piece] == "test")
    }

    // MARK: - Identifiable Tests

    @Test("Piece has unique ID")
    func testPieceID() {
        let piece1 = Piece(type: .king, player: .red)
        let piece2 = Piece(type: .king, player: .red)

        #expect(piece1.id != piece2.id)
    }

    @Test("Piece can have custom ID")
    func testPieceCustomID() {
        let uuid = UUID()
        let piece = Piece(id: uuid, type: .king, player: .red)

        #expect(piece.id == uuid)
    }

    // MARK: - Sendable Tests

    @Test("Piece is Sendable")
    func testPieceSendable() async {
        let piece = Piece(type: .king, player: .red)

        // Should compile without error due to Sendable conformance
        let result = await Task {
            piece.type
        }.value

        #expect(result == .king)
    }
}
