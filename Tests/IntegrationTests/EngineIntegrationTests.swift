import Testing
import Foundation
@testable import Engine
@testable import ChineseChessKit

/// Engine Integration Tests
/// Tests for UCI protocol communication and engine lifecycle
@Suite("Engine Integration Tests")
struct EngineIntegrationTests {

    // MARK: - UCI Protocol Tests

    @Test("UCI command sequence")
    func testUCICommandSequence() async {
        let serializer = await UCISerializer()

        // Test basic commands
        let uciCmd = await serializer.serialize(.uci)
        #expect(uciCmd == "uci")

        let isreadyCmd = await serializer.serialize(.isready)
        #expect(isreadyCmd == "isready")

        let quitCmd = await serializer.serialize(.quit)
        #expect(quitCmd == "quit")
    }

    @Test("Position command with startpos")
    func testPositionCommandStartpos() async {
        let serializer = await UCISerializer()

        let cmd = await serializer.serialize(.position(fen: nil, moves: []))
        #expect(cmd == "position startpos")
    }

    @Test("Position command with moves")
    func testPositionCommandWithMoves() async {
        let serializer = await UCISerializer()

        let cmd = await serializer.serialize(.position(fen: nil, moves: ["e2e4", "e7e5"]))
        #expect(cmd == "position startpos moves e2e4 e7e5")
    }

    @Test("Position command with FEN")
    func testPositionCommandWithFEN() async {
        let serializer = await UCISerializer()

        let fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
        let cmd = await serializer.serialize(.position(fen: fen, moves: []))
        #expect(cmd == "position fen \(fen)")
    }

    @Test("Go command with depth")
    func testGoCommandDepth() async {
        let serializer = await UCISerializer()

        let cmd = await serializer.serialize(.go(.depth(15)))
        #expect(cmd == "go depth 15")
    }

    @Test("Go command with movetime")
    func testGoCommandMovetime() async {
        let serializer = await UCISerializer()

        let cmd = await serializer.serialize(.go(.movetime(1000)))
        #expect(cmd == "go movetime 1000")
    }

    @Test("Go command with infinite")
    func testGoCommandInfinite() async {
        let serializer = await UCISerializer()

        let cmd = await serializer.serialize(.go(.infinite))
        #expect(cmd == "go infinite")
    }

    @Test("SetOption command with value")
    func testSetOptionWithValue() async {
        let serializer = await UCISerializer()

        let cmd = await serializer.serialize(.setoption(id: "Hash", value: "128"))
        #expect(cmd == "setoption name Hash value 128")
    }

    @Test("SetOption command without value")
    func testSetOptionWithoutValue() async {
        let serializer = await UCISerializer()

        let cmd = await serializer.serialize(.setoption(id: "Clear Hash", value: nil))
        #expect(cmd == "setoption name Clear Hash")
    }

    // MARK: - GoParameters Tests

    @Test("GoParameters toCommands")
    func testGoParametersToCommands() {
        let params = GoParameters(
            depth: 15,
            wtime: 60000,
            btime: 60000,
            infinite: false
        )

        let commands = params.toCommands()

        #expect(commands.contains(.depth(15)))
        #expect(commands.contains(.wtime(60000)))
        #expect(commands.contains(.btime(60000)))
        #expect(!commands.contains(.infinite))
    }

    @Test("GoParameters description")
    func testGoParametersDescription() {
        let params = GoParameters(
            depth: 10,
            movetime: 1000
        )

        let description = params.description

        #expect(description.contains("depth 10"))
        #expect(description.contains("movetime 1000"))
    }

    // MARK: - UCI Error Tests

    @Test("UCIError description")
    func testUCIErrorDescription() {
        let parseError = UCIError.parseError("Invalid input")
        #expect(parseError.localizedDescription.contains("Invalid input"))

        let protocolError = UCIError.protocolError("Unexpected response")
        #expect(protocolError.localizedDescription.contains("Unexpected response"))

        let timeoutError = UCIError.timeout
        #expect(timeoutError.localizedDescription.contains("timeout"))
    }

    // MARK: - Integration Flow Tests

    @Test("Complete engine lifecycle flow")
    func testCompleteEngineLifecycle() async {
        let serializer = await UCISerializer()

        // 1. Start UCI
        let uci = await serializer.serialize(.uci)
        #expect(uci == "uci")

        // 2. Check ready
        let isready = await serializer.serialize(.isready)
        #expect(isready == "isready")

        // 3. Set position
        let position = await serializer.serialize(.position(fen: nil, moves: ["e2e4"]))
        #expect(position == "position startpos moves e2e4")

        // 4. Start search
        let go = await serializer.serialize(.go(.depth(10)))
        #expect(go == "go depth 10")

        // 5. Stop search
        let stop = await serializer.serialize(.stop)
        #expect(stop == "stop")

        // 6. New game
        let ucinewgame = await serializer.serialize(.ucinewgame)
        #expect(ucinewgame == "ucinewgame")

        // 7. Quit
        let quit = await serializer.serialize(.quit)
        #expect(quit == "quit")
    }

    @Test("Complex position with multiple moves")
    func testComplexPosition() async {
        let serializer = await UCISerializer()

        // Set up a complex position with FEN
        let fen = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1"
        let position = await serializer.serialize(.position(fen: fen, moves: ["b0c2", "b9c7"]))

        #expect(position.contains("fen"))
        #expect(position.contains(fen))
        #expect(position.contains("moves"))
        #expect(position.contains("b0c2"))
        #expect(position.contains("b9c7"))
    }
}
