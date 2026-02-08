import Foundation

// MARK: - UserDefaults Configuration Store

/// UserDefaults 配置存储实现
public actor UserDefaultsStore: ConfigurationStore {

    // MARK: - Singleton

    public static let shared = UserDefaultsStore()

    // MARK: - Properties

    private let defaults: UserDefaults
    private let key: String

    // MARK: - Initialization

    public init(defaults: UserDefaults = .standard, key: String = "app.configuration") {
        self.defaults = defaults
        self.key = key
    }

    // MARK: - ConfigurationStore

    public func load() async throws -> AppConfiguration {
        guard let data = defaults.data(forKey: key) else {
            throw ConfigurationStoreError.notFound
        }

        do {
            let configuration = try JSONDecoder().decode(AppConfiguration.self, from: data)
            return configuration
        } catch {
            throw ConfigurationStoreError.decodeFailed(error.localizedDescription)
        }
    }

    public func save(_ configuration: AppConfiguration) async throws {
        do {
            let data = try JSONEncoder().encode(configuration)
            defaults.set(data, forKey: key)

            // 同步保存
            if !defaults.synchronize() {
                throw ConfigurationStoreError.writeFailed("Failed to synchronize UserDefaults")
            }
        } catch let error as ConfigurationStoreError {
            throw error
        } catch {
            throw ConfigurationStoreError.encodeFailed(error.localizedDescription)
        }
    }

    public func delete() async throws {
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }

    public func exists() async -> Bool {
        defaults.data(forKey: key) != nil
    }

    // MARK: - Additional Methods

    /// 清除所有配置（包括备份）
    public func clearAll() async {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: key + ".backup")
        defaults.synchronize()
    }

    /// 创建备份
    public func createBackup() async throws {
        guard let data = defaults.data(forKey: key) else {
            return
        }
        defaults.set(data, forKey: key + ".backup")
        defaults.synchronize()
    }

    /// 从备份恢复
    public func restoreFromBackup() async throws {
        guard let data = defaults.data(forKey: key + ".backup") else {
            throw ConfigurationStoreError.notFound
        }
        defaults.set(data, forKey: key)
        defaults.synchronize()
    }

    /// 获取原始数据（用于调试）
    public func getRawData() -> Data? {
        defaults.data(forKey: key)
    }
}

// MARK: - AppStorage Support

import SwiftUI

extension AppConfiguration {
    /// 创建 AppStorage 兼容的配置绑定
    public static func appStorageBinding() -> Binding<AppConfiguration> {
        @AppStorage("app.configuration") var storedData: Data?

        return Binding(
            get: {
                guard let data = storedData else {
                    return AppConfiguration.default
                }
                do {
                    return try JSONDecoder().decode(AppConfiguration.self, from: data)
                } catch {
                    return AppConfiguration.default
                }
            },
            set: { newValue in
                do {
                    storedData = try JSONEncoder().encode(newValue)
                } catch {
                    // 保存失败时静默处理
                }
            }
        )
    }
}
