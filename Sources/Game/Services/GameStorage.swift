import Foundation
import Combine

// MARK: - GameStorage

/// 棋谱存储管理器
/// 负责保存/加载棋谱文件，支持多种格式，管理最近棋谱列表
@MainActor
public final class GameStorage: ObservableObject {

    // MARK: - Properties

    /// 存储的棋谱列表
    @Published public private(set) var records: [GameRecord] = []

    /// 最近棋谱列表
    @Published public private(set) var recentRecords: [RecentRecord] = []

    /// 当前选中的棋谱
    @Published public var selectedRecord: GameRecord?

    /// 存储目录 URL
    public let storageURL: URL

    /// 最近棋谱列表文件 URL
    private let recentListURL: URL

    /// 最近棋谱最大数量
    public var maxRecentRecords: Int = 20

    /// 自动保存间隔（秒）
    public var autoSaveInterval: TimeInterval = 30

    /// 是否启用 iCloud 同步
    @Published public var isiCloudSyncEnabled: Bool = false

    /// 是否正在加载
    @Published public private(set) var isLoading: Bool = false

    /// 错误信息
    @Published public private(set) var lastError: StorageError?

    /// 自动保存定时器
    private var autoSaveTimer: Timer?

    /// 订阅集合
    private var cancellables = Set<AnyCancellable>()

    /// 通知中心
    private let notificationCenter = NotificationCenter.default

    // MARK: - Types

    /// 最近记录条目
    public struct RecentRecord: Codable, Identifiable, Equatable {
        public let id: UUID
        public let fileName: String
        public let filePath: String
        public let format: GameFileFormat
        public let lastOpened: Date
        public let red: String
        public let black: String
        public let result: String
        public let totalMoves: Int

        public init(
            id: UUID = UUID(),
            fileName: String,
            filePath: String,
            format: GameFileFormat,
            lastOpened: Date = Date(),
            red: String,
            black: String,
            result: String,
            totalMoves: Int
        ) {
            self.id = id
            self.fileName = fileName
            self.filePath = filePath
            self.format = format
            self.lastOpened = lastOpened
            self.red = red
            self.black = black
            self.result = result
            self.totalMoves = totalMoves
        }
    }

    /// 存储错误
    public enum StorageError: Error, CustomStringConvertible {
        case fileNotFound(String)
        case invalidFormat(String)
        case saveFailed(String)
        case loadFailed(String)
        case deleteFailed(String)
        case exportFailed(String)
        case importFailed(String)
        case iCloudNotAvailable(String)
        case permissionDenied(String)

        public var description: String {
            switch self {
            case .fileNotFound(let path):
                return "文件未找到: \(path)"
            case .invalidFormat(let msg):
                return "格式无效: \(msg)"
            case .saveFailed(let msg):
                return "保存失败: \(msg)"
            case .loadFailed(let msg):
                return "加载失败: \(msg)"
            case .deleteFailed(let msg):
                return "删除失败: \(msg)"
            case .exportFailed(let msg):
                return "导出失败: \(msg)"
            case .importFailed(let msg):
                return "导入失败: \(msg)"
            case .iCloudNotAvailable(let msg):
                return "iCloud 不可用: \(msg)"
            case .permissionDenied(let msg):
                return "权限被拒绝: \(msg)"
            }
        }
    }

    // MARK: - Initialization

    /// 创建存储管理器
    /// - Parameter storageURL: 存储目录，默认使用应用支持目录
    public init(storageURL: URL? = nil) {
        if let url = storageURL {
            self.storageURL = url
        } else {
            // 使用应用支持目录
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.storageURL = appSupport.appendingPathComponent("ChineseChess/Games", isDirectory: true)
        }

        self.recentListURL = self.storageURL.appendingPathComponent("recent.plist")

        // 创建存储目录
        try? FileManager.default.createDirectory(at: self.storageURL, withIntermediateDirectories: true)

        // 加载最近列表
        loadRecentList()
    }

    // MARK: - File Operations

    /// 保存棋谱到文件
    /// - Parameters:
    ///   - record: 要保存的棋谱
    ///   - format: 文件格式
    ///   - fileName: 文件名（可选，默认自动生成）
    /// - Returns: 保存的文件路径
    @discardableResult
    public func save(
        _ record: GameRecord,
        format: GameFileFormat = .pgn,
        fileName: String? = nil
    ) async throws -> URL {
        isLoading = true
        defer { isLoading = false }

        // 确定文件名
        let actualFileName: String
        if let name = fileName {
            actualFileName = name.hasSuffix(".\(format.rawValue)") ? name : "\(name).\(format.rawValue)"
        } else {
            let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            actualFileName = "\(record.header.red)_vs_\(record.header.black)_\(dateStr).\(format.rawValue)"
        }

        let fileURL = storageURL.appendingPathComponent(actualFileName)

        // 根据格式序列化
        let content: String
        switch format {
        case .pgn:
            content = PGNParser.generate(record)
        case .wxf:
            // WXF 格式需要实现专门的生成器
            content = generateWXF(record)
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(record)
            content = String(data: data, encoding: .utf8) ?? "{}"
        default:
            throw StorageError.invalidFormat("不支持的保存格式: \(format)")
        }

        // 写入文件
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        // 更新记录信息
        record.filePath = fileURL.path
        record.fileFormat = format
        record.isModified = false

        // 添加到最近列表
        addToRecent(record: record, filePath: fileURL.path, format: format)

        // 发送通知
        notificationCenter.post(
            name: .gameSaved,
            object: self,
            userInfo: ["recordId": record.id, "filePath": fileURL.path]
        )

        return fileURL
    }

    /// 从文件加载棋谱
    public func load(from fileURL: URL) async throws -> GameRecord {
        isLoading = true
        defer { isLoading = false }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw StorageError.fileNotFound(fileURL.path)
        }

        // 检测文件格式
        let format = GameFileFormat.detect(from: fileURL.path)

        // 读取文件内容
        let content = try String(contentsOf: fileURL, encoding: .utf8)

        // 根据格式解析
        let record: GameRecord
        switch format {
        case .pgn:
            record = try PGNParser.parse(content)
        case .json:
            let data = content.data(using: .utf8) ?? Data()
            record = try JSONDecoder().decode(GameRecord.self, from: data)
        case .wxf:
            // WXF 格式需要实现专门的解析器
            throw StorageError.invalidFormat("WXF 格式解析器尚未实现")
        default:
            throw StorageError.invalidFormat("无法识别的文件格式: \(format)")
        }

        // 更新记录信息
        record.filePath = fileURL.path
        record.fileFormat = format
        record.isModified = false

        // 添加到最近列表
        addToRecent(record: record, filePath: fileURL.path, format: format)

        // 发送通知
        notificationCenter.post(
            name: .gameLoaded,
            object: self,
            userInfo: ["recordId": record.id, "filePath": fileURL.path]
        )

        return record
    }

    /// 删除棋谱文件
    public func delete(fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw StorageError.fileNotFound(fileURL.path)
        }

        try FileManager.default.removeItem(at: fileURL)

        // 从最近列表中移除
        removeFromRecent(filePath: fileURL.path)

        // 发送通知
        notificationCenter.post(
            name: .gameDeleted,
            object: self,
            userInfo: ["filePath": fileURL.path]
        )
    }

    /// 导出棋谱到指定位置
    public func export(
        _ record: GameRecord,
        to destinationURL: URL,
        format: GameFileFormat = .pgn
    ) async throws {
        let fileURL = destinationURL.hasDirectoryPath
            ? destinationURL.appendingPathComponent("\(record.id).\(format.rawValue)")
            : destinationURL

        // 保存到目标位置
        _ = try await save(record, format: format, fileName: fileURL.lastPathComponent)
    }

    /// 导入棋谱
    public func importGame(from sourceURL: URL) async throws -> GameRecord {
        let record = try await load(from: sourceURL)

        // 复制到存储目录
        let fileName = "\(record.id).\(record.fileFormat?.rawValue ?? "pgn")"
        let destinationURL = storageURL.appendingPathComponent(fileName)

        if sourceURL.path != destinationURL.path {
            try? FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            record.filePath = destinationURL.path
        }

        return record
    }

    /// 列出所有存储的棋谱
    public func listAllGames() async -> [GameRecord] {
        var records: [GameRecord] = []

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: nil)

            for fileURL in contents {
                guard ["pgn", "json", "wxf", "xqf"].contains(fileURL.pathExtension.lowercased()) else {
                    continue
                }

                do {
                    let record = try await load(from: fileURL)
                    records.append(record)
                } catch {
                    print("加载棋谱失败 \(fileURL.path): \(error)")
                }
            }
        } catch {
            print("列出棋谱失败: \(error)")
        }

        return records.sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - Recent Records

    /// 加载最近列表
    private func loadRecentList() {
        guard FileManager.default.fileExists(atPath: recentListURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: recentListURL)
            let records = try PropertyListDecoder().decode([RecentRecord].self, from: data)
            self.recentRecords = records
        } catch {
            print("加载最近列表失败: \(error)")
        }
    }

    /// 保存最近列表
    private func saveRecentList() {
        do {
            let data = try PropertyListEncoder().encode(recentRecords)
            try data.write(to: recentListURL)
        } catch {
            print("保存最近列表失败: \(error)")
        }
    }

    /// 添加到最近列表
    private func addToRecent(record: GameRecord, filePath: String, format: GameFileFormat) {
        // 移除已存在的条目
        recentRecords.removeAll { $0.filePath == filePath }

        // 创建新条目
        let recent = RecentRecord(
            fileName: (filePath as NSString).lastPathComponent,
            filePath: filePath,
            format: format,
            lastOpened: Date(),
            red: record.header.red,
            black: record.header.black,
            result: record.header.resultDescription,
            totalMoves: record.totalMoves
        )

        // 添加到开头
        recentRecords.insert(recent, at: 0)

        // 限制数量
        if recentRecords.count > maxRecentRecords {
            recentRecords.removeLast()
        }

        // 保存
        saveRecentList()
    }

    /// 从最近列表中移除
    private func removeFromRecent(filePath: String) {
        recentRecords.removeAll { $0.filePath == filePath }
        saveRecentList()
    }

    /// 清空最近列表
    public func clearRecentList() {
        recentRecords.removeAll()
        saveRecentList()
    }

    /// 从最近列表加载棋谱
    public func loadFromRecent(_ recent: RecentRecord) async throws -> GameRecord {
        let fileURL = URL(fileURLWithPath: recent.filePath)
        return try await load(from: fileURL)
    }

    // MARK: - iCloud Sync (Optional)

    #if os(iOS) || os(macOS)
    /// 启用 iCloud 同步
    public func enableiCloudSync() async throws {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            throw StorageError.iCloudNotAvailable("iCloud 账户未登录")
        }

        // 获取 iCloud 容器
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            throw StorageError.iCloudNotAvailable("无法访问 iCloud 容器")
        }

        let iCloudGamesURL = iCloudURL.appendingPathComponent("Games", isDirectory: true)

        // 确保目录存在
        try? FileManager.default.createDirectory(at: iCloudGamesURL, withIntermediateDirectories: true)

        // TODO: 实现双向同步逻辑

        isiCloudSyncEnabled = true
    }

    /// 禁用 iCloud 同步
    public func disableiCloudSync() {
        isiCloudSyncEnabled = false
        // TODO: 清理 iCloud 相关数据
    }
    #endif

    // MARK: - Utility Methods

    /// 搜索棋谱
    public func searchRecords(
        keyword: String,
        player: String? = nil,
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) async -> [GameRecord] {
        let allRecords = await listAllGames()

        return allRecords.filter { record in
            // 关键词搜索
            if !keyword.isEmpty {
                let searchText = "\(record.header.event) \(record.header.red) \(record.header.black) \(record.header.site)"
                if !searchText.localizedCaseInsensitiveContains(keyword) {
                    return false
                }
            }

            // 选手过滤
            if let player = player, !player.isEmpty {
                if record.header.red != player && record.header.black != player {
                    return false
                }
            }

            // 日期范围
            if let from = dateFrom, record.createdAt < from {
                return false
            }
            if let to = dateTo, record.createdAt > to {
                return false
            }

            return true
        }
    }

    /// 生成文件名
    public static func generateFileName(for record: GameRecord, format: GameFileFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateStr = dateFormatter.string(from: record.createdAt)

        let red = record.header.red.replacingOccurrences(of: " ", with: "_")
        let black = record.header.black.replacingOccurrences(of: " ", with: "_")

        return "\(dateStr)_\(red)_vs_\(black).\(format.rawValue)"
    }

    // MARK: - Private Helper Methods

    /// 生成 WXF 格式（简化实现）
    private func generateWXF(_ record: GameRecord) -> String {
        var lines: [String] = []

        // 文件头
        lines.append("[Game \"Chinese Chess\"]")
        lines.append("[Event \"\(record.header.event)\"]")
        lines.append("[Date \"\(record.header.date)\"]")
        lines.append("[Red \"\(record.header.red)\"]")
        lines.append("[Black \"\(record.header.black)\"]")
        lines.append("[Result \"\(record.header.result.pgnString)\"]")
        lines.append("")

        // 走法
        let moves = record.rootNode.mainLine.compactMap { $0.move }
        for (index, move) in moves.enumerated() {
            let moveNumber = index / 2 + 1
            let isRed = index % 2 == 0

            if isRed {
                lines.append("\(moveNumber). \(move.chineseNotation ?? move.description)")
            } else {
                lines.append("   \(move.chineseNotation ?? move.description)")
            }
        }

        lines.append("")
        lines.append(record.header.result.pgnString)

        return lines.joined(separator: "\n")
    }
}

// MARK: - Notifications

extension Notification.Name {
    public static let gameSaved = Notification.Name("GameStorage.gameSaved")
    public static let gameLoaded = Notification.Name("GameStorage.gameLoaded")
    public static let gameDeleted = Notification.Name("GameStorage.gameDeleted")
}