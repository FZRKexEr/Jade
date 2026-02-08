import Foundation

// MARK: - PGNParser

/// PGN (Portable Game Notation) 解析器和生成器
/// 兼容国际象棋 PGN 格式，支持变着、评注、标签对
public struct PGNParser {

    // MARK: - Constants

    /// 标签对正则
    private static let tagPairPattern = #"\[\s*(\w+)\s+"([^"]*)"\s*\]"#

    /// 评注正则
    private static let commentPattern = #"\{([^}]*)\}"#

    /// 变着开始
    private static let variationStart = "("
    private static let variationEnd = ")"

    /// 评价符号
    private static let evaluationSymbols = ["!!", "!", "??", "?!", "!?", "?"]

    /// 结果标记
    private static let resultMarkers = ["1-0", "0-1", "1/2-1/2", "*"]

    // MARK: - Parse Errors

    public enum ParseError: Error, CustomStringConvertible {
        case invalidFormat(String)
        case invalidTag(String)
        case invalidMove(String)
        case invalidVariation(String)
        case unexpectedToken(String)
        case missingHeader(String)
        case invalidResult(String)

        public var description: String {
            switch self {
            case .invalidFormat(let msg):
                return "格式错误: \(msg)"
            case .invalidTag(let msg):
                return "标签错误: \(msg)"
            case .invalidMove(let msg):
                return "走法错误: \(msg)"
            case .invalidVariation(let msg):
                return "变着错误: \(msg)"
            case .unexpectedToken(let msg):
                return "意外的标记: \(msg)"
            case .missingHeader(let msg):
                return "缺少头信息: \(msg)"
            case .invalidResult(let msg):
                return "无效的结果: \(msg)"
            }
        }
    }

    // MARK: - Parsing

    /// 解析 PGN 字符串
    public static func parse(_ pgnString: String) throws -> GameRecord {
        var pgn = pgnString.trimmingCharacters(in: .whitespacesAndNewlines)

        // 检查 BOM
        if pgn.hasPrefix("\u{FEFF}") {
            pgn.removeFirst()
        }

        // 解析头信息
        let header = try parseHeaders(pgn)

        // 移除标签对，获取走法部分
        let movesSection = try extractMovesSection(pgn)

        // 解析走法树
        let rootNode = try parseMoves(
            movesSection,
            initialFEN: header.setUp
        )

        // 创建游戏记录
        let record = GameRecord(
            header: header,
            rootNode: rootNode,
            initialFEN: header.setUp
        )

        return record
    }

    /// 解析头信息
    private static func parseHeaders(_ pgn: String) throws -> GameHeader {
        var header = GameHeader()

        // 使用正则表达式匹配标签对
        let pattern = #"\[\s*(\w+)\s+"([^"]*)"\s*\]"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(pgn.startIndex..., in: pgn)

        let matches = regex.matches(in: pgn, options: [], range: range)

        for match in matches {
            guard let tagRange = Range(match.range(at: 1), in: pgn),
                  let valueRange = Range(match.range(at: 2), in: pgn) else {
                continue
            }

            let tag = String(pgn[tagRange])
            let value = String(pgn[valueRange])

            // 设置对应的头信息字段
            setHeaderField(&header, tag: tag, value: value)
        }

        return header
    }

    /// 设置头信息字段
    private static func setHeaderField(_ header: inout GameHeader, tag: String, value: String) {
        switch tag.uppercased() {
        case "EVENT":
            header.event = value
        case "SITE":
            header.site = value
        case "DATE":
            header.date = value
        case "ROUND":
            header.round = value
        case "RED", "WHITE":
            header.red = value
        case "BLACK":
            header.black = value
        case "RESULT":
            header.result = GameResultNotation(rawValue: value) ?? .ongoing
        case "REDELO":
            header.redElo = Int(value)
        case "BLACKELO":
            header.blackElo = Int(value)
        case "OPENING":
            header.opening = value
        case "VARIATION":
            header.variation = value
        case "SETUP", "FEN":
            header.setUp = value
        case "TIMECONTROL":
            header.timeControl = value
        case "ENDTIME":
            header.endTime = value
        case "ANNOTATOR":
            header.annotator = value
        default:
            // 存储在额外标签中
            header.additionalTags[tag] = value
        }
    }

    /// 提取走法部分
    private static func extractMovesSection(_ pgn: String) throws -> String {
        // 找到第一个非标签字符的位置
        var inTag = false
        var inValue = false
        var startIndex: String.Index?

        for (index, char) in pgn.enumerated() {
            let stringIndex = pgn.index(pgn.startIndex, offsetBy: index)

            if char == "[" && !inValue {
                inTag = true
            } else if char == "]" && !inValue {
                inTag = false
                startIndex = pgn.index(after: stringIndex)
            } else if char == "\"" && inTag {
                inValue = !inValue
            }
        }

        guard let start = startIndex else {
            // 没有找到标签，整个字符串都是走法部分
            return pgn
        }

        return String(pgn[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 解析走法树
    private static func parseMoves(
        _ movesSection: String,
        initialFEN: String?
    ) throws -> MoveNode {
        let root = MoveNode.root()
        var currentNode = root
        var state = ParseState()

        // 移除评注进行预处理
        let processedSection = preprocessComments(movesSection)

        // 分词
        let tokens = tokenize(processedSection)

        var index = 0
        while index < tokens.count {
            let token = tokens[index]

            if token == "(" {
                // 变着开始
                state.inVariation = true
                state.variationDepth += 1
                // 保存当前位置，以便变着结束后返回
                if state.variationDepth == 1 {
                    state.variationParent = currentNode.parent
                }
                index += 1
            } else if token == ")" {
                // 变着结束
                state.variationDepth -= 1
                if state.variationDepth == 0 {
                    state.inVariation = false
                    // 返回变着前的位置
                    if let parent = state.variationParent {
                        currentNode = parent
                    }
                }
                index += 1
            } else if token.hasSuffix(".") || Int(token) != nil {
                // 步数标记，跳过
                index += 1
            } else if resultMarkers.contains(token) {
                // 结果标记，结束
                break
            } else {
                // 走法标记（简化处理，实际需要根据棋盘状态解析）
                // 这里只创建占位节点
                index += 1
            }
        }

        return root
    }

    /// 预处理评注（将评注替换为占位符）
    private static func preprocessComments(_ input: String) -> String {
        var result = input

        // 移除花括号评注
        let commentPattern = #"\{[^}]*\}"#
        if let regex = try? NSRegularExpression(pattern: commentPattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: " ")
        }

        // 移除圆括号评注（保留变着结构）
        // 这部分在tokenize阶段处理

        return result
    }

    /// 分词
    private static func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""

        for char in input {
            switch char {
            case " ", "\t", "\n", "\r":
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
            case "(", ")":
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
                tokens.append(String(char))
            case ".", "*":
                currentToken.append(char)
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
            default:
                currentToken.append(char)
            }
        }

        if !currentToken.isEmpty {
            tokens.append(currentToken)
        }

        return tokens
    }

    // MARK: - Generation

    /// 将游戏记录转换为 PGN 格式字符串
    public static func generate(_ record: GameRecord) -> String {
        var lines: [String] = []

        // 七标签
        lines.append("[Event \"\(record.header.event)\"]")
        lines.append("[Site \"\(record.header.site)\"]")
        lines.append("[Date \"\(record.header.date)\"]")
        lines.append("[Round \"\(record.header.round)\"]")
        lines.append("[Red \"\(record.header.red)\"]")
        lines.append("[Black \"\(record.header.black)\"]")
        lines.append("[Result \"\(record.header.result.pgnString)\"]")

        // 可选标签
        if let redElo = record.header.redElo {
            lines.append("[RedElo \"\(redElo)\"]")
        }
        if let blackElo = record.header.blackElo {
            lines.append("[BlackElo \"\(blackElo)\"]")
        }
        if let opening = record.header.opening {
            lines.append("[Opening \"\(opening)\"]")
        }
        if let setUp = record.header.setUp {
            lines.append("[SetUp \"1\"]")
            lines.append("[FEN \"\(setUp)\"]")
        }

        // 自定义标签
        for (key, value) in record.header.additionalTags {
            lines.append("[\(key) \"\(value)\"]")
        }

        lines.append("") // 空行分隔

        // 走法部分
        let movesText = generateMoves(record.rootNode, result: record.header.result)
        lines.append(movesText)

        return lines.joined(separator: "\n")
    }

    /// 生成走法字符串
    private static func generateMoves(_ node: MoveNode, result: GameResultNotation) -> String {
        var parts: [String] = []
        var currentNode: MoveNode? = node.mainVariation

        while let current = currentNode {
            // 添加评注
            if let preComment = current.preComment, !preComment.isEmpty {
                parts.append("{ \(preComment) }")
            }

            // 添加走法
            if let move = current.move {
                if move.piece.player == .red {
                    // 红方走法，添加序号
                    parts.append("\(current.moveNumber).")
                } else if current.moveNumber == 1 {
                    // 黑方第一步
                    parts.append("1...")
                }

                // 走法表示（优先使用 WXF 记谱）
                // 注意：这里需要棋盘状态才能生成正确记谱，简化使用 UCI
                let notation = move.uciNotation
                parts.append(notation)
            }

            // 添加评价符号
            if let symbol = current.evaluationSymbol {
                parts.append(symbol.rawValue)
            }

            // 添加后评注
            if let postComment = current.postComment, !postComment.isEmpty {
                parts.append("{ \(postComment) }")
            }

            // 处理变着
            for (index, variation) in current.variations.enumerated() {
                parts.append("(")
                // 递归生成变着
                let variationMoves = generateVariationMoves(variation)
                parts.append(variationMoves)
                parts.append(")")
            }

            currentNode = current.mainVariation
        }

        // 添加结果
        parts.append(result.pgnString)

        return parts.joined(separator: " ")
    }

    /// 生成变着走法
    private static func generateVariationMoves(_ node: MoveNode) -> String {
        var parts: [String] = []

        // 添加走法
        if let move = node.move {
            if move.piece.player == .red {
                parts.append("\(node.moveNumber).")
            }
            let notation = move.uciNotation
            parts.append(notation)
        }

        // 添加评价符号
        if let symbol = node.evaluationSymbol {
            parts.append(symbol.rawValue)
        }

        // 添加评注
        if let comment = node.postComment, !comment.isEmpty {
            parts.append("{ \(comment) }")
        }

        // 递归添加主变
        if let mainVariation = node.mainVariation {
            let nextMoves = generateVariationMoves(mainVariation)
            if !nextMoves.isEmpty {
                parts.append(nextMoves)
            }
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Utility Methods

    /// 验证 PGN 字符串格式
    public static func isValid(_ pgnString: String) -> Bool {
        do {
            _ = try parse(pgnString)
            return true
        } catch {
            return false
        }
    }

    /// 批量解析 PGN 字符串（可能包含多个对局）
    public static func parseMultiple(_ pgnString: String) -> [GameRecord] {
        var records: [GameRecord] = []

        // 使用结果标记分割对局
        let separators = ["1-0", "0-1", "1/2-1/2", "*"]
        var currentGame = ""

        let lines = pgnString.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[") {
                // 新对局的开始
                if !currentGame.isEmpty {
                    if let record = try? parse(currentGame) {
                        records.append(record)
                    }
                }
                currentGame = line + "\n"
            } else {
                currentGame += line + "\n"
            }
        }

        // 处理最后一个对局
        if !currentGame.isEmpty {
            if let record = try? parse(currentGame) {
                records.append(record)
            }
        }

        return records
    }
}

// MARK: - GameRecord Extension

extension GameRecord {
    /// 导出为 PGN 格式字符串
    public func toPGN() -> String {
        return PGNParser.generate(self)
    }
}