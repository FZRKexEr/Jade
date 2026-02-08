import SwiftUI

/// 走棋历史标签页
struct MoveListTab: View {
    @Bindable var gameViewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("走棋历史")
                    .font(.headline)
                Spacer()
                Text("\(gameViewModel.moveHistory.count) 步")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.5))

            // 走棋列表
            List {
                ForEach(Array(gameViewModel.moveHistory.enumerated()), id: \.offset) { index, move in
                    MoveRow(
                        index: index + 1,
                        move: move,
                        isCurrent: index == gameViewModel.moveHistory.count - 1
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 跳转到该步
                    }
                }
            }
            .listStyle(.plain)

            // 底部导航
            HStack(spacing: 12) {
                Button(action: { gameViewModel.undoMove() }) {
                    Image(systemName: "arrow.backward")
                }
                .buttonStyle(MoveNavButtonStyle())
                .disabled(!gameViewModel.canUndo())

                Button(action: { gameViewModel.redoMove() }) {
                    Image(systemName: "arrow.forward")
                }
                .buttonStyle(MoveNavButtonStyle())
                .disabled(!gameViewModel.canRedo())

                Spacer()

                Button(action: { jumpToStart() }) {
                    Image(systemName: "backward.end.fill")
                }
                .buttonStyle(MoveNavButtonStyle())

                Button(action: { jumpToEnd() }) {
                    Image(systemName: "forward.end.fill")
                }
                .buttonStyle(MoveNavButtonStyle())
            }
            .padding(12)
            .background(.quaternary.opacity(0.3))
        }
    }

    private func jumpToStart() {
        while gameViewModel.canUndo() {
            gameViewModel.undoMove()
        }
    }

    private func jumpToEnd() {
        while gameViewModel.canRedo() {
            gameViewModel.redoMove()
        }
    }
}

/// 走棋行
struct MoveRow: View {
    let index: Int
    let move: Move
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 8) {
            // 序号
            Text("\(index).")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            // 棋子图标
            PieceIcon(piece: move.piece, size: 20)

            // 走法文字
            Text(moveText)
                .font(.system(.body, design: .monospaced))

            Spacer()

            // 当前步标记
            if isCurrent {
                Image(systemName: "chevron.right")
                    .foregroundColor(.accentColor)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
        .background(isCurrent ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }

    private var moveText: String {
        let from = move.from.description
        let to = move.to.description
        let capture = move.capturedPiece != nil ? "x" : "-"
        return "\(from)\(capture)\(to)"
    }
}

/// 棋子图标
struct PieceIcon: View {
    let piece: Piece
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(piece.player == .red ? Color.red : Color.black)
                .frame(width: size, height: size)

            Text(piece.character)
                .font(.system(size: size * 0.6, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

/// 导航按钮样式
struct MoveNavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 28, height: 28)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(4)
    }
}

// MARK: - 预览

#Preview {
    MoveListTab(gameViewModel: GameViewModel())
        .frame(height: 500)
}
