import Foundation
import Combine

// MARK: - GameBrowser

/// 棋谱浏览器
/// 提供前进、后退、跳转、变着切换等浏览功能
@MainActor
public final class GameBrowser: ObservableObject {

    // MARK: - Properties

    /// 关联的对局记录器
    @Published public private(set) var recorder: GameRecorder

    /// 当前位置描述
    @Published public private(set) var currentPosition: PositionInfo

    /// 浏览历史（用于快速跳转）
    private var browseHistory: [MoveNode] = []
    private var browseHistoryIndex = -1

    /// 最大浏览历史长度
    private let maxBrowseHistorySize = 50

    /// 当前变着路径（用于显示变着树）
    @Published public private(set) var currentPath: [MoveNode] = []

    /// 可用的变着列表
    public var availableVariations: [MoveNode] {
        currentNode.parent?.variations.filter { $0.id != currentNode.id } ?? []
    }

    /// 当前节点
    public var currentNode: MoveNode {
        recorder.record.currentNode
    }

    /// 当前棋盘
    public var currentBoard: Board {
        recorder.currentBoard
    }

    /// 是否在开始位置
    public var isAtStart: Bool {
        currentNode.parent == nil || currentNode.isRoot
    }

    /// 是否在结束位置（主变线末尾）
    public var isAtEnd: Bool {
        currentNode.mainVariation == nil
    }

    /// 是否有变着
    public var hasVariations: Bool {
        !currentNode.parent?.variations.isEmpty ?? false
    }

    /// 当前变着信息
    public var currentVariationInfo: VariationInfo? {
        guard let parent = currentNode.parent else { return nil }
        let allVariations = parent.allVariations
        guard let index = allVariations.firstIndex(where: { $0.id == currentNode.id }) else {
            return nil
        }

        return VariationInfo(
            currentIndex: index,
            totalVariations: allVariations.count,
            isMainLine: index == 0,
            variationNames: allVariations.map { node in
                node.move?.chineseNotation ?? "?"
            }
        )
    }

    // MARK: - Initialization

    public init(recorder: GameRecorder) {
        self.recorder = recorder
        self.currentPosition = PositionInfo.empty()

        self.setupBindings()
        self.updatePositionInfo()
        self.updateCurrentPath()
    }

    private func setupBindings() {
        recorder.objectWillChange
            .sink { [weak self] _ in
                self?.updatePositionInfo()
                self?.updateCurrentPath()
            }
            .store(in: &Set<AnyCancellable>())
    }

    // MARK: - Navigation

    /// 前进（走下一步）
    @discardableResult
    public func forward() -> Bool {
        addToBrowseHistory()

        let success = recorder.goForward()
        if success {
            updatePositionInfo()
            updateCurrentPath()
        }
        return success
    }

    /// 后退（撤销一步）
    @discardableResult
    public func backward() -> Bool {
        addToBrowseHistory()

        let success = recorder.goBackward()
        if success {
            updatePositionInfo()
            updateCurrentPath()
        }
        return success
    }

    /// 跳到开始
    public func goToStart() {
        addToBrowseHistory()

        recorder.goToStart()
        updatePositionInfo()
        updateCurrentPath()
    }

    /// 跳到结束（主变线末尾）
    public func goToEnd() {
        addToBrowseHistory()

        recorder.goToEnd()
        updatePositionInfo()
        updateCurrentPath()
    }

    /// 跳到指定步数
    @discardableResult
    public func goToMove(_ moveNumber: Int) -> Bool {
        addToBrowseHistory()

        let success = record.goToMove(moveNumber)
        if success {
            updatePositionInfo()
            updateCurrentPath()
        }
        return success
    }

    /// 跳转到指定节点
    public func goToNode(_ node: MoveNode) {
        addToBrowseHistory()

        record.goToNode(node)
        updatePositionInfo()
        updateCurrentPath()
    }

    /// 切换到变着
    @discardableResult
    public func switchToVariation(_ variation: MoveNode) -> Bool {
        guard let parent = variation.parent,
              parent.id == currentNode.parent?.id else {
            return false
        }

        addToBrowseHistory()
        record.currentNode = variation
        updatePositionInfo()
        updateCurrentPath()
        return true
    }

    /// 切换到下一个变着
    @discardableResult
    public func nextVariation() -> Bool {
        guard let parent = currentNode.parent else { return false }

        let allVariations = parent.allVariations
        guard let currentIndex = allVariations.firstIndex(where: { $0.id == currentNode.id }) else {
            return false
        }

        let nextIndex = (currentIndex + 1) % allVariations.count
        return switchToVariation(allVariations[nextIndex])
    }

    /// 切换到上一个变着
    @discardableResult
    public func previousVariation() -> Bool {
        guard let parent = currentNode.parent else { return false }

        let allVariations = parent.allVariations
        guard let currentIndex = allVariations.firstIndex(where: { $0.id == currentNode.id }) else {
            return false
        }

        let previousIndex = (currentIndex - 1 + allVariations.count) % allVariations.count
        return switchToVariation(allVariations[previousIndex])
    }

    /// 切换回主变线
    @discardableResult
    public func returnToMainLine() -> Bool {
        guard let mainVariation = currentNode.parent?.mainVariation,
              mainVariation.id != currentNode.id else {
            return false
        }

        return switchToVariation(mainVariation)
    }

    // MARK: - Browse History

    /// 添加到浏览历史
    private func addToBrowseHistory() {
        // 移除当前位置之后的历史
        if browseHistoryIndex < browseHistory.count - 1 {
            browseHistory.removeSubrange((browseHistoryIndex + 1)..<browseHistory.endIndex)
        }

        browseHistory.append(currentNode)
        browseHistoryIndex = browseHistory.count - 1

        // 限制历史长度
        if browseHistory.count > maxBrowseHistorySize {
            browseHistory.removeFirst()
            browseHistoryIndex -= 1
        }
    }

    /// 浏览历史中后退
    @discardableResult
    public func browseHistoryBack() -> Bool {
        guard browseHistoryIndex > 0 else { return false }

        browseHistoryIndex -= 1
        let node = browseHistory[browseHistoryIndex]
        goToNode(node)
        return true
    }

    /// 浏览历史中前进
    @discardableResult
    public func browseHistoryForward() -> Bool {
        guard browseHistoryIndex < browseHistory.count - 1 else { return false }

        browseHistoryIndex += 1
        let node = browseHistory[browseHistoryIndex]
        goToNode(node)
        return true
    }

    /// 清除浏览历史
    public func clearBrowseHistory() {
        browseHistory.removeAll()
        browseHistoryIndex = -1
    }

    // MARK: - Private Methods

    /// 更新位置信息
    private func updatePositionInfo() {
        let info = PositionInfo(
            moveNumber: record.currentMoveNumber,
            totalMoves: record.totalMoves,
            currentMove: currentNode.move,
            isAtStart: isAtStart,
            isAtEnd: isAtEnd,
            hasVariations: hasVariations,
            variationInfo: currentVariationInfo,
            fen: generateCurrentFEN()
        )
        currentPosition = info
    }

    /// 更新当前路径
    private func updateCurrentPath() {
        currentPath = currentNode.pathFromRoot
    }

    /// 生成当前 FEN（简化实现）
    private func generateCurrentFEN() -> String {
        return currentBoard.toFEN()
    }

    /// 内部访问器
    private var record: GameRecord {
        recorder.record
    }
}

// MARK: - PositionInfo

/// 位置信息
public struct PositionInfo: Equatable {
    public let moveNumber: Int
    public let totalMoves: Int
    public let currentMove: Move?
    public let isAtStart: Bool
    public let isAtEnd: Bool
    public let hasVariations: Bool
    public let variationInfo: VariationInfo?
    public let fen: String

    public static func empty() -> PositionInfo {
        PositionInfo(
            moveNumber: 0,
            totalMoves: 0,
            currentMove: nil,
            isAtStart: true,
            isAtEnd: true,
            hasVariations: false,
            variationInfo: nil,
            fen: ""
        )
    }
}

// MARK: - VariationInfo

/// 变着信息
public struct VariationInfo: Equatable {
    public let currentIndex: Int
    public let totalVariations: Int
    public let isMainLine: Bool
    public let variationNames: [String]

    public var displayName: String {
        if isMainLine {
            return "主变线"
        } else {
            return "变着 \(currentIndex)/\(totalVariations - 1)"
        }
    }
}