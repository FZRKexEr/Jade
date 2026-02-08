import Foundation
import SwiftUI

// MARK: - Board Theme

/// 棋盘主题详细配置
public struct BoardThemeConfig: Codable, Equatable, Identifiable, Sendable {
    public let id = UUID()
    public var name: String
    public var boardColor: ColorComponents
    public var lineColor: ColorComponents
    public var gridWidth: CGFloat
    public var crossSize: CGFloat
    public var palaceLineStyle: PalaceLineStyle
    public var riverStyle: RiverStyle
    public var backgroundImage: String?
    public var highlightColor: ColorComponents
    public var lastMoveColor: ColorComponents
    public var validMoveColor: ColorComponents
    public var checkColor: ColorComponents

    public init(
        name: String,
        boardColor: ColorComponents,
        lineColor: ColorComponents = ColorComponents(red: 0.1, green: 0.1, blue: 0.1),
        gridWidth: CGFloat = 2.0,
        crossSize: CGFloat = 8.0,
        palaceLineStyle: PalaceLineStyle = .diagonal,
        riverStyle: RiverStyle = .solid,
        backgroundImage: String? = nil,
        highlightColor: ColorComponents = ColorComponents(red: 1.0, green: 0.8, blue: 0.0, opacity: 0.5),
        lastMoveColor: ColorComponents = ColorComponents(red: 0.0, green: 0.5, blue: 1.0, opacity: 0.5),
        validMoveColor: ColorComponents = ColorComponents(red: 0.0, green: 1.0, blue: 0.0, opacity: 0.5),
        checkColor: ColorComponents = ColorComponents(red: 1.0, green: 0.0, blue: 0.0, opacity: 0.7)
    ) {
        self.name = name
        self.boardColor = boardColor
        self.lineColor = lineColor
        self.gridWidth = gridWidth
        self.crossSize = crossSize
        self.palaceLineStyle = palaceLineStyle
        self.riverStyle = riverStyle
        self.backgroundImage = backgroundImage
        self.highlightColor = highlightColor
        self.lastMoveColor = lastMoveColor
        self.validMoveColor = validMoveColor
        self.checkColor = checkColor
    }
}

// MARK: - Palace Line Style

/// 九宫线样式
public enum PalaceLineStyle: String, Codable, CaseIterable, Sendable {
    case diagonal = "diagonal"      // 斜线 (标准中国象棋)
    case solid = "solid"            // 实线边框
    case dotted = "dotted"          // 虚线边框
    case none = "none"              // 无九宫线

    public var displayName: String {
        switch self {
        case .diagonal:
            return "标准斜线"
        case .solid:
            return "实线边框"
        case .dotted:
            return "虚线边框"
        case .none:
            return "无九宫线"
        }
    }
}

// MARK: - River Style

/// 楚河汉界样式
public enum RiverStyle: String, Codable, CaseIterable, Sendable {
    case solid = "solid"            // 实线
    case dashed = "dashed"          // 虚线
    case dotted = "dotted"          // 点线
    case double = "double"          // 双线
    case none = "none"              // 无线

    public var displayName: String {
        switch self {
        case .solid:
            return "实线"
        case .dashed:
            return "虚线"
        case .dotted:
            return "点线"
        case .double:
            return "双线"
        case .none:
            return "无线"
        }
    }
}

// MARK: - Board Theme Extensions

extension BoardTheme {

    /// 获取详细主题配置
    public var config: BoardThemeConfig {
        switch self {
        case .wood:
            return BoardThemeConfig(
                name: "木质",
                boardColor: ColorComponents(red: 0.87, green: 0.70, blue: 0.53),
                lineColor: ColorComponents(red: 0.1, green: 0.1, blue: 0.1),
                gridWidth: 2.0,
                backgroundImage: nil
            )

        case .darkWood:
            return BoardThemeConfig(
                name: "深色木",
                boardColor: ColorComponents(red: 0.55, green: 0.40, blue: 0.25),
                lineColor: ColorComponents(red: 0.9, green: 0.9, blue: 0.9),
                gridWidth: 2.0,
                backgroundImage: nil
            )

        case .lightWood:
            return BoardThemeConfig(
                name: "浅色木",
                boardColor: ColorComponents(red: 0.95, green: 0.85, blue: 0.70),
                lineColor: ColorComponents(red: 0.1, green: 0.1, blue: 0.1),
                gridWidth: 2.0,
                backgroundImage: nil
            )

        case .stone:
            return BoardThemeConfig(
                name: "石质",
                boardColor: ColorComponents(red: 0.75, green: 0.75, blue: 0.75),
                lineColor: ColorComponents(red: 0.2, green: 0.2, blue: 0.2),
                gridWidth: 2.5,
                backgroundImage: nil
            )

        case .modern:
            return BoardThemeConfig(
                name: "现代",
                boardColor: ColorComponents(red: 0.90, green: 0.90, blue: 0.90),
                lineColor: ColorComponents(red: 0.3, green: 0.3, blue: 0.3),
                gridWidth: 1.5,
                backgroundImage: nil
            )

        case .minimalist:
            return BoardThemeConfig(
                name: "极简",
                boardColor: ColorComponents(red: 1.0, green: 1.0, blue: 1.0),
                lineColor: ColorComponents(red: 0.0, green: 0.0, blue: 0.0),
                gridWidth: 1.0,
                backgroundImage: nil
            )

        case .paper:
            return BoardThemeConfig(
                name: "纸质",
                boardColor: ColorComponents(red: 0.98, green: 0.95, blue: 0.90),
                lineColor: ColorComponents(red: 0.3, green: 0.3, blue: 0.3),
                gridWidth: 1.5,
                backgroundImage: nil
            )
        }
    }
}
