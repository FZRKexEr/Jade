import Foundation
import SwiftUI

// MARK: - Piece Theme Configuration

/// 棋子主题详细配置
public struct PieceThemeConfig: Codable, Equatable, Identifiable, Sendable {
    public let id = UUID()
    public var name: String
    public var fontName: String?
    public var fontScale: CGFloat
    public var redColor: ColorComponents
    public var blackColor: ColorComponents
    public var backgroundColor: ColorComponents
    public var borderColor: ColorComponents
    public var borderWidth: CGFloat
    public var shadowRadius: CGFloat
    public var shadowOpacity: Double
    public var textStyle: PieceTextStyle
    public var useGradient: Bool
    public var gradientStartColor: ColorComponents
    public var gradientEndColor: ColorComponents

    public init(
        name: String,
        fontName: String? = nil,
        fontScale: CGFloat = 1.0,
        redColor: ColorComponents = ColorComponents(red: 0.8, green: 0.0, blue: 0.0),
        blackColor: ColorComponents = ColorComponents(red: 0.1, green: 0.1, blue: 0.1),
        backgroundColor: ColorComponents = ColorComponents(red: 1.0, green: 0.95, blue: 0.8),
        borderColor: ColorComponents = ColorComponents(red: 0.4, green: 0.3, blue: 0.2),
        borderWidth: CGFloat = 2.0,
        shadowRadius: CGFloat = 3.0,
        shadowOpacity: Double = 0.3,
        textStyle: PieceTextStyle = .outline,
        useGradient: Bool = false,
        gradientStartColor: ColorComponents = ColorComponents(red: 1.0, green: 1.0, blue: 1.0),
        gradientEndColor: ColorComponents = ColorComponents(red: 0.9, green: 0.9, blue: 0.9)
    ) {
        self.name = name
        self.fontName = fontName
        self.fontScale = fontScale
        self.redColor = redColor
        self.blackColor = blackColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.textStyle = textStyle
        self.useGradient = useGradient
        self.gradientStartColor = gradientStartColor
        self.gradientEndColor = gradientEndColor
    }
}

// MARK: - Piece Theme Extensions

extension PieceTheme {

    /// 获取详细主题配置
    public var config: PieceThemeConfig {
        switch self {
        case .calligraphy:
            return PieceThemeConfig(
                name: "隶书",
                fontName: "STKaiti",
                fontScale: 1.0,
                redColor: ColorComponents(red: 0.85, green: 0.1, blue: 0.05),
                blackColor: ColorComponents(red: 0.1, green: 0.1, blue: 0.1),
                backgroundColor: ColorComponents(red: 1.0, green: 0.97, blue: 0.9),
                borderColor: ColorComponents(red: 0.5, green: 0.4, blue: 0.3),
                borderWidth: 2.5,
                shadowRadius: 2,
                shadowOpacity: 0.25,
                textStyle: .outline,
                useGradient: true
            )

        case .regular:
            return PieceThemeConfig(
                name: "楷书",
                fontName: "STSong",
                fontScale: 0.95,
                redColor: ColorComponents(red: 0.9, green: 0.15, blue: 0.1),
                blackColor: ColorComponents(red: 0.15, green: 0.15, blue: 0.15),
                backgroundColor: ColorComponents(red: 1.0, green: 0.95, blue: 0.85),
                borderColor: ColorComponents(red: 0.4, green: 0.3, blue: 0.25),
                borderWidth: 2.0,
                shadowRadius: 3,
                shadowOpacity: 0.3,
                textStyle: .outline
            )

        case .modern:
            return PieceThemeConfig(
                name: "现代",
                fontName: "PingFang SC",
                fontScale: 0.85,
                redColor: ColorComponents(red: 1.0, green: 0.2, blue: 0.15),
                blackColor: ColorComponents(red: 0.2, green: 0.2, blue: 0.2),
                backgroundColor: ColorComponents(red: 0.95, green: 0.95, blue: 0.95),
                borderColor: ColorComponents(red: 0.6, green: 0.6, blue: 0.6),
                borderWidth: 1.5,
                shadowRadius: 4,
                shadowOpacity: 0.4,
                textStyle: .filled,
                useGradient: true
            )

        case .traditional:
            return PieceThemeConfig(
                name: "传统",
                fontName: "Heiti SC",
                fontScale: 1.0,
                redColor: ColorComponents(red: 0.8, green: 0.0, blue: 0.0),
                blackColor: ColorComponents(red: 0.05, green: 0.05, blue: 0.05),
                backgroundColor: ColorComponents(red: 1.0, green: 0.94, blue: 0.88),
                borderColor: ColorComponents(red: 0.45, green: 0.35, blue: 0.25),
                borderWidth: 3.0,
                shadowRadius: 2,
                shadowOpacity: 0.2,
                textStyle: .embossed
            )

        case .minimal:
            return PieceThemeConfig(
                name: "极简",
                fontName: nil,
                fontScale: 0.7,
                redColor: ColorComponents(red: 0.9, green: 0.1, blue: 0.1),
                blackColor: ColorComponents(red: 0.1, green: 0.1, blue: 0.1),
                backgroundColor: ColorComponents(red: 1.0, green: 1.0, blue: 1.0),
                borderColor: ColorComponents(red: 0.8, green: 0.8, blue: 0.8),
                borderWidth: 1.0,
                shadowRadius: 0,
                shadowOpacity: 0.0,
                textStyle: .simple
            )
        }
    }
}

// MARK: - Piece Style Views

extension PieceThemeConfig {

    /// 创建棋子背景
    @ViewBuilder
    public func pieceBackgroundView(isSelected: Bool = false) -> some View {
        ZStack {
            // 基础形状
            Circle()
                .fill(backgroundColor.color)

            // 渐变效果
            if useGradient {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                gradientStartColor.color,
                                gradientEndColor.color
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.3)
            }

            // 边框
            Circle()
                .stroke(borderColor.color, lineWidth: borderWidth)

            // 选中效果
            if isSelected {
                Circle()
                    .stroke(Color.yellow, lineWidth: borderWidth + 1)
                    .shadow(color: Color.yellow.opacity(0.5), radius: 5)
            }
        }
        .shadow(
            color: Color.black.opacity(shadowOpacity),
            radius: shadowRadius,
            x: 0,
            y: 2
        )
    }
}
