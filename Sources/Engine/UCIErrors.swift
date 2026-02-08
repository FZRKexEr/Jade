import Foundation

// MARK: - UCI Error Types

/// UCI protocol related errors
public enum UCIError: Error, LocalizedError, Equatable {
    // Engine state errors
    case engineNotStarted
    case engineAlreadyRunning
    case engineNotReady
    case engineCrashed

    // Communication errors
    case communicationFailed(Error)
    case writeFailed(Error)
    case readFailed(Error)
    case timeout(Duration)
    case invalidResponse(String)
    case parseError(String)
    case commandFailed(String)

    // State transition errors
    case invalidStateTransition(from: String, to: String)
    case invalidCommandForState(String, String)

    // Configuration errors
    case invalidPath(String)
    case invalidOption(String)
    case unsupportedVariant(String)

    // Process errors
    case processLaunchFailed(Error)
    case processTerminated(Int32)
    case processKilled

    public var errorDescription: String? {
        switch self {
        case .engineNotStarted:
            return "Engine process has not been started"
        case .engineAlreadyRunning:
            return "Engine process is already running"
        case .engineNotReady:
            return "Engine is not ready to receive commands"
        case .engineCrashed:
            return "Engine process has crashed"
        case .communicationFailed(let error):
            return "Communication failed: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to write to engine: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read from engine: \(error.localizedDescription)"
        case .timeout(let duration):
            return "Operation timed out after \(duration) seconds"
        case .invalidResponse(let response):
            return "Invalid response from engine: \(response)"
        case .parseError(let line):
            return "Failed to parse response: \(line)"
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .invalidStateTransition(let from, let to):
            return "Invalid state transition from \(from) to \(to)"
        case .invalidCommandForState(let command, let state):
            return "Command '\(command)' is not valid in state '\(state)'"
        case .invalidPath(let path):
            return "Invalid executable path: \(path)"
        case .invalidOption(let option):
            return "Invalid option: \(option)"
        case .unsupportedVariant(let variant):
            return "Unsupported chess variant: \(variant)"
        case .processLaunchFailed(let error):
            return "Failed to launch engine process: \(error.localizedDescription)"
        case .processTerminated(let code):
            return "Engine process terminated with exit code: \(code)"
        case .processKilled:
            return "Engine process was killed"
        }
    }

    public static func == (lhs: UCIError, rhs: UCIError) -> Bool {
        switch (lhs, rhs) {
        case (.engineNotStarted, .engineNotStarted),
             (.engineAlreadyRunning, .engineAlreadyRunning),
             (.engineNotReady, .engineNotReady),
             (.engineCrashed, .engineCrashed),
             (.processKilled, .processKilled):
            return true
        case (.communicationFailed(let lhsError), .communicationFailed(let rhsError)),
             (.writeFailed(let lhsError), .writeFailed(let rhsError)),
             (.readFailed(let lhsError), .readFailed(let rhsError)),
             (.processLaunchFailed(let lhsError), .processLaunchFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.timeout(let lhsDuration), .timeout(let rhsDuration)):
            return lhsDuration == rhsDuration
        case (.invalidResponse(let lhsResponse), .invalidResponse(let rhsResponse)):
            return lhsResponse == rhsResponse
        case (.parseError(let lhsLine), .parseError(let rhsLine)):
            return lhsLine == rhsLine
        case (.commandFailed(let lhsMsg), .commandFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.invalidStateTransition(let lhsFrom, let lhsTo), .invalidStateTransition(let rhsFrom, let rhsTo)):
            return lhsFrom == rhsFrom && lhsTo == rhsTo
        case (.invalidCommandForState(let lhsCmd, let lhsState), .invalidCommandForState(let rhsCmd, let rhsState)):
            return lhsCmd == rhsCmd && lhsState == rhsState
        case (.invalidPath(let lhsPath), .invalidPath(let rhsPath)):
            return lhsPath == rhsPath
        case (.invalidOption(let lhsOpt), .invalidOption(let rhsOpt)):
            return lhsOpt == rhsOpt
        case (.unsupportedVariant(let lhsVar), .unsupportedVariant(let rhsVar)):
            return lhsVar == rhsVar
        case (.processTerminated(let lhsCode), .processTerminated(let rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
}

// MARK: - Engine State

/// Engine process state
public enum EngineState: Equatable, CustomStringConvertible, Sendable {
    case idle
    case initializing
    case ready
    case searching
    case pondering
    case error(String)

    public var description: String {
        switch self {
        case .idle: return "idle"
        case .initializing: return "initializing"
        case .ready: return "ready"
        case .searching: return "searching"
        case .pondering: return "pondering"
        case .error(let message): return "error: \(message)"
        }
    }

    public var isRunning: Bool {
        switch self {
        case .idle, .error:
            return false
        case .initializing, .ready, .searching, .pondering:
            return true
        }
    }

    public var canAcceptCommands: Bool {
        switch self {
        case .ready, .searching, .pondering:
            return true
        default:
            return false
        }
    }
}

// MARK: - Timeout Configuration

/// Timeout configuration for UCI operations
public struct UCITimeoutConfiguration: Sendable {
    public let initializationTimeout: Duration
    public let commandTimeout: Duration
    public let searchTimeout: Duration
    public let shutdownTimeout: Duration

    public init(
        initializationTimeout: Duration = .seconds(10),
        commandTimeout: Duration = .seconds(5),
        searchTimeout: Duration = .seconds(30),
        shutdownTimeout: Duration = .seconds(5)
    ) {
        self.initializationTimeout = initializationTimeout
        self.commandTimeout = commandTimeout
        self.searchTimeout = searchTimeout
        self.shutdownTimeout = shutdownTimeout
    }

    public static let `default` = UCITimeoutConfiguration()
    public static let relaxed = UCITimeoutConfiguration(
        initializationTimeout: .seconds(30),
        commandTimeout: .seconds(10),
        searchTimeout: .seconds(60),
        shutdownTimeout: .seconds(10)
    )
}
