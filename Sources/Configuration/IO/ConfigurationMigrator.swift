import Foundation

// MARK: - Configuration Migrator

/// 配置迁移器
/// 处理不同版本配置之间的迁移
public struct ConfigurationMigrator {

    /// 迁移历史记录
    public struct MigrationHistory: Codable, Sendable {
        public let fromVersion: String
        public let toVersion: String
        public let date: Date
        public let success: Bool
        public let message: String?

        public init(
            fromVersion: String,
            toVersion: String,
            date: Date = Date(),
            success: Bool,
            message: String? = nil
        ) {
            self.fromVersion = fromVersion
            self.toVersion = toVersion
            self.date = date
            self.success = success
            self.message = message
        }
    }

    // MARK: - Migration Methods

    /// 执行配置迁移
    public static func migrate(
        configuration: AppConfiguration,
        fromVersion: String,
        toVersion: String
    ) -> AppConfiguration {
        var config = configuration

        // 版本号解析
        let fromComponents = parseVersion(fromVersion)
        let toComponents = parseVersion(toVersion)

        // 检查是否需要迁移
        guard fromComponents != toComponents else {
            return config
        }

        // 按版本逐步迁移
        let migrationSteps = generateMigrationSteps(from: fromComponents, to: toComponents)

        for step in migrationSteps {
            config = applyMigrationStep(step, to: config)
        }

        // 更新版本号
        config.version = toVersion

        return config
    }

    /// 检查是否需要迁移
    public static func needsMigration(
        configuration: AppConfiguration,
        targetVersion: String = AppConfiguration.currentVersion
    ) -> Bool {
        configuration.version != targetVersion
    }

    /// 获取迁移说明
    public static func migrationNotes(
        fromVersion: String,
        toVersion: String
    ) -> [String] {
        var notes: [String] = []

        let fromComponents = parseVersion(fromVersion)
        let toComponents = parseVersion(toVersion)

        // 1.0.0 -> 1.1.0
        if fromComponents.major == 1 && fromComponents.minor == 0 &&
           toComponents.major == 1 && toComponents.minor >= 1 {
            notes.append("新增：支持多引擎配置")
            notes.append("新增：引擎配置导出功能")
        }

        // 1.1.0 -> 1.2.0
        if fromComponents.major == 1 && fromComponents.minor <= 1 &&
           toComponents.major == 1 && toComponents.minor >= 2 {
            notes.append("新增：主题系统升级")
            notes.append("改进：配置存储方式")
        }

        if notes.isEmpty {
            notes.append("无重大变更")
        }

        return notes
    }

    // MARK: - Private Methods

    private static func parseVersion(_ version: String) -> (major: Int, minor: Int, patch: Int) {
        let components = version.split(separator: ".").compactMap { Int($0) }
        let major = components.count > 0 ? components[0] : 0
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0
        return (major, minor, patch)
    }

    private static func generateMigrationSteps(
        from: (major: Int, minor: Int, patch: Int),
        to: (major: Int, minor: Int, patch: Int)
    ) -> [MigrationStep] {
        var steps: [MigrationStep] = []

        // 1.0.0 -> 1.1.0
        if from.major == 1 && from.minor == 0 &&
           (to.major > 1 || (to.major == 1 && to.minor >= 1)) {
            steps.append(.v1_0_0_to_v1_1_0)
        }

        // 1.1.0 -> 1.2.0
        if from.major == 1 && from.minor <= 1 &&
           (to.major > 1 || (to.major == 1 && to.minor >= 2)) {
            steps.append(.v1_1_0_to_v1_2_0)
        }

        return steps
    }

    private static func applyMigrationStep(
        _ step: MigrationStep,
        to configuration: AppConfiguration
    ) -> AppConfiguration {
        var config = configuration

        switch step {
        case .v1_0_0_to_v1_1_0:
            // 添加默认 UCI 选项到引擎配置
            for i in config.engineConfigurations.indices {
                if config.engineConfigurations[i].defaultOptions["UCI_Variant"] == nil {
                    config.engineConfigurations[i].defaultOptions["UCI_Variant"] = "xiangqi"
                }
            }

        case .v1_1_0_to_v1_2_0:
            // 迁移主题配置
            // 如果旧版配置使用特定主题名称，映射到新的枚举
            config.uiConfiguration.theme = .system

            // 确保引擎配置有 ID
            for i in config.engineConfigurations.indices {
                // ID 已经存在（因为是 UUID），无需处理
                // 确保 isEnabled 字段存在
                if !config.engineConfigurations[i].isEnabled {
                    // 如果之前被禁用，保持禁用状态
                }
            }
        }

        return config
    }

    // MARK: - Migration Step Enum

    private enum MigrationStep {
        case v1_0_0_to_v1_1_0
        case v1_1_0_to_v1_2_0
    }
}

// MARK: - Migration History Manager

/// 迁移历史管理器
public actor MigrationHistoryManager {

    private let store: UserDefaults
    private let key = "app.migration.history"

    public init(store: UserDefaults = .standard) {
        self.store = store
    }

    /// 记录迁移历史
    public func record(
        fromVersion: String,
        toVersion: String,
        success: Bool,
        message: String? = nil
    ) {
        let history = ConfigurationMigrator.MigrationHistory(
            fromVersion: fromVersion,
            toVersion: toVersion,
            success: success,
            message: message
        )

        var histories = loadHistories()
        histories.append(history)

        // 限制历史记录数量
        if histories.count > 50 {
            histories = Array(histories.suffix(50))
        }

        saveHistories(histories)
    }

    /// 获取迁移历史
    public func getHistories() -> [ConfigurationMigrator.MigrationHistory] {
        loadHistories()
    }

    /// 清除历史记录
    public func clearHistories() {
        store.removeObject(forKey: key)
    }

    // MARK: - Private Methods

    private func loadHistories() -> [ConfigurationMigrator.MigrationHistory] {
        guard let data = store.data(forKey: key) else {
            return []
        }

        do {
            return try JSONDecoder().decode([ConfigurationMigrator.MigrationHistory].self, from: data)
        } catch {
            return []
        }
    }

    private func saveHistories(_ histories: [ConfigurationMigrator.MigrationHistory]) {
        do {
            let data = try JSONEncoder().encode(histories)
            store.set(data, forKey: key)
        } catch {
            // 保存失败，静默处理
        }
    }
}
