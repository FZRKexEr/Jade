import Foundation
import SwiftUI

// MARK: - UI Configuration

/// 界面配置模型
public struct UIConfiguration: Codable, Equatable, Sendable {
    public var theme: ThemeConfiguration
    public var boardTheme: BoardTheme
    public var pieceTheme: PieceTheme
    public var accentColor: AccentColor
    public var fontConfiguration: FontConfiguration
    public var layoutConfiguration: LayoutConfiguration
    public var animationConfiguration: AnimationConfiguration

    public init(
        theme: ThemeConfiguration = .system,
        boardTheme: BoardTheme = .wood,
        pieceTheme: PieceTheme = .calligraphy,
        accentColor: AccentColor = .blue,
        fontConfiguration: FontConfiguration = FontConfiguration(),
        layoutConfiguration: LayoutConfiguration = LayoutConfiguration(),
        animationConfiguration: AnimationConfiguration = AnimationConfiguration()
    ) {
        self.theme = theme
        self.boardTheme = boardTheme
        self.pieceTheme = pieceTheme
        self.accentColor = accentColor
        self.fontConfiguration = fontConfiguration
        self.layoutConfiguration = layoutConfiguration
        self.animationConfiguration = animationConfiguration
    }

    /// 默认配置
    public static let `default` = UIConfiguration()

    /// 深色模式配置
    public static let dark = UIConfiguration(
        theme: .dark,
        boardTheme: .darkWood,
        pieceTheme: .modern,
        accentColor: .purple
    )

    /// 浅色模式配置
    public static let light = UIConfiguration(
        theme: .light,
        boardTheme: .lightWood,
        pieceTheme: .calligraphy,
        accentColor: .blue
    )
}

// MARK: - Theme Configuration

/// 主题配置
public enum ThemeConfiguration: String, Codable, CaseIterable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    public var displayName: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "浅色"
        case .dark:
            return "深色"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Board Theme

/// 棋盘主题
public enum BoardTheme: String, Codable, CaseIterable, Sendable {
    case wood = "wood"
    case darkWood = "darkWood"
    case lightWood = "lightWood"
    case stone = "stone"
    case modern = "modern"
    case minimalist = "minimalist"
    case paper = "paper"

    public var displayName: String {
        switch self {
        case .wood:
            return "木质"
        case .darkWood:
            return "深色木"
        case .lightWood:
            return "浅色木"
        case .stone:
            return "石质"
        case .modern:
            return "现代"
        case .minimalist:
            return "极简"
        case .paper:
            return "纸质"
        }
    }

    public var boardColor: ColorComponents {
        switch self {
        case .wood:
            return ColorComponents(red: 0.87, green: 0.70, blue: 0.53)
        case .darkWood:
            return ColorComponents(red: 0.55, green: 0.40, blue: 0.25)
        case .lightWood:
            return ColorComponents(red: 0.95, green: 0.85, blue: 0.70)
        case .stone:
            return ColorComponents(red: 0.75, green: 0.75, blue: 0.75)
        case .modern:
            return ColorComponents(red: 0.90, green: 0.90, blue: 0.90)
        case .minimalist:
            return ColorComponents(red: 1.0, green: 1.0, blue: 1.0)
        case .paper:
            return ColorComponents(red: 0.98, green: 0.95, blue: 0.90)
        }
    }

    public var lineColor: ColorComponents {
        switch self {
        case .darkWood, .stone:
            return ColorComponents(red: 0.9, green: 0.9, blue: 0.9)
        default:
            return ColorComponents(red: 0.1, green: 0.1, blue: 0.1)
        }
    }

    public var gridWidth: CGFloat {
        switch self {
        case .minimalist:
            return 1.0
        case .modern:
            return 1.5
        default:
            return 2.0
        }
    }
}

// MARK: - Piece Theme

/// 棋子主题
public enum PieceTheme: String, Codable, CaseIterable, Sendable {
    case calligraphy = "calligraphy"
    case regular = "regular"
    case modern = "modern"
    case traditional = "traditional"
    case minimal = "minimal"

    public var displayName: String {
        switch self {
        case .calligraphy:
            return "隶书"
        case .regular:
            return "楷书"
        case .modern:
            return "现代"
        case .traditional:
            return "传统"
        case .minimal:
            return "极简"
        }
    }

    public var fontName: String? {
        switch self {
        case .calligraphy:
            return "STKaiti"
        case .regular:
            return "STSong"
        case .modern:
            return "PingFang SC"
        case .traditional:
            return "Heiti SC"
        case .minimal:
            return nil // 使用系统默认
        }
    }

    public var textStyle: PieceTextStyle {
        switch self {
        case .calligraphy, .regular:
            return .outline
        case .modern:
            return .filled
        case .traditional:
            return .embossed
        case .minimal:
            return .simple
        }
    }

    public var scale: CGFloat {
        switch self {
        case .minimal:
            return 0.85
        default:
            return 1.0
        }
    }
}

// MARK: - Accent Color

/// 强调色配置
public enum AccentColor: String, Codable, CaseIterable, Sendable {
    case blue = "blue"
    case red = "red"
    case green = "green"
    case purple = "purple"
    case orange = "orange"
    case pink = "pink"
    case teal = "teal"
    case indigo = "indigo"

    public var displayName: String {
        switch self {
        case .blue: return "蓝色"
        case .red: return "红色"
        case .green: return "绿色"
        case .purple: return "紫色"
        case .orange: return "橙色"
        case .pink: return "粉色"
        case .teal: return "青色"
        case .indigo: return "靛蓝"
        }
    }

    public var color: ColorComponents {
        switch self {
        case .blue:
            return ColorComponents(red: 0.0, green: 0.48, blue: 1.0)
        case .red:
            return ColorComponents(red: 1.0, green: 0.23, blue: 0.19)
        case .green:
            return ColorComponents(red: 0.20, green: 0.78, blue: 0.35)
        case .purple:
            return ColorComponents(red: 0.69, green: 0.32, blue: 0.87)
        case .orange:
            return ColorComponents(red: 1.0, green: 0.58, blue: 0.0)
        case .pink:
            return ColorComponents(red: 1.0, green: 0.18, blue: 0.53)
        case .teal:
            return ColorComponents(red: 0.35, green: 0.78, blue: 0.98)
        case .indigo:
            return ColorComponents(red: 0.35, green: 0.34, blue: 0.84)
        }
    }

    public var swiftUIColor: Color {
        Color(color.cgColor)
    }
}

// MARK: - Supporting Types

/// 棋子文字样式
public enum PieceTextStyle: String, Codable, Sendable {
    case outline = "outline"       // 空心描边
    case filled = "filled"         // 实心填充
    case embossed = "embossed"     // 浮雕效果
    case simple = "simple"         // 简单文字
}

/// 颜色组件 (用于存储，可转换为 SwiftUI Color)
public struct ColorComponents: Codable, Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let opacity: Double

    public init(
        red: Double,
        green: Double,
        blue: Double,
        opacity: Double = 1.0
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    public var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: opacity)
    }

    public var color: Color {
        Color(cgColor)
    }
}

// MARK: - Font Configuration

/// 字体配置
public struct FontConfiguration: Codable, Equatable, Sendable {
    public var useSystemFont: Bool
    public var customFontName: String?
    public var textSize: TextSize
    public var useBoldText: Bool

    public init(
        useSystemFont: Bool = true,
        customFontName: String? = nil,
        textSize: TextSize = .medium,
        useBoldText: Bool = false
    ) {
        self.useSystemFont = useSystemFont
        self.customFontName = customFontName
        self.textSize = textSize
        self.useBoldText = useBoldText
    }
}

public enum TextSize: String, Codable, CaseIterable, Sendable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"

    public var displayName: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        case .extraLarge: return "特大"
        }
    }

    public var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }
}

// MARK: - Layout Configuration

/// 布局配置
public struct LayoutConfiguration: Codable, Equatable, Sendable {
    public var boardSize: BoardSize
    public var showCoordinates: Bool
    public var showMoveHistory: Bool
    public var showCapturedPieces: Bool
    public var compactMode: Bool

    public init(
        boardSize: BoardSize = .medium,
        showCoordinates: Bool = true,
        showMoveHistory: Bool = true,
        showCapturedPieces: Bool = true,
        compactMode: Bool = false
    ) {
        self.boardSize = boardSize
        self.showCoordinates = showCoordinates
        self.showMoveHistory = showMoveHistory
        self.showCapturedPieces = showCapturedPieces
        self.compactMode = compactMode
    }
}

public enum BoardSize: String, Codable, CaseIterable, Sendable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case fullScreen = "fullScreen"

    public var displayName: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        case .fullScreen: return "全屏"
        }
    }
}

// MARK: - Animation Configuration

/// 动画配置
public struct AnimationConfiguration: Codable, Equatable, Sendable {
    public var enableAnimations: Bool
    public var animationSpeed: AnimationSpeed
    public var enableSound: Bool
    public var soundVolume: Double

    public init(
        enableAnimations: Bool = true,
        animationSpeed: AnimationSpeed = .normal,
        enableSound: Bool = true,
        soundVolume: Double = 0.7
    ) {
        self.enableAnimations = enableAnimations
        self.animationSpeed = animationSpeed
        self.enableSound = enableSound
        self.soundVolume = max(0, min(1, soundVolume))
    }
}

public enum AnimationSpeed: String, Codable, CaseIterable, Sendable {
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"
    case instant = "instant"

    public var displayName: String {
        switch self {
        case .slow: return "慢"
        case .normal: return "正常"
        case .fast: return "快"
        case .instant: return "瞬间"
        }
    }

    public var duration: Double {
        switch self {
        case .slow:
            return 0.5
        case .normal:
            return 0.3
        case .fast:
            return 0.15
        case .instant:
            return 0.0
        }
    }

    public var animation: Animation {
        switch self {
        case .instant:
            return .linear(duration: 0)
        default:
            return .easeInOut(duration: duration)
        }
    }
}
