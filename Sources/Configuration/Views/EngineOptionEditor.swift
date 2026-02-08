import SwiftUI

// MARK: - Engine Option Editor

/// 通用 UCI 选项编辑器
public struct EngineOptionEditor: View {

    // MARK: - Properties

    @State var binder: EngineOptionBinder
    var onCommit: ((String) -> Void)?

    // MARK: - Initialization

    public init(option: UCIOption, value: String? = nil, onCommit: ((String) -> Void)? = nil) {
        self._binder = State(initialValue: EngineOptionBinder(
            option: option,
            initialValue: value
        ))
        self.onCommit = onCommit

        // 设置提交回调
        if let onCommit = onCommit {
            self._binder.wrappedValue.onCommit = onCommit
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 选项标题和类型标签
            HStack {
                Text(binder.option.name)
                    .fontWeight(.medium)

                Spacer()

                optionTypeBadge
            }

            // 当前值显示（如果是默认值则显示为灰色）
            if let defaultValue = binder.option.defaultValue,
               binder.value != defaultValue {
                Text("默认值: \(defaultValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 根据类型显示不同的编辑器
            editorView
                .padding(.top, 4)

            // 验证错误提示
            if let error = binder.validationError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var optionTypeBadge: some View {
        Text(binder.option.type.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(typeColor.opacity(0.15))
            .foregroundColor(typeColor)
            .cornerRadius(4)
    }

    @ViewBuilder
    private var editorView: some View {
        switch binder.option.type {
        case .check:
            checkEditor
        case .spin:
            spinEditor
        case .combo:
            comboEditor
        case .button:
            buttonEditor
        case .string:
            stringEditor
        }
    }

    private var checkEditor: some View {
        Toggle(
            binder.value.lowercased() == "true" ? "已启用" : "已禁用",
            isOn: binder.toggleBinding()
        )
        .toggleStyle(SwitchToggleStyle())
        .onChange(of: binder.value) { _ in
            binder.commit()
        }
    }

    private var spinEditor: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("数值", text: binder.textBinding())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                    .onSubmit {
                        binder.commit()
                    }

                if let min = binder.option.min, let max = binder.option.max {
                    Slider(
                        value: binder.doubleBinding(),
                        in: Double(min)...Double(max),
                        step: 1
                    )

                    Text("\(min) - \(max)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }

            // 快速设置按钮
            if let min = binder.option.min, let max = binder.option.max {
                let range = max - min
                if range > 0 {
                    HStack(spacing: 8) {
                        QuickSetButton(label: "最小", value: min, binder: binder)
                        QuickSetButton(label: "25%", value: min + range / 4, binder: binder)
                        QuickSetButton(label: "50%", value: min + range / 2, binder: binder)
                        QuickSetButton(label: "75%", value: min + range * 3 / 4, binder: binder)
                        QuickSetButton(label: "最大", value: max, binder: binder)
                    }
                }
            }
        }
    }

    private var comboEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            if binder.option.varOptions.count <= 4 {
                // 使用 Picker
                Picker("选择", selection: binder.pickerBinding()) {
                    ForEach(binder.option.varOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: binder.value) { _ in
                    binder.commit()
                }
            } else {
                // 使用下拉菜单
                Picker("选择", selection: binder.pickerBinding()) {
                    ForEach(binder.option.varOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: binder.value) { _ in
                    binder.commit()
                }
            }

            // 显示所有可用选项
            Text("可用选项: \(binder.option.varOptions.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var buttonEditor: some View {
        Button(action: {
            binder.commit()
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("执行")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BorderedProminentButtonStyle())
    }

    private var stringEditor: some View {
        TextField("输入值", text: binder.textBinding())
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onSubmit {
                binder.commit()
            }
    }

    // MARK: - Helper Properties

    private var typeColor: Color {
        switch binder.option.type {
        case .check:
            return .green
        case .spin:
            return .blue
        case .combo:
            return .purple
        case .button:
            return .orange
        case .string:
            return .gray
        }
    }
}

// MARK: - Quick Set Button

struct QuickSetButton: View {
    let label: String
    let value: Int
    @Bindable var binder: EngineOptionBinder

    var body: some View {
        Button(action: {
            binder.value = String(value)
            binder.commit()
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(BorderedButtonStyle())
    }
}
