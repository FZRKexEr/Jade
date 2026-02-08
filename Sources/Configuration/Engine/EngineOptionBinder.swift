import SwiftUI
import Combine

// MARK: - Engine Option Binder

/// 引擎选项绑定器
/// 将 UCI 选项绑定到 SwiftUI 控件
@MainActor
@Observable
public final class EngineOptionBinder {

    // MARK: - Properties

    /// 绑定的选项
    public let option: UCIOption

    /// 当前值
    public var value: String {
        didSet {
            if value != oldValue {
                validate()
            }
        }
    }

    /// 验证错误
    public private(set) var validationError: String?

    /// 值是否有效
    public var isValid: Bool {
        validationError == nil
    }

    /// 值是否已更改（与默认值比较）
    public var isModified: Bool {
        value != option.defaultValue
    }

    /// 值变更回调
    public var onValueChanged: ((String) -> Void)?

    /// 提交回调（用于需要立即发送给引擎的选项）
    public var onCommit: ((String) -> Void)?

    // MARK: - Initialization

    public init(option: UCIOption, initialValue: String? = nil) {
        self.option = option
        self.value = initialValue ?? option.defaultValue ?? ""
        self.validate()
    }

    // MARK: - Validation

    @discardableResult
    public func validate() -> Bool {
        do {
            try option.validate(value: value)
            validationError = nil
            return true
        } catch let error as UCIOptionValidationError {
            validationError = error.localizedDescription
            return false
        } catch {
            validationError = error.localizedDescription
            return false
        }
    }

    // MARK: - Actions

    /// 重置为默认值
    public func resetToDefault() {
        value = option.defaultValue ?? ""
        onValueChanged?(value)
    }

    /// 提交值（发送给引擎）
    public func commit() {
        guard validate() else { return }
        onCommit?(value)
    }

    /// 更新值（不触发回调）
    public func setValueWithoutCallback(_ newValue: String) {
        value = newValue
        validate()
    }
}

// MARK: - SwiftUI View Extensions

extension EngineOptionBinder {

    /// 创建 Toggle 绑定
    public func toggleBinding() -> Binding<Bool> {
        Binding(
            get: { self.value.lowercased() == "true" },
            set: { newValue in
                self.value = newValue ? "true" : "false"
                self.onValueChanged?(self.value)
            }
        )
    }

    /// 创建 TextField 绑定
    public func textBinding() -> Binding<String> {
        Binding(
            get: { self.value },
            set: { newValue in
                self.value = newValue
                self.onValueChanged?(newValue)
            }
        )
    }

    /// 创建数值（Int）绑定
    public func intBinding() -> Binding<Int> {
        Binding(
            get: { Int(self.value) ?? 0 },
            set: { newValue in
                self.value = String(newValue)
                self.onValueChanged?(self.value)
            }
        )
    }

    /// 创建 Slider 绑定（Double）
    public func doubleBinding() -> Binding<Double> {
        Binding(
            get: { Double(self.value) ?? 0.0 },
            set: { newValue in
                self.value = String(format: "%.2f", newValue)
                self.onValueChanged?(self.value)
            }
        )
    }

    /// 创建 Picker 绑定（从 varOptions 中选择）
    public func pickerBinding() -> Binding<String> {
        Binding(
            get: {
                // 如果当前值不在选项中，选择第一个
                if self.option.varOptions.contains(self.value) {
                    return self.value
                } else if let first = self.option.varOptions.first {
                    return first
                }
                return self.value
            },
            set: { newValue in
                self.value = newValue
                self.onValueChanged?(newValue)
            }
        )
    }
}

// MARK: - View Builders

extension EngineOptionBinder {

    /// 创建合适的 SwiftUI 视图
    @ViewBuilder
    public func createView() -> some View {
        switch option.type {
        case .check:
            createToggleView()
        case .spin:
            createSpinView()
        case .combo:
            createComboView()
        case .button:
            createButtonView()
        case .string:
            createStringView()
        }
    }

    @ViewBuilder
    private func createToggleView() -> some View {
        Toggle(option.name, isOn: toggleBinding())
            .onChange(of: value) { _ in
                commit()
            }
    }

    @ViewBuilder
    private func createSpinView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(option.name)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("", text: textBinding())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)

                if let min = option.min, let max = option.max {
                    Slider(
                        value: doubleBinding(),
                        in: Double(min)...Double(max)
                    )
                    .frame(minWidth: 100)
                }

                Text("\(option.min.map(String.init) ?? "-") - \(option.max.map(String.init) ?? "-")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func createComboView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(option.name)
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("", selection: pickerBinding()) {
                ForEach(option.varOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    @ViewBuilder
    private func createButtonView() -> some View {
        Button(action: {
            commit()
        }) {
            Text(option.name)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(BorderedButtonStyle())
    }

    @ViewBuilder
    private func createStringView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(option.name)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("", text: textBinding())
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
