import SwiftUI

// MARK: - BoardContainerView

/// 棋盘容器视图 - 包裹 NSViewRepresentable 的 SwiftUI 容器
/// 使用高性能的 AppKit 渲染
struct BoardContainerView: View {
    @Bindable var boardViewModel: BoardViewModel
    @State private var containerSize: CGSize = .zero

    // 棋盘保持 9:10 宽高比
    private let boardRatio: CGFloat = 9.0 / 10.0

    // 主题配置
    private var boardTheme: BoardThemeConfig {
        // 从配置管理器获取当前主题
        BoardTheme.wood.config
    }

    private var pieceTheme: PieceThemeConfig {
        PieceTheme.calligraphy.config
    }

    var body: some View {
        GeometryReader { geometry in
            let availableSize = geometry.size
            let boardSize = calculateBoardSize(in: availableSize)

            ZStack {
                // 背景阴影层
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )

                // AppKit 棋盘视图
                BoardViewRepresentable(
                    viewModel: boardViewModel,
                    boardTheme: boardTheme,
                    pieceTheme: pieceTheme,
                    isDarkMode: isDarkMode
                )
                .frame(width: boardSize.width, height: boardSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // 坐标标签（可选）
                if boardViewModel.showCoordinates {
                    CoordinateLabelsView(
                        boardSize: boardSize,
                        isFlipped: false
                    )
                }
            }
            .frame(width: boardSize.width + 16, height: boardSize.height + 16)
            .position(x: availableSize.width / 2, y: availableSize.height / 2)
            .onAppear {
                containerSize = availableSize
            }
        }
    }

    // MARK: - 辅助方法

    private func calculateBoardSize(in availableSize: CGSize) -> CGSize {
        let availableRatio = availableSize.width / availableSize.height

        let boardWidth: CGFloat
        let boardHeight: CGFloat

        if availableRatio > boardRatio {
            // 高度受限
            boardHeight = availableSize.height * 0.85
            boardWidth = boardHeight * boardRatio
        } else {
            // 宽度受限
            boardWidth = availableSize.width * 0.85
            boardHeight = boardWidth / boardRatio
        }

        return CGSize(width: boardWidth, height: boardHeight)
    }

    private var isDarkMode: Bool {
        // 检测当前是否为深色模式
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}

// MARK: - CoordinateLabelsView

/// 坐标标签视图
private struct CoordinateLabelsView: View {
    let boardSize: CGSize
    let isFlipped: Bool

    private var cellSize: CGFloat {
        boardSize.width / 8
    }

    var body: some View {
        ZStack {
            // 横坐标（1-9）
            ForEach(0..<9) { index in
                let x = CGFloat(index) * cellSize
                let label = isFlipped ? "\(9 - index)" : "\(index + 1)"

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .position(x: x, y: -12)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .position(x: x, y: boardSize.height + 12)
            }

            // 纵坐标（a-i 或 一-九）
            let files = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
            ForEach(0..<10) { index in
                let y = CGFloat(index) * cellSize
                let labelIndex = isFlipped ? 9 - index : index

                if labelIndex >= 0 && labelIndex < 9 {
                    let label = files[labelIndex]

                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .position(x: -12, y: y)

                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .position(x: boardSize.width + 12, y: y)
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    BoardContainerView(
        boardViewModel: BoardViewModel()
    )
    .frame(width: 600, height: 700)
}
