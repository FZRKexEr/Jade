import Foundation

// MARK: - Mock Engine

/// A mock UCI engine for testing
public actor MockEngine {

    // MARK: - Properties

    public private(set) var isRunning = false
    public private(set) var isReady = false
    public private(set) var currentPosition: String?
    public private(set) var searchStarted = false
    public private(set) var searchStopped = false

    public var bestMoveToReturn: String = "e2e4"
    public var ponderMoveToReturn: String? = "e7e5"

    private var responses: [String] = []
    private var responseIndex = 0

    // MARK: - Initialization

    public init() {}

    // MARK: - UCI Commands

    public func uci() async {
        isRunning = true
        await addResponse("id name MockEngine")
        await addResponse("id author Test")
        await addResponse("uciok")
    }

    public func isReady() async {
        isReady = true
        await addResponse("readyok")
    }

    public func ucinewgame() async {
        currentPosition = nil
        searchStarted = false
        searchStopped = false
    }

    public func position(fen: String?, moves: [String]) async {
        if let fen = fen {
            currentPosition = fen
        } else {
            currentPosition = "startpos"
        }

        if !moves.isEmpty {
            // Store moves if needed
        }
    }

    public func go(
        depth: Int? = nil,
        movetime: Int? = nil,
        infinite: Bool = false
    ) async {
        searchStarted = true
        searchStopped = false

        // Simulate search time
        if let movetime = movetime {
            try? await Task.sleep(nanoseconds: UInt64(movetime) * 1_000_000)
        } else if depth != nil {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        // Send info before bestmove
        await addResponse("info depth 10 score cp 25")

        if searchStopped {
            await addResponse("bestmove 0000")
        } else {
            if let ponder = ponderMoveToReturn {
                await addResponse("bestmove \(bestMoveToReturn) ponder \(ponder)")
            } else {
                await addResponse("bestmove \(bestMoveToReturn)")
            }
        }
    }

    public func stop() async {
        searchStopped = true
    }

    public func ponderhit() async {
        // Continue search
    }

    public func setOption(name: String, value: String?) async {
        // Store option if needed
    }

    public func quit() async {
        isRunning = false
        isReady = false
    }

    // MARK: - Response Management

    private func addResponse(_ response: String) {
        responses.append(response)
    }

    public func getNextResponse() -> String? {
        guard responseIndex < responses.count else {
            return nil
        }
        let response = responses[responseIndex]
        responseIndex += 1
        return response
    }

    public func resetResponses() {
        responses.removeAll()
        responseIndex = 0
    }

    public var hasMoreResponses: Bool {
        responseIndex < responses.count
    }

    // MARK: - Test Configuration

    public func configureForCheckmateResponse() {
        bestMoveToReturn = "a1a9"
        ponderMoveToReturn = nil
    }

    public func configureForDrawResponse() {
        bestMoveToReturn = "a1a1"
        ponderMoveToReturn = nil
    }

    public func configureForErrorResponse() {
        Task {
            await addResponse("info string Error in evaluation")
            await addResponse("bestmove 0000")
        }
    }
}

// MARK: - Mock Engine Errors

public enum MockEngineError: Error, Equatable {
    case notRunning
    case alreadySearching
    case invalidPosition
    case communicationError(String)
}

// MARK: - Async Testing Helpers

extension MockEngine {

    /// Waits for a condition to be true with timeout
    public func waitFor(
        timeout: TimeInterval = 5.0,
        condition: () async -> Bool
    ) async -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if await condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        return false
    }

    /// Waits for the engine to be ready
    public func waitForReady(timeout: TimeInterval = 5.0) async -> Bool {
        await waitFor(timeout: timeout) { [self] in
            await isReady
        }
    }

    /// Waits for search to complete
    public func waitForSearchComplete(timeout: TimeInterval = 30.0) async -> Bool {
        await waitFor(timeout: timeout) { [self] in
            let started = await searchStarted
            let stopped = await searchStopped
            return started && stopped
        }
    }
}
