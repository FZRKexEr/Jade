import Foundation
import Combine

// MARK: - GameRecord

/// 完整对局记录
/// 包含对局的所有信息：头信息、走棋序列、变着树、评注等
public final class GameRecord: Codable, Identifiable, ObservableObject, CustomStringConvertible {

    // MARK: - Properties

    /// 唯一标识符
    public let id: UUID

    /// 对局头信息
    @Published public var header: GameHeader

    /// 走棋序列（变着树的根节点）
    @Published public var rootNode: MoveNode

    /// 当前位置节点
    @Published public var currentNode: MoveNode

    /// 初始 FEN（非标准开局时使用）
    public var initialFEN: String?

    /// 创建时间
    public let createdAt: Date

    /// 最后修改时间
    @Published public var updatedAt: Date

    /// 文件路径（如果已保存）
    public var filePath: String?

    /// 文件格式
    public var fileFormat: GameFileFormat?

    /// 是否已修改
    @Published public var isModified: Bool = false

    // MARK: - Computed Properties

    /// 当前步数
    public var currentMoveNumber: Int {
        currentNode.moveNumber
    }

    /// 总步数（主变线长度）
    public var totalMoves: Int {
        rootNode.mainLine.count
    }

    /// 当前轮到哪方
    public var currentPlayer: Player {
        currentNode.move?.piece.player ?? .red
    }

    /// 对局是否已结束
    public var isEnded: Bool {
        header.result.isEnded
    }

    /// 获胜方 (如果有)
    public var winner: Player? {
        header.result.winner
    }

    /// 所有走棋记录（主变线）
    public var mainLineMoves: [Move] {
        rootNode.mainLine.compactMap { $0.move }
    }

    /// 变着数量
    public var variationCount: Int {
        countVariations(in: rootNode)
    }

    /// 评注数量
    public var commentCount: Int {
        countComments(in: rootNode)
    }

    /// 简洁描述
    public var shortDescription: String {
        "\(header.red) vs \(header.black) - \(header.resultDescription)"
    }

    // MARK: - Initialization

    /// 创建新的对局记录
    public init(
        id: UUID = UUID(),
        header: GameHeader = GameHeader(),
        initialFEN: String? = nil,
        filePath: String? = nil,
        fileFormat: GameFileFormat? = nil
    ) {
        self.id = id
        self.header = header
        self.rootNode = MoveNode.root()
        self.currentNode = rootNode
        self.initialFEN = initialFEN
        self.createdAt = Date()
        self.updatedAt = Date()
        self.filePath = filePath
        self.fileFormat = fileFormat

        // 设置双向绑定
        self.setupBindings()
    }

    /// 从变着树创建对局记录
    public convenience init(
        header: GameHeader,
        rootNode: MoveNode,
        initialFEN: String? = nil
    ) {
        self.init(header: header, initialFEN: initialFEN)
        self.rootNode = rootNode
        self.currentNode = rootNode
        self.setupBindings()
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, header, rootNode, initialFEN
        case createdAt, updatedAt, filePath, fileFormat
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(UUID.self, forKey: .id)
        self.header = try container.decode(GameHeader.self, forKey: .header)
        self.rootNode = try container.decode(MoveNode.self, forKey: .rootNode)
        self.currentNode = self.rootNode
        self.initialFEN = try container.decodeIfPresent(String.self, forKey: .initialFEN)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.filePath = try container.decodeIfPresent(String.self, forKey: .filePath)
        self.fileFormat = try container.decodeIfPresent(GameFileFormat.self, forKey: .fileFormat)

        self.setupBindings()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(header, forKey: .header)
        try container.encode(rootNode, forKey: .rootNode)
        try container.encode(initialFEN, forKey: .initialFEN)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(filePath, forKey: .filePath)
        try container.encode(fileFormat, forKey: .fileFormat)
    }

    // MARK: - Bindings

    private func setupBindings() {
        // 监听header变化
        header.objectWillChange
            .sink { [weak self] _ in
                self?.markModified()
            }
            .store(in: &cancellables)

        // 监听rootNode变化
        rootNode.objectWillChange
            .sink { [weak self] _ in
                self?.markModified()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func markModified() {
        isModified = true
        updatedAt = Date()
    }

    // MARK: - Navigation Methods

    /// 向前一步（主变）
    @discardableResult
    public func goForward() -> Bool {
        guard let next = currentNode.mainVariation else { return false }
        currentNode = next
        return true
    }

    /// 向后一步
    @discardableResult
    public func goBackward() -> Bool {
        guard let parent = currentNode.parent, parent != currentNode else { return false }
        currentNode = parent
        return true
    }

    /// 跳到开始
    public func goToStart() {
        currentNode = rootNode
    }

    /// 跳到结束（主变线末尾）
    public func goToEnd() {
        while let next = currentNode.mainVariation {
            currentNode = next
        }
    }

    /// 跳到指定步数
    @discardableResult
    public func goToMove(_ moveNumber: Int) -> Bool {
        goToStart()
        for _ in 0..<moveNumber {
            if !goForward() {
                return false
            }
        }
        return true
    }

    /// 跳转到指定节点
    public func goToNode(_ node: MoveNode) {
        // 验证节点是否在当前树中
        if rootNode.allNodes.contains(where: { $0.id == node.id }) {
            currentNode = node
        }
    }

    // MARK: - Move Recording

    /// 添加走棋（主变）
    @discardableResult
    public func addMove(_ move: Move) -> MoveNode {
        // 检查是否已存在相同的走法
        if let existing = currentNode.mainVariation,
           existing.move?.from == move.from && existing.move?.to == move.to {
            currentNode = existing
            return existing
        }

        let newNode = MoveNode(move: move)
        currentNode.addMainVariation(newNode)
        currentNode = newNode
        markModified()
        return newNode
    }

    /// 添加变着
    @discardableResult
    public func addVariation(_ move: Move) -> MoveNode {
        // 在变着父节点添加变着
        guard let parent = currentNode.parent else {
            // 如果没有父节点，直接添加到根节点
            let newNode = MoveNode(move: move, moveNumber: 1)
            rootNode.addVariation(newNode)
            markModified()
            return newNode
        }

        let newNode = MoveNode(move: move)
        parent.addVariation(newNode)
        currentNode = newNode
        markModified()
        return newNode
    }

    /// 删除当前节点及其子树
    @discardableResult
    public func deleteCurrentNode() -> Bool {
        guard let parent = currentNode.parent else { return false }

        // 如果是主变，将第一个变着提升为主变
        if parent.mainVariation?.id == currentNode.id {
            if let firstVariation = parent.variations.first {
                parent.mainVariation = firstVariation
                parent.variations.removeFirst()
            } else {
                parent.mainVariation = nil
            }
        } else {
            // 从变着列表中移除
            parent.removeVariation(currentNode)
        }

        currentNode = parent
        markModified()
        return true
    }

    /// 提升变着为主变
    @discardableResult
    public func promoteVariation(_ node: MoveNode) -> Bool {
        guard let parent = node.parent else { return false }
        guard let currentMain = parent.mainVariation else { return false }

        // 找到变着索引
        guard let variationIndex = parent.variations.firstIndex(where: { $0.id == node.id }) else {
            return false
        }

        // 交换主变和指定变着
        parent.variations[variationIndex] = currentMain
        parent.mainVariation = node

        markModified()
        return true
    }

    // MARK: - Comment Operations

    /// 在当前节点添加前评注
    public func addPreComment(_ comment: String) {
        currentNode.addPreComment(comment)
        markModified()
    }

    /// 在当前节点添加后评注
    public func addPostComment(_ comment: String) {
        currentNode.addPostComment(comment)
        markModified()
    }

    /// 设置评价符号
    public func setEvaluationSymbol(_ symbol: EvaluationSymbol) {
        currentNode.setEvaluationSymbol(symbol)
        markModified()
    }

    /// 清除当前节点的所有评注
    public func clearCurrentComments() {
        currentNode.clearComments()
        markModified()
    }

    // MARK: - Utility Methods

    /// 重置对局到开始状态
    public func reset() {
        currentNode = rootNode
    }

    /// 清空所有走法
    public func clearMoves() {
        rootNode = MoveNode.root()
        currentNode = rootNode
        markModified()
    }

    /// 统计变着数量
    private func countVariations(in node: MoveNode) -> Int {
        var count = node.variations.count
        for child in node.allVariations {
            count += countVariations(in: child)
        }
        return count
    }

    /// 统计评注数量
    private func countComments(in node: MoveNode) -> Int {
        var count = 0
        if let pre = node.preComment, !pre.isEmpty { count += 1 }
        if let post = node.postComment, !post.isEmpty { count += 1 }
        for child in node.allVariations {
            count += countComments(in: child)
        }
        return count
    }

    /// 验证节点树完整性
    public func validateTree() -> [String] {
        var errors: [String] = []
        validateNode(rootNode, errors: &errors, visited: [])
        return errors
    }

    private func validateNode(_ node: MoveNode, errors: inout [String], visited: Set<UUID>) {
        if visited.contains(node.id) {
            errors.append("检测到循环引用: \(node.id)")
            return
        }

        var newVisited = visited
        newVisited.insert(node.id)

        // 验证主变
        if let main = node.mainVariation {
            if main.parent?.id != node.id {
                errors.append("主变父节点不匹配: \(main.id)")
            }
            validateNode(main, errors: &errors, visited: newVisited)
        }

        // 验证变着
        for variation in node.variations {
            if variation.parent?.id != node.id {
                errors.append("变着父节点不匹配: \(variation.id)")
            }
            validateNode(variation, errors: &errors, visited: newVisited)
        }
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        """
        GameRecord: \(header.event)
        \(header.red) vs \(header.black)
        Result: \(header.resultDescription)
        Moves: \(totalMoves), Variations: \(variationCount), Comments: \(commentCount)
        Current: Step \(currentMoveNumber)
        """
    }
}

// MARK: - GameFileFormat

/// 棋谱文件格式
public enum GameFileFormat: String, Codable, Equatable, Sendable, CustomStringConvertible {
    /// PGN 格式 (Portable Game Notation)
    case pgn = "pgn"

    /// CBL 格式 (ChessBase)
    case cbl = "cbl"

    /// WXF 格式 (王前易位)
    case wxf = "wxf"

    /// XQF 格式 (象棋桥)
    case xqf = "xqf"

    /// 自定义 JSON 格式
    case json = "json"

    /// 未知格式
    case unknown = "unknown"

    public var description: String {
        switch self {
        case .pgn:
            return "PGN 格式"
        case .cbl:
            return "CBL 格式"
        case .wxf:
            return "WXF 格式"
        case .xqf:
            return "XQF 格式"
        case .json:
            return "JSON 格式"
        case .unknown:
            return "未知格式"
        }
    }

    /// 文件扩展名
    public var fileExtension: String {
        rawValue
    }

    /// MIME 类型
    public var mimeType: String {
        switch self {
        case .pgn:
            return "application/x-chess-pgn"
        case .cbl:
            return "application/x-chessbase"
        case .wxf:
            return "application/x-wxf"
        case .xqf:
            return "application/x-xqf"
        case .json:
            return "application/json"
        case .unknown:
            return "application/octet-stream"
        }
    }

    /// 从文件路径检测格式
    public static func detect(from path: String) -> GameFileFormat {
        let lowercased = path.lowercased()
        if lowercased.hasSuffix(".pgn") {
            return .pgn
        } else if lowercased.hasSuffix(".cbl") {
            return .cbl
        } else if lowercased.hasSuffix(".wxf") {
            return .wxf
        } else if lowercased.hasSuffix(".xqf") {
            return .xqf
        } else if lowercased.hasSuffix(".json") {
            return .json
        }
        return .unknown
    }
}