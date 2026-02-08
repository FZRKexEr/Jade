import Foundation

// MARK: - UCI Value Type

/// UCI 选项值类型
public enum UCIValueType: Codable, Equatable, Sendable {
    case check           // 布尔值 (true/false)
    case spin            // 整数范围 (min-max)
    case combo           // 枚举选项 (var list)
    case button          // 按钮 (无值)
    case string          // 字符串

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .check:
            try container.encode("check", forKey: .type)
        case .spin:
            try container.encode("spin", forKey: .type)
        case .combo:
            try container.encode("combo", forKey: .type)
        case .button:
            try container.encode("button", forKey: .type)
        case .string:
            try container.encode("string", forKey: .type)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        self = UCIValueType.from(string: typeString)
    }

    // MARK: - Factory Methods

    /// 从字符串创建类型
    public static func from(string: String) -> UCIValueType {
        switch string.lowercased() {
        case "check":
            return .check
        case "spin":
            return .spin
        case "combo":
            return .combo
        case "button":
            return .button
        case "string":
            return .string
        default:
            // 默认返回 string 类型
            return .string
        }
    }

    // MARK: - Display

    public var displayName: String {
        switch self {
        case .check:
            return "开关"
        case .spin:
            return "数值"
        case .combo:
            return "选项"
        case .button:
            return "按钮"
        case .string:
            return "文本"
        }
    }

    public var description: String {
        switch self {
        case .check:
            return "布尔值（true/false）"
        case .spin:
            return "整数数值（带最小/最大值限制）"
        case .combo:
            return "从预设选项中选择"
        case .button:
            return "点击触发的动作按钮"
        case .string:
            return "任意文本字符串"
        }
    }
}

// MARK: - UCI Option

/// UCI 选项模型
public struct UCIOption: Codable, Equatable, Identifiable, Sendable {
    public let id = UUID()
    public var name: String
    public var type: UCIValueType
    public var defaultValue: String?
    public var min: Int?
    public var max: Int?
    public var varOptions: [String]

    public init(
        name: String,
        type: UCIValueType = .string,
        defaultValue: String? = nil,
        min: Int? = nil,
        max: Int? = nil,
        varOptions: [String] = []
    ) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.min = min
        self.max = max
        self.varOptions = varOptions
    }

    // MARK: - Validation

    public func isValid(value: String) -> Bool {
        switch type {
        case .check:
            return value.lowercased() == "true" || value.lowercased() == "false"

        case .spin:
            guard let intValue = Int(value) else { return false }
            if let min = min, intValue < min { return false }
            if let max = max, intValue > max { return false }
            return true

        case .combo:
            return varOptions.contains(value)

        case .button:
            // 按钮不需要值
            return true

        case .string:
            // 字符串接受任何值
            return true
        }
    }

    public func validate(value: String) throws {
        guard isValid(value: value) else {
            throw UCIOptionValidationError.invalidValue(
                optionName: name,
                value: value,
                expectedType: type
            )
        }

        if case .spin = type {
            guard Int(value) != nil else {
                throw UCIOptionValidationError.invalidValue(
                    optionName: name,
                    value: value,
                    expectedType: .spin
                )
            }
        }
    }

    // MARK: - Display

    public var displayValue: String {
        switch type {
        case .check:
            if let value = defaultValue?.lowercased() {
                return value == "true" ? "开启" : "关闭"
            }
            return "未设置"

        case .spin:
            if let value = defaultValue {
                var result = value
                if let min = min, let max = max {
                    result += " [\(min)-\(max)]"
                }
                return result
            }
            return "未设置"

        case .combo:
            if let value = defaultValue {
                var result = value
                if !varOptions.isEmpty {
                    result += " [\(varOptions.joined(separator: ", "))]"
                }
                return result
            }
            return "未设置"

        case .button:
            return "点击执行"

        case .string:
            return defaultValue ?? ""
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case defaultValue
        case min
        case max
        case varOptions
    }
}

// MARK: - UCI Option Validation Error

public enum UCIOptionValidationError: Error, Equatable {
    case invalidValue(optionName: String, value: String, expectedType: UCIValueType)
    case outOfRange(optionName: String, value: Int, min: Int, max: Int)
    case invalidOptionType(optionName: String)

    public var localizedDescription: String {
        switch self {
        case .invalidValue(let name, let value, let type):
            return "选项 '\(name)' 的值 '\(value)' 对类型 \(type) 无效"
        case .outOfRange(let name, let value, let min, let max):
            return "选项 '\(name)' 的值 \(value) 超出范围 [\(min), \(max)]"
        case .invalidOptionType(let name):
            return "选项 '\(name)' 的类型无效"
        }
    }
}
