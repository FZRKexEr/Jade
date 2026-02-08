import Foundation

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
