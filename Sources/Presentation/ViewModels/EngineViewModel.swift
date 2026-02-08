import Foundation
import Combine

/// 引擎视图模型 - 管理引擎状态和搜索信息
@MainActor
@Observable
final class EngineViewModel {
    // MARK: - 引擎状态
    var engineState: EngineState = .idle
    var engineInfo: EngineInfo?
    var searchInfo: InfoData?
    var isThinking: Bool = false
    var engineColor: Player = .black  // 引擎执黑
    var engineName: String = "未连接"

    // MARK: - 搜索统计
    var currentDepth: Int = 0
    var currentNPS: Int = 0
    var currentScore: Int = 0
    var principalVariation: [String] = []
    var currentMoveNumber: Int = 0
    var hashFull: Int = 0

    // MARK: - 配置
    var analysisMode: Bool = false
    var multiPV: Int = 1
    var searchTime: Int = 5000  // 默认5秒
    var searchDepth: Int = 0  // 0表示不限制

    // MARK: - 历史记录
    var searchHistory: [InfoData] = []
    var bestMoves: [String] = []

    // MARK: - 回调
    var onBestMove: ((String) -> Void)?
    var onSearchUpdate: ((InfoData) -> Void)?

    init() {}

    // MARK: - 引擎连接
    func connectEngine(name: String) {
        engineState = .initializing
        engineName = name
        // 实际连接逻辑由引擎管理器处理
    }

    func disconnectEngine() {
        engineState = .idle
        engineName = "未连接"
        searchInfo = nil
        isThinking = false
    }

    func engineReady() {
        engineState = .ready
    }

    // MARK: - 搜索控制
    func startThinking(fen: String) {
        guard engineState == .ready else { return }

        isThinking = true
        engineState = .searching
        searchHistory.removeAll()

        // 实际搜索逻辑由引擎管理器处理
    }

    func stopThinking() {
        isThinking = false
        engineState = .ready
    }

    func ponderHit() {
        // 对手走了预期着法，继续长考
    }

    // MARK: - 搜索信息更新
    func updateSearchInfo(_ info: InfoData) {
        searchInfo = info
        searchHistory.append(info)

        // 更新显示值
        if let depth = info.depth {
            currentDepth = depth
        }
        if let nps = info.nps {
            currentNPS = nps
        }
        if let score = info.score {
            switch score {
            case .cp(let value):
                currentScore = value
            case .mate(let moves):
                currentScore = moves > 0 ? 10000 - moves : -10000 - moves
            default:
                break
            }
        }
        if let pv = info.pv {
            principalVariation = pv
        }
        if let hash = info.hashfull {
            hashFull = hash
        }

        onSearchUpdate?(info)
    }

    func receiveBestMove(_ move: String) {
        bestMoves.append(move)
        isThinking = false
        engineState = .ready
        onBestMove?(move)
    }

    // MARK: - 分析模式
    func toggleAnalysisMode() {
        analysisMode.toggle()
        if analysisMode && engineState == .ready {
            // 自动开始分析当前局面
        } else if !analysisMode && isThinking {
            stopThinking()
        }
    }

    // MARK: - 多PV设置
    func setMultiPV(_ count: Int) {
        multiPV = max(1, min(count, 5))
    }

    // MARK: - 搜索时间设置
    func setSearchTime(_ milliseconds: Int) {
        searchTime = max(1000, milliseconds)
    }

    func setSearchDepth(_ depth: Int) {
        searchDepth = max(0, depth)
    }

    // MARK: - 清除历史
    func clearHistory() {
        searchHistory.removeAll()
        bestMoves.removeAll()
        currentDepth = 0
        currentNPS = 0
        currentScore = 0
        principalVariation.removeAll()
    }
}
