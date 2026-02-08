import Foundation

// MARK: - Position

/// 棋盘位置 (0-8列, 0-9行)
/// 中国象棋棋盘为9列×10行
/// 坐标约定：
/// - x: 列，从左到右 0-8
/// - y: 行，从下到上 0-9
/// - 红方在下方 (y=0-4)，黑方在上方 (y=5-9)
public struct Position: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, Comparable {
    public let x: Int  // 列 (0-8)
    public let y: Int  // 行 (0-9)

    /// 创建位置
    /// - Parameters:
    ///   - x: 列坐标 (0-8)
    ///   - y: 行坐标 (0-9)
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    // MARK: - Constants

    /// 棋盘宽度 (列数)
    public static let width = 9

    /// 棋盘高度 (行数)
    public static let height = 10

    /// 红方底线 (底部)
    public static let redBaseline = 0

    /// 黑方底线 (顶部)
    public static let blackBaseline = 9

    /// 河界分隔线 (红方边界)
    public static let riverRed = 4

    /// 河界分隔线 (黑方边界)
    public static let riverBlack = 5

    // MARK: - Validation

    /// 检查位置是否在有效范围内
    public var isValid: Bool {
        x >= 0 && x < Position.width && y >= 0 && y < Position.height
    }

    /// 检查位置是否在九宫格内 (将帅活动范围)
    /// - Parameter player: 阵营 (决定哪个九宫格)
    public func isInPalace(for player: Player) -> Bool {
        let xRange = 3...5
        let yRange = player == .red ? 0...2 : 7...9
        return xRange.contains(x) && yRange.contains(y)
    }

    /// 检查位置是否已过河
    /// - Parameter player: 阵营
    public func hasCrossedRiver(for player: Player) -> Bool {
        player == .red ? y > Position.riverRed : y < Position.riverBlack
    }

    /// 检查位置是否在己方半场
    /// - Parameter player: 阵营
    public func isInOwnHalf(for player: Player) -> Bool {
        player == .red ? y <= Position.riverRed : y >= Position.riverBlack
    }

    // MARK: - Distance and Direction

    /// 计算到另一位置的距离向量
    public func distance(to other: Position) -> (dx: Int, dy: Int) {
        (other.x - x, other.y - y)
    }

    /// 计算曼哈顿距离
    public func manhattanDistance(to other: Position) -> Int {
        abs(other.x - x) + abs(other.y - y)
    }

    /// 计算切比雪夫距离
    public func chebyshevDistance(to other: Position) -> Int {
        max(abs(other.x - x), abs(other.y - y))
    }

    /// 检查是否在同一行
    public func isSameRow(as other: Position) -> Bool {
        y == other.y
    }

    /// 检查是否在同一列
    public func isSameColumn(as other: Position) -> Bool {
        x == other.x
    }

    /// 检查是否在同一对角线
    public func isSameDiagonal(as other: Position) -> Bool {
        abs(x - other.x) == abs(y - other.y)
    }

    // MARK: - String Representation

    /// 从字符串解析位置 (如 "e4", "4e", "0,0")
    /// 支持格式:
    /// - 中国象棋坐标: "e4" (e列4行，从1开始)
    /// - 数组坐标: "0,0" (x,y 从0开始)
    public static func from(string: String) -> Position? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)

        // 尝试解析 "x,y" 格式
        if trimmed.contains(","),
           let commaIndex = trimmed.firstIndex(of: ",") {
            let xPart = String(trimmed[..<commaIndex]).trimmingCharacters(in: .whitespaces)
            let yPart = String(trimmed[trimmed.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)
            if let x = Int(xPart), let y = Int(yPart) {
                return Position(x: x, y: y)
            }
        }

        // 尝试解析 "e4" 格式 (文件+排名)
        if trimmed.count == 2,
           let fileChar = trimmed.first?.lowercased().first,
           let rankChar = trimmed.last,
           let rank = Int(String(rankChar)) {
            let x = Int(fileChar.asciiValue! - Character("a").asciiValue!)
            let y = rank - 1  // 从1-based转为0-based
            return Position(x: x, y: y)
        }

        return nil
    }

    /// 转换为代数记谱 (如 "e4")
    public var algebraic: String {
        let file = String(UnicodeScalar(UInt8(x) + Character("a").asciiValue!))
        let rank = y + 1
        return "\(file)\(rank)"
    }

    /// UCI 格式 (用于引擎通信，如 "e2e4")
    public func uciString(to destination: Position) -> String {
        "\(algebraic)\(destination.algebraic)"
    }

    /// 中国象棋中文坐标表示
    public var chineseNotation: String {
        let files = ["一", "二", "三", "四", "五", "六", "七", "八", "九"]
        let ranks = ["１", "２", "３", "４", "５", "６", "７", "８", "９", "１０"]
        return "\(files[x])\(ranks[y])"
    }

    public var description: String {
        "(\(x),\(y))"
    }

    // MARK: - Comparable

    public static func < (lhs: Position, rhs: Position) -> Bool {
        if lhs.y == rhs.y {
            return lhs.x < rhs.x
        }
        return lhs.y < rhs.y
    }

    // MARK: - Utility

    /// 生成新位置
    public func offset(dx: Int, dy: Int) -> Position {
        Position(x: x + dx, y: y + dy)
    }

    /// 所有相邻位置 (8方向)
    public var adjacentPositions: [Position] {
        [
            offset(dx: 0, dy: 1),
            offset(dx: 0, dy: -1),
            offset(dx: 1, dy: 0),
            offset(dx: -1, dy: 0),
            offset(dx: 1, dy: 1),
            offset(dx: 1, dy: -1),
            offset(dx: -1, dy: 1),
            offset(dx: -1, dy: -1)
        ].filter { $0.isValid }
    }

    /// 四邻域位置 (上下左右)
    public var orthogonalPositions: [Position] {
        [
            offset(dx: 0, dy: 1),
            offset(dx: 0, dy: -1),
            offset(dx: 1, dy: 0),
            offset(dx: -1, dy: 0)
        ].filter { $0.isValid }
    }

    /// 对角线位置
    public var diagonalPositions: [Position] {
        [
            offset(dx: 1, dy: 1),
            offset(dx: 1, dy: -1),
            offset(dx: -1, dy: 1),
            offset(dx: -1, dy: -1)
        ].filter { $0.isValid }
    }

    /// "日"字位置 (马走日)
    public var horsePositions: [Position] {
        [
            offset(dx: 1, dy: 2),
            offset(dx: 2, dy: 1),
            offset(dx: 2, dy: -1),
            offset(dx: 1, dy: -2),
            offset(dx: -1, dy: -2),
            offset(dx: -2, dy: -1),
            offset(dx: -2, dy: 1),
            offset(dx: -1, dy: 2)
        ].filter { $0.isValid }
    }

    /// "田"字位置 (象走田)
    public var elephantPositions: [Position] {
        [
            offset(dx: 2, dy: 2),
            offset(dx: 2, dy: -2),
            offset(dx: -2, dy: 2),
            offset(dx: -2, dy: -2)
        ].filter { $0.isValid }
    }

    // MARK: - Private

    private mutating func placePiece(_ piece: Piece?, at position: Position) {
        guard isValidPosition(position) else { return }
        pieces[position.y][position.x] = piece
    }
}
