import Foundation

// MARK: - Configuration Store Protocol

/// 配置存储协议
public protocol ConfigurationStore: Sendable {
    /// 加载配置
    func load() async throws -> AppConfiguration

    /// 保存配置
    func save(_ configuration: AppConfiguration) async throws

    /// 删除配置
    func delete() async throws

    /// 检查配置是否存在
    func exists() async -> Bool
}

// MARK: - Configuration Store Error

public enum ConfigurationStoreError: Error, Equatable, Sendable {
    case notFound
    case decodeFailed(String)
    case encodeFailed(String)
    case writeFailed(String)
    case readFailed(String)
    case invalidData(String)

    public var localizedDescription: String {
        switch self {
        case .notFound:
            return "配置不存在"
        case .decodeFailed(let reason):
            return "解析配置失败: \(reason)"
        case .encodeFailed(let reason):
            return "编码配置失败: \(reason)"
        case .writeFailed(let reason):
            return "写入配置失败: \(reason)"
        case .readFailed(let reason):
            return "读取配置失败: \(reason)"
        case .invalidData(let reason):
            return "数据无效: \(reason)"
        }
    }
}
