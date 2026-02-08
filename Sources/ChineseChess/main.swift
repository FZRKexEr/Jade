import Foundation
import Engine

// MARK: - Example: Basic Engine Usage

@main
struct ChineseChessApp {
    static func main() async {
        print("Chinese Chess Engine UCI Protocol Demo")
        print("=====================================")

        // Example 1: Basic engine lifecycle
        await demonstrateBasicLifecycle()

        // Example 2: Parse UCI responses
        demonstrateParsing()

        print("\nDemo completed!")
    }

    // MARK: - Example 1: Basic Engine Lifecycle

    static func demonstrateBasicLifecycle() async {
        print("\n--- Example 1: Engine Lifecycle ---")

        // Create configuration
        let config = EngineConfiguration(
            name: "Pikafish",
            executablePath: "/usr/local/bin/pikafish",
            defaultOptions: [
                "Hash": "256",
                "Threads": "4"
            ],
            supportedVariants: ["xiangqi"]
        )

        print("Configuration created:")
        print("  Name: \(config.name)")
        print("  Path: \(config.executablePath)")
        print("  Options: \(config.defaultOptions)")

        // Create engine manager
        let engine = EngineManager(configuration: config)

        // Check if executable exists
        if config.executableExists() {
            print("\nExecutable found at: \(config.executablePath)")

            // Note: Actually starting the engine would require the executable
            // For demo purposes, we just show the code structure
            print("\nTo initialize the engine:")
            print("  try await engine.initialize()")

        } else {
            print("\nNote: Engine executable not found at \(config.executablePath)")
            print("This is expected for demo purposes.")
        }
    }

    // MARK: - Example 2: Parse UCI Responses

    static func demonstrateParsing() {
        print("\n--- Example 2: UCI Response Parsing ---")

        // Create a synchronous wrapper for parsing
        let parser = runParserSync()

        // Example responses
        let examples = [
            "id name Stockfish 16",
            "id author T. Romstad, M. Costalba, J. Kiiski, G. Linscott",
            "uciok",
            "readyok",
            "bestmove e2e4 ponder e7e5",
            "info depth 15 seldepth 20 multipv 1 score cp 34 nodes 1234567 nps 1500000 hashfull 450 time 823 pv e2e4 e7e5 g1f3 b8c6 f1b5",
            "option name Hash type spin default 16 min 1 max 33554432",
            "option name Ponder type check default true",
            "option name UCI_Variant type combo default chess var chess var xiangqi"
        ]

        for example in examples {
            print("\nInput: \(example)")

            if let response = parser(example) {
                print("Parsed: \(response)")
            } else {
                print("Failed to parse")
            }
        }
    }

    /// Helper to run parser synchronously for demo
    static func runParserSync() -> (String) -> UCIResponse? {
        return { line in
            // In actual async context, use await parser.parse(line)
            // For sync demo, we simulate the parsing

            let tokens = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard let command = tokens.first else { return nil }

            switch command {
            case "uciok":
                return .uciok
            case "readyok":
                return .readyok
            case "id":
                if tokens.count >= 2 {
                    let rest = tokens.dropFirst().joined(separator: " ")
                    if rest.hasPrefix("name ") {
                        return .id(IdInfo(name: String(rest.dropFirst(5))))
                    } else if rest.hasPrefix("author ") {
                        return .id(IdInfo(author: String(rest.dropFirst(7))))
                    }
                }
                return nil
            case "bestmove":
                if tokens.count >= 2 {
                    let move = tokens[1]
                    var ponder: String?
                    if tokens.count >= 4 && tokens[2] == "ponder" {
                        ponder = tokens[3]
                    }
                    return .bestmove(move, ponder: ponder)
                }
                return nil
            case "info":
                // Simplified info parsing for demo
                var depth: Int?
                var score: ScoreInfo?
                var pv: [String]?

                var i = 1
                while i < tokens.count {
                    if tokens[i] == "depth" && i + 1 < tokens.count {
                        depth = Int(tokens[i + 1])
                        i += 2
                    } else if tokens[i] == "score" && i + 2 < tokens.count {
                        if tokens[i + 1] == "cp", let val = Int(tokens[i + 2]) {
                            score = .cp(val)
                        }
                        i += 3
                    } else if tokens[i] == "pv" {
                        var pvMoves: [String] = []
                        i += 1
                        while i < tokens.count && !["depth", "seldepth", "time", "nodes", "score", "multipv"].contains(tokens[i]) {
                            pvMoves.append(tokens[i])
                            i += 1
                        }
                        pv = pvMoves
                    } else {
                        i += 1
                    }
                }

                return .info(InfoData(
                    depth: depth,
                    pv: pv,
                    score: score
                ))
            case "option":
                // Simplified option parsing for demo
                if let nameIndex = tokens.firstIndex(of: "name"),
                   let typeIndex = tokens.firstIndex(of: "type"),
                   nameIndex + 1 < typeIndex {
                    let name = tokens[(nameIndex + 1)..<typeIndex].joined(separator: " ")
                    let typeStr = tokens[typeIndex + 1]
                    let type = OptionType(rawValue: typeStr) ?? .string

                    return .option(OptionConfig(
                        name: name,
                        type: type
                    ))
                }
                return nil
            default:
                return nil
            }
        }
    }
}
