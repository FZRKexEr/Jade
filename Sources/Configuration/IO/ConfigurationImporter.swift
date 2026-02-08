import Foundation

// MARK: - Configuration Importer

/// 配置导入器
public struct ConfigurationImporter {

    // MARK: - Import Options

    /// 导入选项
    public struct ImportOptions: Sendable {
        /// 是否合并引擎配置（而不是替换）
        public var mergeEngineConfigs: Bool
        /// 是否导入 UI 配置
        public var importUIConfig: Bool
        /// 是否导入游戏配置
        public var importGameConfig: Bool
        /// 导入冲突时优先使用导入的配置
        public var preferImported: Bool
        /// 是否验证导入的配置
        public var validate: Bool

        public init(
            mergeEngineConfigs: Bool = true,
            importUIConfig: Bool = true,
            importGameConfig: Bool = true,
            preferImported: Bool = false,
            validate: Bool = true
        ) {
            self.mergeEngineConfigs = mergeEngineConfigs
            self.importUIConfig = importUIConfig
            self.importGameConfig = importGameConfig
            self.preferImported = preferImported
            self.validate = validate
        }

        /// 默认选项
        public static let `default` = ImportOptions()

        /// 导入所有内容（替换现有）
        public static let replaceAll = ImportOptions(
            mergeEngineConfigs: false,
            importUIConfig: true,
            importGameConfig: true,
            preferImported: true
        )

        /// 仅导入引擎配置
        public static let enginesOnly = ImportOptions(
            mergeEngineConfigs: true,
            importUIConfig: false,
            importGameConfig: false
        )
    }

    // MARK: - Import Result

    /// 导入结果
    public struct ImportResult {
        /// 导入的配置
        public let configuration: AppConfiguration
        /// 导入的引擎配置数量
        public let importedEngineCount: Int
        /// 合并的引擎配置数量（如果是合并模式）
        public let mergedEngineCount: Int
        /// 是否包含 UI 配置
        public let hasUIConfig: Bool
        /// 是否包含游戏配置
        public let hasGameConfig: Bool
        /// 导入过程中的警告
        public let warnings: [String]

        public init(
            configuration: AppConfiguration,
            importedEngineCount: Int,
            mergedEngineCount: Int = 0,
            hasUIConfig: Bool,
            hasGameConfig: Bool,
            warnings: [String] = []
        ) {
            self.configuration = configuration
            self.importedEngineCount = importedEngineCount
            self.mergedEngineCount = mergedEngineCount
            self.hasUIConfig = hasUIConfig
            self.hasGameConfig = hasGameConfig
            self.warnings = warnings
        }

        /// 导入是否成功
        public var isSuccess: Bool {
            importedEngineCount > 0 || hasUIConfig || hasGameConfig
        }

        /// 总引擎配置数量
        public var totalEngineCount: Int {
            configuration.engineConfigurations.count
        }
    }

    // MARK: - Import Methods

    /// 从 Data 导入配置
    public static func `import`(
        from data: Data,
        mergingWith currentConfig: AppConfiguration? = nil,
        options: ImportOptions = .default
    ) throws -> ImportResult {
        // 解码导入的配置
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let importedConfig: AppConfiguration
        do {
            importedConfig = try decoder.decode(AppConfiguration.self, from: data)
        } catch {
            // 尝试解码为部分配置（只包含引擎）
            if let engines = try? decoder.decode([EngineConfiguration].self, from: data) {
                var config = currentConfig ?? AppConfiguration.default
                config.engineConfigurations = engines
                importedConfig = config
            } else {
                throw ConfigurationError.importFailed("Failed to decode configuration: \(error.localizedDescription)")
            }
        }

        // 验证配置
        if options.validate {
            try validateConfiguration(importedConfig)
        }

        // 合并配置
        return try mergeConfigurations(
            imported: importedConfig,
            current: currentConfig,
            options: options
        )
    }

    /// 从 URL 导入配置
    public static func `import`(
        from url: URL,
        mergingWith currentConfig: AppConfiguration? = nil,
        options: ImportOptions = .default
    ) throws -> ImportResult {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ConfigurationError.importFailed("Failed to read file: \(error.localizedDescription)")
        }

        return try `import`(
            from: data,
            mergingWith: currentConfig,
            options: options
        )
    }

    /// 从 JSON 字符串导入配置
    public static func `import`(
        from jsonString: String,
        mergingWith currentConfig: AppConfiguration? = nil,
        options: ImportOptions = .default
    ) throws -> ImportResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw ConfigurationError.importFailed("Failed to convert string to data")
        }

        return try `import`(
            from: data,
            mergingWith: currentConfig,
            options: options
        )
    }

    // MARK: - Private Methods

    private static func validateConfiguration(_ config: AppConfiguration) throws {
        var errors: [String] = []

        // 验证引擎配置
        for engine in config.engineConfigurations {
            let engineErrors = engine.validate()
            if !engineErrors.isEmpty {
                errors.append(contentsOf: engineErrors.map { "[\(engine.name)] \($0.localizedDescription)" })
            }
        }

        if !errors.isEmpty {
            throw ConfigurationError.invalidConfiguration(errors.joined(separator: "; "))
        }
    }

    private static func mergeConfigurations(
        imported: AppConfiguration,
        current: AppConfiguration?,
        options: ImportOptions
    ) throws -> ImportResult {
        var result = AppConfiguration.default
        var warnings: [String] = []
        var importedEngineCount = 0
        var mergedEngineCount = 0
        var hasUIConfig = false
        var hasGameConfig = false

        // 合并引擎配置
        if options.mergeEngineConfigs {
            // 合并模式
            var engineDict: [UUID: EngineConfiguration] = [:]

            // 添加当前配置
            for engine in current?.engineConfigurations ?? [] {
                engineDict[engine.id] = engine
            }

            // 添加导入的配置（根据优先级决定覆盖）
            for engine in imported.engineConfigurations {
                if engineDict[engine.id] == nil || options.preferImported {
                    engineDict[engine.id] = engine
                    if engineDict[engine.id] == nil {
                        importedEngineCount += 1
                    } else {
                        mergedEngineCount += 1
                    }
                }
            }

            result.engineConfigurations = Array(engineDict.values)
        } else {
            // 替换模式
            result.engineConfigurations = imported.engineConfigurations
            importedEngineCount = imported.engineConfigurations.count
        }

        // 合并 UI 配置
        if options.importUIConfig {
            hasUIConfig = true
            if options.preferImported || current?.uiConfiguration == nil {
                result.uiConfiguration = imported.uiConfiguration
            } else {
                result.uiConfiguration = current?.uiConfiguration ?? imported.uiConfiguration
            }
        } else {
            result.uiConfiguration = current?.uiConfiguration ?? imported.uiConfiguration
        }

        // 合并游戏配置
        if options.importGameConfig {
            hasGameConfig = true
            if options.preferImported || current?.gameConfiguration == nil {
                result.gameConfiguration = imported.gameConfiguration
            } else {
                result.gameConfiguration = current?.gameConfiguration ?? imported.gameConfiguration
            }
        } else {
            result.gameConfiguration = current?.gameConfiguration ?? imported.gameConfiguration
        }

        // 保留其他字段
        result.version = imported.version
        result.lastUsedEngineID = imported.lastUsedEngineID ?? current?.lastUsedEngineID
        result.recentGamePaths = current?.recentGamePaths ?? imported.recentGamePaths
        result.windowSize = current?.windowSize ?? imported.windowSize
        result.isFirstLaunch = false  // 导入后不再是首次启动

        return ImportResult(
            configuration: result,
            importedEngineCount: importedEngineCount,
            mergedEngineCount: mergedEngineCount,
            hasUIConfig: hasUIConfig,
            hasGameConfig: hasGameConfig,
            warnings: warnings
        )
    }
}
