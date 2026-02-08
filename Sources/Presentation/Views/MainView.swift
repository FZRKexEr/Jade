import SwiftUI

/// 主窗口视图 - 三栏布局
struct MainView: View {
    @State private var gameViewModel = GameViewModel()
    @State private var engineViewModel = EngineViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    // 侧边栏宽度
    private let leftSidebarWidth: CGFloat = 220
    private let rightSidebarWidth: CGFloat = 280

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 左侧控制区
            LeftSidebarView(
                gameViewModel: gameViewModel,
                engineViewModel: engineViewModel
            )
            .frame(minWidth: leftSidebarWidth)
            .navigationSplitViewColumnWidth(min: leftSidebarWidth, ideal: leftSidebarWidth)
        } content: {
            // 中间棋盘区
            BoardAreaView(
                gameViewModel: gameViewModel,
                engineViewModel: engineViewModel
            )
            .frame(minWidth: 500, minHeight: 600)
        } detail: {
            // 右侧信息区
            RightSidebarView(
                gameViewModel: gameViewModel,
                engineViewModel: engineViewModel
            )
            .frame(minWidth: rightSidebarWidth)
            .navigationSplitViewColumnWidth(min: rightSidebarWidth, ideal: rightSidebarWidth)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                ControlBarView(
                    gameViewModel: gameViewModel,
                    engineViewModel: engineViewModel
                )
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
}

// MARK: - 左侧边栏

struct LeftSidebarView: View {
    @Bindable var gameViewModel: GameViewModel
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        VStack(spacing: 16) {
            // 引擎状态面板
            EngineStatusPanel(engineViewModel: engineViewModel)
                .padding(.horizontal, 12)

            Divider()

            // 对局信息
            GameInfoPanel(gameViewModel: gameViewModel)
                .padding(.horizontal, 12)

            Divider()

            // 快捷操作
            QuickActionsPanel(
                gameViewModel: gameViewModel,
                engineViewModel: engineViewModel
            )
            .padding(.horizontal, 12)

            Spacer()
        }
        .padding(.vertical, 16)
    }
}

// MARK: - 右侧边栏

struct RightSidebarView: View {
    @Bindable var gameViewModel: GameViewModel
    @Bindable var engineViewModel: EngineViewModel

    var body: some View {
        TabView {
            // 走棋历史
            MoveListTab(gameViewModel: gameViewModel)
                .tabItem {
                    Label("历史", systemImage: "list.bullet")
                }

            // 引擎分析
            EngineAnalysisTab(engineViewModel: engineViewModel)
                .tabItem {
                    Label("分析", systemImage: "cpu")
                }

            // 变着评注
            VariationTab()
                .tabItem {
                    Label("变着", systemImage: "arrow.branch")
                }
        }
        .padding(.top, 8)
    }
}

// MARK: - 棋盘区域

struct BoardAreaView: View {
    @Bindable var gameViewModel: GameViewModel
    @Bindable var engineViewModel: EngineViewModel
    @State private var boardSize: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.clear

                // 棋盘容器
                BoardContainerView(
                    gameViewModel: gameViewModel,
                    size: min(geometry.size.width, geometry.size.height * 0.9) * gameViewModel.boardScale
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - 预览

#Preview {
    MainView()
}
