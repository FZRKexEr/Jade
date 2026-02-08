import Foundation

// MARK: - ICCSerializer

/// ICC 格式（国际通用）解析器和生成器
/// ICC = International Chess Coordinate
/// 格式: 源位置-目标位置，使用 a-i 表示列，0-9 表示行
/// 示例: b0-c2 (马二进三), e0-e1 (帅五进一)
public struct ICCSerializer {

    // MARK: - Constants

    /// 列标签 a-i (从左到右)
    public static let fileLabels = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]

    /// 行标签 0-9 (从下到上)
    public static let rankLabels = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    // MARK: - Parsing

    /// 解析 ICC 格式的走法
    /// - Parameter iccString: ICC 字符串 (如 "b0-c2")
    /// - Returns: 起始位置和目标位置
    public static func parse(_ iccString: String) throws -> (from: Position, to: Position) {
        let trimmed = iccString.trimmingCharacters(in: .whitespaces)

        // 移除可能的 "-" 或空格分隔符
        let components: [String]
        if trimmed.contains("-") {
            components = trimmed.split(separator: "-").map { String($0) }
        } else if trimmed.contains(" ") {
            components = trimmed.split(separator: " ").map { String($0) }
        } else if trimmed.count == 4 {
            // 没有分隔符，直接分割
            let start = String(trimmed.prefix(2))
            let end = String(trimmed.suffix(2))
            components = [start, end]
        } else {
            throw ParseError.invalidFormat("无法识别格式: \(trimmed)")
        }

        guard components.count == 2 else {
            throw ParseError.invalidFormat("需要两个位置坐标，实际有 \(components.count) 个")
        }

        let from = try parsePosition(components[0])
        let to = try parsePosition(components[1])

        return (from, to)
    }

    /// 解析位置字符串
    private static func parsePosition(_ string: String) throws -> Position {
        let trimmed = string.lowercased().trimmingCharacters(in: .whitespaces)

        guard trimmed.count == 2 else {
            throw ParseError.invalidPosition("位置坐标必须是2个字符: \(trimmed)")
        }

        let fileChar = trimmed.first!
        let rankChar = trimmed.last!

        // 解析列 (a-i -> 0-8)
        guard let fileIndex = fileLabels.firstIndex(of: String(fileChar)) else {
            throw ParseError.invalidPosition("无效列坐标 '\(fileChar)'，应为 a-i")
        }

        // 解析行 (0-9)
        guard let rankIndex = rankLabels.firstIndex(of: String(rankChar)) else {
            throw ParseError.invalidPosition("无效行坐标 '\(rankChar)'，应为 0-9")
        }

        return Position(x: fileIndex, y: rankIndex)
    }

    // MARK: - Generation

    /// 将走法转换为 ICC 格式
    /// - Parameter move: 走棋记录
    /// - Returns: ICC 格式字符串 (如 "b0-c2")
    public static func generate(from move: Move) -> String {
        return "\(move.from.algebraic)-\(move.to.algebraic)"
    }

    /// 将位置转换为 ICC 格式
    public static func generate(from position: Position) -> String {
        return position.algebraic
    }

    /// 生成批量 ICC 序列
    public static func generateSequence(from moves: [Move]) -> String {
        return moves.map { generate(from: $0) }.joined(separator: " ")
    }

    // MARK: - Batch Processing

    /// 批量解析 ICC 序列
    public static func parseSequence(_ sequence: String) -> [(from: Position, to: Position)] {
        let tokens = sequence.split(separator: " ").map { String($0) }
        var results: [(from: Position, to: Position)] = []

        for token in tokens {
            if let result = try? parse(token) {
                results.append(result)
            }
        }

        return results
    }

    // MARK: - Validation

    /// 验证 ICC 字符串是否有效
    public static func isValid(_ iccString: String) -> Bool {
        do {
            _ = try parse(iccString)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Conversion

    /// 将 ICC 转换为其他坐标表示
    public static func convertToNumeric(from: Position, to: Position) -> (from: (x: Int, y: Int), to: (x: Int, y: Int)) {
        return (
            from: (x: from.x, y: from.y),
            to: (x: to.x, y: to.y)
        )
    }

    /// 将 ICC 转换为 UCI 格式
    public static func convertToUCI(from: Position, to: Position) -> String {
        // UCI 格式与 ICC 相同
        return "\(from.algebraic)\(to.algebraic)"
    }

    /// 将 UCI 转换为 ICC
    public static func convertFromUCI(_ uci: String) throws -> (from: Position, to: Position) {
        // UCI 格式: e2e4 (4个字符)
        guard uci.count == 4 else {
            throw ParseError.invalidFormat("UCI格式需要4个字符: \(uci)")
        }

        let fromStr = String(uci.prefix(2))
        let toStr = String(uci.suffix(2))

        let from = try parsePosition(fromStr)
        let to = try parsePosition(toStr)

        return (from, to)
    }

    // MARK: - Parse Errors

    public enum ParseError: Error, CustomStringConvertible {
        case invalidFormat(String)
        case invalidPosition(String)

        public var description: String {
            switch self {
            case .invalidFormat(let msg):
                return "格式错误: \(msg)"
            case .invalidPosition(let msg):
                return "位置错误: \(msg)"
            }
        }
    }
}

// MARK: - Position Extension

extension Position {
    /// 将位置转换为 ICC 代数记谱 (如 "b0")
    var iccNotation: String {
        return ICCSerializer.generate(from: self)
    }

    /// 从 ICC 代数记谱创建位置
    static func from(icc: String) throws -> Position {
        let result = try ICCSerializer.parse(icc)
        return result.from
    }
}