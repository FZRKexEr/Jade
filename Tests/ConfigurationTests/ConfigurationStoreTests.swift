import Testing
import Foundation
@testable import ChineseChessKit

/// Configuration Store Tests
/// Tests for configuration storage and retrieval
@Suite("Configuration Store Tests")
struct ConfigurationStoreTests {

    // MARK: - UserDefaultsStore Tests

    @Test("Save and load configuration")
    func testSaveAndLoad() async throws {
        let store = UserDefaultsStore()
        let config = AppConfiguration(
            version: "1.0.0",
            engineConfigurations: [EngineConfiguration.pikafishDefault],
            uiConfiguration: UIConfiguration.default,
            gameConfiguration: GameConfiguration.default,
            isFirstLaunch: false
        )

        try await store.save(config)
        let loadedConfig = try await store.load()

        #expect(loadedConfig.version == "1.0.0")
        #expect(loadedConfig.isFirstLaunch == false)
    }

    @Test("Check configuration exists")
    func testExists() async throws {
        let store = UserDefaultsStore()

        // Initially should not exist
        let existsBefore = await store.exists()

        // Save configuration
        let config = AppConfiguration.default
        try await store.save(config)

        // Should exist now
        let existsAfter = await store.exists()
    }

    @Test("Delete configuration")
    func testDelete() async throws {
        let store = UserDefaultsStore()

        // Save configuration
        let config = AppConfiguration.default
        try await store.save(config)

        // Verify it exists
        #expect(await store.exists())

        // Delete it
        try await store.delete()

        // Verify it's gone
        #expect(await !store.exists())
    }

    @Test("Load non-existent configuration throws error")
    func testLoadNonExistent() async {
        let store = UserDefaultsStore()
        await store.delete() // Ensure no config exists

        do {
            _ = try await store.load()
            #expect(false, "Expected error to be thrown")
        } catch {
            // Expected error
            #expect(error is ConfigurationStoreError)
        }
    }

    // MARK: - AppConfiguration Tests

    @Test("Default configuration values")
    func testDefaultConfiguration() {
        let config = AppConfiguration.default

        #expect(config.version == AppConfiguration.currentVersion)
        #expect(config.isFirstLaunch == true)
        #expect(config.engineConfigurations.count == 1)
        #expect(config.recentGamePaths.isEmpty)
    }

    @Test("Add engine configuration")
    func testAddEngineConfiguration() {
        var config = AppConfiguration.default
        let newEngine = EngineConfiguration(
            name: "Test Engine",
            path: "/usr/local/bin/test"
        )

        config.addEngineConfiguration(newEngine)

        #expect(config.engineConfigurations.count == 2)
        #expect(config.engineConfigurations.contains { $0.name == "Test Engine" })
    }

    @Test("Remove engine configuration")
    func testRemoveEngineConfiguration() {
        var config = AppConfiguration.default
        let engine = EngineConfiguration.pikafishDefault

        // First add a second engine so we can remove one
        let newEngine = EngineConfiguration(
            name: "Test Engine",
            path: "/usr/local/bin/test"
        )
        config.addEngineConfiguration(newEngine)

        // Remove the Pikafish engine
        config.removeEngineConfiguration(id: engine.id)

        #expect(config.engineConfigurations.count == 1)
        #expect(!config.engineConfigurations.contains { $0.id == engine.id })
    }

    @Test("Update engine configuration")
    func testUpdateEngineConfiguration() {
        var config = AppConfiguration.default
        let originalEngine = config.engineConfigurations[0]

        var updatedEngine = originalEngine
        updatedEngine.name = "Updated Engine"

        config.updateEngineConfiguration(updatedEngine)

        #expect(config.engineConfigurations[0].name == "Updated Engine")
    }

    @Test("Add recent game path")
    func testAddRecentGamePath() {
        var config = AppConfiguration.default

        config.addRecentGamePath("/path/to/game1.pgn")
        config.addRecentGamePath("/path/to/game2.pgn")
        config.addRecentGamePath("/path/to/game1.pgn") // Duplicate

        #expect(config.recentGamePaths.count == 2)
        #expect(config.recentGamePaths[0] == "/path/to/game1.pgn") // Moved to front
    }

    @Test("Clear recent game paths")
    func testClearRecentGamePaths() {
        var config = AppConfiguration.default

        config.addRecentGamePath("/path/to/game1.pgn")
        config.clearRecentGamePaths()

        #expect(config.recentGamePaths.isEmpty)
    }

    @Test("Mark as launched")
    func testMarkAsLaunched() {
        var config = AppConfiguration.default

        #expect(config.isFirstLaunch == true)

        config.markAsLaunched()

        #expect(config.isFirstLaunch == false)
    }

    @Test("Current engine configuration")
    func testCurrentEngineConfiguration() {
        var config = AppConfiguration.default
        let defaultEngine = config.engineConfigurations[0]

        // Initially returns default
        #expect(config.currentEngineConfiguration?.id == defaultEngine.id)

        // Set last used
        config.lastUsedEngineID = defaultEngine.id

        // Should return the last used one
        #expect(config.currentEngineConfiguration?.id == defaultEngine.id)
    }
}
