# macOS 中国象棋应用架构设计

## 1. 技术栈选择

### 1.1 SwiftUI vs AppKit 对比分析

| 维度 | SwiftUI | AppKit |
|------|---------|--------|
| **学习曲线** | 现代化声明式语法，易上手 | 传统命令式，学习成本高 |
| **性能** | 适合大部分场景，复杂场景可能受限 | 完全控制渲染，性能最优 |
| **定制性** | 组件有限，复杂UI需要桥接AppKit | 完全可定制，自定义NSView灵活 |
| **响应式数据流** | 原生支持 @State, @Observable | 需手动实现KVO或绑定 |
| **游戏渲染** | 可用Canvas/Metal桥接 | 原生NSOpenGLView/MetalView |
| **跨平台** | 代码可复用到iOS/iPadOS | 仅限macOS |

### 1.2 最终选择：SwiftUI + AppKit 混合架构

**核心决策理由：**

1. **UI层采用 SwiftUI**：棋盘外框、控制面板、设置界面使用SwiftUI，利用其声明式语法快速开发
2. **棋盘视图使用 NSViewRepresentable**：象棋棋盘需要精确像素控制和自定义绘制，桥接AppKit的`NSView`实现
3. **引擎通信使用Foundation**：进程管理使用`Process`类（底层是NSTask），与UI框架无关
4. **数据模型使用Swift**：纯Swift结构体和类，可在SwiftUI和AppKit间共享

**架构层次图：**

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐  │
│  │  Settings   │  │ Control Bar  │  │   Board Container   │  │
│  │   SwiftUI   │  │   SwiftUI    │  │     SwiftUI         │  │
│  └─────────────┘  └──────────────┘  └─────────────────────┘  │
│                           │                                  │
│              ┌────────────┴────────────┐                    │
│              │  NSViewRepresentable      │                    │
│              │    Bridge Layer           │                    │
│              └────────────┬────────────┘                    │
└───────────────────────────┼─────────────────────────────────┘
                            │
┌───────────────────────────┼─────────────────────────────────┐
│                      Rendering Layer                         │
│              ┌────────────┴────────────┐                    │
│              │      Board NSView         │                    │
│              │    (CALayer / Canvas)     │                    │
│              └───────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
                            │
┌───────────────────────────┼─────────────────────────────────┐
│                      Domain Layer                            │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐  │
│  │    Board    │  │    Piece     │  │       Move          │  │
│  │   Model     │  │    Model     │  │      Model          │  │
│  └─────────────┘  └──────────────┘  └─────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    Game State Manager                    │  │
│  │              (局面管理、胜负判定、历史记录)               │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
┌───────────────────────────┼─────────────────────────────────┐
│                     Infrastructure Layer                       │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    UCI Protocol Handler                  │  │
│  │              (UCI命令解析、响应处理、状态机)               │  │
│  └─────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    Engine Manager                        │  │
│  │     (引擎进程管理、生命周期控制、多引擎支持)               │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 项目目录结构

```
ChineseChess/
├── App/
│   ├── ChineseChessApp.swift           # App入口
│   └── AppDelegate.swift               # (可选)生命周期处理
│
├── Presentation/                        # 表示层 (SwiftUI)
│   ├── Views/
│   │   ├── MainView.swift              # 主窗口视图
│   │   ├── BoardView.swift             # 棋盘容器 (SwiftUI)
│   │   ├── ControlBarView.swift        # 控制栏
│   │   ├── MoveListView.swift          # 走棋历史
│   │   ├── SettingsView.swift          # 设置面板
│   │   └── Components/
│   │       ├── PieceView.swift         # 棋子视图组件
│   │       ├── BoardGrid.swift         # 棋盘网格
│   │       └── Markers.swift           # 选中/提示标记
│   │
│   ├── ViewModels/
│   │   ├── BoardViewModel.swift        # 棋盘VM
│   │   ├── GameViewModel.swift         # 游戏状态VM
│   │   └── EngineViewModel.swift       # 引擎控制VM
│   │
│   └── Representables/                # SwiftUI与AppKit桥接
│       ├── BoardViewRepresentable.swift
│       └── NSViewWrapper.swift
│
├── Presentation-AppKit/               # AppKit原生视图
│   └── Views/
│       ├── BoardNSView.swift           # 棋盘NSView
│       ├── PieceCALayer.swift          # 棋子CALayer
│       └── BoardRenderer.swift         # 棋盘绘制逻辑
│
├── Domain/                              # 领域层 (核心模型)
│   ├── Models/
│   │   ├── Board.swift                 # 棋盘模型
│   │   ├── Piece.swift                 # 棋子模型
│   │   ├── Move.swift                  # 走棋
│   │   ├── Position.swift              # 位置坐标
│   │   ├── GameState.swift             # 游戏状态
│   │   ├── Player.swift                # 玩家(红/黑)
│   │   └── Notation.swift              # 记谱法
│   │
│   ├── Rules/
│   │   ├── RuleEngine.swift            # 规则引擎
│   │   ├── MovementRules.swift         # 各棋子走法
│   │   ├── ValidationRules.swift       # 合法性验证
│   │   ├── CheckDetection.swift        # 将军检测
│   │   └── WinCondition.swift          # 胜负判定
│   │
│   └── Services/
│       ├── GameManager.swift           # 游戏管理器
│       └── MoveHistory.swift           # 历史记录管理
│
├── Infrastructure/                      # 基础设施层
│   ├── UCI/
│   │   ├── UCIProtocol.swift           # UCI协议定义
│   │   ├── UCICommand.swift            # UCI命令
│   │   ├── UCIResponse.swift           # UCI响应
│   │   ├── UCIStateMachine.swift       # 状态机
│   │   └── UCIParser.swift             # 解析器
│   │
│   ├── Engine/
│   │   ├── EngineManager.swift         # 引擎管理器
│   │   ├── EngineProcess.swift         # 引擎进程包装
│   │   ├── EngineConfiguration.swift   # 引擎配置
│   │   ├── EngineCapabilities.swift    # 引擎能力
│   │   └── MultiEngineSupport.swift    # 多引擎支持
│   │
│   └── Utilities/
│       ├── Logger.swift                # 日志系统
│       ├── EventBus.swift              # 事件总线
│       └── AsyncUtils.swift            # 异步工具
│
├── Resources/                           # 资源文件
│   ├── Assets.xcassets/
│   ├── Pieces/                         # 棋子图片资源
│   ├── Sounds/                         # 音效
│   └── Engines/                        # 内置引擎
│
├── Tests/
│   ├── ChineseChessTests/
│   └── ChineseChessUITests/
│
└── Package.swift                        # SPM依赖管理
```

---

## 3. UCI 协议通信层架构设计

### 3.1 UCI 协议概述

UCI (Universal Chess Interface) 是象棋引擎的标准通信协议。本应用需要适配中国象棋引擎（如 Pikafish - Stockfish的中国象棋版本）。

### 3.2 核心协议定义

```swift
// MARK: - UCI Protocol Core

/// UCI 命令类型
enum UCICommand {
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
enum GoCommand {
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
enum UCIResponse {
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
struct IdInfo {
    let name: String?
    let author: String?
}

/// info 命令的详细数据
struct InfoData {
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
enum ScoreInfo {
    case cp(Int)                      // 百分制分数（白方优势为正）
    case mate(Int)                    // 杀棋步数（正=白方杀，负=黑方杀）
    case lowerbound(Int)              // 下界
    case upperbound(Int)              // 上界
}

/// 引擎配置选项
struct OptionConfig {
    let name: String
    let type: OptionType
    let defaultValue: String?
    let min: Int?
    let max: Int?
    let varOptions: [String]?
}

enum OptionType {
    case check           // 布尔值
    case spin            // 整数范围
    case combo           // 枚举选项
    case button          // 按钮
    case string          // 字符串
}
```

### 3.3 UCI 状态机设计

```swift
/// UCI 状态机
actor UCIStateMachine {
    enum State {
        case idle           // 初始状态
        case initializing // 发送uci后等待uciok
        case ready        // 引擎就绪，可接收命令
        case searching    // 正在搜索
        case pondering    // 长考模式
        case error        // 错误状态
    }

    private var state: State = .idle
    private var pendingCommand: UCICommand?

    // 状态转换
    func transition(to newState: State) throws {
        guard isValidTransition(from: state, to: newState) else {
            throw UCIError.invalidStateTransition(from: state, to: newState)
        }
        state = newState
    }

    private func isValidTransition(from: State, to: State) -> Bool {
        switch (from, to) {
        case (.idle, .initializing),
             (.initializing, .ready),
             (.initializing, .error),
             (.ready, .searching),
             (.ready, .pondering),
             (.ready, .error),
             (.searching, .ready),
             (.searching, .pondering),
             (.pondering, .searching),
             (.pondering, .ready),
             (.error, .idle):
            return true
        default:
            return false
        }
    }
}
```

### 3.4 UCI 通信协议处理器

```swift
/// UCI 协议处理器协议
protocol UCIObserver: AnyObject {
    func didReceive(response: UCIResponse)
    func didEncounterError(_ error: UCIError)
}

/// UCI 协议处理器
actor UCIProtocolHandler {
    private var observers: [UCIObserver] = []
    private let parser = UCIParser()
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
        do {
            let response = try parser.parse(line)
            notifyObservers(response)
        } catch {
            notifyErrorObservers(UCIError.parseError(line))
        }
    }

    private func notifyObservers(_ response: UCIResponse) {
        for observer in observers {
            observer.didReceive(response: response)
        }
    }

    private func notifyErrorObservers(_ error: UCIError) {
        for observer in observers {
            observer.didEncounterError(error)
        }
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
        // 实现细节省略...
        ""
    }
}
```

---

## 4. 引擎管理器设计

### 4.1 引擎管理器架构

```swift
import Foundation

// MARK: - Error Types

enum EngineError: Error {
    case notInitialized
    case alreadyRunning
    case processFailed(Error)
    case communicationFailed
    case engineNotReady
    case invalidPath
    case timeout
    case engineCrashed
}

// MARK: - Engine State

enum EngineState: Equatable {
    case idle
    case initializing
    case ready
    case searching
    case pondering
    case error(String)
}

// MARK: - Engine Configuration

struct EngineConfiguration: Codable, Equatable {
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

// MARK: - Engine Info

struct EngineInfo {
    let name: String?
    let author: String?
    let options: [String: OptionConfig]
    let availableVariants: [String]
}

// MARK: - Engine Manager Protocol

protocol EngineManagerProtocol: AnyObject {
    var state: EngineState { get }
    var configuration: EngineConfiguration { get }

    // 生命周期
    func initialize() async throws
    func shutdown() async
    func restart() async throws

    // UCI命令
    func sendUCI() async throws
    func sendIsReady() async throws
    func setOption(name: String, value: String) async throws
    func setPosition(fen: String?, moves: [String]) async throws
    func go(command: GoCommand) async throws
    func stop() async throws
    func ponderHit() async throws
    func newGame() async throws

    // 状态查询
    func isReady() async -> Bool
    func getEngineInfo() async -> EngineInfo?
}

// MARK: - Engine Manager Implementation

actor EngineManager: EngineManagerProtocol {

    // MARK: - Properties

    private(set) var state: EngineState = .idle
    private(set) var configuration: EngineConfiguration

    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?

    private var protocolHandler: UCIProtocolHandler?
    private var responseContinuation: CheckedContinuation<UCIResponse, Error>?

    private var engineInfo: EngineInfo?
    private var isEngineReady: Bool = false

    // MARK: - Initialization

    init(configuration: EngineConfiguration = .pikafishDefault) {
        self.configuration = configuration
    }

    // MARK: - Lifecycle

    func initialize() async throws {
        guard state == .idle else {
            throw EngineError.alreadyRunning
        }

        await transition(to: .initializing)

        do {
            try await setupProcess()
            protocolHandler = UCIProtocolHandler()
            await protocolHandler?.addObserver(self)

            // 发送uci命令初始化
            try await sendUCI()

            // 等待uciok响应
            try await waitForResponse(timeout: 5.0) { response in
                if case .uciok = response {
                    return true
                }
                return false
            }

            // 设置默认选项
            for (name, value) in configuration.defaultOptions {
                try await setOption(name: name, value: value)
            }

            // 检查引擎就绪
            try await sendIsReady()
            try await waitForResponse(timeout: 5.0) { response in
                if case .readyok = response {
                    return true
                }
                return false
            }

            isEngineReady = true
            await transition(to: .ready)

        } catch {
            await transition(to: .error(error.localizedDescription))
            throw EngineError.processFailed(error)
        }
    }

    func shutdown() async {
        if let process = process, process.isRunning {
            do {
                try await sendCommand(.quit)
            } catch {
                // 忽略错误，强制终止
            }
            process.terminate()
        }

        process = nil
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
        protocolHandler = nil
        isEngineReady = false

        await transition(to: .idle)
    }

    func restart() async throws {
        await shutdown()
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        try await initialize()
    }

    // MARK: - UCI Commands

    func sendUCI() async throws {
        try await sendCommand(.uci)
    }

    func sendIsReady() async throws {
        try await sendCommand(.isready)
    }

    func setOption(name: String, value: String) async throws {
        try await sendCommand(.setoption(id: name, value: value))
    }

    func setPosition(fen: String? = nil, moves: [String] = []) async throws {
        try await sendCommand(.position(fen: fen, moves: moves))
    }

    func go(command: GoCommand) async throws {
        await transition(to: .searching)
        try await sendCommand(.go(command))
    }

    func stop() async throws {
        try await sendCommand(.stop)
        await transition(to: .ready)
    }

    func ponderHit() async throws {
        try await sendCommand(.ponderhit)
    }

    func newGame() async throws {
        try await sendCommand(.ucinewgame)
    }

    // MARK: - State Query

    func isReady() async -> Bool {
        return isEngineReady
    }

    func getEngineInfo() async -> EngineInfo? {
        return engineInfo
    }

    // MARK: - Private Methods

    private func setupProcess() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: configuration.executablePath)
        process.arguments = configuration.arguments

        if let workingDirectory = configuration.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // 设置输出处理
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !line.isEmpty else { return }

            Task { [weak self] in
                await self?.handleOutput(line)
            }
        }

        // 错误处理
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !line.isEmpty else { return }

            Task { [weak self] in
                await self?.handleError(line)
            }
        }

        try process.run()

        self.process = process
        self.inputPipe = inputPipe
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
    }

    private func sendCommand(_ command: UCICommand) async throws {
        guard let inputPipe = inputPipe else {
            throw EngineError.notInitialized
        }

        let commandString = await protocolHandler?.processCommand(command) ?? ""
        let data = (commandString + "\n").data(using: .utf8)!

        try await Task {
            inputPipe.fileHandleForWriting.write(data)
        }.value
    }

    private func handleOutput(_ line: String) async {
        await protocolHandler?.processResponse(line)
    }

    private func handleError(_ line: String) async {
        // 记录错误日志
    }

    private func transition(to newState: EngineState) {
        state = newState
    }

    private func waitForResponse(timeout: TimeInterval, predicate: (UCIResponse) -> Bool) async throws {
        // 实现超时等待逻辑
    }
}

// MARK: - UCIObserver Extension

extension EngineManager: UCIObserver {
    nonisolated func didReceive(response: UCIResponse) {
        Task { [weak self] in
            await self?.handleResponse(response)
        }
    }

    nonisolated func didEncounterError(_ error: UCIError) {
        // 处理错误
    }

    private func handleResponse(_ response: UCIResponse) async {
        switch response {
        case .id(let info):
            // 更新引擎信息
            var newInfo = engineInfo ?? EngineInfo(name: nil, author: nil, options: [:], availableVariants: [])
            if let name = info.name {
                newInfo = EngineInfo(name: name, author: newInfo.author, options: newInfo.options, availableVariants: newInfo.availableVariants)
            }
            if let author = info.author {
                newInfo = EngineInfo(name: newInfo.name, author: author, options: newInfo.options, availableVariants: newInfo.availableVariants)
            }
            engineInfo = newInfo

        case .uciok:
            // UCI初始化完成
            break

        case .readyok:
            isEngineReady = true

        case .bestmove(let move, let ponder):
            // 处理最佳走法
            await transition(to: .ready)
            // 通知游戏管理器

        case .info(let data):
            // 处理搜索信息
            // 转发给UI显示
            break

        case .option(let config):
            // 处理可配置选项
            break

        default:
            break
        }
    }
}
```

---

## 4. 引擎管理器设计

### 4.1 类图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              EngineManager                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│ - state: EngineState                                                          │
│ - configuration: EngineConfiguration                                        │
│ - process: Process?                                                           │
│ - protocolHandler: UCIProtocolHandler?                                      │
│ - engineInfo: EngineInfo?                                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ + initialize() async throws                                                 │
│ + shutdown() async                                                            │
│ + restart() async throws                                                      │
│ + setPosition(fen:moves:) async throws                                       │
│ + startSearch(command:) async throws                                         │
│ + stopSearch() async throws                                                  │
│ + setOption(name:value:) async throws                                        │
│ + isReady() async -> Bool                                                   │
│ + getEngineInfo() async -> EngineInfo?                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ uses
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           UCIProtocolHandler                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ + processCommand(_:) -> String                                               │
│ + processResponse(_:)                                                         │
│ + addObserver(_:)                                                             │
│ + removeObserver(_:)                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ implements
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              UCIObserver                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│ + didReceive(response:)                                                       │
│ + didEncounterError(_:)                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 接口定义

```swift
// MARK: - EngineManager Protocol

/// 引擎管理器协议
protocol EngineManagerProtocol: AnyObject {
    /// 当前引擎状态
    var state: EngineState { get }

    /// 引擎配置
    var configuration: EngineConfiguration { get }

    /// 初始化引擎
    func initialize() async throws

    /// 关闭引擎
    func shutdown() async

    /// 重启引擎
    func restart() async throws

    /// 设置局面
    func setPosition(fen: String?, moves: [String]) async throws

    /// 开始搜索
    func startSearch(command: GoCommand) async throws

    /// 停止搜索
    func stopSearch() async throws

    /// 设置引擎选项
    func setOption(name: String, value: String) async throws

    /// 检查引擎是否就绪
    func isReady() async -> Bool

    /// 获取引擎信息
    func getEngineInfo() async -> EngineInfo?
}

// MARK: - Search Delegate

/// 搜索结果代理
protocol EngineSearchDelegate: AnyObject {
    /// 收到最佳走法
    func engineDidFindBestMove(_ move: String, ponder: String?)

    /// 收到搜索信息
    func engineDidUpdateInfo(_ info: InfoData)

    /// 搜索完成
    func engineDidFinishSearch()

    /// 搜索出错
    func engineDidEncounterError(_ error: Error)
}

// MARK: - Multi-Engine Support

/// 多引擎管理器
protocol MultiEngineManagerProtocol {
    var activeEngine: EngineManagerProtocol? { get }
    var availableEngines: [EngineConfiguration] { get }

    func registerEngine(_ config: EngineConfiguration)
    func unregisterEngine(id: UUID)
    func switchToEngine(id: UUID) async throws
    func startAllEngines() async -> [UUID: Result<Void, Error>]
    func stopAllEngines() async
}
```

---

## 5. UI 层与数据层的数据接口定义

### 5.1 数据流架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Presentation Layer                                │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐          │
│  │   BoardView      │  │  ControlBarView  │  │  MoveListView    │          │
│  │    (SwiftUI)     │  │    (SwiftUI)     │  │    (SwiftUI)     │          │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘          │
│           │                   │                    │                      │
│           └───────────────────┴────────────────────┘                      │
│                               │                                           │
│                   ┌───────────┴───────────┐                               │
│                   │   ViewModel Layer    │                               │
│                   │  (State Management)  │                               │
│                   └───────────┬───────────┘                               │
└───────────────────────────────┼───────────────────────────────────────────┘
                                │
┌───────────────────────────────┼───────────────────────────────────────────┐
│                      Domain Layer (Business Logic)                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐          │
│  │   GameManager    │  │   Board Model    │  │   Rule Engine    │          │
│  │  (游戏状态管理)   │  │   (棋盘数据)     │  │   (规则验证)     │          │
│  └────────┬─────────┘  └──────────────────┘  └──────────────────┘          │
│           │                                                                │
│           │  ┌──────────────────┐  ┌──────────────────┐                     │
│           └──┤   Move Model   │  │   FEN Parser   │                     │
│              │   (走棋数据)    │  │  (FEN解析器)   │                     │
│              └──────────────────┘  └──────────────────┘                     │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
┌───────────────────────────────┼───────────────────────────────────────────┐
│                    Infrastructure Layer                                    │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐          │
│  │ EngineManager  │  │  UCIProtocol   │  │  EngineProcess │          │
│  │  (引擎管理器)   │  │   (UCI协议)    │  │  (进程管理)    │          │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 数据接口定义

```swift
import Foundation
import Combine

// MARK: - Board View Model

/// 棋盘视图模型协议
protocol BoardViewModelProtocol: ObservableObject {
    var board: Board { get }
    var selectedPosition: Position? { get set }
    var validMoves: [Move] { get }
    var lastMove: Move? { get }
    var isFlipped: Bool { get set }
    var gameResult: GameResult? { get }

    func selectPiece(at position: Position)
    func movePiece(from: Position, to: Position) async throws
    func undoMove() async throws
    func flipBoard()
}

/// 棋盘视图模型实现
@MainActor
class BoardViewModel: ObservableObject, BoardViewModelProtocol {
    @Published private(set) var board: Board
    @Published var selectedPosition: Position?
    @Published private(set) var validMoves: [Move] = []
    @Published private(set) var lastMove: Move?
    @Published var isFlipped: Bool = false
    @Published private(set) var gameResult: GameResult?

    private let gameManager: GameManagerProtocol
    private let ruleEngine: RuleEngineProtocol
    private var cancellables = Set<AnyCancellable>()

    init(gameManager: GameManagerProtocol,
         ruleEngine: RuleEngineProtocol,
         initialBoard: Board = Board.initial()) {
        self.gameManager = gameManager
        self.ruleEngine = ruleEngine
        self.board = initialBoard

        setupBindings()
    }

    func selectPiece(at position: Position) {
        guard board.isValidPosition(position) else { return }

        if let piece = board.piece(at: position),
           piece.player == board.currentPlayer {
            // 选中己方棋子
            selectedPosition = position
            validMoves = ruleEngine.generateValidMoves(for: piece, at: position, on: board)
        } else if let selected = selectedPosition,
                  validMoves.contains(where: { $0.to == position }) {
            // 执行走棋
            Task {
                try? await movePiece(from: selected, to: position)
            }
        } else {
            // 取消选择
            selectedPosition = nil
            validMoves = []
        }
    }

    func movePiece(from: Position, to: Position) async throws {
        let move = try ruleEngine.createMove(from: from, to: to, on: board)
        try await gameManager.executeMove(move)

        lastMove = move
        selectedPosition = nil
        validMoves = []
    }

    func undoMove() async throws {
        try await gameManager.undoLastMove()
        lastMove = gameManager.lastMove
    }

    func flipBoard() {
        isFlipped.toggle()
    }

    private func setupBindings() {
        gameManager.boardPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] board in
                self?.board = board
            }
            .store(in: &cancellables)

        gameManager.gameResultPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.gameResult = result
            }
            .store(in: &cancellables)
    }
}

// MARK: - Engine View Model

/// 引擎视图模型
@MainActor
class EngineViewModel: ObservableObject {
    @Published var engineState: EngineState = .idle
    @Published var engineInfo: EngineInfo?
    @Published var searchInfo: InfoData?
    @Published var isThinking: Bool = false
    @Published var engineColor: Player = .black  // 引擎执黑

    private let engineManager: EngineManagerProtocol

    init(engineManager: EngineManagerProtocol) {
        self.engineManager = engineManager
    }

    func initializeEngine() async {
        do {
            try await engineManager.initialize()
            engineState = .ready
            engineInfo = await engineManager.getEngineInfo()
        } catch {
            engineState = .error(error.localizedDescription)
        }
    }

    func startThinking(fen: String, timeConfig: TimeConfiguration?) async {
        isThinking = true

        do {
            try await engineManager.setPosition(fen: fen, moves: [])

            let goCommand: GoCommand
            if let timeConfig = timeConfig {
                goCommand = .wtime(timeConfig.whiteTime)  // 简化示例
            } else {
                goCommand = .infinite
            }

            try await engineManager.go(command: goCommand)
        } catch {
            isThinking = false
        }
    }

    func stopThinking() async {
        do {
            try await engineManager.stop()
            isThinking = false
        } catch {
            // 处理错误
        }
    }
}

// MARK: - Time Configuration

struct TimeConfiguration {
    let whiteTime: Int  // 毫秒
    let blackTime: Int
    let whiteIncrement: Int
    let blackIncrement: Int
    let movesToGo: Int?
}
```

---

## 6. 核心数据模型

### 6.1 棋盘与棋子模型

```swift
import Foundation

// MARK: - Player

/// 玩家 (红方先行)
enum Player: Int, Codable, CaseIterable, Sendable {
    case red = 0    // 红方
    case black = 1  // 黑方

    var displayName: String {
        switch self {
        case .red: return "红方"
        case .black: return "黑方"
        }
    }

    var isRed: Bool { self == .red }
    var isBlack: Bool { self == .black }

    var opponent: Player {
        self == .red ? .black : .red
    }
}

// MARK: - PieceType

/// 棋子类型
enum PieceType: Int, Codable, CaseIterable, Sendable {
    case king = 0       // 将/帅
    case advisor = 1    // 士/仕
    case elephant = 2   // 象/相
    case horse = 3      // 马/傌
    case rook = 4       // 车/俥
    case cannon = 5     // 炮/砲
    case pawn = 6       // 卒/兵

    var displayName: String {
        switch self {
        case .king: return "将"
        case .advisor: return "士"
        case .elephant: return "象"
        case .horse: return "马"
        case .rook: return "车"
        case .cannon: return "炮"
        case .pawn: return "卒"
        }
    }

    var englishName: String {
        switch self {
        case .king: return "King"
        case .advisor: return "Advisor"
        case .elephant: return "Elephant"
        case .horse: return "Horse"
        case .rook: return "Rook"
        case .cannon: return "Cannon"
        case .pawn: return "Pawn"
        }
    }
}

// MARK: - Piece

/// 棋子
struct Piece: Codable, Equatable, Hashable, Sendable, Identifiable {
    let id: UUID
    let type: PieceType
    let player: Player

    init(id: UUID = UUID(), type: PieceType, player: Player) {
        self.id = id
        self.type = type
        self.player = player
    }

    /// 棋子显示字符 (简化的中文表示)
    var character: String {
        let redChars = ["帅", "仕", "相", "傌", "俥", "炮", "兵"]
        let blackChars = ["将", "士", "象", "马", "车", "砲", "卒"]

        let chars = player == .red ? redChars : blackChars
        return chars[type.rawValue]
    }

    var isEmpty: Bool { false }
}

// MARK: - Position

/// 棋盘位置 (0-8列, 0-9行)
/// 红方在下方(0-4行)，黑方在上方(5-9行)
struct Position: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    let x: Int  // 列 (0-8)
    let y: Int  // 行 (0-9)

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    static func from(string: String) -> Position? {
        // 解析类似 "a1" 或 "0,0" 的字符串
        if string.count == 2,
           let file = string.first?.asciiValue,
           let rank = string.last?.wholeNumberValue {
            let x = Int(file) - Int(Character("a").asciiValue!)
            let y = rank - 1
            return Position(x: x, y: y)
        }
        return nil
    }

    var description: String {
        let file = String(UnicodeScalar(UInt8(x) + UInt8(Character("a").asciiValue!)))
        let rank = y + 1
        return "\(file)\(rank)"
    }

    func isValid() -> Bool {
        x >= 0 && x <= 8 && y >= 0 && y <= 9
    }

    func distance(to other: Position) -> (dx: Int, dy: Int) {
        (other.x - x, other.y - y)
    }
}

// MARK: - Move

/// 走棋
struct Move: Codable, Equatable, Hashable, Sendable, Identifiable, CustomStringConvertible {
    let id: UUID
    let from: Position
    let to: Position
    let piece: Piece
    let capturedPiece: Piece?
    let promotion: PieceType?        // 升变（中国象棋中一般没有）
    let isCheck: Bool
    let isCheckmate: Bool
    let notation: String?            // 代数记谱法
    let timestamp: Date

    init(id: UUID = UUID(),
         from: Position,
         to: Position,
         piece: Piece,
         capturedPiece: Piece? = nil,
         promotion: PieceType? = nil,
         isCheck: Bool = false,
         isCheckmate: Bool = false,
         notation: String? = nil,
         timestamp: Date = Date()) {
        self.id = id
        self.from = from
        self.to = to
        self.piece = piece
        self.capturedPiece = capturedPiece
        self.promotion = promotion
        self.isCheck = isCheck
        self.isCheckmate = isCheckmate
        self.notation = notation
        self.timestamp = timestamp
    }

    var description: String {
        let capture = capturedPiece != nil ? "x" : "-"
        return "\(piece.character)\(from)\(capture)\(to)"
    }

    var uciNotation: String {
        // UCI格式: e2e4, e1g1 (王车易位)
        "\(from.x)\(from.y)\(to.x)\(to.y)"
    }
}

// MARK: - Board

/// 棋盘
struct Board: Codable, Equatable, Sendable, CustomStringConvertible {
    static let width = 9
    static let height = 10

    private var pieces: [[Piece?]]  // 10行 x 9列
    private(set) var currentPlayer: Player
    private(set) var moveCount: Int
    private(set) var halfMoveClock: Int  // 用于50步规则

    // MARK: - Initialization

    init(pieces: [[Piece?]], currentPlayer: Player = .red, moveCount: Int = 0, halfMoveClock: Int = 0) {
        self.pieces = pieces
        self.currentPlayer = currentPlayer
        self.moveCount = moveCount
        self.halfMoveClock = halfMoveClock
    }

    static func empty() -> Board {
        let emptyPieces: [[Piece?]] = Array(repeating: Array(repeating: nil, count: width), count: height)
        return Board(pieces: emptyPieces)
    }

    static func initial() -> Board {
        var board = empty()

        // 红方 (下方, y=0-4)
        let redPieces: [(PieceType, Int, Int)] = [
            (.rook, 0, 0), (.rook, 8, 0),
            (.horse, 1, 0), (.horse, 7, 0),
            (.elephant, 2, 0), (.elephant, 6, 0),
            (.advisor, 3, 0), (.advisor, 5, 0),
            (.king, 4, 0),
            (.cannon, 1, 2), (.cannon, 7, 2),
            (.pawn, 0, 3), (.pawn, 2, 3), (.pawn, 4, 3), (.pawn, 6, 3), (.pawn, 8, 3)
        ]

        // 黑方 (上方, y=5-9)
        let blackPieces: [(PieceType, Int, Int)] = [
            (.rook, 0, 9), (.rook, 8, 9),
            (.horse, 1, 9), (.horse, 7, 9),
            (.elephant, 2, 9), (.elephant, 6, 9),
            (.advisor, 3, 9), (.advisor, 5, 9),
            (.king, 4, 9),
            (.cannon, 1, 7), (.cannon, 7, 7),
            (.pawn, 0, 6), (.pawn, 2, 6), (.pawn, 4, 6), (.pawn, 6, 6), (.pawn, 8, 6)
        ]

        for (type, x, y) in redPieces {
            board.pieces[y][x] = Piece(type: type, player: .red)
        }

        for (type, x, y) in blackPieces {
            board.pieces[y][x] = Piece(type: type, player: .black)
        }

        return board
    }

    // MARK: - Accessors

    func piece(at position: Position) -> Piece? {
        guard isValidPosition(position) else { return nil }
        return pieces[position.y][position.x]
    }

    func piece(atX x: Int, y: Int) -> Piece? {
        piece(at: Position(x: x, y: y))
    }

    func isValidPosition(_ position: Position) -> Bool {
        position.x >= 0 && position.x < Board.width &&
        position.y >= 0 && position.y < Board.height
    }

    // MARK: - Mutations

    mutating func placePiece(_ piece: Piece?, at position: Position) {
        guard isValidPosition(position) else { return }
        pieces[position.y][position.x] = piece
    }

    mutating func movePiece(from: Position, to: Position) {
        guard isValidPosition(from), isValidPosition(to) else { return }
        pieces[to.y][to.x] = pieces[from.y][from.x]
        pieces[from.y][from.x] = nil
    }

    mutating func switchTurn() {
        currentPlayer = currentPlayer.opponent
        moveCount += 1
    }

    // MARK: - FEN

    func toFEN() -> String {
        var fen = ""

        // 棋子位置 (从第9行到第0行)
        for row in (0..<Board.height).reversed() {
            var emptyCount = 0
            for col in 0..<Board.width {
                if let piece = pieces[row][col] {
                    if emptyCount > 0 {
                        fen += String(emptyCount)
                        emptyCount = 0
                    }
                    fen += piece.fenCharacter
                } else {
                    emptyCount += 1
                }
            }
            if emptyCount > 0 {
                fen += String(emptyCount)
            }
            if row > 0 {
                fen += "/"
            }
        }

        // 当前行棋方
        fen += " \(currentPlayer == .red ? "w" : "b")"

        // 中国象棋没有王车易位和吃过路兵，用 - 表示
        fen += " - -"

        // 半回合计数 (用于50步规则)
        fen += " \(halfMoveClock)"

        // 回合数
        fen += " \(moveCount / 2 + 1)"

        return fen
    }

    static func fromFEN(_ fen: String) -> Board? {
        // 解析FEN字符串创建棋盘
        // 实现细节省略
        nil
    }

    // MARK: - CustomStringConvertible

    var description: String {
        var result = "  a b c d e f g h i\n"
        for row in (0..<Board.height).reversed() {
            result += "\(row) "
            for col in 0..<Board.width {
                if let piece = pieces[row][col] {
                    result += piece.character
                } else {
                    result += "."
                }
                result += " "
            }
            result += "\(row)\n"
        }
        result += "  a b c d e f g h i"
        return result
    }
}

// MARK: - Piece Extension for FEN

extension Piece {
    /// FEN表示字符
    var fenCharacter: String {
        let char: String
        switch type {
        case .king: char = "k"
        case .advisor: char = "a"
        case .elephant: char = "b"
        case .horse: char = "n"
        case .rook: char = "r"
        case .cannon: char = "c"
        case .pawn: char = "p"
        }
        return player == .red ? char.uppercased() : char
    }
}

// MARK: - Game Result

enum GameResult: Equatable {
    case win(Player, WinReason)
    case draw(DrawReason)
    case ongoing
}

enum WinReason: String {
    case checkmate = "将杀"
    case timeout = "超时"
    case resignation = "认输"
    case illegalMove = "违规"
}

enum DrawReason: String {
    case stalemate = "逼和"
    case fiftyMoveRule = "50步规则"
    case threefoldRepetition = "三次重复"
    case insufficientMaterial = "子力不足"
    case agreement = "协议和棋"
}
```

### 6.2 游戏状态管理

```swift
import Foundation
import Combine

// MARK: - Game Manager Protocol

protocol GameManagerProtocol: AnyObject {
    var currentBoard: Board { get }
    var moveHistory: [Move] { get }
    var currentTurn: Player { get }
    var gameResult: GameResult { get }

    var boardPublisher: AnyPublisher<Board, Never> { get }
    var movePublisher: AnyPublisher<Move, Never> { get }
    var gameResultPublisher: AnyPublisher<GameResult, Never> { get }

    func executeMove(_ move: Move) async throws
    func undoLastMove() async throws
    func redoMove() async throws
    func resetGame() async
    func loadGame(fromFEN fen: String) async throws
    func exportToFEN() -> String
}

// MARK: - Game Manager Implementation

@MainActor
class GameManager: GameManagerProtocol, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var currentBoard: Board
    @Published private(set) var moveHistory: [Move] = []
    @Published private(set) var redoStack: [Move] = []
    @Published private(set) var currentTurn: Player = .red
    @Published private(set) var gameResult: GameResult = .ongoing

    // MARK: - Publishers

    private let boardSubject = PassthroughSubject<Board, Never>()
    private let moveSubject = PassthroughSubject<Move, Never>()
    private let gameResultSubject = PassthroughSubject<GameResult, Never>()

    var boardPublisher: AnyPublisher<Board, Never> {
        boardSubject.eraseToAnyPublisher()
    }

    var movePublisher: AnyPublisher<Move, Never> {
        moveSubject.eraseToAnyPublisher()
    }

    var gameResultPublisher: AnyPublisher<GameResult, Never> {
        gameResultSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let ruleEngine: RuleEngineProtocol

    // MARK: - Initialization

    init(ruleEngine: RuleEngineProtocol, initialBoard: Board = Board.initial()) {
        self.ruleEngine = ruleEngine
        self.currentBoard = initialBoard
        self.currentTurn = initialBoard.currentPlayer
    }

    // MARK: - Game Operations

    func executeMove(_ move: Move) async throws {
        guard gameResult == .ongoing else {
            throw GameError.gameAlreadyEnded
        }

        guard move.piece.player == currentTurn else {
            throw GameError.wrongTurn
        }

        // 验证走法合法性
        guard ruleEngine.isValidMove(move, on: currentBoard) else {
            throw GameError.invalidMove
        }

        // 执行走法
        var newBoard = currentBoard
        newBoard.movePiece(from: move.from, to: move.to)

        // 检查将军和将杀
        let opponent = currentTurn.opponent
        let isCheck = ruleEngine.isKingInCheck(player: opponent, on: newBoard)
        let isCheckmate = isCheck && ruleEngine.isCheckmate(player: opponent, on: newBoard)

        // 创建完整的走法记录
        let completeMove = Move(
            id: move.id,
            from: move.from,
            to: move.to,
            piece: move.piece,
            capturedPiece: currentBoard.piece(at: move.to),
            promotion: nil,
            isCheck: isCheck,
            isCheckmate: isCheckmate,
            notation: nil,  // 后续计算
            timestamp: Date()
        )

        // 更新状态
        newBoard.switchTurn()
        currentBoard = newBoard
        currentTurn = newBoard.currentPlayer
        moveHistory.append(completeMove)
        redoStack.removeAll()

        // 更新游戏结果
        if isCheckmate {
            gameResult = .win(currentTurn.opponent, .checkmate)
        } else if ruleEngine.isStalemate(player: currentTurn, on: currentBoard) {
            gameResult = .draw(.stalemate)
        }

        // 发送事件
        boardSubject.send(currentBoard)
        moveSubject.send(completeMove)
        gameResultSubject.send(gameResult)
    }

    func undoLastMove() async throws {
        guard let lastMove = moveHistory.last else {
            throw GameError.noMovesToUndo
        }

        // 回退棋盘状态
        var newBoard = currentBoard
        newBoard.placePiece(lastMove.piece, at: lastMove.from)
        newBoard.placePiece(lastMove.capturedPiece, at: lastMove.to)
        newBoard.switchTurn()

        currentBoard = newBoard
        currentTurn = newBoard.currentPlayer

        moveHistory.removeLast()
        redoStack.append(lastMove)

        // 重置游戏结果
        gameResult = .ongoing

        boardSubject.send(currentBoard)
        gameResultSubject.send(gameResult)
    }

    func redoMove() async throws {
        guard let move = redoStack.last else {
            throw GameError.noMovesToRedo
        }

        // 重新执行走法
        // 这里需要重新验证走法合法性
        // 简化实现，实际应该从历史记录中完整恢复

        redoStack.removeLast()
    }

    func resetGame() async {
        currentBoard = Board.initial()
        currentTurn = .red
        moveHistory.removeAll()
        redoStack.removeAll()
        gameResult = .ongoing

        boardSubject.send(currentBoard)
        gameResultSubject.send(gameResult)
    }

    func loadGame(fromFEN fen: String) async throws {
        guard let board = Board.fromFEN(fen) else {
            throw GameError.invalidFEN
        }

        currentBoard = board
        currentTurn = board.currentPlayer
        moveHistory.removeAll()
        redoStack.removeAll()
        gameResult = .ongoing

        boardSubject.send(currentBoard)
        gameResultSubject.send(gameResult)
    }

    func exportToFEN() -> String {
        currentBoard.toFEN()
    }
}

// MARK: - Game Error

enum GameError: Error {
    case gameAlreadyEnded
    case wrongTurn
    case invalidMove
    case noMovesToUndo
    case noMovesToRedo
    case invalidFEN
}
```

---

## 7. 包依赖清单

### 7.1 Package.swift

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ChineseChess",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ChineseChess",
            targets: ["ChineseChess"]
        ),
        .library(
            name: "ChineseChessKit",
            targets: ["ChineseChessKit"]
        )
    ],
    dependencies: [
        // 日志框架 (可选，可使用OSLog)
        // .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),

        // 测试依赖
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.3.0"),
    ],
    targets: [
        // 主应用目标
        .executableTarget(
            name: "ChineseChess",
            dependencies: [
                "ChineseChessKit",
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // 核心库目标
        .target(
            name: "ChineseChessKit",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // 测试目标
        .testTarget(
            name: "ChineseChessTests",
            dependencies: [
                "ChineseChessKit",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
```

### 7.2 Xcode Project 依赖 (SPM)

对于使用 Xcode 的开发者，可通过以下 SPM 依赖:

| 依赖 | 用途 | 版本 |
|------|------|------|
| SwiftUI | UI框架 | 系统内置 |
| Combine | 响应式编程 | 系统内置 |
| Foundation | 基础功能 | 系统内置 |
| OSLog | 日志系统 | 系统内置 |

**开发配置:**

- **macOS**: 14.0+
- **Swift**: 5.9+
- **Xcode**: 15.0+

---

## 8. 架构设计总结

### 8.1 关键设计决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| UI框架 | SwiftUI + AppKit | 快速开发+精细控制 |
| 架构模式 | MVVM + Clean Architecture | 关注点分离，可测试性 |
| 并发模型 | Swift Concurrency (async/await) | 现代、安全、易读 |
| 数据流 | Combine + 单向数据流 | 响应式、可预测 |
| 引擎通信 | UCI Protocol | 行业标准，通用性强 |
| 数据持久化 | Codable + JSON | 简单、通用 |

### 8.2 模块依赖关系

```
Presentation (SwiftUI)
    ↓ depends on
Presentation-AppKit (NSView)
    ↓ depends on
Domain (Models, Rules, GameManager)
    ↓ depends on
Infrastructure (UCI, EngineManager)
```

### 8.3 下一步工作

1. **Task #2**: 实现 UCI 协议解析器 (`UCIParser.swift`)
2. **Task #4**: 实现棋盘数据模型 (`Board.swift`, `Piece.swift`)
3. **Task #7**: 实现棋盘 UI (`BoardView.swift`)
4. **Task #8**: 实现引擎通信层 (`EngineManager.swift`)

---

*文档版本: 1.0*
*创建日期: 2026-02-09*
*作者: Swift 架构师*
