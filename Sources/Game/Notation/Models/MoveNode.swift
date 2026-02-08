import Foundation

// MARK: - MoveNode

/// 走棋节点（变着树节点）
/// 支持主变、变着、评注等复杂棋谱结构
public final class MoveNode: Codable, Identifiable, Equatable, CustomStringConvertible, ObservableObject {

    // MARK: - Properties

    /// 节点唯一标识
    public let id: UUID

    /// 走棋记录（根节点可能为nil）
    public var move: Move?

    /// 节点序号（从1开始，表示这是第几步）
    public var moveNumber: Int

    /// 主变（主要走法）
    public var mainVariation: MoveNode?

    /// 变着列表（替代走法）
    public var variations: [MoveNode]

    /// 前评注（走棋前的评注）
    public var preComment: String?

    /// 后评注（走棋后的评注）
    public var postComment: String?

    /// 评价符号（!, !!, ?, ??, !?）
    public var evaluationSymbol: EvaluationSymbol?

    /// 创建时间
    public let createdAt: Date

    /// 父节点（用于向上导航，不编码）
    public weak var parent: MoveNode?

    // MARK: - Initialization

    /// 创建走棋节点
    public init(
        id: UUID = UUID(),
        move: Move? = nil,
        moveNumber: Int = 0,
        mainVariation: MoveNode? = nil,
        variations: [MoveNode] = [],
        preComment: String? = nil,
        postComment: String? = nil,
        evaluationSymbol: EvaluationSymbol? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.move = move
        self.moveNumber = moveNumber
        self.mainVariation = mainVariation
        self.variations = variations
        self.preComment = preComment
        self.postComment = postComment
        self.evaluationSymbol = evaluationSymbol
        self.createdAt = createdAt

        // 设置子节点的父节点
        mainVariation?.parent = self
        for variation in variations {
            variation.parent = self
        }
    }

    /// 创建根节点
    public static func root() -> MoveNode {
        MoveNode(move: nil, moveNumber: 0)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, move, moveNumber, mainVariation, variations
        case preComment, postComment, evaluationSymbol, createdAt
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(move, forKey: .move)
        try container.encode(moveNumber, forKey: .moveNumber)
        try container.encode(mainVariation, forKey: .mainVariation)
        try container.encode(variations, forKey: .variations)
        try container.encode(preComment, forKey: .preComment)
        try container.encode(postComment, forKey: .postComment)
        try container.encode(evaluationSymbol, forKey: .evaluationSymbol)
        try container.encode(createdAt, forKey: .createdAt)
    }

    // MARK: - Equatable

    public static func == (lhs: MoveNode, rhs: MoveNode) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        var parts: [String] = []

        if let preComment = preComment, !preComment.isEmpty {
            parts.append("{\(preComment)}")
        }

        if let move = move {
            if move.piece.player == .red {
                parts.append("\(moveNumber).")
            }
            if let notation = move.chineseNotation {
                parts.append(notation)
            } else {
                parts.append(move.description)
            }
        }

        if let symbol = evaluationSymbol {
            parts.append(symbol.rawValue)
        }

        if let postComment = postComment, !postComment.isEmpty {
            parts.append("{\(postComment)}")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Tree Operations

    /// 添加主变
    @discardableResult
    public func addMainVariation(_ node: MoveNode) -> MoveNode {
        node.moveNumber = self.moveNumber + 1
        node.parent = self
        self.mainVariation = node
        return node
    }

    /// 添加变着
    @discardableResult
    public func addVariation(_ node: MoveNode) -> MoveNode {
        node.moveNumber = self.moveNumber
        node.parent = self
        self.variations.append(node)
        return node
    }

    /// 移除指定的变着
    public func removeVariation(_ node: MoveNode) -> Bool {
        guard let index = variations.firstIndex(where: { $0.id == node.id }) else {
            return false
        }
        variations.remove(at: index)
        return true
    }

    /// 获取所有变着（包括主变的第一个变着）
    public var allVariations: [MoveNode] {
        var result: [MoveNode] = []
        if let main = mainVariation {
            result.append(main)
        }
        result.append(contentsOf: variations)
        return result
    }

    // MARK: - Navigation

    /// 是否是根节点
    public var isRoot: Bool {
        parent == nil && move == nil
    }

    /// 是否是叶节点（没有后续走法）
    public var isLeaf: Bool {
        mainVariation == nil && variations.isEmpty
    }

    /// 获取根节点
    public var rootNode: MoveNode {
        var current: MoveNode = self
        while let parent = current.parent {
            current = parent
        }
        return current
    }

    /// 获取到根节点的路径
    public var pathFromRoot: [MoveNode] {
        var path: [MoveNode] = []
        var current: MoveNode? = self
        while let node = current {
            path.insert(node, at: 0)
            current = node.parent
        }
        return path
    }

    /// 获取从起点到当前节点的走法序列
    public var moveSequence: [Move] {
        pathFromRoot.compactMap { $0.move }
    }

    /// 获取主变线（从当前节点开始的第一个主变序列）
    public var mainLine: [MoveNode] {
        var result: [MoveNode] = []
        var current: MoveNode? = self.mainVariation
        while let node = current {
            result.append(node)
            current = node.mainVariation
        }
        return result
    }

    /// 获取以当前节点为根的完整主变树（所有走法）
    public var allNodes: [MoveNode] {
        var result: [MoveNode] = [self]
        for child in allVariations {
            result.append(contentsOf: child.allNodes)
        }
        return result
    }

    /// 获取节点深度（到根节点的距离）
    public var depth: Int {
        pathFromRoot.count - 1
    }

    /// 在树中查找包含指定走法的节点
    public func findNode(withMove moveId: UUID) -> MoveNode? {
        if self.id == moveId || self.move?.id == moveId {
            return self
        }
        for child in allVariations {
            if let found = child.findNode(withMove: moveId) {
                return found
            }
        }
        return nil
    }

    // MARK: - Comment Operations

    /// 添加前评注
    public func addPreComment(_ comment: String) {
        if let existing = preComment, !existing.isEmpty {
            preComment = existing + " " + comment
        } else {
            preComment = comment
        }
    }

    /// 添加后评注
    public func addPostComment(_ comment: String) {
        if let existing = postComment, !existing.isEmpty {
            postComment = existing + " " + comment
        } else {
            postComment = comment
        }
    }

    /// 设置评价符号
    public func setEvaluationSymbol(_ symbol: EvaluationSymbol) {
        self.evaluationSymbol = symbol
    }

    /// 清除所有评注
    public func clearComments() {
        preComment = nil
        postComment = nil
        evaluationSymbol = nil
    }

    // MARK: - Export

    /// 导出为 PGN 格式的走法字符串
    public func toPGNString() -> String {
        var parts: [String] = []

        if let preComment = preComment, !preComment.isEmpty {
            parts.append("{ \(preComment) }")
        }

        if let move = move {
            if move.piece.player == .red {
                parts.append("\(moveNumber).")
            } else if moveNumber == 1 {
                parts.append("1...")
            }

            // 使用 UCI 格式或代数记谱
            let notation = move.chineseNotation ?? move.uciNotation
            parts.append(notation)
        }

        if let symbol = evaluationSymbol {
            parts.append(symbol.rawValue)
        }

        if let postComment = postComment, !postComment.isEmpty {
            parts.append("{ \(postComment) }")
        }

        // 添加变着
        for (index, variation) in variations.enumerated() {
            if index == 0 {
                parts.append("(")
            }
            parts.append(variation.toPGNString())
            if index == variations.count - 1 {
                parts.append(")")
            }
        }

        // 添加主变
        if let main = mainVariation {
            parts.append(main.toPGNString())
        }

        return parts.joined(separator: " ")
    }

    /// 导出为简洁的字符串表示（用于显示）
    public func toDisplayString() -> String {
        var result = ""
        let nodes = [self] + mainLine
        for node in nodes {
            if let move = node.move {
                if move.piece.player == .red {
                    result += "\(node.moveNumber). "
                }
                result += move.chineseNotation ?? move.description
                result += " "
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    /// 克隆节点（深拷贝）
    public func clone() -> MoveNode {
        let cloned = MoveNode(
            id: UUID(),  // 新ID
            move: move,
            moveNumber: moveNumber,
            preComment: preComment,
            postComment: postComment,
            evaluationSymbol: evaluationSymbol,
            createdAt: createdAt
        )

        if let main = mainVariation {
            cloned.mainVariation = main.clone()
            cloned.mainVariation?.parent = cloned
        }

        for variation in variations {
            let clonedVariation = variation.clone()
            clonedVariation.parent = cloned
            cloned.variations.append(clonedVariation)
        }

        return cloned
    }
}

// MARK: - EvaluationSymbol

/// 评价符号枚举
/// 用于标记走棋的质量
public enum EvaluationSymbol: String, Codable, Equatable, Sendable, CustomStringConvertible {
    /// 好棋 (!)
    case good = "!"

    /// 妙棋 (!!)
    case excellent = "!!"

    /// 疑问步 (?)
    case questionable = "?"

    /// 劣着 (??)
    case blunder = "??"

    /// 有趣 (!?)
    case interesting = "!?"

    /// 值得怀疑 (?!)
    case dubious = "?!"

    public var description: String {
        switch self {
        case .good:
            return "好棋 (!)"
        case .excellent:
            return "妙棋 (!!)"
        case .questionable:
            return "疑问步 (?)"
        case .blunder:
            return "劣着 (??)"
        case .interesting:
            return "有趣 (!?)"
        case .dubious:
            return "值得怀疑 (?!)"
        }
    }

    /// 符号的权重（用于排序）
    public var weight: Int {
        switch self {
        case .excellent: return 6
        case .good: return 5
        case .interesting: return 4
        case .dubious: return 3
        case .questionable: return 2
        case .blunder: return 1
        }
    }
}