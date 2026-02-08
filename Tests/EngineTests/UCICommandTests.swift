import Testing
@testable import Engine

/// UCI Command Tests
/// Tests for UCI command serialization
@Suite("UCI Command Tests")
struct UCICommandTests {

    // MARK: - Engine Control Tests

    @Test("UCI command serializes to 'uci'")
    func testUCICommand() {
        let command = UCICommand.uci
        #expect(command.description == "uci")
    }

    @Test("isready command serializes to 'isready'")
    func testIsreadyCommand() {
        let command = UCICommand.isready
        #expect(command.description == "isready")
    }

    @Test("ucinewgame command serializes to 'ucinewgame'")
    func testUcinewgameCommand() {
        let command = UCICommand.ucinewgame
        #expect(command.description == "ucinewgame")
    }

    @Test("quit command serializes to 'quit'")
    func testQuitCommand() {
        let command = UCICommand.quit
        #expect(command.description == "quit")
    }

    // MARK: - Debug Tests

    @Test("debug on command")
    func testDebugOn() {
        let command = UCICommand.debug(true)
        #expect(command.description == "debug on")
    }

    @Test("debug off command")
    func testDebugOff() {
        let command = UCICommand.debug(false)
        #expect(command.description == "debug off")
    }

    // MARK: - SetOption Tests

    @Test("setoption with value")
    func testSetOptionWithValue() {
        let command = UCICommand.setoption(id: "Hash", value: "128")
        #expect(command.description == "setoption name Hash value 128")
    }

    @Test("setoption without value")
    func testSetOptionWithoutValue() {
        let command = UCICommand.setoption(id: "Clear Hash", value: nil)
        #expect(command.description == "setoption name Clear Hash")
    }

    @Test("setoption with complex name")
    func testSetOptionComplexName() {
        let command = UCICommand.setoption(id: "UCI_Variant", value: "xiangqi")
        #expect(command.description == "setoption name UCI_Variant value xiangqi")
    }

    // MARK: - Position Tests

    @Test("position with startpos")
    func testPositionStartpos() {
        let command = UCICommand.position(fen: nil, moves: [])
        #expect(command.description == "position startpos")
    }

    @Test("position with startpos and moves")
    func testPositionStartposWithMoves() {
        let command = UCICommand.position(fen: nil, moves: ["e2e4", "e7e5", "g1f3"])
        #expect(command.description == "position startpos moves e2e4 e7e5 g1f3")
    }

    @Test("position with FEN")
    func testPositionWithFEN() {
        let fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
        let command = UCICommand.position(fen: fen, moves: [])
        #expect(command.description == "position fen \(fen)")
    }

    @Test("position with FEN and moves")
    func testPositionWithFENAndMoves() {
        let fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
        let command = UCICommand.position(fen: fen, moves: ["e7e5", "g1f3"])
        #expect(command.description == "position fen \(fen) moves e7e5 g1f3")
    }

    // MARK: - Go Tests

    @Test("go infinite")
    func testGoInfinite() {
        let command = UCICommand.go(.infinite)
        #expect(command.description == "go infinite")
    }

    @Test("go depth")
    func testGoDepth() {
        let command = UCICommand.go(.depth(15))
        #expect(command.description == "go depth 15")
    }

    @Test("go movetime")
    func testGoMovetime() {
        let command = UCICommand.go(.movetime(1000))
        #expect(command.description == "go movetime 1000")
    }

    @Test("go wtime and btime")
    func testGoWtimeBtime() {
        let params = GoParameters(
            wtime: 60000,
            btime: 60000
        )
        let command = UCICommand.go(.wtime(60000))

        // Test individual commands
        let wtimeCmd = UCICommand.go(.wtime(60000))
        let btimeCmd = UCICommand.go(.btime(60000))

        #expect(wtimeCmd.description == "go wtime 60000")
        #expect(btimeCmd.description == "go btime 60000")
    }

    @Test("go nodes")
    func testGoNodes() {
        let command = UCICommand.go(.nodes(1000000))
        #expect(command.description == "go nodes 1000000")
    }

    @Test("go mate")
    func testGoMate() {
        let command = UCICommand.go(.mate(5))
        #expect(command.description == "go mate 5")
    }

    @Test("go ponder")
    func testGoPonder() {
        let command = UCICommand.go(.ponder)
        #expect(command.description == "go ponder")
    }

    // MARK: - Stop and Ponderhit Tests

    @Test("stop command")
    func testStopCommand() {
        let command = UCICommand.stop
        #expect(command.description == "stop")
    }

    @Test("ponderhit command")
    func testPonderhitCommand() {
        let command = UCICommand.ponderhit
        #expect(command.description == "ponderhit")
    }

    // MARK: - Complex Command Tests

    @Test("Complex go parameters")
    func testComplexGoParameters() {
        let params = GoParameters(
            depth: 20,
            wtime: 60000,
            btime: 60000,
            winc: 100,
            binc: 100,
            movestogo: 40
        )

        // Verify all parameters are set
        #expect(params.depth == 20)
        #expect(params.wtime == 60000)
        #expect(params.btime == 60000)
        #expect(params.winc == 100)
        #expect(params.binc == 100)
        #expect(params.movestogo == 40)
    }

    @Test("GoParameters toCommands conversion")
    func testGoParametersToCommands() {
        let params = GoParameters(
            searchmoves: ["e2e4", "d2d4"],
            depth: 15,
            nodes: 1000000,
            mate: 5,
            movetime: 1000
        )

        let commands = params.toCommands()

        // Check specific commands exist
        #expect(commands.contains(.depth(15)))
        #expect(commands.contains(.nodes(1000000)))
        #expect(commands.contains(.mate(5)))
        #expect(commands.contains(.movetime(1000)))
    }
}
