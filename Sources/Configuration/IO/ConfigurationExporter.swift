import Foundation

// MARK: - Configuration Exporter

/// 配置导出器
public struct ConfigurationExporter {

    // MARK: - Export Options

    /// 导出选项
    public struct ExportOptions: Sendable {
        /// 是否包含引擎配置
        public var includeEngineConfigs: Bool
        /// 是否包含 UI 配置
        public var includeUIConfig: Bool
        /// 是否包含游戏配置
        public var includeGameConfig: Bool
        /// 是否美化输出
        public var prettyPrint: Bool
        /// 是否加密敏感信息
        public var encryptSensitive: Bool

        public init(
            includeEngineConfigs: Bool = true,
            includeUIConfig: Bool = true,
            includeGameConfig: Bool = true,
            prettyPrint: Bool = true,
            encryptSensitive: Bool = false
        ) {
            self.includeEngineConfigs = includeEngineConfigs
            self.includeUIConfig = includeUIConfig
            self.includeGameConfig = includeGameConfig
            self.prettyPrint = prettyPrint
            self.encryptSensitive = encryptSensitive
        }

        /// 默认选项
        public static let `default` = ExportOptions()

        /// 仅包含引擎配置
        public static let enginesOnly = ExportOptions(
            includeEngineConfigs: true,
            includeUIConfig: false,
            includeGameConfig: false
        )

        /// 最小化导出（用于分享）
        public static let minimal = ExportOptions(
            includeEngineConfigs: true,
            includeUIConfig: true,
            includeGameConfig: false,
            prettyPrint: false
        )
    }

    // MARK: - Export Methods

    /// 导出配置为 JSON 数据
    public static func export(
        _ configuration: AppConfiguration,
        options: ExportOptions = .default
    ) throws -> Data {
        // 根据选项过滤配置
        let exportableConfig = createExportableConfiguration(configuration, options: options)

        // 编码为 JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if options.prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }

        do {
            let data = try encoder.encode(exportableConfig)

            // 如果需要加密，在这里处理
            if options.encryptSensitive {
                // 实现加密逻辑
                // 返回加密后的数据
            }

            return data
        } catch {
            throw ConfigurationError.exportFailed("Failed to encode configuration: \(error.localizedDescription)")
        }
    }

    /// 导出配置为 JSON 字符串
    public static func exportToString(
        _ configuration: AppConfiguration,
        options: ExportOptions = .default
    ) throws -> String {
        let data = try export(configuration, options: options)

        guard let string = String(data: data, encoding: .utf8) else {
            throw ConfigurationError.exportFailed("Failed to convert data to string")
        }

        return string
    }

    /// 导出到指定 URL
    public static func export(
        _ configuration: AppConfiguration,
        to url: URL,
        options: ExportOptions = .default
    ) throws {
        let data = try export(configuration, options: options)

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ConfigurationError.exportFailed("Failed to write to file: \(error.localizedDescription)")
        }
    }

    /// 导出引擎配置列表
    public static func exportEngineConfigurations(
        _ configurations: [EngineConfiguration],
        prettyPrint: Bool = true
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }

        return try encoder.encode(configurations)
    }

    // MARK: - Private Methods

    private static func createExportableConfiguration(
        _ configuration: AppConfiguration,
        options: ExportOptions
    ) -> ExportableConfiguration {
        return ExportableConfiguration(
            version: configuration.version,
            engineConfigurations: options.includeEngineConfigs ? configuration.engineConfigurations : nil,
            uiConfiguration: options.includeUIConfig ? configuration.uiConfiguration : nil,
            gameConfiguration: options.includeGameConfig ? configuration.gameConfiguration : nil,
            lastUsedEngineID: configuration.lastUsedEngineID,
            exportDate: Date(),
            exportOptions: options
        )
    }
}

// MARK: - Exportable Configuration

/// 可导出的配置结构
private struct ExportableConfiguration: Codable {
    let version: String
    let engineConfigurations: [EngineConfiguration]?
    let uiConfiguration: UIConfiguration?
    let gameConfiguration: GameConfiguration?
    let lastUsedEngineID: UUID?
    let exportDate: Date
    let exportOptions: ConfigurationExporter.ExportOptions
}
