import Foundation
import SwiftUI

// MARK: - Accent Color Extensions

extension AccentColor {

    /// 获取适合背景的前景色
    public var foregroundColor: Color {
        switch self {
        case .blue, .indigo, .purple, .teal, .green:
            return .white
        case .red, .orange, .pink:
            return .white
        }
    }

    /// 获取浅色版本
    public var lightColor: Color {
        color.color.opacity(0.3)
    }

    /// 获取深色版本
    public var darkColor: Color {
        color.color.opacity(0.8)
    }

    /// 获取渐变色
    public var gradient: Gradient {
        Gradient(colors: [lightColor, color.color, darkColor])
    }

    /// 获取线性渐变
    public var linearGradient: LinearGradient {
        LinearGradient(
            gradient: gradient,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 获取 Angular 渐变
    public var angularGradient: AngularGradient {
        AngularGradient(gradient: gradient, center: .center)
    }

    /// 是否为暖色调
    public var isWarmColor: Bool {
        switch self {
        case .red, .orange, .pink:
            return true
        case .blue, .indigo, .teal, .green, .purple:
            return false
        }
    }

    /// 色温描述
    public var temperature: String {
        isWarmColor ? "暖色" : "冷色"
    }

    /// 获取推荐的配套颜色
    public var complementaryColors: [AccentColor] {
        switch self {
        case .blue:
            return [.orange, .teal, .purple]
        case .red:
            return [.green, .pink, .orange]
        case .green:
            return [.red, .teal, .blue]
        case .orange:
            return [.blue, .red, .pink]
        case .purple:
            return [.pink, .blue, .teal]
        case .pink:
            return [.purple, .red, .orange]
        case .teal:
            return [.blue, .green, .purple]
        case .indigo:
            return [.purple, .blue, .teal]
        }
    }
}

// MARK: - SwiftUI Color Extensions

extension Color {

    /// 从 AccentColor 创建 Color
    public init(accentColor: AccentColor) {
        self = accentColor.swiftUIColor
    }

    /// 获取颜色的 RGB 组件
    public var rgbComponents: (red: Double, green: Double, blue: Double, opacity: Double)? {
        // 这是一个简化实现，实际应用中可能需要使用 Core Graphics
        // 这里返回 nil，表示无法直接获取
        return nil
    }

    /// 判断颜色是否为亮色
    public var isLight: Bool {
        // 简化的亮度计算
        // 实际应该基于 RGB 值计算
        return true
    }

    /// 获取对比色（黑或白）
    public var contrastColor: Color {
        isLight ? .black : .white
    }
}

// MARK: - Color Scheme Extensions

extension ColorScheme {

    /// 显示名称
    public var displayName: String {
        switch self {
        case .light:
            return "浅色"
        case .dark:
            return "深色"
        @unknown default:
            return "自动"
        }
    }

    /// 相反的配色方案
    public var opposite: ColorScheme {
        switch self {
        case .light:
            return .dark
        case .dark:
            return .light
        @unknown default:
            return .light
        }
    }
}
