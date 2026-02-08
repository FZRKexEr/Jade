import SwiftUI

/// 偏好设置面板
struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .engine

    enum SettingsTab: String, CaseIterable, Identifiable {
        case engine = "引擎"
        case interface = "界面"
        case board = "棋盘"
        case sound = "音效"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .engine: return "cpu"
            case .interface: return "paintbrush"
            case .board: return "square.grid.2x2"
            case .sound: return "speaker.wave.2"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            EngineSettingsTab()
                .tabItem {
                    Label("引擎", systemImage: "cpu")
                }
                .tag(SettingsTab.engine)

            InterfaceSettingsTab()
                .tabItem {
                    Label("界面", systemImage: "paintbrush")
                }
                .tag(SettingsTab.interface)

            BoardSettingsTab()
                .tabItem {
                    Label("棋盘", systemImage: "square.grid.2x2")
                }
                .tag(SettingsTab.board)

            SoundSettingsTab()
                .tabItem {
                    Label("音效", systemImage: "speaker.wave.2")
                }
                .tag(SettingsTab.sound)
        }
        .padding()
        .frame(width: 600, height: 450)
    }
}

// MARK: - 引擎设置

struct EngineSettingsTab: View {
    @State private var enginePath: String = ""
    @State private var hashSize: Double = 256
    @State private var threadCount: Double = 4
    @State private var ponderEnabled: Bool = true
    @State private var contempt: Double = 24

    var body: some View {
        Form {
            Section("引擎路径") {
                HStack {
                    TextField("选择引擎可执行文件", text: $enginePath)
                        .textFieldStyle(.roundedBorder)
                    Button("选择...") {
                        selectEngineFile()
                    }
                }
            }

            Section("内存设置") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hash 大小")
                        Spacer()
                        Text("\(Int(hashSize)) MB")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $hashSize, in: 16...4096, step: 16)
                }
            }

            Section("线程设置") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("线程数")
                        Spacer()
                        Text("\(Int(threadCount))")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $threadCount, in: 1...32, step: 1)
                }
            }

            Section("高级选项") {
                Toggle("启用Ponder（长考）", isOn: $ponderEnabled)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Contempt（和棋倾向）")
                        Spacer()
                        Text("\(Int(contempt))")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $contempt, in: -100...100, step: 1)
                }
            }
        }
    }

    private func selectEngineFile() {
        let panel = NSOpenPanel()
        panel.title = "选择引擎可执行文件"
        panel.allowedContentTypes = [.unixExecutable]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            enginePath = url.path
        }
    }
}

// MARK: - 界面设置

struct InterfaceSettingsTab: View {
    @State private var selectedTheme: Theme = .system
    @State private var showStatusBar: Bool = true
    @State private var showToolbar: Bool = true
    @State private var sidebarPosition: SidebarPosition = .left

    enum Theme: String, CaseIterable {
        case light = "浅色"
        case dark = "深色"
        case system = "跟随系统"
    }

    enum SidebarPosition: String, CaseIterable {
        case left = "左侧"
        case right = "右侧"
    }

    var body: some View {
        Form {
            Section("外观主题") {
                Picker("主题", selection: $selectedTheme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("界面元素") {
                Toggle("显示状态栏", isOn: $showStatusBar)
                Toggle("显示工具栏", isOn: $showToolbar)

                Picker("侧边栏位置", selection: $sidebarPosition) {
                    ForEach(SidebarPosition.allCases, id: \.self) { position in
                        Text(position.rawValue).tag(position)
                    }
                }
            }

            Section("窗口设置") {
                Toggle("启动时恢复上次窗口大小", isOn: .constant(true))
                Toggle("窗口大小改变时保持棋盘比例", isOn: .constant(true))
            }
        }
    }
}

// MARK: - 棋盘设置

struct BoardSettingsTab: View {
    @State private var boardStyle: BoardStyle = .wood
    @State private var pieceStyle: PieceStyle = .traditional
    @State private var boardScale: Double = 1.0
    @State private var showCoordinates: Bool = true
    @State private var showLastMove: Bool = true
    @State private var showValidMoves: Bool = true
    @State private var animateMoves: Bool = true

    enum BoardStyle: String, CaseIterable {
        case wood = "木纹"
        case paper = "纸质"
        case green = "翠绿"
        case blue = "蔚蓝"
    }

    enum PieceStyle: String, CaseIterable {
        case traditional = "传统"
        case modern = "现代"
        case international = "国际"
    }

    var body: some View {
        Form {
            Section("棋盘外观") {
                Picker("棋盘样式", selection: $boardStyle) {
                    ForEach(BoardStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }

                Picker("棋子风格", selection: $pieceStyle) {
                    ForEach(PieceStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
            }

            Section("棋盘大小") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("缩放比例")
                        Spacer()
                        Text("\(Int(boardScale * 100))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $boardScale, in: 0.5...1.5, step: 0.1)
                }
            }

            Section("显示选项") {
                Toggle("显示坐标", isOn: $showCoordinates)
                Toggle("高亮最后一步", isOn: $showLastMove)
                Toggle("显示可移动位置", isOn: $showValidMoves)
                Toggle("走棋动画", isOn: $animateMoves)
            }

            Section("高级选项") {
                Toggle("允许拖动走棋", isOn: .constant(true))
                Toggle("自动翻转棋盘", isOn: .constant(false))
            }
        }
    }
}

// MARK: - 音效设置

struct SoundSettingsTab: View {
    @State private var soundEnabled: Bool = true
    @State private var moveVolume: Double = 0.7
    @State private var captureVolume: Double = 0.8
    @State private var checkVolume: Double = 1.0
    @State private var gameEndVolume: Double = 0.9
    @State private var selectedSoundPack: SoundPack = .classic

    enum SoundPack: String, CaseIterable {
        case classic = "经典"
        case modern = "现代"
        case wood = "木质"
        case minimal = "极简"
    }

    var body: some View {
        Form {
            Section("音效开关") {
                Toggle("启用音效", isOn: $soundEnabled)
            }

            Section("音效包") {
                Picker("音效风格", selection: $selectedSoundPack) {
                    ForEach(SoundPack.allCases, id: \.self) { pack in
                        Text(pack.rawValue).tag(pack)
                    }
                }

                Button("试听") {
                    playTestSound()
                }
            }
            .disabled(!soundEnabled)

            Section("音量调节") {
                VStack(alignment: .leading, spacing: 12) {
                    VolumeSlider(label: "走棋音量", value: $moveVolume)
                    VolumeSlider(label: "吃子音量", value: $captureVolume)
                    VolumeSlider(label: "将军音量", value: $checkVolume)
                    VolumeSlider(label: "终局音量", value: $gameEndVolume)
                }
            }
            .disabled(!soundEnabled)

            Section("高级选项") {
                Toggle("使用系统提示音", isOn: .constant(false))
                Toggle("耳机插入时自动降低音量", isOn: .constant(true))
            }
        }
    }

    private func playTestSound() {
        // 播放测试音效
    }
}

// MARK: - 音量滑块

struct VolumeSlider: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .frame(width: 80, alignment: .leading)

            Slider(value: $value, in: 0...1, step: 0.1)
                .frame(width: 120)

            Text("\(Int(value * 100))%")
                .frame(width: 40, alignment: .trailing)
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

// MARK: - 设置窗口

struct SettingsWindow: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SettingsView()
            .frame(width: 600, height: 450)
    }
}

// MARK: - 预览

#Preview {
    SettingsView()
}
