import SwiftUI

/// 控制栏视图 - 工具按钮和状态显示
struct ControlBarView: View {
    @Bindable var gameViewModel: GameViewModel
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        HStack(spacing: 20) {
            // 左侧：主要控制按钮
            MainControlsView(
                gameViewModel: gameViewModel,
                engineViewModel: engineViewModel
            )

            Divider()
                .frame(height: 24)

            // 中间：引擎控制
            EngineControlsView(engineViewModel: engineViewModel)

            Divider()
                .frame(height: 24)

            // 右侧：状态显示
            StatusView(
                gameViewModel: gameViewModel,
                engineViewModel: engineViewModel
            )

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(.bar)
    }
}

// MARK: - 主要控制按钮

struct MainControlsView: View {
    @Bindable var gameViewModel: GameViewModel
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        HStack(spacing: 12) {
            // 新局
            Button(action: { gameViewModel.newGame() }) {
                Image(systemName: "square.and.pencil")
            }
            .buttonStyle(ToolbarButtonStyle())
            .help("新局 (⌘N)")

            // 悔棋
            Button(action: { gameViewModel.undoMove() }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(ToolbarButtonStyle())
            .disabled(!gameViewModel.canUndo())
            .help("悔棋 (⌘Z)")

            // 重做
            Button(action: { gameViewModel.redoMove() }) {
                Image(systemName: "arrow.uturn.forward")
            }
            .buttonStyle(ToolbarButtonStyle())
            .disabled(!gameViewModel.canRedo())
            .help("重做 (⌘⇧Z)")

            Divider()
                .frame(height: 20)

            // 翻转棋盘
            Button(action: { gameViewModel.flipBoard() }) {
                Image(systemName: "arrow.up.arrow.down")
            }
            .buttonStyle(ToolbarButtonStyle())
            .help("翻转棋盘 (F)")

            // 提示
            Button(action: { requestHint() }) {
                Image(systemName: "lightbulb")
            }
            .buttonStyle(ToolbarButtonStyle())
            .help("提示 (H)")
        }
    }

    private func requestHint() {
        // 请求引擎给出提示
        if engineViewModel.engineState == .ready {
            // 开始短时间搜索获取提示
        }
    }
}

// MARK: - 引擎控制

struct EngineControlsView: View {
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        HStack(spacing: 12) {
            // 分析模式开关
            Toggle(isOn: $engineViewModel.analysisMode) {
                Image(systemName: "brain")
            }
            .toggleStyle(ToolbarToggleStyle())
            .help("分析模式 (A)")

            // 开始/停止思考
            Button(action: toggleThinking) {
                Image(systemName: engineViewModel.isThinking ? "stop.fill" : "play.fill")
                    .foregroundColor(engineViewModel.isThinking ? .red : .green)
            }
            .buttonStyle(ToolbarButtonStyle())
            .disabled(engineViewModel.engineState != .ready && engineViewModel.engineState != .searching)
            .help(engineViewModel.isThinking ? "停止思考" : "开始思考")

            Divider()
                .frame(height: 20)

            // 引擎连接按钮
            Button(action: connectEngine) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(engineStatusColor)
                        .frame(width: 8, height: 8)
                    Text(engineViewModel.engineName)
                        .font(.caption)
                }
            }
            .buttonStyle(ToolbarButtonStyle())
        }
    }

    private var engineStatusColor: Color {
        switch engineViewModel.engineState {
        case .ready:
            return .green
        case .searching, .pondering:
            return .blue
        case .initializing:
            return .yellow
        case .error:
            return .red
        case .idle:
            return .gray
        }
    }

    private func toggleThinking() {
        if engineViewModel.isThinking {
            engineViewModel.stopThinking()
        } else {
            // 开始思考当前局面
            engineViewModel.startThinking(fen: gameViewModel.board.toFEN())
        }
    }

    private func connectEngine() {
        // 显示引擎连接对话框
        if engineViewModel.engineState == .idle {
            engineViewModel.connectEngine(name: "Pikafish")
        } else {
            engineViewModel.disconnectEngine()
        }
    }
}

// MARK: - 状态显示

struct StatusView: View {
    @Bindable var gameViewModel: GameViewModel
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        HStack(spacing: 16) {
            // 当前回合
            HStack(spacing: 6) {
                Circle()
                    .fill(gameViewModel.currentTurn == .red ? Color.red : Color.black)
                    .frame(width: 10, height: 10)
                Text(gameViewModel.currentTurn == .red ? "红方走" : "黑方走")
                    .font(.system(size: 12, weight: .medium))
            }

            Divider()
                .frame(height: 16)

            // 步数
            HStack(spacing: 4) {
                Image(systemName: "number")
                    .font(.caption)
                Text("\(gameViewModel.moveHistory.count)")
                    .font(.system(size: 12, weight: .medium))
            }

            // 引擎思考信息
            if engineViewModel.isThinking {
                Divider()
                    .frame(height: 16)

                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)

                    Text("深度: \(engineViewModel.currentDepth)")
                        .font(.caption)
                        .monospacedDigit()

                    Text("评分: \(formatScore(engineViewModel.currentScore))")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(scoreColor(engineViewModel.currentScore))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.5))
        .cornerRadius(6)
    }

    private func formatScore(_ score: Int) -> String {
        if score > 9000 {
            return "+M\(10000 - score)"
        } else if score < -9000 {
            return "-M\(10000 + score)"
        } else {
            let sign = score >= 0 ? "+" : ""
            return "\(sign)\(Double(score) / 100.0, specifier: "%.2f")"
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score > 100 {
            return .green
        } else if score < -100 {
            return .red
        } else {
            return .primary
        }
    }
}

// MARK: - 工具栏按钮样式

struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
            .background(configuration.isPressed ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(4)
    }
}

struct ToolbarToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            configuration.label
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .background(configuration.isOn ? Color.accentColor.opacity(0.3) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

// 修复 GameViewModel 引用问题
private var gameViewModel: GameViewModel {
    GameViewModel()
}

// MARK: - 预览

#Preview {
    ControlBarView(
        gameViewModel: GameViewModel(),
        engineViewModel: EngineViewModel()
    )
    .frame(width: 800)
}
