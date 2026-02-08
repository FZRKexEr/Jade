# 贡献指南

感谢你对本项目感兴趣！本文档将指导你如何参与项目的开发和贡献。

## 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发环境设置](#开发环境设置)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [测试要求](#测试要求)
- [Pull Request 流程](#pull-request-流程)
- [Issue 提交规范](#issue-提交规范)

## 行为准则

参与本项目时，请遵守以下准则：

- 尊重他人，保持友善和耐心
- 欢迎新成员，帮助他们融入社区
- 接受建设性的批评，优雅地处理分歧
- 关注社区最有利的事情

## 如何贡献

你可以通过以下方式参与项目：

### 报告 Bug

如果你发现了 Bug，请通过 GitHub Issues 报告：

1. 首先搜索现有的 Issues，确认问题没有被报告过
2. 创建新的 Issue，使用 Bug 报告模板
3. 提供尽可能详细的信息：
   - 问题描述
   - 复现步骤
   - 期望结果
   - 实际结果
   - 系统信息（macOS 版本、硬件配置等）
   - 相关日志或截图

### 提交功能请求

如果你有新功能的想法：

1. 搜索现有的 Issues，确认功能没有被请求过
2. 创建新的 Issue，使用功能请求模板
3. 描述清楚：
   - 功能的用途
   - 期望的行为
   - 可能的实现方式（可选）

### 改进文档

文档的改进同样重要：

- 修正拼写和语法错误
- 改进文档的清晰度和可读性
- 添加缺失的文档
- 更新过时的信息

### 提交代码

如果你有代码贡献：

1. Fork 本仓库
2. 创建功能分支
3. 编写代码和测试
4. 提交 Pull Request

详见 [Pull Request 流程](#pull-request-流程)

## 开发环境设置

### 系统要求

- **macOS**: 14.0 (Sonoma) 或更高版本
- **Xcode**: 15.0 或更高版本
- **Swift**: 5.9 或更高版本

### 克隆仓库

```bash
git clone https://github.com/yourusername/ChineseChess.git
cd ChineseChess
```

### 打开项目

1. 使用 Xcode 打开 `ChineseChess.xcodeproj`
2. 等待 Xcode 加载项目依赖

### 构建项目

1. 选择目标设备（如"My Mac"）
2. 点击运行按钮或按 `Cmd+R`

### 运行测试

```bash
# 使用 Xcode 运行测试
Cmd+U

# 或使用命令行
xcodebuild test -scheme ChineseChess -destination 'platform=macOS'
```

## 代码规范

### Swift 代码规范

本项目遵循 Swift 官方 [API 设计指南](https://swift.org/documentation/api-design-guidelines/) 和以下规范：

#### 命名规范

- **类型名**: 使用 PascalCase（如 `GameState`, `ChessBoard`）
- **函数名**: 使用 camelCase，描述动作（如 `makeMove()`, `validatePosition()`）
- **常量**: 使用 camelCase（如 `boardWidth`, `maxHistorySize`）
- **属性**: 使用名词或描述性形容词（如 `currentPlayer`, `isGameOver`）

#### 代码组织

```swift
// MARK: - Properties

private var board: [[Piece?]]
private(set) var currentPlayer: PieceColor

// MARK: - Initialization

init() {
    // 初始化代码
}

// MARK: - Public Methods

func makeMove(_ move: Move) throws {
    // 方法实现
}

// MARK: - Private Methods

private func validateMove(_ move: Move) -> Bool {
    // 私有方法实现
}
```

#### 注释规范

- 使用 `///` 为公共 API 添加文档注释
- 使用 `//` 为代码添加行内注释
- 复杂逻辑应添加说明性注释

```swift
/// 表示棋盘上的一个着法
struct Move {
    /// 起始位置
    let from: Position

    /// 目标位置
    let to: Position

    /// 是否吃子
    var isCapture: Bool {
        return pieceAt(to) != nil
    }
}
```

### SwiftUI 规范

#### 视图结构

```swift
struct ChessBoardView: View {
    // MARK: - Properties

    @StateObject private var viewModel: BoardViewModel
    @State private var selectedPiece: Piece?

    // MARK: - Body

    var body: some View {
        ZStack {
            boardBackground
            piecesLayer
            highlightLayer
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Subviews

    private var boardBackground: some View {
        // 棋盘背景实现
    }

    private var piecesLayer: some View {
        // 棋子层实现
    }

    private var highlightLayer: some View {
        // 高亮层实现
    }
}
```

#### 状态管理

- 使用 `@State` 管理视图内部状态
- 使用 `@StateObject` 管理视图模型
- 使用 `@ObservedObject` 注入外部可观察对象
- 使用 `@Binding` 创建双向绑定
- 使用 `@Environment` 访问环境值

### 错误处理

使用 Swift 的错误处理机制：

```swift
enum ChessError: LocalizedError {
    case invalidMove(reason: String)
    case invalidPosition
    case gameOver
    case notYourTurn

    var errorDescription: String? {
        switch self {
        case .invalidMove(let reason):
            return "无效的着法: \(reason)"
        case .invalidPosition:
            return "无效的位置"
        case .gameOver:
            return "对局已结束"
        case .notYourTurn:
            return "不是你的回合"
        }
    }
}

func makeMove(_ move: Move) throws {
    guard !isGameOver else {
        throw ChessError.gameOver
    }

    guard isValid(move) else {
        throw ChessError.invalidMove(reason: "违反规则")
    }

    // 执行着法
}
```

## 提交规范

### 提交信息格式

提交信息应遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/v1.0.0/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type（类型）

| 类型 | 说明 |
|------|------|
| `feat` | 新功能（feature）|
| `fix` | 修复 bug |
| `docs` | 文档更新 |
| `style` | 代码格式调整（不影响功能）|
| `refactor` | 代码重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建过程或辅助工具的变动 |
| `revert` | 回滚到上一个版本 |

#### Scope（可选）

表示影响的范围，如：

- `board`: 棋盘相关
- `engine`: 引擎相关
- `ui`: 界面相关
- `docs`: 文档相关

#### Subject

简短描述变更内容，使用祈使句，首字母小写，结尾不加句号。

#### Body（可选）

详细描述变更内容，说明变更的原因和与之前行为的对比。

#### Footer（可选）

- **Breaking Changes**: 不兼容的 API 修改
- **Closes**: 关闭的 Issue 编号

### 提交示例

```
feat(board): 添加棋子拖拽功能

实现棋子拖拽移动功能，支持拖拽到目标位置
和拖回原位取消操作。

- 添加拖拽手势识别
- 添加拖拽动画效果
- 支持拖拽预览

Closes #123
```

```
fix(engine): 修复引擎连接超时问题

增加引擎连接超时时间，从 5 秒增加到 30 秒，
解决在较慢系统上引擎连接失败的问题。

Fixes #456
```

```
docs(readme): 更新安装说明

添加 macOS Sonoma 的安装步骤说明，
并补充了常见问题解答。
```

```
refactor(board): 重构棋盘渲染逻辑

将棋盘渲染逻辑拆分为独立的视图组件，
提高代码可维护性和可测试性。

BREAKING CHANGE: 修改了 BoardView 的初始化参数
```

## 测试要求

### 测试策略

本项目采用多层次的测试策略：

1. **单元测试**: 测试独立的函数和类
2. **集成测试**: 测试多个组件的协作
3. **UI 测试**: 测试用户界面交互

### 编写测试

#### 单元测试示例

```swift
import XCTest
@testable import ChineseChess

class BoardTests: XCTestCase {

    var board: ChessBoard!

    override func setUp() {
        super.setUp()
        board = ChessBoard()
    }

    override func tearDown() {
        board = nil
        super.tearDown()
    }

    func testInitialPosition() {
        // 测试初始局面
        XCTAssertEqual(board.pieceAt(file: 0, rank: 0)?.type, .rook)
        XCTAssertEqual(board.pieceAt(file: 0, rank: 0)?.color, .red)
        XCTAssertEqual(board.currentPlayer, .red)
    }

    func testLegalMove() {
        // 测试合法着法
        let move = Move(from: Position(file: 1, rank: 0), to: Position(file: 2, rank: 2))
        XCTAssertTrue(board.isLegal(move))
    }

    func testIllegalMove() {
        // 测试不合法着法
        let move = Move(from: Position(file: 0, rank: 0), to: Position(file: 0, rank: 5))
        XCTAssertFalse(board.isLegal(move))
    }
}
```

#### UI 测试示例

```swift
import XCTest

class ChessBoardUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testMakeMove() {
        // 点击棋子
        let piece = app.images["piece_horse_red_1"]
        piece.tap()

        // 点击目标位置
        let targetSquare = app.buttons["square_2_2"]
        targetSquare.tap()

        // 验证棋子移动
        let movedPiece = app.images["piece_horse_red_1"]
        XCTAssertTrue(movedPiece.exists)
    }

    func testNewGame() {
        // 点击菜单
        app.menuBars.menuBarItems["File"].click()

        // 点击新局
        app.menuItems["New Game"].click()

        // 验证新局对话框出现
        let dialog = app.dialogs["New Game"]
        XCTAssertTrue(dialog.exists)
    }
}
```

### 运行测试

```bash
# 使用 Xcode 运行所有测试
Cmd+U

# 使用命令行运行测试
xcodebuild test -scheme ChineseChess -destination 'platform=macOS'

# 运行特定测试类
xcodebuild test -scheme ChineseChess -destination 'platform=macOS' -only-testing:ChineseChessTests/BoardTests

# 运行特定测试方法
xcodebuild test -scheme ChineseChess -destination 'platform=macOS' -only-testing:ChineseChessTests/BoardTests/testInitialPosition
```

### 测试覆盖率

目标测试覆盖率：

- **Domain 层**: 80%+
- **ViewModel 层**: 70%+
- **Service 层**: 60%+
- **UI 层**: 40%+

查看测试覆盖率：

```bash
xcodebuild test -scheme ChineseChess -destination 'platform=macOS' -enableCodeCoverage YES
```

## Pull Request 流程

### 提交前准备

1. **获取最新代码**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/issue-description
   ```

3. **编写代码**
   - 遵循代码规范
   - 编写测试
   - 确保所有测试通过

4. **提交更改**
   ```bash
   git add .
   git commit -m "feat(board): 添加棋子拖拽功能

   实现棋子拖拽移动功能，支持拖拽到目标位置
   和拖回原位取消操作。

   - 添加拖拽手势识别
   - 添加拖拽动画效果
   - 支持拖拽预览

   Closes #123"
   ```

5. **推送到远程**
   ```bash
   git push origin feature/your-feature-name
   ```

### 创建 Pull Request

1. 访问 GitHub 仓库页面
2. 点击 "Compare & pull request" 按钮
3. 填写 Pull Request 信息：
   - **标题**: 简洁描述变更内容
   - **描述**: 详细说明变更内容、原因、测试情况等
   - **关联 Issue**: 使用 `Fixes #123` 或 `Closes #123` 关联 Issue

4. 提交 Pull Request

### PR 审查流程

1. **自动化检查**
   - CI 测试必须通过
   - 代码覆盖率不能下降
   - 代码风格检查通过

2. **人工审查**
   - 至少一名维护者审查
   - 检查代码质量和设计
   - 确认测试充分

3. **修改反馈**
   - 根据审查意见修改代码
   - 重新提交直到通过审查

4. **合并代码**
   - 审查通过后由维护者合并
   - 使用 "Squash and merge" 方式
   - 删除功能分支

## Issue 提交规范

### Bug 报告模板

```markdown
## Bug 描述
清晰简洁地描述 Bug 是什么。

## 复现步骤
1. 打开应用
2. 点击 '...'
3. 滚动到 '...'
4. 出现错误

## 期望行为
清晰描述你期望发生的行为。

## 实际行为
描述实际发生的行为。

## 截图
如果适用，添加截图帮助解释问题。

## 环境信息
- 操作系统: [例如 macOS 14.2]
- 应用版本: [例如 1.0.0]
- 硬件: [例如 MacBook Pro M3]

## 附加信息
添加任何其他相关信息，如日志文件。
```

### 功能请求模板

```markdown
## 功能描述
清晰简洁地描述你想要的功能。

## 问题描述
描述你遇到的问题或需求背景。

## 期望解决方案
描述你希望如何解决这个问题。

## 替代方案
描述你考虑过的其他替代方案。

## 附加信息
添加任何其他相关信息或截图。
```

### 问题标签

创建 Issue 时请选择适当的标签：

- `bug`: 功能不正常
- `enhancement`: 新功能请求
- `documentation`: 文档相关
- `good first issue`: 适合新手的任务
- `help wanted`: 需要帮助
- `question`: 问题咨询

---

感谢你的贡献！有任何问题请随时联系维护团队。
