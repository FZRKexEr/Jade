import Foundation
import Combine

// MARK: - Configuration Manager

/// 统一配置管理器
@MainActor
@Observable
public final class ConfigurationManager {

    // MARK: - Properties

    /// 当前配置
    public var configuration: AppConfiguration {
        didSet {
            // 配置变更时通知观察者
            notifyConfigurationChanged()
        }
    }

    /// 是否正在加载
    public private(set) var isLoading = false

    /// 是否已修改但未保存
    public private(set) var hasUnsavedChanges = false

    /// 最后一次错误
    public private(set) var lastError: ConfigurationError?

    /// 主存储
    private let primaryStore: ConfigurationStore

    /// 备份存储（可选）
    private let backupStore: ConfigurationStore?

    /// 变更回调
    private var changeCallbacks: [(AppConfiguration) -> Void] = []

    // MARK: - Initialization

    public init(
        primaryStore: ConfigurationStore? = nil,
        backupStore: ConfigurationStore? = nil
    ) {
        // 默认使用 UserDefaults 作为主存储
        self.primaryStore = primaryStore ?? UserDefaultsStore.shared
        self.backupStore = backupStore
        self.configuration = AppConfiguration.default
    }

    // MARK: - Public Methods

    /// 加载配置
    public func load() async {
        guard !isLoading else { return }

        isLoading = true
        lastError = nil

        do {
            // 尝试从主存储加载
            let loadedConfig = try await primaryStore.load()
            configuration = migrateIfNeeded(loadedConfig)
            hasUnsavedChanges = false
        } catch {
            // 主存储加载失败，尝试备份存储
            if let backupStore = backupStore {
                do {
                    let backupConfig = try await backupStore.load()
                    configuration = migrateIfNeeded(backupConfig)
                    hasUnsavedChanges = true
                } catch {
                    lastError = .loadFailed(error.localizedDescription)
                    configuration = AppConfiguration.default
                }
            } else {
                lastError = .loadFailed(error.localizedDescription)
                configuration = AppConfiguration.default
            }
        }

        isLoading = false
    }

    /// 保存配置
    public func save() async {
        lastError = nil

        do {
            // 保存到主存储
            try await primaryStore.save(configuration)

            // 同时保存到备份存储
            try? await backupStore?.save(configuration)

            hasUnsavedChanges = false
        } catch {
            lastError = .saveFailed(error.localizedDescription)
        }
    }

    /// 重置为默认配置
    public func resetToDefaults() {
        configuration = AppConfiguration.default
        hasUnsavedChanges = true
    }

    /// 导出配置
    public func export(to url: URL) throws {
        do {
            let data = try ConfigurationExporter.export(configuration)
            try data.write(to: url, options: .atomic)
        } catch {
            throw ConfigurationError.exportFailed(error.localizedDescription)
        }
    }

    /// 从文件导入配置
    public func `import`(from url: URL) throws {
        do {
            let data = try Data(contentsOf: url)
            let importedConfig = try ConfigurationImporter.import(from: data)
            configuration = migrateIfNeeded(importedConfig)
            hasUnsavedChanges = true
        } catch {
            throw ConfigurationError.importFailed(error.localizedDescription)
        }
    }

    /// 注册配置变更回调
    public func onConfigurationChanged(_ callback: @escaping (AppConfiguration) -> Void) {
        changeCallbacks.append(callback)
    }

    /// 移除配置变更回调
    public func removeConfigurationChangedCallback(_ callback: @escaping (AppConfiguration) -> Void) {
        changeCallbacks.removeAll { $0 as AnyObject === callback as AnyObject }
    }

    // MARK: - Engine Configuration Helpers

    /// 获取引擎配置
    public func getEngineConfiguration(id: UUID) -> EngineConfiguration? {
        configuration.engineConfigurations.first { $0.id == id }
    }

    /// 添加或更新引擎配置
    public func setEngineConfiguration(_ engineConfig: EngineConfiguration) {
        if let index = configuration.engineConfigurations.firstIndex(where: { $0.id == engineConfig.id }) {
            // 如果设为默认，取消其他默认
            if engineConfig.isDefault {
                for i in configuration.engineConfigurations.indices where i != index {
                    configuration.engineConfigurations[i].isDefault = false
                }
            }
            configuration.engineConfigurations[index] = engineConfig
        } else {
            // 如果设为默认，取消其他默认
            if engineConfig.isDefault {
                for i in configuration.engineConfigurations.indices {
                    configuration.engineConfigurations[i].isDefault = false
                }
            }
            configuration.engineConfigurations.append(engineConfig)
        }
        hasUnsavedChanges = true
    }

    /// 删除引擎配置
    public func removeEngineConfiguration(id: UUID) {
        configuration.engineConfigurations.removeAll { $0.id == id }

        // 如果删除了默认配置，设置第一个为默认
        if !configuration.engineConfigurations.isEmpty,
           !configuration.engineConfigurations.contains(where: { $0.isDefault }) {
            configuration.engineConfigurations[0].isDefault = true
        }

        hasUnsavedChanges = true
    }

    // MARK: - Private Methods

    private func notifyConfigurationChanged() {
        hasUnsavedChanges = true
        for callback in changeCallbacks {
            callback(configuration)
        }
    }

    private func migrateIfNeeded(_ config: AppConfiguration) -> AppConfiguration {
        var migratedConfig = config

        // 版本检查和迁移
        let currentVersion = AppConfiguration.currentVersion
        if migratedConfig.version != currentVersion {
            migratedConfig = ConfigurationMigrator.migrate(
                configuration: migratedConfig,
                fromVersion: migratedConfig.version,
                toVersion: currentVersion
            )
            migratedConfig.version = currentVersion
        }

        return migratedConfig
    }
}

// MARK: - Configuration Backup Manager

/// 配置备份管理器
public actor ConfigurationBackupManager {

    // MARK: - Properties

    private let store: ConfigurationStore
    private let maxBackupCount: Int
    private let backupDirectory: URL

    // MARK: - Initialization

    public init(
        store: ConfigurationStore,
        maxBackupCount: Int = 10,
        backupDirectory: URL? = nil
    ) throws {
        self.store = store
        self.maxBackupCount = maxBackupCount

        if let directory = backupDirectory {
            self.backupDirectory = directory
        } else {
            // 使用应用支持目录
            guard let appSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw ConfigurationStoreError.writeFailed("Cannot access Application Support directory")
            }
            self.backupDirectory = appSupportURL.appendingPathComponent("ChineseChess/Backups")
        }

        // 确保备份目录存在
        try createBackupDirectoryIfNeeded()
    }

    // MARK: - Public Methods

    /// 创建备份
    public func createBackup(name: String? = nil) async throws {
        let configuration = try await store.load()
        let data = try ConfigurationExporter.export(configuration)

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupName = name ?? "backup_\(timestamp)"
        let backupURL = backupDirectory.appendingPathComponent("\(backupName).json")

        try data.write(to: backupURL, options: .atomic)

        // 清理旧备份
        try await cleanupOldBackups()
    }

    /// 列出所有备份
    public func listBackups() async throws -> [BackupInfo] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        )

        var backups: [BackupInfo] = []

        for url in contents where url.pathExtension == "json" {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let creationDate = attributes[.creationDate] as? Date ?? Date()
                let fileSize = attributes[.size] as? Int64 ?? 0

                // 尝试读取配置名称
                let data = try Data(contentsOf: url)
                if let config = try? JSONDecoder().decode(AppConfiguration.self, from: data) {
                    let name = url.deletingPathExtension().lastPathComponent
                    backups.append(BackupInfo(
                        name: name,
                        creationDate: creationDate,
                        fileSize: fileSize,
                        configuration: config
                    ))
                }
            } catch {
                // 跳过损坏的备份文件
                continue
            }
        }

        return backups.sorted { $0.creationDate > $1.creationDate }
    }

    /// 从备份恢复
    public func restore(from backupName: String) async throws -> AppConfiguration {
        let backupURL = backupDirectory.appendingPathComponent("\(backupName).json")

        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw ConfigurationStoreError.notFound
        }

        let data = try Data(contentsOf: backupURL)
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: data)

        // 保存到主存储
        try await store.save(configuration)

        return configuration
    }

    /// 删除备份
    public func deleteBackup(name: String) async throws {
        let backupURL = backupDirectory.appendingPathComponent("\(name).json")

        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw ConfigurationStoreError.notFound
        }

        try FileManager.default.removeItem(at: backupURL)
    }

    /// 清理所有备份
    public func clearAllBackups() async throws {
        let contents = try FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )

        for url in contents {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Private Methods

    private func createBackupDirectoryIfNeeded() throws {
        if !FileManager.default.fileExists(atPath: backupDirectory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: backupDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw ConfigurationStoreError.writeFailed("Failed to create backup directory: \(error.localizedDescription)")
            }
        }
    }

    private func cleanupOldBackups() async throws {
        let backups = try await listBackups()

        if backups.count > maxBackupCount {
            let backupsToDelete = backups.suffix(backups.count - maxBackupCount)
            for backup in backupsToDelete {
                try? await deleteBackup(name: backup.name)
            }
        }
    }
}

// MARK: - Backup Info

/// 备份信息
public struct BackupInfo: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let creationDate: Date
    public let fileSize: Int64
    public let configuration: AppConfiguration

    public init(
        name: String,
        creationDate: Date,
        fileSize: Int64,
        configuration: AppConfiguration
    ) {
        self.name = name
        self.creationDate = creationDate
        self.fileSize = fileSize
        self.configuration = configuration
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    public var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: creationDate, relativeTo: Date())
    }
}
