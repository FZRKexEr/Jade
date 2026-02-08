import Foundation

// MARK: - Configuration Backup

/// 配置自动备份机制
public actor ConfigurationBackup {

    // MARK: - Properties

    /// 备份目录
    private let backupDirectory: URL

    /// 最大备份数量
    private let maxBackups: Int

    /// 文件管理器
    private let fileManager: FileManager

    /// 自动备份间隔（秒）
    private let autoBackupInterval: TimeInterval

    /// 上次备份时间
    private var lastBackupTime: Date?

    /// 备份任务
    private var backupTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(
        backupDirectory: URL? = nil,
        maxBackups: Int = 10,
        autoBackupInterval: TimeInterval = 3600, // 1小时
        fileManager: FileManager = .default
    ) throws {
        self.fileManager = fileManager
        self.maxBackups = maxBackups
        self.autoBackupInterval = autoBackupInterval

        // 设置备份目录
        if let directory = backupDirectory {
            self.backupDirectory = directory
        } else {
            // 使用应用支持目录
            guard let appSupportURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw ConfigurationError.importFailed("Cannot access Application Support directory")
            }

            self.backupDirectory = appSupportURL
                .appendingPathComponent("ChineseChess", isDirectory: true)
                .appendingPathComponent("AutoBackups", isDirectory: true)
        }

        // 确保备份目录存在
        try createBackupDirectoryIfNeeded()
    }

    // MARK: - Public Methods

    /// 创建手动备份
    public func createBackup(
        from configuration: AppConfiguration,
        name: String? = nil
    ) async throws -> BackupInfo {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupName = name ?? "manual_backup_\(timestamp)"

        return try await performBackup(
            configuration: configuration,
            backupName: backupName,
            isAuto: false
        )
    }

    /// 启动自动备份
    public func startAutoBackup(configurationProvider: @escaping () async -> AppConfiguration) {
        stopAutoBackup()

        backupTask = Task {
            while !Task.isCancelled {
                // 检查是否需要备份
                if shouldPerformAutoBackup() {
                    let config = await configurationProvider()
                    try? await performAutoBackup(configuration: config)
                }

                // 等待下一次检查
                try? await Task.sleep(nanoseconds: UInt64(autoBackupInterval * 1_000_000_000))
            }
        }
    }

    /// 停止自动备份
    public func stopAutoBackup() {
        backupTask?.cancel()
        backupTask = nil
    }

    /// 列出所有备份
    public func listBackups() async throws -> [BackupInfo] {
        let contents = try fileManager.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        )

        var backups: [BackupInfo] = []

        for url in contents where url.pathExtension == "json" {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                let creationDate = attributes[.creationDate] as? Date ?? Date()
                let fileSize = attributes[.size] as? Int64 ?? 0

                // 读取配置
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

        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw ConfigurationStoreError.notFound
        }

        let data = try Data(contentsOf: backupURL)
        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: data)

        return configuration
    }

    /// 删除备份
    public func deleteBackup(name: String) async throws {
        let backupURL = backupDirectory.appendingPathComponent("\(name).json")

        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw ConfigurationStoreError.notFound
        }

        try fileManager.removeItem(at: backupURL)
    }

    /// 清理旧备份
    public func cleanupOldBackups(keepCount: Int? = nil) async throws {
        let count = keepCount ?? maxBackups
        var backups = try await listBackups()

        if backups.count > count {
            let backupsToDelete = backups.suffix(backups.count - count)
            for backup in backupsToDelete {
                try? await deleteBackup(name: backup.name)
            }
        }
    }

    /// 清除所有备份
    public func clearAllBackups() async throws {
        let backups = try await listBackups()
        for backup in backups {
            try? await deleteBackup(name: backup.name)
        }
    }

    // MARK: - Private Methods

    private func createBackupDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: backupDirectory.path) {
            do {
                try fileManager.createDirectory(
                    at: backupDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw ConfigurationError.importFailed("Failed to create backup directory: \(error.localizedDescription)")
            }
        }
    }

    private func shouldPerformAutoBackup() -> Bool {
        guard let lastTime = lastBackupTime else {
            return true
        }

        let timeSinceLastBackup = Date().timeIntervalSince(lastTime)
        return timeSinceLastBackup >= autoBackupInterval
    }

    private func performAutoBackup(configuration: AppConfiguration) async throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupName = "auto_backup_\(timestamp)"

        _ = try await performBackup(
            configuration: configuration,
            backupName: backupName,
            isAuto: true
        )

        lastBackupTime = Date()

        // 清理旧备份
        try? await cleanupOldBackups()
    }

    private func performBackup(
        configuration: AppConfiguration,
        backupName: String,
        isAuto: Bool
    ) async throws -> BackupInfo {
        let backupURL = backupDirectory.appendingPathComponent("\(backupName).json")

        // 编码配置
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(configuration)

        // 写入文件
        try data.write(to: backupURL, options: .atomic)

        // 获取文件信息
        let attributes = try fileManager.attributesOfItem(atPath: backupURL.path)
        let creationDate = attributes[.creationDate] as? Date ?? Date()
        let fileSize = attributes[.size] as? Int64 ?? 0

        return BackupInfo(
            name: backupName,
            creationDate: creationDate,
            fileSize: fileSize,
            configuration: configuration
        )
    }
}
