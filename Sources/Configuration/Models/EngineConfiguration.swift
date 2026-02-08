import Foundation

// MARK: - Engine Configuration

/// 引擎配置模型
public struct EngineConfiguration: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var executablePath: String
    public var workingDirectory: String?
    public var arguments: [String]
    public var defaultOptions: [String: String]
    public var supportedVariants: [String]
    public var isDefault: Bool
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        executablePath: String,
        workingDirectory: String? = nil,
        arguments: [String] = [],
        defaultOptions: [String: String] = [:],
        supportedVariants: [String] = ["xiangqi"],
        isDefault: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.executablePath = executablePath
        self.workingDirectory = workingDirectory
        self.arguments = arguments
        self.defaultOptions = defaultOptions
        self.supportedVariants = supportedVariants
        self.isDefault = isDefault
        self.isEnabled = isEnabled
    }

    /// 获取完整的可执行文件路径（解析 ~ 等符号）
    public var resolvedExecutablePath: String {
        NSString(string: executablePath).expandingTildeInPath
    }

    /// 验证配置是否有效
    public func validate() -> [EngineConfigurationError] {
        var errors: [EngineConfigurationError] = []

        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.emptyName)
        }

        if executablePath.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.emptyPath)
        }

        let resolvedPath = resolvedExecutablePath
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: resolvedPath) {
            errors.append(.fileNotFound(resolvedPath))
        } else if !fileManager.isExecutableFile(atPath: resolvedPath) {
            errors.append(.notExecutable(resolvedPath))
        }

        return errors
    }

    /// 检查配置是否有效
    public var isValid: Bool {
        validate().isEmpty
    }
}

// MARK: - Configuration Errors

public enum EngineConfigurationError: Error, Equatable, Sendable {
    case emptyName
    case emptyPath
    case fileNotFound(String)
    case notExecutable(String)
    case invalidVariant(String)
    case configurationNotFound(UUID)
    case saveFailed(String)
    case loadFailed(String)

    public var localizedDescription: String {
        switch self {
        case .emptyName:
            return "引擎名称不能为空"
        case .emptyPath:
            return "可执行文件路径不能为空"
        case .fileNotFound(let path):
            return "找不到文件: \(path)"
        case .notExecutable(let path):
            return "文件没有可执行权限: \(path)"
        case .invalidVariant(let variant):
            return "不支持的变体: \(variant)"
        case .configurationNotFound(let id):
            return "找不到配置: \(id)"
        case .saveFailed(let reason):
            return "保存配置失败: \(reason)"
        case .loadFailed(let reason):
            return "加载配置失败: \(reason)"
        }
    }
}

// MARK: - Default Configurations

extension EngineConfiguration {
    /// Pikafish 默认配置
    public static let pikafishDefault = EngineConfiguration(
        name: "Pikafish",
        executablePath: "/usr/local/bin/pikafish",
        defaultOptions: [
            "Hash": "256",
            "Threads": "4",
            "UCI_Variant": "xiangqi",
            "UCI_LimitStrength": "false",
            "UCI_Elo": "3000"
        ],
        supportedVariants: ["xiangqi", "chess"],
        isDefault: true
    )

    /// 创建自定义 Pikafish 配置
    public static func pikafish(at path: String) -> EngineConfiguration {
        var config = pikafishDefault
        config.executablePath = path
        return config
    }

    /// Stockfish 配置（需要适配中国象棋变体）
    public static let stockfishDefault = EngineConfiguration(
        name: "Stockfish",
        executablePath: "/usr/local/bin/stockfish",
        defaultOptions: [
            "Hash": "256",
            "Threads": "4",
            "UCI_Variant": "xiangqi"
        ],
        supportedVariants: ["xiangqi", "chess", "antichess"]
    )
}
