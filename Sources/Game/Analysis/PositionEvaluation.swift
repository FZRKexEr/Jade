import Foundation

// MARK: - EvaluationScore

/// 评估分数
public enum EvaluationScore: CustomStringConvertible, Sendable, Equatable, Codable {
    /// 百分制分数 (正数表示红方优势，负数表示黑方优势)
    case centipawns(Int)

    /// 杀棋步数 (正数表示红方杀，负数表示黑方杀)
    case mateIn(Int)

    /// 未知
    case unknown

    public var description: String {
        switch self {
        case .centipawns(let cp):
            let pawns = Double(cp) / 100.0
            if pawns > 0 {
                return String(format: "+%.2f", pawns)
            } else if pawns < 0 {
                return String(format: "%.2f", pawns)
            } else {
                return "0.00"
            }
        case .mateIn(let moves):
            if moves > 0 {
                return "M\(moves)"
            } else {
                return "M\(abs(moves))"
            }
        case .unknown:
            return "?"
        }
    }

    /// 从原始分数创建评估分数
    public init(from scoreInfo: ScoreInfo) {
        switch scoreInfo {
        case .cp(let cp):
            self = .centipawns(cp)
        case .mate(let moves):
            self = .mateIn(moves)
        default:
            self = .unknown
        }
    }

    /// 是否表示红方优势
    public var isRedAdvantage: Bool {
        switch self {
        case .centipawns(let cp):
            return cp > 0
        case .mateIn(let moves):
            return moves > 0
        case .unknown:
            return false
        }
    }

    /// 是否表示黑方优势
    public var isBlackAdvantage: Bool {
        switch self {
        case .centipawns(let cp):
            return cp < 0
        case .mateIn(let moves):
            return moves < 0
        case .unknown:
            return false
        }
    }

    /// 是否平衡
    public var isEqual: Bool {
        switch self {
        case .centipawns(let cp):
            return abs(cp) < 20  // 小于0.2兵价值视为平衡
        default:
            return false
        }
    }

    /// 绝对值（用于比较大小）
    public var absoluteValue: Int {
        switch self {
        case .centipawns(let cp):
            return abs(cp)
        case .mateIn(let moves):
            // 杀棋的权重远高于普通评估
            return 10000 + (100 - abs(moves)) * 100
        case .unknown:
            return 0
        }
    }
}

// MARK: - Variation

/// 主变例 (Principal Variation)
public struct Variation: CustomStringConvertible, Sendable, Equatable, Identifiable, Codable {
    public let id: UUID

    /// MultiPV 序号 (1-based)
    public let multipv: Int

    /// 评估分数
    public let score: EvaluationScore

    /// 深度
    public let depth: Int

    /// 选择性搜索深度
    public let seldepth: Int?

    /// 着法列表 (UCI格式)
    public let moves: [String]

    /// 搜索节点数
    public let nodes: Int?

    /// 每秒节点数
    public let nps: Int?

    /// 哈希表填充率 (0-1000)
    public let hashfull: Int?

    /// 创建时间
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        multipv: Int = 1,
        score: EvaluationScore,
        depth: Int,
        seldepth: Int? = nil,
        moves: [String],
        nodes: Int? = nil,
        nps: Int? = nil,
        hashfull: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.multipv = multipv
        self.score = score
        self.depth = depth
        self.seldepth = seldepth
        self.moves = moves
        self.nodes = nodes
        self.nps = nps
        self.hashfull = hashfull
        self.timestamp = timestamp
    }

    public var description: String {
        let scoreStr = score.description
        let movesStr = moves.prefix(6).joined(separator: " ")
        return "\(multipv). [\(scoreStr)] d\(depth) \(movesStr)"
    }

    /// 首步着法
    public var firstMove: String? {
        moves.first
    }

    /// 是否有杀棋
    public var isMate: Bool {
        if case .mateIn = score {
            return true
        }
        return false
    }

    /// 杀棋步数 (如果不是杀棋则返回nil)
    public var mateIn: Int? {
        if case .mateIn(let moves) = score {
            return moves
        }
        return nil
    }
}

// MARK: - PositionEvaluation

/// 局面评估数据
public struct PositionEvaluation: CustomStringConvertible, Sendable, Identifiable, Codable {
    public let id: UUID

    /// 评估时间戳
    public let timestamp: Date

    /// FEN字符串
    public let fen: String

    /// 最佳着法 (UCI格式)
    public let bestMove: String?

    /// 预思考着法 (UCI格式)
    public let ponderMove: String?

    /// 主变例列表 (支持MultiPV)
    public let variations: [Variation]

    /// 最佳主变例
    public var bestVariation: Variation? {
        variations.first { $0.multipv == 1 }
    }

    /// 搜索总节点数
    public let totalNodes: Int?

    /// 搜索时间 (毫秒)
    public let searchTimeMs: Int?

    /// 每秒节点数
    public let nps: Int?

    /// 使用的哈希表大小 (MB)
    public let hashSizeMB: Int?

    /// 是否来自完整搜索 (而非部分结果)
    public let isComplete: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        fen: String,
        bestMove: String? = nil,
        ponderMove: String? = nil,
        variations: [Variation] = [],
        totalNodes: Int? = nil,
        searchTimeMs: Int? = nil,
        nps: Int? = nil,
        hashSizeMB: Int? = nil,
        isComplete: Bool = true
    ) {
        self.id = id
        self.timestamp = timestamp
        self.fen = fen
        self.bestMove = bestMove
        self.ponderMove = ponderMove
        self.variations = variations
        self.totalNodes = totalNodes
        self.searchTimeMs = searchTimeMs
        self.nps = nps
        self.hashSizeMB = hashSizeMB
        self.isComplete = isComplete
    }

    public var description: String {
        var parts: [String] = []

        if let bestMove = bestMove {
            parts.append("Best: \(bestMove)")
        }

        if let variation = bestVariation {
            parts.append("Score: \(variation.score)")
            parts.append("Depth: \(variation.depth)")
        }

        if let nodes = totalNodes {
            parts.append("Nodes: \(formatNumber(nodes))")
        }

        if let nps = nps {
            parts.append("NPS: \(formatNumber(nps))")
        }

        if let time = searchTimeMs {
            parts.append("Time: \(Double(time) / 1000.0, specifier: "%.2f")s")
        }

        return parts.joined(separator: " | ")
    }

    /// 从 InfoData 创建评估
    public static func from(infoData: InfoData, fen: String, multipv: Int = 1) -> PositionEvaluation? {
        guard let scoreInfo = infoData.score else { return nil }

        let score = EvaluationScore(from: scoreInfo)

        let variation = Variation(
            multipv: infoData.multipv ?? multipv,
            score: score,
            depth: infoData.depth ?? 0,
            seldepth: infoData.seldepth,
            moves: infoData.pv ?? [],
            nodes: infoData.nodes,
            nps: infoData.nps,
            hashfull: infoData.hashfull
        )

        return PositionEvaluation(
            fen: fen,
            variations: [variation],
            totalNodes: infoData.nodes,
            nps: infoData.nps
        )
    }

    // MARK: - Private Helpers

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000_000 {
            return String(format: "%.2fB", Double(number) / 1_000_000_000.0)
        } else if number >= 1_000_000 {
            return String(format: "%.2fM", Double(number) / 1_000_000.0)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000.0)
        } else {
            return String(number)
        }
    }
}
