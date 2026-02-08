import SwiftUI

/// 应用菜单定义
struct AppMenus: Commands {
    @Binding var gameViewModel: GameViewModel
    @Binding var engineViewModel: EngineViewModel
    @Binding var isSettingsPresented: Bool

    var body: some Commands {
        // 文件菜单
        fileMenu

        // 编辑菜单
        editMenu

        // 视图菜单
        viewMenu

        // 引擎菜单
        engineMenu

        // 游戏菜单
        gameMenu

        // 帮助菜单
        helpMenu

        // 替换标准菜单
        CommandGroup(replacing: .newItem) { }
        CommandGroup(replacing: .pasteboard) { }
        CommandGroup(replacing: .undoRedo) { }
    }

    // MARK: - 文件菜单

    @CommandsBuilder
    private var fileMenu: some Commands {
        CommandMenu("文件") {
            Button("新局") {
                gameViewModel.newGame()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("从FEN加载...") {
                showFENInputDialog()
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()

            Button("保存棋谱...") {
                saveGameToFile()
            }
            .keyboardShortcut("s", modifiers: .command)

            Button("导出FEN") {
                copyFENToClipboard()
            }
            .keyboardShortcut("e", modifiers: .command)

            Button("导出图片...") {
                exportBoardImage()
            }

            Divider()

            Button("打印...") {
                printBoard()
            }
            .keyboardShortcut("p", modifiers: .command)
        }
    }

    // MARK: - 编辑菜单

    @CommandsBuilder
    private var editMenu: some Commands {
        CommandMenu("编辑") {
            Button("悔棋") {
                gameViewModel.undoMove()
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!gameViewModel.canUndo())

            Button("重做") {
                gameViewModel.redoMove()
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!gameViewModel.canRedo())

            Divider()

            Button("复制FEN") {
                copyFENToClipboard()
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("粘贴FEN") {
                pasteFENFromClipboard()
            }
            .keyboardShortcut("v", modifiers: .command)

            Divider()

            Menu("选择") {
                Button("全选") {
                    // 选择全部
                }
                .keyboardShortcut("a", modifiers: .command)
            }
        }
    }

    // MARK: - 视图菜单

    @CommandsBuilder
    private var viewMenu: some Commands {
        CommandMenu("视图") {
            Toggle("显示坐标", isOn: $gameViewModel.showCoordinates)
                .keyboardShortcut("1", modifiers: .command)

            Toggle("显示最后一步", isOn: $gameViewModel.showLastMove)
                .keyboardShortcut("2", modifiers: .command)

            Toggle("显示可移动位置", isOn: $gameViewModel.showValidMoves)
                .keyboardShortcut("3", modifiers: .command)

            Divider()

            Toggle("左侧边栏", isOn: .constant(true))
                .keyboardShortcut("b", modifiers: .command)

            Toggle("右侧边栏", isOn: .constant(true))
                .keyboardShortcut("o", modifiers: .command)

            Divider()

            Menu("棋盘样式") {
                Button("经典") { }
                Button("简约") { }
                Button("木纹") { }
                Divider()
                Button("自定义...") { }
            }

            Menu("棋子风格") {
                Button("传统") { }
                Button("现代") { }
                Button("立体") { }
            }

            Divider()

            Button("进入全屏幕") {
                toggleFullScreen()
            }
            .keyboardShortcut("f", modifiers: .command)
        }
    }

    // MARK: - 引擎菜单

    @CommandsBuilder
    private var engineMenu: some Commands {
        CommandMenu("引擎") {
            Button("连接引擎...") {
                showEngineConnectDialog()
            }
            .keyboardShortcut("e", modifiers: .command)

            Button("断开连接") {
                engineViewModel.disconnectEngine()
            }
            .disabled(engineViewModel.engineState == .idle)

            Divider()

            Toggle("分析模式", isOn: $engineViewModel.analysisMode)
                .keyboardShortcut("a", modifiers: .command)

            Button("开始思考") {
                engineViewModel.startThinking(fen: gameViewModel.board.toFEN())
            }
            .disabled(engineViewModel.engineState != .ready)

            Button("停止思考") {
                engineViewModel.stopThinking()
            }
            .disabled(!engineViewModel.isThinking)

            Divider()

            Menu("多PV分析") {
                ForEach(1...5, id: \.self) { count in
                    Button("\(count) 行") {
                        engineViewModel.setMultiPV(count)
                    }
                    .disabled(engineViewModel.multiPV == count)
                }
            }

            Menu("搜索深度") {
                Button("无限制") { engineViewModel.setSearchDepth(0) }
                ForEach([10, 15, 20, 25, 30], id: \.self) { depth in
                    Button("\(depth) 层") {
                        engineViewModel.setSearchDepth(depth)
                    }
                }
            }

            Divider()

            Button("引擎配置...") {
                isSettingsPresented = true
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }

    // MARK: - 游戏菜单

    @CommandsBuilder
    private var gameMenu: some Commands {
        CommandMenu("游戏") {
            Button("新局") {
                gameViewModel.newGame()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Divider()

            Menu("难度") {
                Button("入门") { }
                Button("初级") { }
                Button("中级") { }
                Button("高级") { }
                Button("大师") { }
            }

            Menu("模式") {
                Button("人机对战") { }
                Button("人人对战") { }
                Button("引擎自战") { }
            }

            Divider()

            Button("翻转棋盘") {
                gameViewModel.flipBoard()
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])

            Button("提示") {
                // 显示提示
            }
            .keyboardShortcut("h", modifiers: .command)
        }
    }

    // MARK: - 帮助菜单

    @CommandsBuilder
    private var helpMenu: some Commands {
        CommandGroup(replacing: .help) {
            Button("用户指南") {
                openUserGuide()
            }
            .keyboardShortcut("?", modifiers: .command)

            Button("快捷键参考") {
                showKeyboardShortcuts()
            }

            Divider()

            Button("在线帮助") {
                NSWorkspace.shared.open(URL(string: "https://github.com/chinesechess/help")!)
            }

            Button("提交反馈") {
                NSWorkspace.shared.open(URL(string: "https://github.com/chinesechess/issues")!)
            }

            Divider()

            Button("检查更新") {
                checkForUpdates()
            }

            Divider()

            Button("关于中国象棋") {
                showAboutPanel()
            }
        }
    }

    // MARK: - 辅助方法

    private func showFENInputDialog() {
        // 显示FEN输入对话框
    }

    private func saveGameToFile() {
        // 保存棋谱到文件
    }

    private func copyFENToClipboard() {
        let fen = gameViewModel.board.toFEN()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fen, forType: .string)
    }

    private func pasteFENFromClipboard() {
        if let fen = NSPasteboard.general.string(forType: .string) {
            // 从FEN加载局面
        }
    }

    private func exportBoardImage() {
        // 导出棋盘图片
    }

    private func printBoard() {
        // 打印棋盘
    }

    private func toggleFullScreen() {
        if let window = NSApp.mainWindow {
            window.toggleFullScreen(nil)
        }
    }

    private func showEngineConnectDialog() {
        // 显示引擎连接对话框
    }

    private func openUserGuide() {
        // 打开用户指南
    }

    private func showKeyboardShortcuts() {
        // 显示快捷键参考
    }

    private func checkForUpdates() {
        // 检查更新
    }

    private func showAboutPanel() {
        NSApp.orderFrontStandardAboutPanel()
    }
}

// MARK: - 预览

#Preview {
    VStack {
        EngineStatusPanel(engineViewModel: EngineViewModel())
            .frame(width: 200)
    }
    .padding()
}
