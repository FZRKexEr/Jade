import Foundation
import OSLog

// MARK: - Engine Capabilities

/// Engine capabilities and information
public struct EngineCapabilities: Sendable, Equatable {
    public let name: String?
    public let author: String?
    public let options: [String: OptionConfig]
    public let availableVariants: [String]

    public init(
        name: String? = nil,
        author: String? = nil,
        options: [String: OptionConfig] = [:],
        availableVariants: [String] = []
    ) {
        self.name = name
        self.author = author
        self.options = options
        self.availableVariants = availableVariants
    }
}

// MARK: - Search Result

/// Result of a search operation
public struct SearchResult: Sendable, Equatable {
    public let bestMove: String
    public let ponderMove: String?
    public let info: InfoData?

    public init(bestMove: String, ponderMove: String? = nil, info: InfoData? = nil) {
        self.bestMove = bestMove
        self.ponderMove = ponderMove
        self.info = info
    }
}

// MARK: - Engine Manager Protocol

/// Protocol for engine manager
public protocol EngineManagerProtocol: Actor {
    var state: EngineState { get }
    var configuration: EngineConfiguration { get }
    var capabilities: EngineCapabilities? { get }

    /// Initialize the engine
    func initialize() async throws

    /// Shutdown the engine
    func shutdown() async

    /// Restart the engine
    func restart() async throws

    /// Send UCI command
    func sendUCI() async throws

    /// Check if engine is ready
    func checkReady() async throws

    /// Set option
    func setOption(name: String, value: String) async throws

    /// Set position
    func setPosition(fen: String?, moves: [String]) async throws

    /// Start search
    func startSearch(parameters: GoParameters) async throws

    /// Stop search
    func stopSearch() async throws

    /// Send ponder hit
    func ponderHit() async throws

    /// Start new game
    func newGame() async throws

    /// Quit engine
    func quit() async throws
}

// MARK: - Engine Manager Implementation

/// Manages chess engine lifecycle and UCI communication
public actor EngineManager: EngineManagerProtocol {

    // MARK: - Properties

    public let configuration: EngineConfiguration
    private let timeoutConfig: UCITimeoutConfiguration

    private var processManager: EngineProcessManager?
    private var parser: UCIParser?
    private var serializer: UCISerializer?

    private(set) public var state: EngineState = .idle
    private(set) public var capabilities: EngineCapabilities?
    private(set) public var isRunning: Bool = false

    private var responseHandlers: [String: (UCIResponse) -> Bool] = [:]
    private var pendingContinuation: CheckedContinuation<UCIResponse?, Error>?

    private let logger = Logger(subsystem: "com.chinesechess", category: "EngineManager")

    // MARK: - Initialization

    public init(
        configuration: EngineConfiguration,
        timeoutConfig: UCITimeoutConfiguration = .default
    ) {
        self.configuration = configuration
        self.timeoutConfig = timeoutConfig
    }

    // MARK: - Lifecycle Control

    public func initialize() async throws {
        guard state == .idle else {
            throw UCIError.engineAlreadyRunning
        }

        logger.info("Initializing engine: \(self.configuration.name)")
        await transition(to: .initializing)

        do {
            // Create and start process manager
            let processManager = EngineProcessManager(configuration: configuration)
            await processManager.setOutputDelegate(self)
            try await processManager.start()

            self.processManager = processManager
            self.parser = UCIParser()
            self.serializer = UCISerializer()

            // Send UCI command and wait for uciok
            try await sendUCI()

            // Wait for uciok with timeout
            let uciokResponse = try await waitForResponse(
                timeout: timeoutConfig.initializationTimeout,
                predicate: { response in
                    if case .uciok = response {
                        return true
                    }
                    if case .option(let option) = response {
                        // Store option info
                        Task { [weak self] in
                            await self?.handleOptionResponse(option)
                        }
                    }
                    if case .id(let idInfo) = response {
                        Task { [weak self] in
                            await self?.handleIdResponse(idInfo)
                        }
                    }
                    return false
                }
            )

            guard uciokResponse != nil else {
                throw UCIError.timeout(timeoutConfig.initializationTimeout)
            }

            // Send default options
            for (name, value) in configuration.defaultOptions {
                try await setOption(name: name, value: value)
            }

            // Check if ready
            try await checkReady()

            await transition(to: .ready)
            logger.info("Engine initialized successfully")

        } catch {
            await transition(to: .error(error.localizedDescription))
            throw error
        }
    }

    public func shutdown() async {
        guard state != .idle else { return }

        logger.info("Shutting down engine")

        // Cancel any pending continuations
        if let continuation = pendingContinuation {
            pendingContinuation = nil
            continuation.resume(throwing: UCIError.engineNotStarted)
        }

        // Stop process
        if let processManager = processManager {
            await processManager.stop()
        }

        processManager = nil
        parser = nil
        serializer = nil
        capabilities = nil

        await transition(to: .idle)
        logger.info("Engine shutdown complete")
    }

    public func restart() async throws {
        await shutdown()
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        try await initialize()
    }

    // MARK: - UCI Commands

    public func sendUCI() async throws {
        try await sendCommand(.uci)
    }

    public func checkReady() async throws {
        try await sendCommand(.isready)

        let response = try await waitForResponse(
            timeout: timeoutConfig.commandTimeout,
            predicate: { response in
                if case .readyok = response {
                    return true
                }
                return false
            }
        )

        guard response != nil else {
            throw UCIError.timeout(timeoutConfig.commandTimeout)
        }
    }

    public func setOption(name: String, value: String) async throws {
        try await sendCommand(.setoption(id: name, value: value))
    }

    public func setPosition(fen: String?, moves: [String]) async throws {
        try await sendCommand(.position(fen: fen, moves: moves))
    }

    public func startSearch(parameters: GoParameters) async throws {
        guard state == .ready else {
            throw UCIError.invalidCommandForState("go", state.description)
        }

        // Convert GoParameters to GoCommands
        let commands = parameters.toCommands()
        try await sendCommand(.go(commands.first ?? .infinite))

        await transition(to: .searching)
    }

    public func stopSearch() async throws {
        guard state == .searching || state == .pondering else {
            return
        }

        try await sendCommand(.stop)
        await transition(to: .ready)
    }

    public func ponderHit() async throws {
        try await sendCommand(.ponderhit)
    }

    public func newGame() async throws {
        try await sendCommand(.ucinewgame)
    }

    public func quit() async throws {
        try await sendCommand(.quit)
        await shutdown()
    }

    // MARK: - Response Handling

    /// Wait for a response matching the predicate
    public func waitForResponse(
        timeout: Duration,
        predicate: @escaping (UCIResponse) -> Bool
    ) async throws -> UCIResponse? {
        let timeoutTask = Task {
            try await Task.sleep(for: timeout)
            return Optional<UCIResponse>.none
        }

        let responseTask = Task {
            while let response = await nextResponse() {
                if predicate(response) {
                    return response
                }
                // Store in handlers if not matched
                await handleResponse(response)
            }
            return Optional<UCIResponse>.none
        }

        // Race the tasks
        let result = await withTaskGroup(of: Optional<UCIResponse>.self) { group in
            group.addTask { await timeoutTask.value }
            group.addTask { await responseTask.value }

            // Return the first completed result
            if let first = await group.next() {
                // Cancel remaining tasks
                group.cancelAll()
                return first
            }
            return nil
        }

        return result
    }

    /// Get the next response (blocking)
    private func nextResponse() async -> UCIResponse? {
        return await withCheckedContinuation { continuation in
            pendingContinuation = continuation
        }
    }

    /// Handle a parsed response
    private func handleResponse(_ response: UCIResponse) async {
        // Handle specific responses
        switch response {
        case .id(let idInfo):
            await handleIdResponse(idInfo)
        case .option(let option):
            await handleOptionResponse(option)
        case .bestmove(let move, let ponder):
            await handleBestmoveResponse(move: move, ponder: ponder)
        default:
            break
        }
    }

    private func handleIdResponse(_ idInfo: IdInfo) async {
        var caps = capabilities ?? EngineCapabilities()
        caps = EngineCapabilities(
            name: idInfo.name ?? caps.name,
            author: idInfo.author ?? caps.author,
            options: caps.options,
            availableVariants: caps.availableVariants
        )
        capabilities = caps
    }

    private func handleOptionResponse(_ option: OptionConfig) async {
        var caps = capabilities ?? EngineCapabilities()
        var options = caps.options
        options[option.name] = option
        caps = EngineCapabilities(
            name: caps.name,
            author: caps.author,
            options: options,
            availableVariants: caps.availableVariants
        )
        capabilities = caps
    }

    private func handleBestmoveResponse(move: String, ponder: String?) async {
        if state == .searching || state == .pondering {
            Task {
                await transition(to: .ready)
            }
        }
    }

    // MARK: - Private Helper Methods

    private func sendCommand(_ command: UCICommand) async throws {
        guard let serializer = serializer else {
            throw UCIError.engineNotStarted
        }

        let commandString = await serializer.serialize(command)
        logger.debug("Sending command: \(commandString)")

        try await sendRawCommand(commandString + "\n")
    }

    private func sendRawCommand(_ command: String) async throws {
        guard isRunning, let processManager = processManager else {
            throw UCIError.engineNotStarted
        }

        try await processManager.sendCommand(command)
    }

    private func transition(to newState: EngineState) async {
        guard self.state != newState else { return }
        logger.debug("State transition: \(self.state.description) -> \(newState.description)")
        self.state = newState
    }
}

// MARK: - EngineManager + EngineProcessOutputDelegate

extension EngineManager: EngineProcessOutputDelegate {
    nonisolated public func processDidReceiveOutput(_ line: String) {
        Task {
            do {
                guard let parser = await parser else { return }
                let response = try await parser.parse(line)
                await receiveResponse(response)
            } catch {
                logger.warning("Failed to parse engine output: \(line), error: \(error.localizedDescription)")
            }
        }
    }

    nonisolated public func processDidReceiveError(_ line: String) {
        logger.error("Engine error: \(line)")
    }

    nonisolated public func processDidTerminate(exitCode: Int32) {
        logger.info("Engine process terminated with exit code: \(exitCode)")

        Task {
            await handleProcessTermination()
        }
    }

    private func receiveResponse(_ response: UCIResponse) async {
        // Resume pending continuation if any
        if let continuation = pendingContinuation {
            pendingContinuation = nil
            continuation.resume(returning: response)
            return
        }

        // Otherwise handle the response normally
        await handleResponse(response)
    }

    private func handleProcessTermination() async {
        isRunning = false

        // Resume any pending continuation with error
        if let continuation = pendingContinuation {
            pendingContinuation = nil
            continuation.resume(throwing: UCIError.processTerminated(0))
        }

        await transition(to: .error("Process terminated"))
    }
}
