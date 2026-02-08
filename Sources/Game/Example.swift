import Foundation

// MARK: - 使用示例

/// GameController 使用示例
public struct GameControllerExample {

    /// 运行基本示例
    public static func runBasicExample() {
        print("=== 中国象棋游戏控制器示例 ===\n")

        // 1. 创建游戏控制器
        let game = GameController()
        print("1. 创建新游戏")
        print("当前棋盘:")
        print(game.currentBoard)
        print()

        // 2. 执行一步走棋 (炮二平五 - 当头炮)
        let from = Position(x: 1, y: 2)  // 炮的位置
        let to = Position(x: 4, y: 2)   // 中间

        print("2. 执行走棋: 炮二平五")
        let result = game.makeMove(from: from, to: to)

        switch result {
        case .success(let move):
            print("走棋成功: \(move)")
        case .failure(let error):
            print("走棋失败: \(error)")
        }

        print("\n更新后的棋盘:")
        print(game.currentBoard)
        print()

        // 3. 获取当前FEN
        print("3. 当前FEN字符串:")
        print(game.currentFEN)
        print()

        // 4. 生成UCI position命令
        print("4. UCI position命令:")
        print(game.generateUCIPositionCommand())
        print()

        // 5. 获取合法移动
        print("5. 当前方的合法移动:")
        let legalMoves = PositionAnalyzer.generateAllLegalMoves(
            for: game.currentPlayer,
            on: game.currentBoard
        )
        print("共有 \(legalMoves.count) 种合法移动")
        for move in legalMoves.prefix(5) {
            print("  - \(move.from) -> \(move.to) (\(move.piece.character))")
        }
        if legalMoves.count > 5 {
            print("  ... 还有 \(legalMoves.count - 5) 种")
        }
        print()
    }

    /// 运行FEN解析示例
    public static func runFENExample() {
        print("=== FEN解析示例 ===\n")

        // 标准初始局面的FEN
        let initialFEN = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1"

        print("初始局面FEN:")
        print(initialFEN)
        print()

        // 解析FEN
        do {
            let result = try FENParser.parse(initialFEN)
            print("解析成功!")
            print("轮到: \(result.currentPlayer.displayName)")
            print("半回合: \(result.halfMoveClock)")
            print("回合数: \(result.fullMoveNumber)")
            print()
            print("棋盘:")
            print(result.board)
        } catch {
            print("解析失败: \(error)")
        }
        print()

        // 测试自定义FEN
        print("测试自定义FEN:")
        let customFEN = "4k4/9/9/9/9/9/9/9/9/4K4 w - - 0 1"
        print("FEN: \(customFEN)")

        do {
            let result = try FENParser.parse(customFEN)
            print("解析成功!")
            print("棋盘:")
            print(result.board)
        } catch {
            print("解析失败: \(error)")
        }
    }

    /// 运行局面分析示例
    public static func runAnalysisExample() {
        print("=== 局面分析示例 ===\n")

        // 创建初始局面
        let board = Board.initial()
        print("初始局面评估:")
        let evaluation = PositionAnalyzer.evaluatePosition(board)
        print("局面评分: \(evaluation) (正值对红方有利)")
        print()

        // 检查将军
        let isCheck = PositionAnalyzer.isInCheck(player: .red, on: board)
        print("红方是否被将军: \(isCheck)")
        print()

        // 生成所有合法移动
        print("红方所有合法移动 (前10个):")
        let legalMoves = PositionAnalyzer.generateAllLegalMoves(for: .red, on: board)
        for (index, move) in legalMoves.prefix(10).enumerated() {
            print("  \(index + 1). \(move.from) -> \(move.to) (\(move.piece.character))")
        }
        print("  共 \(legalMoves.count) 种合法移动")
        print()

        // 测试一个特殊局面：将军
        print("测试将军局面:")
        let checkFEN = "4k4/4r4/9/9/9/9/9/9/4R4/4K4 w - - 0 1"
        if let board = Board.fromFEN(checkFEN) {
            let isRedInCheck = PositionAnalyzer.isInCheck(player: .red, on: board)
            print("红方是否被将军: \(isRedInCheck)")

            let redMoves = PositionAnalyzer.generateAllLegalMoves(for: .red, on: board)
            print("红方应将移动数: \(redMoves.count)")
            for move in redMoves {
                print("  - \(move.from) -> \(move.to) (\(move.piece.character))")
            }
        }
    }

    /// 运行所有示例
    public static func runAll() {
        runBasicExample()
        print("\n" + String(repeating: "=", count: 50) + "\n")
        runFENExample()
        print("\n" + String(repeating: "=", count: 50) + "\n")
        runAnalysisExample()
    }
}

// MARK: - 主程序入口

/// 命令行测试入口
public func runGameExamples() {
    GameControllerExample.runAll()
}
