import SwiftUI

// MARK: - 引擎状态面板

struct EngineStatusPanel: View {
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.secondary)
                Text("引擎状态")
                    .font(.headline)
                Spacer()
                StatusIndicator(state: engineViewModel.engineState)
            }

            if engineViewModel.engineState == .ready || engineViewModel.engineState == .searching {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "名称", value: engineViewModel.engineName)

                    if engineViewModel.isThinking {
                        InfoRow(label: "深度", value: "\(engineViewModel.currentDepth)")
                        InfoRow(label: "NPS", value: formatNPS(engineViewModel.currentNPS))
                    }
                }
                .font(.caption)
            }

            // 连接/断开按钮
            Button(action: toggleEngineConnection) {
                HStack {
                    Image(systemName: engineViewModel.engineState == .idle ? "link" : "link.slash")
                    Text(engineViewModel.engineState == .idle ? "连接引擎" : "断开连接")
                }
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(engineViewModel.engineState == .initializing)
        }
        .padding(12)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(8)
    }

    private func toggleEngineConnection() {
        if engineViewModel.engineState == .idle {
            engineViewModel.connectEngine(name: "Pikafish")
        } else {
            engineViewModel.disconnectEngine()
        }
    }

    private func formatNPS(_ nps: Int) -> String {
        if nps >= 1_000_000 {
            return String(format: "%.1fM", Double(nps) / 1_000_000)
        } else if nps >= 1_000 {
            return String(format: "%.1fK", Double(nps) / 1_000)
        } else {
            return "\(nps)"
        }
    }
}

// MARK: - 对局信息面板

struct GameInfoPanel: View {
    @Bindable var gameViewModel: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("对局信息")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "当前回合", value: gameViewModel.currentTurn == .red ? "红方" : "黑方")
                InfoRow(label: "总步数", value: "\(gameViewModel.moveHistory.count)")
                InfoRow(label: "棋盘方向", value: gameViewModel.isBoardFlipped ? "黑方在下" : "红方在下")
            }
            .font(.caption)

            // 胜负信息
            if case .win(let player, let reason) = gameViewModel.gameResult {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("\(player == .red ? "红方" : "黑方")胜 - \(reason.rawValue)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(4)
            } else if case .draw(let reason) = gameViewModel.gameResult {
                HStack {
                    Image(systemName: "handshake.fill")
                        .foregroundColor(.gray)
                    Text("和棋 - \(reason.rawValue)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(8)
    }
}

// MARK: - 快捷操作面板

struct QuickActionsPanel: View {
    @Bindable var gameViewModel: GameViewModel
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.secondary)
                Text("快捷操作")
                    .font(.headline)
            }

            VStack(spacing: 8) {
                Button(action: { gameViewModel.flipBoard() }) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("翻转棋盘")
                        Spacer()
                    }
                }
                .buttonStyle(QuickActionButtonStyle())

                Button(action: { copyFEN() }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("复制FEN")
                        Spacer()
                    }
                }
                .buttonStyle(QuickActionButtonStyle())

                Button(action: { toggleSound() }) {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                        Text("音效开关")
                        Spacer()
                    }
                }
                .buttonStyle(QuickActionButtonStyle())

                Divider()

                Button(action: { showSettings() }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("设置...")
                        Spacer()
                    }
                }
                .buttonStyle(QuickActionButtonStyle())
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(8)
    }

    private func copyFEN() {
        let fen = gameViewModel.board.toFEN()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fen, forType: .string)
    }

    private func toggleSound() {
        // 切换音效开关
    }

    private func showSettings() {
        // 显示设置面板
    }
}

// MARK: - 辅助组件

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct StatusIndicator: View {
    let state: EngineState

    var color: Color {
        switch state {
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

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
    }
}

// MARK: - 预览

#Preview {
    SideBarPreview()
}

struct SideBarPreview: View {
    var body: some View {
        HStack(spacing: 0) {
            LeftSidebarView(
                gameViewModel: GameViewModel(),
                engineViewModel: EngineViewModel()
            )
            .frame(width: 220)
        }
    }
}
