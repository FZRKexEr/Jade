import Foundation

// MARK: - Engine Manager Usage Examples

/// Examples demonstrating how to use the UCI engine manager
public enum EngineUsageExamples {

    // MARK: - Basic Engine Lifecycle

    /// Example: Initialize and shutdown engine
    public static func basicLifecycle() async {
        // Create engine configuration (using Pikafish defaults)
        let config = EngineConfiguration.pikafishDefault

        // Create engine manager
        let engineManager = EngineManager(configuration: config)

        do {
            // Initialize the engine (starts process, sends uci, etc.)
            try await engineManager.initialize()
            print("Engine initialized successfully")

            // Check engine state
            let state = await engineManager.state
            print("Engine state: \(state)")

            // Get engine capabilities
            if let caps = await engineManager.capabilities {
                print("Engine: \(caps.name ?? "Unknown")")
                print("Author: \(caps.author ?? "Unknown")")
                print("Options: \(caps.options.count)")
            }

            // Shutdown the engine
            await engineManager.shutdown()
            print("Engine shutdown complete")

        } catch {
            print("Engine error: \(error.localizedDescription)")
        }
    }

    // MARK: - Search Operations

    /// Example: Set position and search
    public static func positionSearch(engineManager: EngineManager) async throws {
        // Set starting position
        try await engineManager.setPosition(fen: nil, moves: [])

        // Search with time control
        let params = GoParameters(
            wtime: 60000,  // White has 60 seconds
            btime: 60000,  // Black has 60 seconds
            winc: 1000,    // 1 second increment
            binc: 1000
        )

        try await engineManager.startSearch(parameters: params)

        // Wait for some time then stop
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

        try await engineManager.stopSearch()
    }

    /// Example: Search specific position with FEN
    public static func searchFEN(engineManager: EngineManager) async throws {
        // Ruy Lopez position
        let fen = "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3"

        try await engineManager.setPosition(fen: fen, moves: [])

        // Search at depth 20
        let params = GoParameters(depth: 20)
        try await engineManager.startSearch(parameters: params)
    }

    // MARK: - Engine Options

    /// Example: Configure engine options
    public static func configureEngine(engineManager: EngineManager) async throws {
        // Set hash table size
        try await engineManager.setOption(name: "Hash", value: "512")

        // Set number of threads
        try await engineManager.setOption(name: "Threads", value: "8")

        // Enable/Disable pondering
        try await engineManager.setOption(name: "Ponder", value: "false")

        // Set engine to Xiangqi mode (for Pikafish)
        try await engineManager.setOption(name: "UCI_Variant", value: "xiangqi")
    }

    // MARK: - Game Operations

    /// Example: Start a new game
    public static func startNewGame(engineManager: EngineManager) async throws {
        // Notify engine of new game
        try await engineManager.newGame()

        // Set starting position
        try await engineManager.setPosition(fen: nil, moves: [])
    }

    /// Example: Play a sequence of moves
    public static func playMoves(engineManager: EngineManager) async throws {
        // Starting position with moves
        let moves = ["e2e4", "e7e5", "g1f3", "b8c6", "f1b5"]

        try await engineManager.setPosition(fen: nil, moves: moves)
    }

    // MARK: - Complete Example

    /// Complete example: Play a game against the engine
    public static func playAgainstEngine() async {
        // Configuration for playing
        let config = EngineConfiguration(
            name: "Pikafish",
            executablePath: "/usr/local/bin/pikafish",
            defaultOptions: [
                "Hash": "256",
                "Threads": "4",
                "UCI_Variant": "xiangqi"
            ],
            supportedVariants: ["xiangqi"]
        )

        let engine = EngineManager(configuration: config)

        do {
            // Initialize
            try await engine.initialize()
            print("Engine ready: \(await engine.capabilities?.name ?? "Unknown")")

            // Start new game
            try await engine.newGame()

            // Game loop simulation
            var currentMoves: [String] = []
            let maxMoves = 10

            for moveNumber in 1...maxMoves {
                print("\nMove \(moveNumber):")

                // Set position
                try await engine.setPosition(fen: nil, moves: currentMoves)

                // Search for best move
                let params = GoParameters(movetime: 1000) // 1 second per move
                try await engine.startSearch(parameters: params)

                // Wait for search to complete (in real implementation, use delegate)
                try await Task.sleep(nanoseconds: 1_200_000_000)

                try await engine.stopSearch()

                // In real implementation, you'd get the best move from the engine response
                // For now, simulate a move
                let moves = ["e2e4", "e7e5", "g1f3", "b8c6", "f1b5"]
                if moveNumber <= moves.count {
                    let move = moves[moveNumber - 1]
                    currentMoves.append(move)
                    print("Engine plays: \(move)")
                }
            }

            // Shutdown
            await engine.shutdown()
            print("\nGame complete!")

        } catch {
            print("Error: \(error.localizedDescription)")
            await engine.shutdown()
        }
    }
}
