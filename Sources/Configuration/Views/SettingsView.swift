import SwiftUI

// MARK: - Settings View

/// 主设置界面
public struct SettingsView: View {

    // MARK: - Properties

    @Bindable var configurationManager: ConfigurationManager

    @State private var selectedTab: SettingsTab = .general
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingResetAlert = false
    @State private var showingRestartAlert = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    // MARK: - Initialization

    public init(configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            toolbar

            // 分隔线
            Divider()

            // 主内容区
            HSplitView {
                // 左侧导航
                sidebar
                    .frame(minWidth: 180, idealWidth: 200, maxWidth: 250)

                // 右侧内容
                contentView
                    .frame(minWidth: 400)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("重置配置", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) {
                resetConfiguration()
            }
        } message: {
            Text("这将重置所有设置为默认值，此操作不可撤销。")
        }
    }

    // MARK: - Subviews

    private var toolbar: some View {
        HStack {
            Text("设置")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            // 导出按钮
            Button(action: { showingExportSheet = true }) {
                Label("导出", systemImage: "square.and.arrow.up")
            }

            // 导入按钮
            Button(action: { showingImportSheet = true }) {
                Label("导入", systemImage: "square.and.arrow.down")
            }

            // 重置按钮
            Button(action: { showingResetAlert = true }) {
                Label("重置", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(BorderlessButtonStyle())

            Divider()
                .frame(height: 20)

            // 保存按钮
            Button(action: saveConfiguration) {
                Label("保存", systemImage: "checkmark")
            }
            .keyboardShortcut("s", modifiers: .command)
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
    }

    private var sidebar: some View {
        List(SettingsTab.allCases, selection: $selectedTab) { tab in
            Label(tab.displayName, systemImage: tab.icon)
                .tag(tab)
        }
        .listStyle(SidebarListStyle())
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsView(configuration: $configurationManager.configuration)
        case .engine:
            EngineSettingsView(
                configuration: $configurationManager.configuration,
                onEngineSelected: { engineId in
                    configurationManager.configuration.lastUsedEngineID = engineId
                }
            )
        case .appearance:
            UISettingsView(configuration: $configurationManager.configuration.uiConfiguration)
        case .game:
            GameSettingsView(configuration: $configurationManager.configuration.gameConfiguration)
        case .advanced:
            AdvancedSettingsView(
                configuration: $configurationManager.configuration,
                onExport: { showingExportSheet = true },
                onImport: { showingImportSheet = true },
                onReset: { showingResetAlert = true }
            )
        }
    }

    // MARK: - Actions

    private func saveConfiguration() {
        Task {
            await configurationManager.save()
            await MainActor.run {
                alertMessage = "配置已保存"
                showAlert = true
            }
        }
    }

    private func resetConfiguration() {
        configurationManager.resetToDefaults()
        Task {
            await configurationManager.save()
            await MainActor.run {
                alertMessage = "配置已重置为默认值"
                showAlert = true
            }
        }
    }
}

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case engine
    case appearance
    case game
    case advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .general:
            return "通用"
        case .engine:
            return "引擎"
        case .appearance:
            return "外观"
        case .game:
            return "游戏"
        case .advanced:
            return "高级"
        }
    }

    var icon: String {
        switch self {
        case .general:
            return "gear"
        case .engine:
            return "cpu"
        case .appearance:
            return "paintbrush"
        case .game:
            return "checkerboard.rectangle"
        case .advanced:
            return "wrench.and.screwdriver"
        }
    }
}
