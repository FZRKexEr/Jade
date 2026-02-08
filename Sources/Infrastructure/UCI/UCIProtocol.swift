import Foundation

// MARK: - UCI Protocol Core

/// UCI 命令类型
enum UCICommand: Sendable {
    // 引擎控制
    case uci                          // 初始化UCI
    case debug(Bool)                  // 开启/关闭调试
    case isready                      // 查询引擎是否就绪
    case setoption(id: String, value: String?)  // 设置选项
    case register(String)             // 注册引擎
    case ucinewgame                   // 新游戏
    case quit                         // 退出

    // 位置与搜索
    case position(fen: String?, moves: [String])  // 设置局面
    case go(GoCommand)                // 开始搜索
    case stop                         // 停止搜索
    case ponderhit                    // 对手走了预期的棋
}

/// go 命令的子参数
enum GoCommand: Sendable {
    case searchmoves([String])        // 限制搜索的棋
    case ponder                       // 长考模式
    case wtime(Int)                 // 白方剩余时间(ms)
    case btime(Int)                 // 黑方剩余时间(ms)
    case winc(Int)                  // 白方每步增量(ms)
    case binc(Int)                  // 黑方每步增量(ms)
    case movestogo(Int)             // 当前时段剩余步数
    case depth(Int)                 // 固定深度搜索
    case nodes(Int)                 // 固定节点数搜索
    case mate(Int)                  // 搜索杀棋步数
    case movetime(Int)              // 固定时间搜索(ms)
    case infinite                   // 无限搜索
}

/// UCI 响应类型
enum UCIResponse: Sendable {
    case id(IdInfo)                 // 引擎信息
    case uciok                        // UCI初始化完成
    case readyok                      // 引擎就绪
    case bestmove(String, ponder: String?)  // 最佳走法
    case copyprotection(String)       // 版权保护状态
    case registration(String)         // 注册状态
    case info(InfoData)               // 搜索信息
    case option(OptionConfig)         // 可配置选项
}

/// 引擎身份信息
struct IdInfo: Sendable {
    let name: String?
    let author: String?
}

/// UCI 协议处理器
actor UCIProtocolHandler {
    private var observers: [UCIObserver] = []
    private var commandHistory: [UCICommand] = []

    // MARK: - Observer Pattern

    func addObserver(_ observer: UCIObserver) {
        observers.append(observer)
    }

    func removeObserver(_ observer: UCIObserver) {
        observers.removeAll { $0 === observer }
    }

    // MARK: - Command Processing

    func processCommand(_ command: UCICommand) -> String {
        let commandString = serialize(command)
        commandHistory.append(command)
        return commandString
    }

    // MARK: - Response Processing

    func processResponse(_ line: String) {
        // 简化实现，实际应解析响应
    }

    // MARK: - Serialization

    private func serialize(_ command: UCICommand) -> String {
        switch command {
        case .uci:
            return "uci"
        case .debug(let on):
            return "debug \(on ? "on" : "off")"
        case .isready:
            return "isready"
        case .setoption(let id, let value):
            if let value = value {
                return "setoption name \(id) value \(value)"
            } else {
                return "setoption name \(id)"
            }
        case .register(let token):
            return "register \(token)"
        case .ucinewgame:
            return "ucinewgame"
        case .quit:
            return "quit"
        case .position(let fen, let moves):
            var result = "position "
            if let fen = fen {
                result += "fen \(fen)"
            } else {
                result += "startpos"
            }
            if !moves.isEmpty {
                result += " moves \(moves.joined(separator: " "))"
            }
            return result
        case .go(let params):
            return serializeGoCommand(params)
        case .stop:
            return "stop"
        case .ponderhit:
            return "ponderhit"
        }
    }

    private func serializeGoCommand(_ command: GoCommand) -> String {
        switch command {
        case .searchmoves(let moves):
            return "go searchmoves \(moves.joined(separator: " "))"
        case .ponder:
            return "go ponder"
        case .wtime(let time):
            return "go wtime \(time)"
        case .btime(let time):
            return "go btime \(time)"
        case .winc(let inc):
            return "go winc \(inc)"
        case .binc(let inc):
            return "go binc \(inc)"
        case .movestogo(let moves):
            return "go movestogo \(moves)"
        case .depth(let depth):
            return "go depth \(depth)"
        case .nodes(let nodes):
            return "go nodes \(nodes)"
        case .mate(let mate):
            return "go mate \(mate)"
        case .movetime(let time):
            return "go movetime \(time)"
        case .infinite:
            return "go infinite"
        }
    }
}

/// UCI 观察者协议
protocol UCIObserver: AnyObject {
    func didReceive(response: UCIResponse)
    func didEncounterError(_ error: Error)
}
