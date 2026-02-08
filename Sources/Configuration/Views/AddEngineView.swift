import SwiftUI

// MARK: - Add Engine View

/// 添加引擎视图
public struct AddEngineView: View {

    // MARK: - Properties

    let onAdd: (EngineConfiguration) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var path = ""
    @State private var workingDirectory = ""
    @State private var arguments = ""
    @State private var variant = "xiangqi"
    @State private var showingFilePicker = false
    @State private var validationErrors: [String] = []
    @State private var isValidating = false

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("添加引擎")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("添加") {
                    addEngine()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(!validationErrors.isEmpty || name.isEmpty || path.isEmpty)
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .padding()

            Divider()

            // 表单内容
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 引擎名称
                    FormField(label: "引擎名称") {
                        TextField("例如: Pikafish", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 可执行文件路径
                    FormField(label: "可执行文件") {
                        HStack {
                            TextField("/usr/local/bin/pikafish", text: $path)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button("浏览...") {
                                showingFilePicker = true
                            }
                        }
                    }

                    // 工作目录
                    FormField(label: "工作目录 (可选)") {
                        TextField("留空使用默认", text: $workingDirectory)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 启动参数
                    FormField(label: "启动参数 (可选)") {
                        TextField("多个参数用空格分隔", text: $arguments)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // 支持的棋类
                    FormField(label: "支持棋类") {
                        Picker("", selection: $variant) {
                            Text("中国象棋").tag("xiangqi")
                            Text("国际象棋").tag("chess")
                            Text("将棋").tag("shogi")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // 验证错误
                    if !validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("请修正以下错误:")
                                .font(.headline)
                                .foregroundColor(.red)

                            ForEach(validationErrors, id: \.self) { error in
                                HStack(alignment: .top, spacing: 4) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text(error)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.executable, .unixExecutable],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .onChange(of: name) { _ in validate() }
        .onChange(of: path) { _ in validate() }
        .onAppear {
            validate()
        }
    }

    // MARK: - Helper Views

    private func FormField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            content()
        }
    }

    // MARK: - Actions

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                // 安全检查：访问文件
                if url.startAccessingSecurityScopedResource() {
                    path = url.path
                    url.stopAccessingSecurityScopedResource()
                } else {
                    path = url.path
                }

                // 如果名称为空，使用文件名
                if name.isEmpty {
                    name = url.deletingPathExtension().lastPathComponent
                }
            }
        case .failure(let error):
            alertMessage = "选择文件失败: \(error.localizedDescription)"
        }
    }

    private func validate() {
        var errors: [String] = []

        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("引擎名称不能为空")
        }

        let trimmedPath = path.trimmingCharacters(in: .whitespaces)
        if trimmedPath.isEmpty {
            errors.append("可执行文件路径不能为空")
        } else {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: trimmedPath) {
                errors.append("文件不存在: \(trimmedPath)")
            } else if !fileManager.isExecutableFile(atPath: trimmedPath) {
                errors.append("文件没有可执行权限: \(trimmedPath)")
            }
        }

        validationErrors = errors
    }

    private func addEngine() {
        let args = arguments
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }

        let workingDir = workingDirectory.isEmpty ? nil : workingDirectory

        let engine = EngineConfiguration(
            name: name.trimmingCharacters(in: .whitespaces),
            executablePath: path.trimmingCharacters(in: .whitespaces),
            workingDirectory: workingDir,
            arguments: args,
            defaultOptions: [
                "UCI_Variant": variant
            ],
            supportedVariants: [variant],
            isDefault: configuration.engineConfigurations.isEmpty,
            isEnabled: true
        )

        onAdd(engine)
        dismiss()
    }
}

// MARK: - Add Engine View Extension

extension AddEngineView {
    public init(onAdd: @escaping (EngineConfiguration) -> Void) {
        self.onAdd = onAdd
    }
}
