import Foundation

// MARK: - File Configuration Store

/// JSON 文件配置存储实现
public actor FileConfigurationStore: ConfigurationStore {

    // MARK: - Properties

    private let fileURL: URL
    private let backupFileURL: URL
    private let fileManager: FileManager

    // MARK: - Initialization

    public init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        self.fileManager = fileManager

        if let url = fileURL {
            self.fileURL = url
        } else {
            // 使用应用支持目录
            guard let appSupportURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw ConfigurationStoreError.writeFailed("Cannot access Application Support directory")
            }

            let appDirectory = appSupportURL.appendingPathComponent("ChineseChess", isDirectory: true)
            self.fileURL = appDirectory.appendingPathComponent("configuration.json")
        }

        self.backupFileURL = self.fileURL.appendingPathExtension("backup")

        // 确保目录存在
        try createDirectoryIfNeeded()
    }

    // MARK: - ConfigurationStore

    public func load() async throws -> AppConfiguration {
        // 首先尝试加载主配置文件
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                return try await loadFromFile(fileURL)
            } catch {
                // 主文件加载失败，尝试备份
                return try await loadFromBackup()
            }
        }

        // 主文件不存在，尝试备份
        if fileManager.fileExists(atPath: backupFileURL.path) {
            return try await loadFromBackup()
        }

        throw ConfigurationStoreError.notFound
    }

    public func save(_ configuration: AppConfiguration) async throws {
        // 先创建备份
        if fileManager.fileExists(atPath: fileURL.path) {
            try? createBackup()
        }

        // 写入临时文件
        let tempURL = fileURL.appendingPathExtension("tmp")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(configuration)

            try data.write(to: tempURL, options: .atomic)

            // 原子替换
            try fileManager.replaceItem(at: fileURL, withItemAt: tempURL, backupItemName: nil, resultingItemURL: nil)

        } catch {
            // 清理临时文件
            try? fileManager.removeItem(at: tempURL)
            throw ConfigurationStoreError.writeFailed(error.localizedDescription)
        }
    }

    public func delete() async throws {
        // 删除前先备份
        if fileManager.fileExists(atPath: fileURL.path) {
            try createBackup()
        }

        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            throw ConfigurationStoreError.writeFailed(error.localizedDescription)
        }
    }

    public func exists() async -> Bool {
        fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - Public Methods

    /// 创建备份
    public func createBackup() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            if fileManager.fileExists(atPath: backupFileURL.path) {
                try fileManager.removeItem(at: backupFileURL)
            }
            try fileManager.copyItem(at: fileURL, to: backupFileURL)
        } catch {
            throw ConfigurationStoreError.writeFailed("Failed to create backup: \(error.localizedDescription)")
        }
    }

    /// 从备份恢复
    public func restoreFromBackup() throws -> AppConfiguration {
        guard fileManager.fileExists(atPath: backupFileURL.path) else {
            throw ConfigurationStoreError.notFound
        }

        // 恢复备份文件
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        try fileManager.copyItem(at: backupFileURL, to: fileURL)

        // 加载配置
        return try loadFromFile(fileURL)
    }

    /// 获取配置文件的文件大小
    public func getFileSize() -> Int64? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }

    /// 获取配置文件的修改日期
    public func getModificationDate() -> Date? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    // MARK: - Private Methods

    private func createDirectoryIfNeeded() throws {
        let directory = fileURL.deletingLastPathComponent()

        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw ConfigurationStoreError.writeFailed("Failed to create directory: \(error.localizedDescription)")
            }
        }
    }

    private func loadFromFile(_ url: URL) throws -> AppConfiguration {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AppConfiguration.self, from: data)
        } catch {
            throw ConfigurationStoreError.decodeFailed(error.localizedDescription)
        }
    }

    private func loadFromBackup() async throws -> AppConfiguration {
        guard fileManager.fileExists(atPath: backupFileURL.path) else {
            throw ConfigurationStoreError.notFound
        }

        return try loadFromFile(backupFileURL)
    }
}

// MARK: - FileManager Extension

extension FileManager {
    func isExecutableFile(atPath path: String) -> Bool {
        guard fileExists(atPath: path) else { return false }

        do {
            let attributes = try attributesOfItem(atPath: path)
            // 检查文件类型
            if let type = attributes[.type] as? FileAttributeType,
               type == .typeRegular {
                // 在实际应用中，这里应该检查文件权限
                // 简化为始终返回 true
                return true
            }
        } catch {
            return false
        }

        return false
    }
}
