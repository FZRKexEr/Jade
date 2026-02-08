import Testing
@testable import Engine

/// Tests for UCI protocol parser
@Suite("UCI Parser Tests")
struct UCIParserTests {

    var parser: UCIParser!

    init() async {
        parser = await UCIParser()
    }

    // MARK: - Basic Response Tests

    @Test("Parse uciok response")
    func testParseUciok() async throws {
        let response = try await parser.parse("uciok")

        if case .uciok = response {
            // Success
        } else {
            Issue.record("Expected uciok, got \(response)")
        }
    }

    @Test("Parse readyok response")
    func testParseReadyok() async throws {
        let response = try await parser.parse("readyok")

        if case .readyok = response {
            // Success
        } else {
            Issue.record("Expected readyok, got \(response)")
        }
    }

    // MARK: - ID Response Tests

    @Test("Parse id name response")
    func testParseIdName() async throws {
        let response = try await parser.parse("id name Stockfish 16")

        if case .id(let info) = response {
            #expect(info.name == "Stockfish 16")
            #expect(info.author == nil)
        } else {
            Issue.record("Expected id response, got \(response)")
        }
    }

    @Test("Parse id author response")
    func testParseIdAuthor() async throws {
        let response = try await parser.parse("id author T. Romstad, M. Costalba, J. Kiiski, G. Linscott")

        if case .id(let info) = response {
            #expect(info.name == nil)
            #expect(info.author == "T. Romstad, M. Costalba, J. Kiiski, G. Linscott")
        } else {
            Issue.record("Expected id response, got \(response)")
        }
    }

    // MARK: - Bestmove Response Tests

    @Test("Parse bestmove response")
    func testParseBestmove() async throws {
        let response = try await parser.parse("bestmove e2e4")

        if case .bestmove(let move, let ponder) = response {
            #expect(move == "e2e4")
            #expect(ponder == nil)
        } else {
            Issue.record("Expected bestmove response, got \(response)")
        }
    }

    @Test("Parse bestmove with ponder")
    func testParseBestmoveWithPonder() async throws {
        let response = try await parser.parse("bestmove e2e4 ponder e7e5")

        if case .bestmove(let move, let ponder) = response {
            #expect(move == "e2e4")
            #expect(ponder == "e7e5")
        } else {
            Issue.record("Expected bestmove response, got \(response)")
        }
    }

    // MARK: - Info Response Tests

    @Test("Parse info depth")
    func testParseInfoDepth() async throws {
        let response = try await parser.parse("info depth 15")

        if case .info(let data) = response {
            #expect(data.depth == 15)
        } else {
            Issue.record("Expected info response, got \(response)")
        }
    }

    @Test("Parse info score")
    func testParseInfoScore() async throws {
        let response = try await parser.parse("info score cp 34")

        if case .info(let data) = response {
            if case .cp(let value) = data.score {
                #expect(value == 34)
            } else {
                Issue.record("Expected score cp")
            }
        } else {
            Issue.record("Expected info response, got \(response)")
        }
    }

    @Test("Parse info pv")
    func testParseInfoPV() async throws {
        let response = try await parser.parse("info pv e2e4 e7e5 g1f3")

        if case .info(let data) = response {
            #expect(data.pv == ["e2e4", "e7e5", "g1f3"])
        } else {
            Issue.record("Expected info response, got \(response)")
        }
    }

    @Test("Parse complex info")
    func testParseComplexInfo() async throws {
        let line = "info depth 10 seldepth 15 multipv 1 score cp 25 nodes 1234567 nps 1500000 hashfull 450 time 823 pv e2e4 e7e5 g1f3 b8c6 f1b5"
        let response = try await parser.parse(line)

        if case .info(let data) = response {
            #expect(data.depth == 10)
            #expect(data.seldepth == 15)
            #expect(data.multipv == 1)
            #expect(data.nodes == 1234567)
            #expect(data.nps == 1500000)
            #expect(data.hashfull == 450)
            #expect(data.time == 823)
            #expect(data.pv?.count == 5)
        } else {
            Issue.record("Expected info response, got \(response)")
        }
    }

    // MARK: - Option Response Tests

    @Test("Parse option check")
    func testParseOptionCheck() async throws {
        let response = try await parser.parse("option name Ponder type check default true")

        if case .option(let config) = response {
            #expect(config.name == "Ponder")
            #expect(config.type == .check)
            #expect(config.defaultValue == "true")
        } else {
            Issue.record("Expected option response, got \(response)")
        }
    }

    @Test("Parse option spin")
    func testParseOptionSpin() async throws {
        let response = try await parser.parse("option name Hash type spin default 16 min 1 max 33554432")

        if case .option(let config) = response {
            #expect(config.name == "Hash")
            #expect(config.type == .spin)
            #expect(config.defaultValue == "16")
            #expect(config.min == 1)
            #expect(config.max == 33554432)
        } else {
            Issue.record("Expected option response, got \(response)")
        }
    }

    @Test("Parse option combo")
    func testParseOptionCombo() async throws {
        let response = try await parser.parse("option name UCI_Variant type combo default chess var chess var xiangqi")

        if case .option(let config) = response {
            #expect(config.name == "UCI_Variant")
            #expect(config.type == .combo)
            #expect(config.defaultValue == "chess")
            #expect(config.varOptions == ["chess", "xiangqi"])
        } else {
            Issue.record("Expected option response, got \(response)")
        }
    }

    // MARK: - Error Tests

    @Test("Parse empty line throws error")
    func testParseEmptyLine() async {
        do {
            _ = try await parser.parse("")
            Issue.record("Expected error for empty line")
        } catch {
            // Expected
        }
    }

    @Test("Parse unknown command throws error")
    func testParseUnknownCommand() async {
        do {
            _ = try await parser.parse("unknown command")
            Issue.record("Expected error for unknown command")
        } catch {
            // Expected
        }
    }
}

// MARK: - UCI Command Serialization Tests

@Suite("UCI Command Serialization Tests")
struct UCICommandSerializationTests {

    var serializer: UCISerializer!

    init() async {
        serializer = await UCISerializer()
    }

    @Test("Serialize uci command")
    func testSerializeUci() async {
        let result = await serializer.serialize(.uci)
        #expect(result == "uci")
    }

    @Test("Serialize isready command")
    func testSerializeIsready() async {
        let result = await serializer.serialize(.isready)
        #expect(result == "isready")
    }

    @Test("Serialize quit command")
    func testSerializeQuit() async {
        let result = await serializer.serialize(.quit)
        #expect(result == "quit")
    }

    @Test("Serialize ucinewgame command")
    func testSerializeUcinewgame() async {
        let result = await serializer.serialize(.ucinewgame)
        #expect(result == "ucinewgame")
    }

    @Test("Serialize debug on command")
    func testSerializeDebugOn() async {
        let result = await serializer.serialize(.debug(true))
        #expect(result == "debug on")
    }

    @Test("Serialize debug off command")
    func testSerializeDebugOff() async {
        let result = await serializer.serialize(.debug(false))
        #expect(result == "debug off")
    }

    @Test("Serialize setoption with value")
    func testSerializeSetoptionWithValue() async {
        let result = await serializer.serialize(.setoption(id: "Hash", value: "128"))
        #expect(result == "setoption name Hash value 128")
    }

    @Test("Serialize setoption without value")
    func testSerializeSetoptionWithoutValue() async {
        let result = await serializer.serialize(.setoption(id: "Clear Hash", value: nil))
        #expect(result == "setoption name Clear Hash")
    }

    @Test("Serialize position startpos")
    func testSerializePositionStartpos() async {
        let result = await serializer.serialize(.position(fen: nil, moves: []))
        #expect(result == "position startpos")
    }

    @Test("Serialize position startpos with moves")
    func testSerializePositionStartposWithMoves() async {
        let result = await serializer.serialize(.position(fen: nil, moves: ["e2e4", "e7e5"]))
        #expect(result == "position startpos moves e2e4 e7e5")
    }

    @Test("Serialize position with FEN")
    func testSerializePositionWithFEN() async {
        let fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
        let result = await serializer.serialize(.position(fen: fen, moves: []))
        #expect(result == "position fen \(fen)")
    }

    @Test("Serialize stop command")
    func testSerializeStop() async {
        let result = await serializer.serialize(.stop)
        #expect(result == "stop")
    }

    @Test("Serialize ponderhit command")
    func testSerializePonderhit() async {
        let result = await serializer.serialize(.ponderhit)
        #expect(result == "ponderhit")
    }

    @Test("Serialize go depth")
    func testSerializeGoDepth() async {
        let result = await serializer.serialize(.go(.depth(15)))
        #expect(result == "go depth 15")
    }

    @Test("Serialize go infinite")
    func testSerializeGoInfinite() async {
        let result = await serializer.serialize(.go(.infinite))
        #expect(result == "go infinite")
    }

    @Test("Serialize go movetime")
    func testSerializeGoMovetime() async {
        let result = await serializer.serialize(.go(.movetime(1000)))
        #expect(result == "go movetime 1000")
    }
}
