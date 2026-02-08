import Testing
@testable import ChineseChessKit

/// Position Tests
/// Tests for the Position domain model
@Suite("Position Tests")
struct PositionTests {

    // MARK: - Creation Tests

    @Test("Create valid position")
    func testCreateValidPosition() {
        let position = Position(x: 4, y: 5)

        #expect(position.x == 4)
        #expect(position.y == 5)
    }

    @Test("Create position at boundaries")
    func testCreateBoundaryPositions() {
        // Corners
        let bottomLeft = Position(x: 0, y: 0)
        let bottomRight = Position(x: 8, y: 0)
        let topLeft = Position(x: 0, y: 9)
        let topRight = Position(x: 8, y: 9)

        #expect(bottomLeft.x == 0 && bottomLeft.y == 0)
        #expect(bottomRight.x == 8 && bottomRight.y == 0)
        #expect(topLeft.x == 0 && topLeft.y == 9)
        #expect(topRight.x == 8 && topRight.y == 9)
    }

    // MARK: - Parsing Tests

    @Test("Parse position from algebraic notation")
    func testParseFromAlgebraicNotation() {
        let a1 = Position.from(string: "a1")
        #expect(a1?.x == 0)
        #expect(a1?.y == 0)

        let e5 = Position.from(string: "e5")
        #expect(e5?.x == 4)
        #expect(e5?.y == 4)

        let i10 = Position.from(string: "j10")
        #expect(i10?.x == 9)
        #expect(i10?.y == 9)
    }

    @Test("Parse invalid position string returns nil")
    func testParseInvalidPosition() {
        #expect(Position.from(string: "") == nil)
        #expect(Position.from(string: "a") == nil)
        #expect(Position.from(string: "1") == nil)
        #expect(Position.from(string: "k1") == nil)  // Out of range
        #expect(Position.from(string: "a11") == nil) // Too long
    }

    // MARK: - Description Tests

    @Test("Position description returns algebraic notation")
    func testDescription() {
        let a1 = Position(x: 0, y: 0)
        #expect(a1.description == "a1")

        let e5 = Position(x: 4, y: 4)
        #expect(e5.description == "e5")

        let i10 = Position(x: 8, y: 9)
        #expect(i10.description == "i10")
    }

    // MARK: - Validation Tests

    @Test("Valid positions pass validation")
    func testValidPositionValidation() {
        #expect(Position(x: 0, y: 0).isValid() == true)
        #expect(Position(x: 8, y: 9).isValid() == true)
        #expect(Position(x: 4, y: 4).isValid() == true)
    }

    @Test("Invalid positions fail validation")
    func testInvalidPositionValidation() {
        #expect(Position(x: -1, y: 0).isValid() == false)
        #expect(Position(x: 0, y: -1).isValid() == false)
        #expect(Position(x: 9, y: 0).isValid() == false)
        #expect(Position(x: 0, y: 10).isValid() == false)
    }

    // MARK: - Distance Tests

    @Test("Distance between positions")
    func testDistance() {
        let pos1 = Position(x: 2, y: 3)
        let pos2 = Position(x: 5, y: 7)

        let distance = pos1.distance(to: pos2)

        #expect(distance.dx == 3)
        #expect(distance.dy == 4)
    }

    @Test("Distance with negative values")
    func testDistanceNegative() {
        let pos1 = Position(x: 5, y: 7)
        let pos2 = Position(x: 2, y: 3)

        let distance = pos1.distance(to: pos2)

        #expect(distance.dx == -3)
        #expect(distance.dy == -4)
    }

    // MARK: - Equatable Tests

    @Test("Position equality")
    func testEquality() {
        let pos1 = Position(x: 4, y: 5)
        let pos2 = Position(x: 4, y: 5)
        let pos3 = Position(x: 3, y: 5)
        let pos4 = Position(x: 4, y: 6)

        #expect(pos1 == pos2)
        #expect(pos1 != pos3)
        #expect(pos1 != pos4)
    }

    // MARK: - Hashable Tests

    @Test("Position hashing")
    func testHashing() {
        let pos1 = Position(x: 4, y: 5)
        let pos2 = Position(x: 4, y: 5)

        var dict: [Position: String] = [:]
        dict[pos1] = "test"

        #expect(dict[pos2] == "test")
    }

    // MARK: - Sendable Tests

    @Test("Position is Sendable")
    func testSendable() async {
        let position = Position(x: 4, y: 5)

        let result = await Task {
            position.x + position.y
        }.value

        #expect(result == 9)
    }
}
