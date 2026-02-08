import SwiftUI

/// 中国象棋应用主入口
@main
struct ChineseChessApp: App {
    @State private var gameViewModel = GameViewModel()
    @State private var engineViewModel = EngineViewModel()
    @State private var isSettingsPresented = false

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(gameViewModel)
                .environment(engineViewModel)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            AppMenus(
                gameViewModel: $gameViewModel,
                engineViewModel: $engineViewModel,
                isSettingsPresented: $isSettingsPresented
            )
        }

        // 设置窗口
        Settings {
            SettingsView()
        }
    }
}

/// 环境值的定义
private struct GameViewModelKey: EnvironmentKey {
    static let defaultValue = GameViewModel()
}

private struct EngineViewModelKey: EnvironmentKey {
    static let defaultValue = EngineViewModel()
}

extension EnvironmentValues {
    var gameViewModel: GameViewModel {
        get { self[GameViewModelKey.self] }
        set { self[GameViewModelKey.self] = newValue }
    }

    var engineViewModel: EngineViewModel {
        get { self[EngineViewModelKey.self] }
        set { self[EngineViewModelKey.self] = newValue }
    }
}
