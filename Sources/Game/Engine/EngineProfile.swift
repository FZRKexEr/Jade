import Foundation

// MARK: - EngineProfile

/// 引擎配置文件
/// 存储单个引擎的配置信息，包括路径、工作目录、UCI选项等
public struct EngineProfile: Identifiable, Codable, Sendable, Equatable, CustomStringConvertible {

    /// 唯一标识符
    public let id: UUID

    /// 引擎名称
    public var name: String

    /// 引擎可执行文件路径
    public var executablePath: String

    /// 工作目录 (可选)
    public var workingDirectory: String?

    /// 启动参数
    public var arguments: [String]

    /// 默认UCI选项
    public var defaultOptions: [String: String]

    /// 支持的变体列表 (如 xiangqi, chess 等)
    public var supportedVariants: [String]

    /// 引擎描述
    public var description: String?

    /// 引擎版本
    public var version: String?

    /// 作者信息
    public var author: String?

    /// 创建时间
    public let createdAt: Date

    /// 最后修改时间
    public var updatedAt: Date

    /// 是否启用
    public var isEnabled: Bool

    /// 是否为默认引擎
    public var isDefault: Bool

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        executablePath: String,
        workingDirectory: String? = nil,
        arguments: [String] = [],
        defaultOptions: [String: String] = [:],
        supportedVariants: [String] = ["xiangqi"],
        description: String? = nil,
        version: String? = nil,
        author: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isEnabled: Bool = true,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.executablePath = executablePath
        self.workingDirectory = workingDirectory
        self.arguments = arguments
        self.defaultOptions = defaultOptions
        self.supportedVariants = supportedVariants
        self.description = description
        self.version = version
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isEnabled = isEnabled
        self.isDefault = isDefault
    }

    // MARK: - Computed Properties

    public var description: String {
        let variantStr = supportedVariants.joined(separator: ", ")
        return "\(name) [\(variantStr)] - \(executablePath)"
    }

    /// 是否为有效的引擎配置
    public var isValid: Bool {
        !name.isEmpty && !executablePath.isEmpty
    }

    /// 支持中国象棋
    public var supportsXiangqi: Bool {
        supportedVariants.contains("xiangqi")
    }

    /// 支持国际象棋
    public var supportsChess: Bool {
        supportedVariants.contains("chess") || supportedVariants.contains("standard")
    }

    /// 转换为 EngineConfiguration
    public func toEngineConfiguration() -> EngineConfiguration {
        EngineConfiguration(
            id: id,
            name: name,
            executablePath: executablePath,
            workingDirectory: workingDirectory,
            arguments: arguments,
            defaultOptions: defaultOptions,
            supportedVariants: supportedVariants
        )
    }

    // MARK: - Factory Methods

    /// 创建 Pikafish 默认配置
    public static func pikafishDefault(path: String = "/usr/local/bin/pikafish") -> EngineProfile {
        EngineProfile(
            name: "Pikafish",
            executablePath: path,
            defaultOptions: [
                "Hash": "256",
                "Threads": "4",
                "UCI_Variant": "xiangqi"
            ],
            supportedVariants: ["xiangqi"],
            description: "基于 Stockfish 的中国象棋引擎",
            isDefault: true
        )
    }

    /// 创建引擎配置的副本
    public func copy(
        name: String? = nil,
        executablePath: String? = nil
    ) -> EngineProfile {
        EngineProfile(
            id: UUID(),
            name: name ?? self.name + " Copy",
            executablePath: executablePath ?? self.executablePath,
            workingDirectory: self.workingDirectory,
            arguments: self.arguments,
            defaultOptions: self.defaultOptions,
            supportedVariants: self.supportedVariants,
            description: self.description,
            version: self.version,
            author: self.author,
            isEnabled: self.isEnabled
        )
    }
}

// MARK: - EngineProfileManager

/// 引擎配置管理器
@MainActor
public final class EngineProfileManager: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var profiles: [EngineProfile] = []
    @Published public private(set) var defaultProfile: EngineProfile?

    // MARK: - Private Properties

    private let storageKey = "engine_profiles"
    private let defaultProfileKey = "default_engine_profile_id"

    // MARK: - Initialization

    public init() {
        loadProfiles()
    }

    // MARK: - Public Methods

    /// 添加引擎配置
    public func addProfile(_ profile: EngineProfile) {
        profiles.append(profile)

        // 如果这是第一个配置，设为默认
        if profiles.count == 1 {
            setDefaultProfile(profile)
        }

        saveProfiles()
    }

    /// 更新引擎配置
    public func updateProfile(_ profile: EngineProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updatedProfile = profile
            updatedProfile.updatedAt = Date()
            profiles[index] = updatedProfile

            // 如果更新的是默认配置，更新默认配置引用
            if defaultProfile?.id == profile.id {
                defaultProfile = updatedProfile
            }

            saveProfiles()
        }
    }

    /// 删除引擎配置
    public func removeProfile(_ profile: EngineProfile) {
        profiles.removeAll { $0.id == profile.id }

        // 如果删除的是默认配置，重新设置默认配置
        if defaultProfile?.id == profile.id {
            defaultProfile = profiles.first
            if let newDefault = defaultProfile {
                UserDefaults.standard.set(newDefault.id.uuidString, forKey: defaultProfileKey)
            } else {
                UserDefaults.standard.removeObject(forKey: defaultProfileKey)
            }
        }

        saveProfiles()
    }

    /// 设置默认引擎配置
    public func setDefaultProfile(_ profile: EngineProfile?) {
        defaultProfile = profile

        if let profile = profile {
            UserDefaults.standard.set(profile.id.uuidString, forKey: defaultProfileKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultProfileKey)
        }
    }

    /// 根据ID获取引擎配置
    public func getProfile(byId id: UUID) -> EngineProfile? {
        profiles.first { $0.id == id }
    }

    /// 获取可用的引擎配置列表
    public func getEnabledProfiles() -> [EngineProfile] {
        profiles.filter { $0.isEnabled }
    }

    /// 验证引擎配置是否有效
    public func validateProfile(_ profile: EngineProfile) -> [String] {
        var errors: [String] = []

        if profile.name.isEmpty {
            errors.append("引擎名称不能为空")
        }

        if profile.executablePath.isEmpty {
            errors.append("可执行文件路径不能为空")
        }

        // 检查路径是否存在 (仅在非沙盒环境下)
        #if !os(iOS)
        let fileManager = FileManager.default
        if !profile.executablePath.isEmpty && !fileManager.fileExists(atPath: profile.executablePath) {
            errors.append("可执行文件不存在: \(profile.executablePath)")
        }

        if let workingDir = profile.workingDirectory,
           !workingDir.isEmpty && !fileManager.fileExists(atPath: workingDir) {
            errors.append("工作目录不存在: \(workingDir)")
        }
        #endif

        return errors
    }

    // MARK: - Private Methods

    private func saveProfiles() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(profiles)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save engine profiles: \(error)")
        }
    }

    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            // 如果没有保存的配置，创建默认配置
            createDefaultProfiles()
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            profiles = try decoder.decode([EngineProfile].self, from: data)

            // 加载默认配置
            if let defaultIdString = UserDefaults.standard.string(forKey: defaultProfileKey),
               let defaultId = UUID(uuidString: defaultIdString) {
                defaultProfile = profiles.first { $0.id == defaultId }
            } else {
                defaultProfile = profiles.first
            }
        } catch {
            print("Failed to load engine profiles: \(error)")
            createDefaultProfiles()
        }
    }

    private func createDefaultProfiles() {
        // 创建 Pikafish 默认配置
        let pikafishProfile = EngineProfile.pikafishDefault()

        profiles = [pikafishProfile]
        defaultProfile = pikafishProfile

        saveProfiles()
    }
}
