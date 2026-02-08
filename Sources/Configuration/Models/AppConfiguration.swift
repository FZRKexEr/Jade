import Foundation
import Combine

// MARK: - App Configuration

/// 应用整体配置容器
public struct AppConfiguration: Codable, Equatable, Sendable {
    public var version: String
    public var engineConfigurations: [EngineConfiguration]
    public var uiConfiguration: UIConfiguration
    public var gameConfiguration: GameConfiguration
    public var lastUsedEngineID: UUID?
    public var recentGamePaths: [String]
    public var windowSize: WindowSize?
    public var isFirstLaunch: Bool

    public init(
        version: String = AppConfiguration.currentVersion,
        engineConfigurations: [EngineConfiguration] = [EngineConfiguration.pikafishDefault],
        uiConfiguration: UIConfiguration = UIConfiguration.default,
        gameConfiguration: GameConfiguration = GameConfiguration.default,
        lastUsedEngineID: UUID? = nil,
        recentGamePaths: [String] = [],
        windowSize: WindowSize? = nil,
        isFirstLaunch: Bool = true
    ) {
        self.version = version
        self.engineConfigurations = engineConfigurations
        self.uiConfiguration = uiConfiguration
        self.gameConfiguration = gameConfiguration
        self.lastUsedEngineID = lastUsedEngineID
        self.recentGamePaths = recentGamePaths
        self.windowSize = windowSize
        self.isFirstLaunch = isFirstLaunch
    }

    /// 当前配置版本
    public static let currentVersion = "1.0.0"

    /// 默认配置
    public static let `default` = AppConfiguration()

    /// 获取默认引擎配置
    public var defaultEngineConfiguration: EngineConfiguration? {
        engineConfigurations.first { $0.isDefault && $0.isEnabled }
            ?? engineConfigurations.first { $0.isEnabled }
    }

    /// 获取上次使用的引擎配置
    public var lastUsedEngineConfiguration: EngineConfiguration? {
        guard let id = lastUsedEngineID else { return nil }
        return engineConfigurations.first { $0.id == id && $0.isEnabled }
    }

    /// 获取当前活动引擎配置
    public var currentEngineConfiguration: EngineConfiguration? {
        lastUsedEngineConfiguration ?? defaultEngineConfiguration
    }

    /// 添加引擎配置
    public mutating func addEngineConfiguration(_ config: EngineConfiguration) {
        // 如果设为默认，取消其他默认
        if config.isDefault {
            for i in engineConfigurations.indices {
                engineConfigurations[i].isDefault = false
            }
        }
        engineConfigurations.append(config)
    }

    /// 更新引擎配置
    public mutating func updateEngineConfiguration(_ config: EngineConfiguration) {
        if let index = engineConfigurations.firstIndex(where: { $0.id == config.id }) {
            // 如果设为默认，取消其他默认
            if config.isDefault {
                for i in engineConfigurations.indices where i != index {
                    engineConfigurations[i].isDefault = false
                }
            }
            engineConfigurations[index] = config
        }
    }

    /// 删除引擎配置
    public mutating func removeEngineConfiguration(id: UUID) {
        engineConfigurations.removeAll { $0.id == id }
        // 如果删除了默认配置，设置第一个为默认
        if !engineConfigurations.isEmpty,
           !engineConfigurations.contains(where: { $0.isDefault }) {
            engineConfigurations[0].isDefault = true
        }
    }

    /// 添加最近游戏路径
    public mutating func addRecentGamePath(_ path: String) {
        recentGamePaths.removeAll { $0 == path }
        recentGamePaths.insert(path, at: 0)
        // 只保留最近10个
        if recentGamePaths.count > 10 {
            recentGamePaths = Array(recentGamePaths.prefix(10))
        }
    }

    /// 清除最近游戏历史
    public mutating func clearRecentGamePaths() {
        recentGamePaths.removeAll()
    }

    /// 标记为非首次启动
    public mutating func markAsLaunched() {
        isFirstLaunch = false
    }
}

// MARK: - Window Size

/// 窗口尺寸
public struct WindowSize: Codable, Equatable, Sendable {
    public var width: CGFloat
    public var height: CGFloat
    public var isMaximized: Bool

    public init(
        width: CGFloat = 1200,
        height: CGFloat = 800,
        isMaximized: Bool = false
    ) {
        self.width = width
        self.height = height
        self.isMaximized = isMaximized
    }

    public static let `default` = WindowSize()
}

// MARK: - Configuration Manager (Observable)

/// 配置管理器（可观察）
@MainActor
@Observable
public final class AppConfigurationManager {
    public var configuration: AppConfiguration {
        didSet {
            // 配置变更时自动保存
            Task {
                await saveConfiguration()
            }
        }
    }

    public private(set) var isLoading = false
    public private(set) var lastError: ConfigurationError?

    private let store: ConfigurationStore

    public init(store: ConfigurationStore = UserDefaultsStore.shared) {
        self.store = store
        self.configuration = AppConfiguration.default
    }

    /// 加载配置
    public func loadConfiguration() async {
        isLoading = true
        lastError = nil

        do {
            let loadedConfig = try await store.load()
            // 版本检查和迁移
            self.configuration = migrateConfiguration(loadedConfig)
        } catch {
            lastError = .loadFailed(error.localizedDescription)
            // 使用默认配置
            self.configuration = AppConfiguration.default
        }

        isLoading = false
    }

    /// 保存配置
    public func saveConfiguration() async {
        do {
            try await store.save(configuration)
        } catch {
            lastError = .saveFailed(error.localizedDescription)
        }
    }

    /// 重置为默认配置
    public func resetToDefaults() {
        configuration = AppConfiguration.default
    }

    /// 导出配置
    public func exportConfiguration() throws -> Data {
        return try ConfigurationExporter.export(configuration)
    }

    /// 导入配置
    public func importConfiguration(from data: Data) throws {
        let importedConfig = try ConfigurationImporter.import(from: data)
        configuration = migrateConfiguration(importedConfig)
    }

    // MARK: - Private

    private func migrateConfiguration(_ config: AppConfiguration) -> AppConfiguration {
        var migratedConfig = config

        // 版本迁移逻辑
        let currentVersion = AppConfiguration.currentVersion
        if migratedConfig.version != currentVersion {
            // 执行版本特定的迁移
            migratedConfig = performMigration(from: migratedConfig.version, to: currentVersion, config: migratedConfig)
            migratedConfig.version = currentVersion
        }

        return migratedConfig
    }

    private func performMigration(from oldVersion: String, to newVersion: String, config: AppConfiguration) -> AppConfiguration {
        // 实现版本迁移逻辑
        var newConfig = config

        // 示例：1.0.0 -> 1.1.0 的迁移
        // if oldVersion == "1.0.0" && newVersion == "1.1.0" {
        //     // 迁移逻辑
        // }

        return newConfig
    }
}

// MARK: - Configuration Error

public enum ConfigurationError: Error, Equatable {
    case loadFailed(String)
    case saveFailed(String)
    case exportFailed(String)
    case importFailed(String)
    case migrationFailed(String)
    case invalidConfiguration(String)

    public var localizedDescription: String {
        switch self {
        case .loadFailed(let reason):
            return "加载配置失败: \(reason)"
        case .saveFailed(let reason):
            return "保存配置失败: \(reason)"
        case .exportFailed(let reason):
            return "导出配置失败: \(reason)"
        case .importFailed(let reason):
            return "导入配置失败: \(reason)"
        case .migrationFailed(let reason):
            return "配置迁移失败: \(reason)"
        case .invalidConfiguration(let reason):
            return "配置无效: \(reason)"
        }
    }
}
