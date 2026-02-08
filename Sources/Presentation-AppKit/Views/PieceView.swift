import AppKit
import QuartzCore

// MARK: - PieceView

/// 单个棋子渲染视图
/// 支持主题切换（传统/现代）、选中状态动画、拖拽跟随
final class PieceView: NSView {

    // MARK: - 属性

    let piece: Piece
    var isSelected: Bool = false {
        didSet { updateSelectionState() }
    }
    var isDragged: Bool = false {
        didSet { updateDragState() }
    }

    var pieceTheme: PieceThemeConfig = PieceTheme.calligraphy.config {
        didSet { needsDisplay = true }
    }

    var isDarkMode: Bool = false

    // 动画图层
    private var selectionLayer: CALayer?
    private var shadowLayer: CALayer?

    // MARK: - 初始化

    init(piece: Piece, frame: NSRect = .zero) {
        self.piece = piece
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 设置

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = bounds.width / 2
        layer?.masksToBounds = false

        // 启用用户交互
        // 拖拽相关设置
    }

    // MARK: - 绘制

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let rect = bounds
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 2

        // 绘制棋子背景
        drawPieceBackground(in: context, center: center, radius: radius)

        // 绘制棋子文字
        drawPieceText(in: context, center: center, radius: radius)

        // 绘制选中效果
        if isSelected {
            drawSelectionIndicator(in: context, center: center, radius: radius)
        }
    }

    // MARK: - 绘制辅助方法

    private func drawPieceBackground(in context: CGContext, center: CGPoint, radius: CGFloat) {
        let path = CGPath(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ), transform: nil)

        // 渐变填充
        if pieceTheme.useGradient {
            let gradientColors = [
                pieceTheme.gradientStartColor.cgColor,
                pieceTheme.gradientEndColor.cgColor
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientColors as CFArray,
                locations: [0.0, 1.0]
            )

            context.saveGState()
            context.addPath(path)
            context.clip()
            context.drawLinearGradient(
                gradient!,
                start: CGPoint(x: center.x - radius, y: center.y - radius),
                end: CGPoint(x: center.x + radius, y: center.y + radius),
                options: []
            )
            context.restoreGState()
        } else {
            context.saveGState()
            context.addPath(path)
            context.setFillColor(pieceTheme.backgroundColor.cgColor)
            context.fillPath()
            context.restoreGState()
        }

        // 边框
        context.saveGState()
        context.addPath(path)
        context.setStrokeColor(pieceTheme.borderColor.cgColor)
        context.setLineWidth(pieceTheme.borderWidth)
        context.strokePath()
        context.restoreGState()

        // 阴影效果
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: 2),
            blur: pieceTheme.shadowRadius,
            color: NSColor.black.withAlphaComponent(pieceTheme.shadowOpacity).cgColor
        )
        context.restoreGState()
    }

    private func drawPieceText(in context: CGContext, center: CGPoint, radius: CGFloat) {
        let text = piece.character
        let fontSize = radius * pieceTheme.fontScale * 0.9

        // 创建字体
        let font: NSFont
        if let fontName = pieceTheme.fontName,
           let customFont = NSFont(name: fontName, size: fontSize) {
            font = customFont
        } else {
            font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        }

        // 文字颜色
        let textColor = piece.player == .red ?
            pieceTheme.redColor.nsColor :
            pieceTheme.blackColor.nsColor

        // 绘制文字效果
        switch pieceTheme.textStyle {
        case .outline:
            // 描边效果
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .strokeColor: NSColor.white,
                .strokeWidth: -3.0
            ]

            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.size()
            let textRect = CGRect(
                x: center.x - textSize.width / 2,
                y: center.y - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )

            attributedString.draw(in: textRect)

        case .embossed:
            // 浮雕效果
            // 阴影层
            let shadowAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black.withAlphaComponent(0.5)
            ]
            let shadowString = NSAttributedString(string: text, attributes: shadowAttributes)
            let textSize = shadowString.size()
            let shadowRect = CGRect(
                x: center.x - textSize.width / 2 + 1,
                y: center.y - textSize.height / 2 - 1,
                width: textSize.width,
                height: textSize.height
            )
            shadowString.draw(in: shadowRect)

            // 主文字层
            let mainAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            let mainString = NSAttributedString(string: text, attributes: mainAttributes)
            let mainRect = CGRect(
                x: center.x - textSize.width / 2,
                y: center.y - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            mainString.draw(in: mainRect)

        default:
            // 普通填充
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.size()
            let textRect = CGRect(
                x: center.x - textSize.width / 2,
                y: center.y - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            attributedString.draw(in: textRect)
        }
    }

    private func drawSelectionIndicator(in context: CGContext, center: CGPoint, radius: CGFloat) {
        let selectionRadius = radius + 4

        let path = CGPath(ellipseIn: CGRect(
            x: center.x - selectionRadius,
            y: center.y - selectionRadius,
            width: selectionRadius * 2,
            height: selectionRadius * 2
        ), transform: nil)

        context.saveGState()
        context.addPath(path)
        context.setStrokeColor(NSColor.systemYellow.cgColor)
        context.setLineWidth(3)
        context.strokePath()
        context.restoreGState()

        // 发光效果
        context.saveGState()
        context.setShadow(
            offset: .zero,
            blur: 10,
            color: NSColor.systemYellow.cgColor
        )
        context.addPath(path)
        context.setStrokeColor(NSColor.systemYellow.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(5)
        context.strokePath()
        context.restoreGState()
    }

    // MARK: - 更新状态

    private func updateSelectionState() {
        needsDisplay = true
    }

    private func updateDragState() {
        if isDragged {
            layer?.opacity = 0.7
            layer?.shadowOpacity = 0.5
        } else {
            layer?.opacity = 1.0
            layer?.shadowOpacity = Float(pieceTheme.shadowOpacity)
        }
    }

    // MARK: - 辅助方法

    /// 将棋盘坐标转换为屏幕坐标
    private func screenPosition(for position: Position) -> CGPoint {
        // 注意：这里假设调用者在 BoardNSView 中，需要根据实际布局调整
        // 这个方法是辅助 PieceView 使用的，实际坐标转换在 BoardNSView 中完成
        return .zero
    }
}

// MARK: - 扩展

private extension Piece {
    var character: String {
        let redChars = ["帅", "仕", "相", "傌", "俥", "炮", "兵"]
        let blackChars = ["将", "士", "象", "马", "车", "砲", "卒"]
        let chars = player == .red ? redChars : blackChars
        return chars[type.rawValue]
    }
}
