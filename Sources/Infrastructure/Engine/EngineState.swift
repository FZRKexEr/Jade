import Foundation

/// 引擎状态
enum EngineState: Equatable, Sendable {
    case idle
    case initializing
    case ready
    case searching
    case pondering
    case error(String)
}

/// 引擎配置
struct EngineConfiguration: Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let executablePath: String
    let workingDirectory: String?
    let arguments: [String]
    let defaultOptions: [String: String]
    let supportedVariants: [String]  // xiangqi, chess等

    static let pikafishDefault = EngineConfiguration(
        id: UUID(),
        name: "Pikafish",
        executablePath: "/usr/local/bin/pikafish",
        workingDirectory: nil,
        arguments: [],
        defaultOptions: [
            "Hash": "256",
            "Threads": "4",
            "UCI_Variant": "xiangqi"
        ],
        supportedVariants: ["xiangqi"]
    )
}

/// 引擎信息
struct EngineInfo: Sendable {
    let name: String?
    let author: String?
    let options: [String: OptionConfig]
    let availableVariants: [String]
}

/// 选项配置
struct OptionConfig: Sendable {
    let name: String
    let type: OptionType
    let defaultValue: String?
    let min: Int?
    let max: Int?
    let varOptions: [String]?
}

enum OptionType: Sendable {
    case check           // 布尔值
    case spin            // 整数范围
    case combo           // 枚举选项
    case button          // 按钮
    case string          // 字符串
}

/// 搜索信息
struct InfoData: Sendable {
    let depth: Int?                  // 当前深度
    let seldepth: Int?               // 选择性搜索深度
    let time: Int?                   // 搜索时间(ms)
    let nodes: Int?                  // 搜索节点数
    let pv: [String]?                // 主变例
    let multipv: Int?                // 多PV序号
    let score: ScoreInfo?            // 评估分数
    let currmove: String?            // 当前分析的着法
    let currmovenumber: Int?         // 当前分析序号
    let hashfull: Int?               // 哈希表填充率
    let nps: Int?                    // 每秒节点数
    let tbhits: Int?                 // 残局库命中
    let sbhits: Int?                 // 静态评估命中
    let cpuload: Int?                // CPU负载
    let string: String?              // 自定义字符串
    let refutation: [String]?        // 反驳线
    let currline: [String]?          // 当前搜索线
}

/// 评估分数信息
enum ScoreInfo: Sendable {
    case cp(Int)                      // 百分制分数（白方优势为正）
    case mate(Int)                    // 杀棋步数（正=白方杀，负=黑方杀）
    case lowerbound(Int)              // 下界
    case upperbound(Int)              // 上界
}
