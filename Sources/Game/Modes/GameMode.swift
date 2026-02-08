import Foundation

// MARK: - GameMode

/// 游戏模式枚举
/// 定义了对弈的不同模式：人机对弈、人人对弈、机机对弈、分析模式
public enum GameMode: String, CaseIterable, Sendable, CustomStringConvertible, Identifiable {
    /// 人机对弈
    case humanVsEngine = "humanVsEngine"

    /// 人人对弈
    case humanVsHuman = "humanVsHuman"

    /// 机机对弈
    case engineVsEngine = "engineVsEngine"

    /// 分析模式
    case analysis = "analysis"

    public var id: String { rawValue }

    public var description: String {
        displayName
    }

    /// 显示名称
    public var displayName: String {
        switch self {
        case .humanVsEngine:
            return "人机对弈"
        case .humanVsHuman:
            return "人人对弈"
        case .engineVsEngine:
            return "机机对弈"
        case .analysis:
            return "分析模式"
        }
    }

    /// 图标名称
    public var iconName: String {
        switch self {
        case .humanVsEngine:
            return "person.fill"
        case .humanVsHuman:
            return "person.2.fill"
        case .engineVsEngine:
            return "cpu.fill"
        case .analysis:
            return "magnifyingglass"
        }
    }

    /// 是否需要引擎
    public var requiresEngine: Bool {
        switch self {
        case .humanVsHuman:
            return false
        case .humanVsEngine, .engineVsEngine, .analysis:
            return true
        }
    }

    /// 需要几个引擎
    public var requiredEngineCount: Int {
        switch self {
        case .humanVsHuman, .analysis, .humanVsEngine:
            return 0
        case .engineVsEngine:
            return 2
        }
    }

    /// 是否支持悔棋
    public var supportsUndo: Bool {
        switch self {
        case .analysis:
            return false
        default:
            return true
        }
    }

    /// 是否显示思考信息
    public var showsThinkingInfo: Bool {
        switch self {
        case .humanVsEngine, .engineVsEngine, .analysis:
            return true
        case .humanVsHuman:
            return false
        }
    }
}
