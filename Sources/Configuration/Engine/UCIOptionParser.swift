import Foundation

// MARK: - UCI Option Parser

/// UCI 选项解析器
/// 解析引擎返回的 `option` 命令输出
public struct UCIOptionParser {

    /// 解析选项字符串
    /// - Parameter line: 引擎输出的 `option` 行
    /// - Returns: 解析后的选项配置
    public static func parse(_ line: String) throws -> UCIOption {
        // 检查是否以 "option" 开头
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix("option") else {
            throw UCIOptionParseError.invalidFormat("Line does not start with 'option'")
        }

        // 移除 "option" 前缀
        let withoutPrefix = trimmed.dropFirst("option".count).trimmingCharacters(in: .whitespaces)

        // 解析名称
        guard let nameResult = parseName(from: withoutPrefix) else {
            throw UCIOptionParseError.missingName
        }

        var option = UCIOption(name: nameResult.name)
        var remaining = nameResult.remaining

        // 解析类型和其他属性
        while !remaining.isEmpty {
            let trimmedRemaining = remaining.trimmingCharacters(in: .whitespaces)
            guard !trimmedRemaining.isEmpty else { break }

            if let typeResult = parseType(from: trimmedRemaining) {
                option.type = typeResult.type
                remaining = typeResult.remaining
            } else if let defaultResult = parseDefault(from: trimmedRemaining) {
                option.defaultValue = defaultResult.value
                remaining = defaultResult.remaining
            } else if let minResult = parseMin(from: trimmedRemaining) {
                option.min = minResult.value
                remaining = minResult.remaining
            } else if let maxResult = parseMax(from: trimmedRemaining) {
                option.max = maxResult.value
                remaining = maxResult.remaining
            } else if let varResult = parseVar(from: trimmedRemaining) {
                option.varOptions.append(varResult.value)
                remaining = varResult.remaining
            } else {
                // 无法解析的部分，跳过
                break
            }
        }

        // 验证选项
        try validateOption(option)

        return option
    }

    /// 批量解析多行选项输出
    public static func parseMultiple(_ lines: [String]) -> [UCIOption] {
        var options: [UCIOption] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.lowercased().hasPrefix("option") else { continue }

            do {
                let option = try parse(trimmed)
                options.append(option)
            } catch {
                // 解析失败的行，记录日志但继续
                print("Failed to parse option: \(error)")
            }
        }

        return options
    }

    // MARK: - Private Parsing Methods

    private static func parseName(from string: String) -> (name: String, remaining: String)? {
        // 格式: name <名称>
        let pattern = #"^name\s+([^\s]+(?:\s+[^\s]+)*)\s*(.*)$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        let range = NSRange(string.startIndex..., in: string)
        if let match = regex?.firstMatch(in: string, options: [], range: range) {
            if let nameRange = Range(match.range(at: 1), in: string) {
                let name = String(string[nameRange])
                if let remainingRange = Range(match.range(at: 2), in: string) {
                    let remaining = String(string[remainingRange])
                    return (name: name, remaining: remaining)
                }
                return (name: name, remaining: "")
            }
        }

        return nil
    }

    private static func parseType(from string: String) -> (type: UCIValueType, remaining: String)? {
        // 格式: type <check|spin|combo|button|string>
        let pattern = #"^type\s+(check|spin|combo|button|string)\s*(.*)$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        let range = NSRange(string.startIndex..., in: string)
        if let match = regex?.firstMatch(in: string, options: [], range: range) {
            if let typeRange = Range(match.range(at: 1), in: string) {
                let typeString = String(string[typeRange]).lowercased()
                let type = UCIValueType.from(string: typeString)

                if let remainingRange = Range(match.range(at: 2), in: string) {
                    let remaining = String(string[remainingRange])
                    return (type: type, remaining: remaining)
                }
                return (type: type, remaining: "")
            }
        }

        return nil
    }

    private static func parseDefault(from string: String) -> (value: String, remaining: String)? {
        // 格式: default <值>
        // 值可以包含空格
        let pattern = #"^default\s+(.+?)(?:\s+(type|min|max|var)\s+|$)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        let range = NSRange(string.startIndex..., in: string)
        if let match = regex?.firstMatch(in: string, options: [], range: range) {
            if let valueRange = Range(match.range(at: 1), in: string) {
                let value = String(string[valueRange]).trimmingCharacters(in: .whitespaces)

                // 找到下一个关键字的起始位置
                if let remainingRange = match.range(at: 2).location != NSNotFound,
                   let range = Range(match.range(at: 2), in: string) {
                    let keyword = String(string[range])
                    let remaining = String(string[range.lowerBound...])
                    return (value: value, remaining: keyword + remaining.dropFirst(keyword.count))
                }

                return (value: value, remaining: "")
            }
        }

        return nil
    }

    private static func parseMin(from string: String) -> (value: Int, remaining: String)? {
        // 格式: min <值>
        let pattern = #"^min\s+(-?\d+)\s*(.*)$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        let range = NSRange(string.startIndex..., in: string)
        if let match = regex?.firstMatch(in: string, options: [], range: range) {
            if let valueRange = Range(match.range(at: 1), in: string),
               let value = Int(string[valueRange]) {
                let remaining = Range(match.range(at: 2), in: string).map { String(string[$0]) } ?? ""
                return (value: value, remaining: remaining)
            }
        }

        return nil
    }

    private static func parseMax(from string: String) -> (value: Int, remaining: String)? {
        // 格式: max <值>
        let pattern = #"^max\s+(-?\d+)\s*(.*)$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        let range = NSRange(string.startIndex..., in: string)
        if let match = regex?.firstMatch(in: string, options: [], range: range) {
            if let valueRange = Range(match.range(at: 1), in: string),
               let value = Int(string[valueRange]) {
                let remaining = Range(match.range(at: 2), in: string).map { String(string[$0]) } ?? ""
                return (value: value, remaining: remaining)
            }
        }

        return nil
    }

    private static func parseVar(from string: String) -> (value: String, remaining: String)? {
        // 格式: var <值>
        let pattern = #"^var\s+(\S+)\s*(.*)$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        let range = NSRange(string.startIndex..., in: string)
        if let match = regex?.firstMatch(in: string, options: [], range: range) {
            if let valueRange = Range(match.range(at: 1), in: string) {
                let value = String(string[valueRange])
                let remaining = Range(match.range(at: 2), in: string).map { String(string[$0]) } ?? ""
                return (value: value, remaining: remaining)
            }
        }

        return nil
    }

    private static func validateOption(_ option: UCIOption) throws {
        // 验证名称不为空
        guard !option.name.isEmpty else {
            throw UCIOptionParseError.invalidOption("Option name cannot be empty")
        }

        // 根据类型验证属性
        switch option.type {
        case .spin:
            // spin 类型必须有 min 和 max
            guard option.min != nil && option.max != nil else {
                throw UCIOptionParseError.invalidOption("Spin option must have min and max values")
            }

            // 验证默认值在范围内
            if let defaultValue = option.defaultValue,
               let intValue = Int(defaultValue),
               let min = option.min,
               let max = option.max {
                guard intValue >= min && intValue <= max else {
                    throw UCIOptionParseError.invalidOption("Default value \(intValue) is outside range [\(min), \(max)]")
                }
            }

        case .combo:
            // combo 类型必须有 var 选项
            guard !option.varOptions.isEmpty else {
                throw UCIOptionParseError.invalidOption("Combo option must have at least one var option")
            }

            // 验证默认值在选项中
            if let defaultValue = option.defaultValue {
                guard option.varOptions.contains(defaultValue) else {
                    throw UCIOptionParseError.invalidOption("Default value '\(defaultValue)' is not in var options")
                }
            }

        case .check:
            // check 类型的默认值必须是 true 或 false
            if let defaultValue = option.defaultValue?.lowercased() {
                guard defaultValue == "true" || defaultValue == "false" else {
                    throw UCIOptionParseError.invalidOption("Check option default must be 'true' or 'false'")
                }
            }

        case .string, .button:
            // string 和 button 类型没有额外验证
            break
        }
    }
}

// MARK: - UCI Option Parse Error

public enum UCIOptionParseError: Error, Equatable {
    case invalidFormat(String)
    case missingName
    case missingType
    case invalidOption(String)
    case unknownType(String)

    public var localizedDescription: String {
        switch self {
        case .invalidFormat(let message):
            return "格式无效: \(message)"
        case .missingName:
            return "缺少选项名称"
        case .missingType:
            return "缺少选项类型"
        case .invalidOption(let message):
            return "选项无效: \(message)"
        case .unknownType(let type):
            return "未知类型: \(type)"
        }
    }
}
