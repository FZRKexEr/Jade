import Foundation
import OSLog

// MARK: - Engine Configuration

/// Configuration for chess engine
public struct EngineConfiguration: Sendable, Equatable, Codable {
    public let id: UUID
    public let name: String
    public let executablePath: String
    public let workingDirectory: String?
    public let arguments: [String]
    public let defaultOptions: [String: String]
    public let supportedVariants: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        executablePath: String,
        workingDirectory: String? = nil,
        arguments: [String] = [],
        defaultOptions: [String: String] = [:],
        supportedVariants: [String] = ["chess"]
    ) {
        self.id = id
        self.name = name
        self.executablePath = executablePath
        self.workingDirectory = workingDirectory
        self.arguments = arguments
        self.defaultOptions = defaultOptions
        self.supportedVariants = supportedVariants
    }

    /// Default Pikafish configuration for Xiangqi
    public static let pikafishDefault: EngineConfiguration = {
        // Determine architecture
        let arch = getMachineArchitecture()
        let binaryName = "pikafish-\(arch)"

        return EngineConfiguration(
            id: UUID(),
            name: "Pikafish",
            executablePath: "/usr/local/bin/\(binaryName)",
            workingDirectory: nil,
            arguments: [],
            defaultOptions: [
                "Hash": "256",
                "Threads": "4",
                "UCI_Variant": "xiangqi"
            ],
            supportedVariants: ["xiangqi", "chess"]
        )
    }()

    /// Determine if the executable exists at the configured path
    public func executableExists() -> Bool {
        FileManager.default.isExecutableFile(atPath: executablePath)
    }
}

// Helper function to get machine architecture
private func getMachineArchitecture() -> String {
    #if arch(x86_64)
    return "x86-64"
    #elseif arch(arm64)
    return "apple-silicon"
    #else
    return "modern"
    #endif
}

// MARK: - Process Output Handler

/// Delegate protocol for process output handling
public protocol EngineProcessOutputDelegate: AnyObject {
    func processDidReceiveOutput(_ line: String)
    func processDidReceiveError(_ line: String)
    func processDidTerminate(exitCode: Int32)
}

// MARK: - Engine Process Manager

/// Manages the chess engine process lifecycle and communication
public actor EngineProcessManager {
    // MARK: - Properties

    private let configuration: EngineConfiguration
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?

    private let logger = Logger(subsystem: "com.chinesechess", category: "EngineProcessManager")
    private var outputDelegate: EngineProcessOutputDelegate?

    /// Current process state
    private(set) public var isRunning: Bool = false

    // MARK: - Initialization

    public init(configuration: EngineConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Lifecycle Control

    /// Start the engine process
    public func start() async throws {
        guard !isRunning else {
            throw UCIError.engineAlreadyRunning
        }

        // Validate executable path
        guard FileManager.default.fileExists(atPath: configuration.executablePath) else {
            throw UCIError.invalidPath(configuration.executablePath)
        }

        guard FileManager.default.isExecutableFile(atPath: configuration.executablePath) else {
            throw UCIError.invalidPath("Not executable: \(configuration.executablePath)")
        }

        logger.info("Starting engine: \(self.configuration.name) at \(self.configuration.executablePath)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: configuration.executablePath)
        process.arguments = configuration.arguments

        if let workingDirectory = configuration.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }

        // Setup pipes
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Setup output handling
        setupOutputHandling(outputPipe: outputPipe, errorPipe: errorPipe)

        // Setup termination handler
        process.terminationHandler = { [weak self] proc in
            Task { [weak self] in
                await self?.handleProcessTermination(exitCode: proc.terminationStatus)
            }
        }

        // Start process
        do {
            try process.run()
        } catch {
            throw UCIError.processLaunchFailed(error)
        }

        self.process = process
        self.inputPipe = inputPipe
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
        self.isRunning = true

        logger.info("Engine process started successfully")
    }

    /// Stop the engine process
    public func stop() async {
        guard isRunning, let process = process else {
            return
        }

        logger.info("Stopping engine process")

        // Send quit command if possible
        do {
            try await sendCommand("quit\n")
            // Give it a moment to shut down gracefully
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
        } catch {
            logger.warning("Failed to send quit command: \(error.localizedDescription)")
        }

        // Force terminate if still running
        if process.isRunning {
            process.terminate()

            // Wait a bit for termination
            let deadline = Date().addingTimeInterval(2.0)
            while process.isRunning && Date() < deadline {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }

            // Force kill if still running
            if process.isRunning {
                process.terminate() // Use terminate() which sends SIGTERM
                // If needed, could use kill(pid, SIGKILL) via lower-level API
            }
        }

        // Clean up
        cleanup()
    }

    /// Send a command to the engine process
    public func sendCommand(_ command: String) async throws {
        guard isRunning, let inputPipe = inputPipe else {
            throw UCIError.engineNotStarted
        }

        let data = command.data(using: .utf8)!

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                inputPipe.fileHandleForWriting.write(data)
                continuation.resume()
            }
        }
    }

    /// Set the output delegate
    public func setOutputDelegate(_ delegate: EngineProcessOutputDelegate?) {
        self.outputDelegate = delegate
    }

    // MARK: - Private Methods

    private func setupOutputHandling(outputPipe: Pipe, errorPipe: Pipe) {
        // Setup stdout handling
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let line = String(data: data, encoding: .utf8) else { return }

            // Handle each line
            line.components(separatedBy: .newlines).forEach { outputLine in
                let trimmed = outputLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }

                Task { [weak self] in
                    await self?.handleOutput(trimmed)
                }
            }
        }

        // Setup stderr handling
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let line = String(data: data, encoding: .utf8) else { return }

            line.components(separatedBy: .newlines).forEach { errorLine in
                let trimmed = errorLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }

                Task { [weak self] in
                    await self?.handleError(trimmed)
                }
            }
        }
    }

    private func handleOutput(_ line: String) {
        logger.debug("Engine output: \(line)")
        outputDelegate?.processDidReceiveOutput(line)
    }

    private func handleError(_ line: String) {
        logger.warning("Engine error: \(line)")
        outputDelegate?.processDidReceiveError(line)
    }

    private func handleProcessTermination(exitCode: Int32) {
        logger.info("Engine process terminated with exit code: \(exitCode)")

        isRunning = false

        if exitCode != 0 {
            logger.error("Engine process terminated abnormally")
        }

        outputDelegate?.processDidTerminate(exitCode: exitCode)
    }

    private func cleanup() {
        process = nil
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
        isRunning = false

        logger.info("Engine process resources cleaned up")
    }
}

// MARK: - Engine Process Output Buffer

/// Actor to buffer process output for synchronous reading
public actor EngineProcessOutputBuffer {
    private var outputLines: [String] = []
    private var errorLines: [String] = []
    private var continuation: CheckedContinuation<String?, Never>?

    public init() {}

    public func readLine() async -> String? {
        // Check if there's already output available
        if !outputLines.isEmpty {
            return outputLines.removeFirst()
        }

        // Wait for new output
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    // MARK: - Internal Methods for Delegate

    internal func addOutput(_ line: String) {
        if let continuation = continuation {
            self.continuation = nil
            continuation.resume(returning: line)
        } else {
            outputLines.append(line)
        }
    }

    internal func addError(_ line: String) {
        errorLines.append(line)
    }

    internal func setTerminated(exitCode: Int32) {
        if let continuation = continuation {
            self.continuation = nil
            continuation.resume(returning: nil)
        }
    }

    /// Get all accumulated errors
    public func getErrors() -> [String] {
        let errors = errorLines
        errorLines.removeAll()
        return errors
    }
}

// MARK: - EngineProcessOutputBuffer + EngineProcessOutputDelegate

extension EngineProcessOutputBuffer: EngineProcessOutputDelegate {
    nonisolated public func processDidReceiveOutput(_ line: String) {
        Task { await addOutput(line) }
    }

    nonisolated public func processDidReceiveError(_ line: String) {
        Task { await addError(line) }
    }

    nonisolated public func processDidTerminate(exitCode: Int32) {
        Task { await setTerminated(exitCode: exitCode) }
    }
}
