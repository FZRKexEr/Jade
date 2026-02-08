import SwiftUI

// MARK: - General Settings View

/// 通用设置视图
public struct GeneralSettingsView: View {

    @Binding var configuration: AppConfiguration

    @State private var showingResetConfirmation = false
    @State private var showingClearHistoryConfirmation = false

    public var body: some View {
        Form {
            // 启动设置
            Section("启动") {
                Toggle("开机时启动", isOn: .constant(false))
                    .disabled(true)
                    .help("此功能将在后续版本中添加")

                Toggle("恢复上次的游戏", isOn: .constant(true))

                Toggle("显示欢迎界面", isOn: .constant(false))
            }

            // 语言设置
            Section("语言") {
                Picker("界面语言", selection: .constant("zh-CN")) {
                    Text("简体中文").tag("zh-CN")
                    Text("繁體中文").tag("zh-TW")
                    Text("English").tag("en")
                }
                .pickerStyle(MenuPickerStyle())
            }

            // 窗口设置
            Section("窗口") {
                Toggle("记住窗口位置", isOn: .constant(true))
                Toggle("记住窗口大小", isOn: .constant(true))

                HStack {
                    Text("默认窗口大小")
                    Spacer()
                    Text("1200 x 800")
                        .foregroundColor(.secondary)
                }
            }

            // 历史记录
            Section("历史记录") {
                HStack {
                    Text("最近游戏")
                    Spacer()
                    Text("\(configuration.recentGamePaths.count) 个")
                        .foregroundColor(.secondary)
                }

                Button("清除历史记录") {
                    showingClearHistoryConfirmation = true
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.red)
                .alert("清除历史记录", isPresented: $showingClearHistoryConfirmation) {
                    Button("取消", role: .cancel) {}
                    Button("清除", role: .destructive) {
                        configuration.recentGamePaths.removeAll()
                    }
                } message: {
                    Text("确定要清除所有历史记录吗？此操作不可撤销。")
                }
            }

            // 版本信息
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0 (Build 1)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("配置版本")
                    Spacer()
                    Text(configuration.version)
                        .foregroundColor(.secondary)
                }

                Link(destination: URL(string: "https://github.com/example/chinesechess")!) {
                    HStack {
                        Text("GitHub 仓库")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Advanced Settings View

/// 高级设置视图
public struct AdvancedSettingsView: View {

    var configuration: AppConfiguration
    let onExport: () -> Void
    let onImport: () -> Void
    let onReset: () -> Void

    @State private var showingClearCacheAlert = false
    @State private var showingDebugModeToggle = false

    public var body: some View {
        Form {
            // 配置管理
            Section("配置管理") {
                Button(action: onExport) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("导出配置")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onImport) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("导入配置")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onReset) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.red)
                        Text("重置所有设置")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }

            // 调试选项
            Section("调试") {
                Toggle("启用调试模式", isOn: .constant(false))
                    .disabled(true)
                    .help("此功能将在后续版本中添加")

                Toggle("记录详细日志", isOn: .constant(false))

                Toggle("显示 FPS 计数器", isOn: .constant(false))

                Button("查看日志文件") {
                    // 打开日志文件
                }
                .disabled(true)
            }

            // 缓存管理
            Section("缓存") {
                HStack {
                    Text("缓存大小")
                    Spacer()
                    Text("0 MB")
                        .foregroundColor(.secondary)
                }

                Button("清除缓存") {
                    showingClearCacheAlert = true
                }
                .alert("清除缓存", isPresented: $showingClearCacheAlert) {
                    Button("取消", role: .cancel) {}
                    Button("清除", role: .destructive) {
                        // 清除缓存
                    }
                } message: {
                    Text("确定要清除所有缓存数据吗？")
                }
            }

            // 开发者信息
            Section("开发者") {
                HStack {
                    Text("配置文件位置")
                    Spacer()
                    Text("~/Library/Application Support/ChineseChess")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("在 Finder 中显示") {
                    // 打开 Finder
                }

                Toggle("启用实验性功能", isOn: .constant(false))
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Flow Layout (Helper)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
