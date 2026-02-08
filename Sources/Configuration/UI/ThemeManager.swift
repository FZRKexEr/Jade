import SwiftUI
import Combine

// MARK: - Theme Manager

/// 主题管理器
@MainActor
@Observable
public final class ThemeManager {

    // MARK: - Properties

    /// 当前主题配置
    public var theme: ThemeConfiguration {
        didSet {
            applyTheme()
        }
    }

    /// 当前颜色方案（由系统或用户设置决定）
    public private(set) var colorScheme: ColorScheme = .light

    /// 是否使用深色模式
    public var isDarkMode: Bool {
        colorScheme == .dark
    }

    /// 当前强调色
    public var accentColor: Color {
        configuration.uiConfiguration.accentColor.swiftUIColor
    }

    /// 配置管理器引用
    private let configuration: AppConfiguration

    // MARK: - Colors

    /// 背景颜色
    public var backgroundColor: Color {
        isDarkMode ? Color(white: 0.1) : Color(white: 0.95)
    }

    /// 前景颜色（文字）
    public var foregroundColor: Color {
        isDarkMode ? Color.white : Color.black
    }

    /// 次级文字颜色
    public var secondaryForegroundColor: Color {
        isDarkMode ? Color.gray : Color(white: 0.3)
    }

    /// 卡片/面板背景
    public var cardBackgroundColor: Color {
        isDarkMode ? Color(white: 0.15) : Color.white
    }

    /// 分隔线颜色
    public var dividerColor: Color {
        isDarkMode ? Color(white: 0.25) : Color(white: 0.85)
    }

    /// 选中状态颜色
    public var selectionColor: Color {
        accentColor.opacity(0.2)
    }

    /// 高亮状态颜色
    public var highlightColor: Color {
        accentColor.opacity(0.1)
    }

    // MARK: - Initialization

    public init(configuration: AppConfiguration) {
        self.configuration = configuration
        self.theme = configuration.uiConfiguration.theme
        self.colorScheme = configuration.uiConfiguration.theme.colorScheme ?? .light

        // 监听系统外观变化
        setupAppearanceObserver()
    }

    // MARK: - Public Methods

    /// 设置主题
    public func setTheme(_ theme: ThemeConfiguration) {
        self.theme = theme
    }

    /// 切换深浅模式
    public func toggleColorScheme() {
        colorScheme = colorScheme == .dark ? .light : .dark
        applyTheme()
    }

    /// 应用主题到视图
    @ViewBuilder
    public func applyThemeToView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .preferredColorScheme(colorScheme)
    }

    /// 获取适合当前主题的颜色
    public func adaptiveColor(light: Color, dark: Color) -> Color {
        isDarkMode ? dark : light
    }

    /// 获取对比色
    public func contrastColor(for color: Color) -> Color {
        // 简化的对比度计算
        isDarkMode ? .black : .white
    }

    // MARK: - Private Methods

    private func applyTheme() {
        // 更新颜色方案
        switch theme {
        case .system:
            // 跟随系统设置
            colorScheme = .light  // 默认，实际由系统决定
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }

    private func setupAppearanceObserver() {
        // 监听系统外观变化
        // 在 macOS 上可以使用 DistributedNotificationCenter
        // 这里简化处理
    }
}

// MARK: - View Modifier

/// 主题视图修饰符
struct ThemedViewModifier: ViewModifier {
    @State private var themeManager: ThemeManager?

    func body(content: Content) -> some View {
        content
            .environment(\.themeManager, themeManager)
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

extension EnvironmentValues {
    var themeManager: ThemeManager? {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
