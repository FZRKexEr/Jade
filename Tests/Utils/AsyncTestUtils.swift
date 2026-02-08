import Foundation
import Testing

// MARK: - Async Test Utilities

/// Utilities for testing async code
public enum AsyncTestUtils {

    /// The default timeout for async operations
    public static let defaultTimeout: TimeInterval = 5.0

    /// The default poll interval for waiting
    public static let defaultPollInterval: TimeInterval = 0.01

    // MARK: - Timeout Helpers

    /// Executes an async operation with a timeout
    /// - Parameters:
    ///   - timeout: The maximum time to wait
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    /// - Throws: An error if the operation times out or fails
    public static func withTimeout<T>(
        timeout: TimeInterval = defaultTimeout,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the operation task
            group.addTask {
                try await operation()
            }

            // Add the timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AsyncTestError.timeout(duration: timeout)
            }

            // Return the first result and cancel the other
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    /// Waits for a condition to be true with timeout
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - pollInterval: How often to check the condition
    ///   - condition: The condition to wait for
    /// - Returns: True if condition was met, false if timed out
    public static func waitFor(
        timeout: TimeInterval = defaultTimeout,
        pollInterval: TimeInterval = defaultPollInterval,
        condition: () async -> Bool
    ) async -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if await condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        return false
    }

    /// Waits for an async condition to be true with timeout
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - pollInterval: How often to check the condition
    ///   - condition: The async condition to wait for
    /// - Returns: True if condition was met, false if timed out
    public static func waitFor(
        timeout: TimeInterval = defaultTimeout,
        pollInterval: TimeInterval = defaultPollInterval,
        condition: @escaping () async throws -> Bool
    ) async rethrows -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if try await condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        return false
    }

    // MARK: - Retry Helpers

    /// Retries an operation with exponential backoff
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts
    ///   - initialDelay: Initial delay between attempts
    ///   - maxDelay: Maximum delay between attempts
    ///   - operation: The operation to retry
    /// - Returns: The result of the operation
    /// - Throws: The last error if all attempts fail
    public static func retryWithBackoff<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 0.1,
        maxDelay: TimeInterval = 1.0,
        operation: () async throws -> T
    ) async rethrows -> T {
        var delay = initialDelay
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay = min(delay * 2, maxDelay)
                }
            }
        }

        throw lastError!
    }
}

// MARK: - Async Test Errors

/// Errors that can occur during async testing
public enum AsyncTestError: Error, Equatable, CustomStringConvertible {
    case timeout(duration: TimeInterval)
    case conditionNotMet
    case tooManyRetries

    public var description: String {
        switch self {
        case .timeout(let duration):
            return "Operation timed out after \(duration) seconds"
        case .conditionNotMet:
            return "Condition was not met within the specified time"
        case .tooManyRetries:
            return "Operation failed after maximum number of retries"
        }
    }

    public var localizedDescription: String {
        description
    }
}

// MARK: - Convenience Extensions

extension Task where Success == Never, Failure == Never {
    /// Sleeps for a specified time interval
    public static func sleep(timeInterval: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
    }
}

extension TimeInterval {
    /// Converts seconds to nanoseconds
    public var nanoseconds: UInt64 {
        UInt64(self * 1_000_000_000)
    }

    /// Converts seconds to milliseconds
    public var milliseconds: UInt64 {
        UInt64(self * 1_000)
    }
}
