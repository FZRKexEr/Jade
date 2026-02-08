import Foundation

// MARK: - Notation Examples

/// 棋谱管理功能使用示例
public struct NotationExamples {

    // MARK: - Example 1: Creating a New Game

    /// 创建新对局示例
    public static func createNewGame() {
        print("=== 示例 1: 创建新对局 ===")

        // 创建对局头信息
        let header = GameHeader(
            event: "网络对弈",
            site: "中国象棋平台",
            date: GameHeader.currentDateString(),
            round: "1",
            red: "张三",
            black: "李四",
            result: .ongoing
        )

        // 创建对局记录
        let record = GameRecord(header: header)

        print("创建对局: \(header.red) vs \(header.black)")
        print("赛事: \(header.event)")
        print("日期: \(header.date)")
        print()
    }

    // MARK: - Example 2: Recording Moves

    /// 记录走棋示例
    public static func recordingMoves() {
        print("=== 示例 2: 记录走棋 ===")

        // 创建记录器
        let recorder = GameRecorder()

        // 模拟走棋记录
        let moves = [
            (from: Position(x: 1, y: 2), to: Position(x: 4, y: 2), piece: Piece(type: .cannon, player: .red)),
            (from: Position(x: 7, y: 9), to: Position(x: 4, y: 9), piece: Piece(type: .cannon, player: .black))
        ]

        for moveData in moves {
            let move = Move(
                from: moveData.from,
                to: moveData.to,
                piece: moveData.piece,
                timestamp: Date()
            )

            let success = recorder.recordMove(move)
            print("记录走法 \(move.description): \(success ? "成功" : "失败")")
        }

        print("总步数: \(recorder.record.totalMoves)")
        print()
    }

    // MARK: - Example 3: Adding Comments and Annotations

    /// 添加评注示例
    public static func addingComments() {
        print("=== 示例 3: 添加评注 ===")

        let recorder = GameRecorder()

        // 记录一步棋
        let move = Move(
            from: Position(x: 1, y: 0),
            to: Position(x: 2, y: 2),
            piece: Piece(type: .horse, player: .red),
            timestamp: Date()
        )
        recorder.recordMove(move)

        // 添加评注
        recorder.addPostComment("这是一步好棋，马八进七准备出车")
        recorder.setEvaluationSymbol(.good)

        print("添加评注: 这是一步好棋")
        print("评价符号: ! (好棋)")
        print()
    }

    // MARK: - Example 4: Creating Variations

    /// 创建变着示例
    public static func creatingVariations() {
        print("=== 示例 4: 创建变着 ===")

        let recorder = GameRecorder()

        // 走炮二平五
        let cannonMove = Move(
            from: Position(x: 1, y: 2),
            to: Position(x: 4, y: 2),
            piece: Piece(type: .cannon, player: .red),
            timestamp: Date()
        )
        recorder.recordMove(cannonMove)

        // 对方走马8进7
        let horseMove = Move(
            from: Position(x: 7, y: 9),
            to: Position(x: 6, y: 7),
            piece: Piece(type: .horse, player: .black),
            timestamp: Date()
        )
        recorder.recordMove(horseMove)

        // 现在添加一个变着：红方改为走马二进三
        let variationMove = Move(
            from: Position(x: 1, y: 0),
            to: Position(x: 2, y: 2),
            piece: Piece(type: .horse, player: .red),
            timestamp: Date()
        )

        // 回退到炮二平五的位置
        recorder.undo()

        // 添加变着
        _ = recorder.addVariation(move: variationMove)

        print("创建主变: 炮二平五 -> 马8进7")
        print("创建变着: 炮二平五 -> 马二进三")
        print("总变着数: \(recorder.record.variationCount)")
        print()
    }

    // MARK: - Example 5: Undo and Redo

    /// 悔棋和重做示例
    public static func undoAndRedo() {
        print("=== 示例 5: 悔棋和重做 ===")

        let recorder = GameRecorder()

        // 连续走几步
        let moves = [
            (from: Position(x: 4, y: 3), to: Position(x: 4, y: 4)),
            (from: Position(x: 4, y: 6), to: Position(x: 4, y: 5)),
            (from: Position(x: 2, y: 0), to: Position(x: 4, y: 2))
        ]

        for moveData in moves {
            let move = Move(
                from: moveData.from,
                to: moveData.to,
                piece: Piece(type: .pawn, player: .red),
                timestamp: Date()
            )
            recorder.recordMove(move)
            print("走棋: \(move.description)")
        }

        print("\n当前步数: \(recorder.currentMoveNumber)")

        // 悔棋一步
        print("\n悔棋一步...")
        recorder.undo()
        print("悔棋后步数: \(recorder.currentMoveNumber)")

        // 重做
        print("\n重做...")
        recorder.redo()
        print("重做后步数: \(recorder.currentMoveNumber)")

        // 悔棋多步
        print("\n悔棋 2 步...")
        recorder.undo(steps: 2)
        print("悔棋后步数: \(recorder.currentMoveNumber)")

        print()
    }

    // MARK: - Example 6: Saving and Loading

    /// 保存和加载示例
    public static func savingAndLoading() async {
        print("=== 示例 6: 保存和加载棋谱 ===")

        let storage = GameStorage()

        // 创建一个棋谱
        let header = GameHeader(
            event: "测试比赛",
            site: "北京",
            date: "2024.01.15",
            round: "1",
            red: "王五",
            black: "赵六",
            result: .redWin
        )

        let record = GameRecord(header: header)

        // 添加几步走法
        let moves = [
            (from: Position(x: 1, y: 2), to: Position(x: 4, y: 2)),
            (from: Position(x: 7, y: 9), to: Position(x: 4, y: 9))
        ]

        for moveData in moves {
            let move = Move(
                from: moveData.from,
                to: moveData.to,
                piece: Piece(type: .cannon, player: .red),
                timestamp: Date()
            )
            record.addMove(move)
        }

        do {
            // 保存为 PGN 格式
            let fileURL = try await storage.save(record, format: .pgn)
            print("棋谱已保存到: \(fileURL.path)")

            // 加载棋谱
            let loadedRecord = try await storage.load(from: fileURL)
            print("加载棋谱成功:")
            print("- 红方: \(loadedRecord.header.red)")
            print("- 黑方: \(loadedRecord.header.black)")
            print("- 结果: \(loadedRecord.header.resultDescription)")
            print("- 总步数: \(loadedRecord.totalMoves)")

        } catch {
            print("保存/加载失败: \(error)")
        }

        print()
    }

    // MARK: - Example 7: Browsing Game

    /// 浏览棋谱示例
    public static func browsingGame() {
        print("=== 示例 7: 浏览棋谱 ===")

        // 创建一个带有多步棋的棋谱
        let recorder = GameRecorder()

        // 记录一些走法
        let moves = [
            (from: Position(x: 1, y: 2), to: Position(x: 4, y: 2), piece: Piece(type: .cannon, player: .red)),
            (from: Position(x: 7, y: 9), to: Position(x: 4, y: 9), piece: Piece(type: .cannon, player: .black)),
            (from: Position(x: 2, y: 0), to: Position(x: 3, y: 2), piece: Piece(type: .horse, player: .red))
        ]

        for moveData in moves {
            let move = Move(
                from: moveData.from,
                to: moveData.to,
                piece: moveData.piece,
                timestamp: Date()
            )
            recorder.recordMove(move)
        }

        // 创建浏览器
        let browser = GameBrowser(recorder: recorder)

        print("初始位置: 第 \(browser.currentMoveNumber) 步")

        // 前进到第2步
        browser.goToMove(2)
        print("跳到第 2 步后: \(browser.currentMoveNumber)")

        // 后退
        browser.backward()
        print("后退一步后: \(browser.currentMoveNumber)")

        // 前进到结束
        browser.goToEnd()
        print("跳到结束: \(browser.currentMoveNumber)")

        // 返回开始
        browser.goToStart()
        print("返回开始: \(browser.currentMoveNumber)")

        print()
    }

    // MARK: - Run All Examples

    /// 运行所有示例
    public static func runAllExamples() async {
        print("=" * 50)
        print("中国象棋棋谱管理功能示例")
        print("=" * 50)
        print()

        createNewGame()
        recordingMoves()
        addingComments()
        creatingVariations()
        undoAndRedo()
        browsingGame()
        await savingAndLoading()

        print("=" * 50)
        print("示例运行完成")
        print("=" * 50)
    }
}

// MARK: - String Extension for repeating

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}