import Foundation

// MARK: - UCI Option Validator

/// UCI 选项值验证器
public struct UCIOptionValidator {

    // MARK: - Validation Result

    public enum ValidationResult: Equatable {
        case valid
        case invalid(reason: String)
        case warning(message: String)

        public var isValid: Bool {
            switch self {
            case .valid, .warning:
                return true
            case .invalid:
                return false
            }
        }

        public var isWarning: Bool {
            if case .warning = self {
                return true
            }
            return false
        }
    }

    // MARK: - Public Methods

    /// 验证值是否符合选项定义
    public static func validate(value: String, for option: UCIOption) -> ValidationResult {
        // 空值验证
        if value.isEmpty {
            // 除了 button 类型，其他类型不应该为空
            if case .button = option.type {
                return .valid
            }
            return .invalid(reason: "值不能为空")
        }

        switch option.type {
        case .check:
            return validateCheckValue(value)

        case .spin:
            return validateSpinValue(value, min: option.min, max: option.max)

        case .combo:
            return validateComboValue(value, options: option.varOptions)

        case .button:
            // 按钮类型不需要值
            return .valid

        case .string:
            return validateStringValue(value)
        }
    }

    /// 批量验证多个选项值
    public static func validate(values: [String: String], against options: [UCIOption]) -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]

        for option in options {
            let value = values[option.name] ?? option.defaultValue ?? ""
            results[option.name] = validate(value: value, for: option)
        }

        return results
    }

    /// 获取建议值（如果当前值无效，返回最接近的有效值）
    public static func suggestedValue(for option: UCIOption, invalidValue: String) -> String? {
        if option.type == .spin {
            guard let intValue = Int(invalidValue) else { return option.defaultValue }

            var suggested = intValue

            if let min = option.min, suggested < min {
                suggested = min
            } else if let max = option.max, suggested > max {
                suggested = max
            }

            return String(suggested)
        }

        if option.type == .combo {
            if !option.varOptions.isEmpty {
                return option.defaultValue ?? option.varOptions.first
            }
        }

        return option.defaultValue
    }

    // MARK: - Private Validation Methods

    private static func validateCheckValue(_ value: String) -> ValidationResult {
        let normalized = value.lowercased().trimmingCharacters(in: .whitespaces)
        if normalized == "true" || normalized == "false" {
            return .valid
        }
        return .invalid(reason: "开关值必须是 'true' 或 'false'")
    }

    private static func validateSpinValue(_ value: String, min: Int?, max: Int?) -> ValidationResult {
        guard let intValue = Int(value) else {
            return .invalid(reason: "数值必须是整数")
        }

        // 检查最小值
        if let min = min, intValue < min {
            return .invalid(reason: "数值 \(intValue) 小于最小值 \(min)")
        }

        // 检查最大值
        if let max = max, intValue > max {
            return .invalid(reason: "数值 \(intValue) 大于最大值 \(max)")
        }

        // 提供警告建议
        if let min = min, let max = max {
            let range = max - min
            if range > 0 {
                let ratio = Double(intValue - min) / Double(range)
                if ratio > 0.9 {
                    return .warning(message: "数值接近最大值，可能影响引擎性能")
                }
                if ratio < 0.1 && min > 0 {
                    return .warning(message: "数值接近最小值，引擎可能无法正常运行")
                }
            }
        }

        return .valid
    }

    private static func validateComboValue(_ value: String, options: [String]) -> ValidationResult {
        // 检查值是否在选项列表中
        if options.contains(value) {
            return .valid
        }

        // 尝试大小写不敏感匹配
        for option in options {
            if option.lowercased() == value.lowercased() {
                return .warning(message: "值 '\(value)' 的大小写与选项 '\(option)' 不完全匹配")
            }
        }

        return .invalid(reason: "值 '\(value)' 不是有效的选项。可用选项: \(options.joined(separator: ", "))")
    }

    private static func validateStringValue(_ value: String) -> ValidationResult {
        // 字符串类型接受任何非空值
        // 可以在这里添加额外的验证，如长度限制等
        return .valid
    }
}

// MARK: - Validation Results Extension

public extension Dictionary where Key == String, Value == UCIOptionValidator.ValidationResult {

    /// 是否全部验证通过
    var isAllValid: Bool {
        allSatisfy { $0.value.isValid }
    }

    /// 获取所有错误
    var errors: [String: String] {
        compactMapValues { result in
            if case .invalid(let reason) = result {
                return reason
            }
            return nil
        }
    }

    /// 获取所有警告
    var warnings: [String: String] {
        compactMapValues { result in
            if case .warning(let message) = result {
                return message
            }
            return nil
        }
    }
}
