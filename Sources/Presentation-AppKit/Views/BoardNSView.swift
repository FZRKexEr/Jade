import AppKit
import QuartzCore

// MARK: - BoardNSView

/// 高性能棋盘视图 - 使用 CALayer 进行高效渲染
/// 绘制棋盘网格、楚河汉界、棋子、选中/高亮效果
final class BoardNSView: NSView {

    // MARK: - 属性

    weak var delegate: BoardNSViewDelegate?

    var boardTheme: BoardThemeConfig = BoardTheme.wood.config {
        didSet { updateTheme() }
    }

    var pieceTheme: PieceThemeConfig = PieceTheme.calligraphy.config {
        didSet { updateTheme() }
    }

    var isDarkMode: Bool = false {
        didSet { updateTheme() }
    }

    // 棋盘状态
    private var pieces: [Position: Piece] = [:]
    private var selectedPosition: Position?
    private var validMoves: [Position] = []
    private var lastMove: Move?
    private var isKingInCheck: Bool = false
    private var checkPosition: Position?

    // 布局参数
    private var cellSize: CGFloat = 0
    private var pieceSize: CGFloat = 0
    private var boardOrigin: CGPoint = .zero

    // 动画参数
    private var checkPulseAnimation: CABasicAnimation?
    private var selectedPieceLayer: CALayer?

    // MARK: - 图层

    private lazy var boardLayer: CALayer = {
        let layer = CALayer()
        layer.name = "board"
        return layer
    }()

    private lazy var gridLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.name = "grid"
        layer.fillColor = NSColor.clear.cgColor
        return layer
    }()

    private lazy var piecesLayer: CALayer = {
        let layer = CALayer()
        layer.name = "pieces"
        return layer
    }()

    private lazy var highlightsLayer: CALayer = {
        let layer = CALayer()
        layer.name = "highlights"
        return layer
    }()

    private lazy var checkIndicatorLayer: CALayer = {
        let layer = CALayer()
        layer.name = "checkIndicator"
        layer.opacity = 0
        return layer
    }()

    // MARK: - 初始化

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    // MARK: - 图层设置

    private func setupLayers() {
        wantsLayer = true

        // 添加图层（从底到顶）
        layer?.addSublayer(boardLayer)
        layer?.addSublayer(gridLayer)
        layer?.addSublayer(highlightsLayer)
        layer?.addSublayer(piecesLayer)
        layer?.addSublayer(checkIndicatorLayer)

        // 设置默认主题
        updateTheme()
    }

    // MARK: - 布局

    override func layout() {
        super.layout()

        let bounds = self.bounds

        // 计算棋盘尺寸（9:10 比例）
        let boardRatio: CGFloat = 9.0 / 10.0
        let availableRatio = bounds.width / bounds.height

        let boardWidth: CGFloat
        let boardHeight: CGFloat

        if availableRatio > boardRatio {
            boardHeight = bounds.height * 0.9
            boardWidth = boardHeight * boardRatio
        } else {
            boardWidth = bounds.width * 0.9
            boardHeight = boardWidth / boardRatio
        }

        // 计算单元格大小
        cellSize = boardWidth / 8
        pieceSize = cellSize * 0.85

        // 计算棋盘原点（居中）
        boardOrigin = CGPoint(
            x: (bounds.width - boardWidth) / 2,
            y: (bounds.height - boardHeight) / 2
        )

        // 更新图层位置
        let boardRect = CGRect(origin: boardOrigin, size: CGSize(width: boardWidth, height: boardHeight))
        boardLayer.frame = boardRect
        gridLayer.frame = boardRect
        piecesLayer.frame = boardRect
        highlightsLayer.frame = boardRect
        checkIndicatorLayer.frame = bounds

        // 重绘内容
        redrawBoard()
        redrawPieces()
        redrawHighlights()
    }

    // MARK: - 更新主题

    private func updateTheme() {
        // 更新棋盘背景
        let bgColor = isDarkMode ?
            NSColor(calibratedWhite: 0.15, alpha: 1.0) :
            boardTheme.boardColor.nsColor
        boardLayer.backgroundColor = bgColor.cgColor

        // 更新网格线颜色
        let lineColor = isDarkMode ?
            NSColor(calibratedWhite: 0.6, alpha: 1.0) :
            boardTheme.lineColor.nsColor
        gridLayer.strokeColor = lineColor.cgColor
        gridLayer.lineWidth = boardTheme.gridWidth

        // 重绘
        redrawBoard()
        redrawPieces()
    }

    // MARK: - 更新棋盘状态

    func updateBoardState(
        pieces: [Position: Piece],
        selectedPosition: Position?,
        validMoves: [Position],
        lastMove: Move?,
        isKingInCheck: Bool,
        checkPosition: Position?
    ) {
        self.pieces = pieces
        self.selectedPosition = selectedPosition
        self.validMoves = validMoves
        self.lastMove = lastMove
        self.isKingInCheck = isKingInCheck
        self.checkPosition = checkPosition

        redrawPieces()
        redrawHighlights()
        updateCheckIndicator()
    }

    // MARK: - 绘制方法

    private func redrawBoard() {
        // 绘制棋盘背景（可选纹理）
        boardLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // 添加圆角
        let cornerRadius: CGFloat = 8.0
        boardLayer.cornerRadius = cornerRadius

        // 添加阴影
        boardLayer.shadowColor = NSColor.black.cgColor
        boardLayer.shadowOffset = CGSize(width: 0, height: 2)
        boardLayer.shadowRadius = 4
        boardLayer.shadowOpacity = 0.2

        // 绘制网格
        redrawGrid()
    }

    private func redrawGrid() {
        let path = CGMutablePath()
        let cellWidth = cellSize
        let cellHeight = cellSize
        let width = gridLayer.bounds.width
        let height = gridLayer.bounds.height

        // 横线
        for row in 0...<10 {
            let y = CGFloat(row) * cellHeight
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }

        // 竖线（中间断开）
        for col in 0...<9 {
            let x = CGFloat(col) * cellWidth
            // 上方
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: 4 * cellHeight))
            // 下方
            path.move(to: CGPoint(x: x, y: 5 * cellHeight))
            path.addLine(to: CGPoint(x: x, y: 9 * cellHeight))
        }

        // 九宫格斜线 - 红方
        let redLeft = 3 * cellWidth
        let redRight = 5 * cellWidth
        let redTop = 0
        let redBottom = 2 * Int(cellHeight)

        path.move(to: CGPoint(x: redLeft, y: CGFloat(redTop)))
        path.addLine(to: CGPoint(x: redRight, y: CGFloat(redBottom)))
        path.move(to: CGPoint(x: redRight, y: CGFloat(redTop)))
        path.addLine(to: CGPoint(x: redLeft, y: CGFloat(redBottom)))

        // 九宫格斜线 - 黑方
        let blackLeft = 3 * cellWidth
        let blackRight = 5 * cellWidth
        let blackTop = 7 * Int(cellHeight)
        let blackBottom = 9 * Int(cellHeight)

        path.move(to: CGPoint(x: blackLeft, y: CGFloat(blackTop)))
        path.addLine(to: CGPoint(x: blackRight, y: CGFloat(blackBottom)))
        path.move(to: CGPoint(x: blackRight, y: CGFloat(blackTop)))
        path.addLine(to: CGPoint(x: blackLeft, y: CGFloat(blackBottom)))

        gridLayer.path = path

        // 绘制楚河汉界文字
        // 这里使用额外的 CATextLayer
        updateRiverLabels()
    }

    private func updateRiverLabels() {
        // 移除旧的文字图层
        gridLayer.sublayers?.forEach { if $0.name == "riverLabel" { $0.removeFromSuperlayer() } }

        // 创建楚河汉界文字
        let cellHeight = cellSize
        let width = gridLayer.bounds.width

        // 楚河 (红方视角在上方，实际坐标是黑方)
        let chuheLayer = CATextLayer()
        chuheLayer.name = "riverLabel"
        chuheLayer.string = "楚河"
        chuheLayer.fontSize = cellHeight * 0.4
        chuheLayer.alignmentMode = .center
        chuheLayer.foregroundColor = gridLayer.strokeColor
        chuheLayer.frame = CGRect(
            x: width * 0.25 - 30,
            y: 4.3 * cellHeight,
            width: 60,
            height: cellHeight * 0.5
        )
        gridLayer.addSublayer(chuheLayer)

        // 汉界
        let hanjieLayer = CATextLayer()
        hanjieLayer.name = "riverLabel"
        hanjieLayer.string = "汉界"
        hanjieLayer.fontSize = cellHeight * 0.4
        hanjieLayer.alignmentMode = .center
        hanjieLayer.foregroundColor = gridLayer.strokeColor
        hanjieLayer.frame = CGRect(
            x: width * 0.75 - 30,
            y: 4.3 * cellHeight,
            width: 60,
            height: cellHeight * 0.5
        )
        gridLayer.addSublayer(hanjieLayer)
    }

    private func redrawPieces() {
        // 清除旧棋子图层
        piecesLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // 创建新棋子图层
        for (position, piece) in pieces {
            let pieceLayer = createPieceLayer(for: piece, at: position)
            piecesLayer.addSublayer(pieceLayer)
        }
    }

    private func createPieceLayer(for piece: Piece, at position: Position) -> CALayer {
        let screenPos = screenPosition(for: position)
        let size = pieceSize

        // 创建棋子容器图层
        let containerLayer = CALayer()
        containerLayer.frame = CGRect(
            x: screenPos.x - size / 2,
            y: screenPos.y - size / 2,
            width: size,
            height: size
        )
        containerLayer.name = "piece_\(position.x)_\(position.y)"

        // 棋子背景（圆形）
        let backgroundLayer = CALayer()
        backgroundLayer.frame = containerLayer.bounds
        backgroundLayer.cornerRadius = size / 2
        backgroundLayer.backgroundColor = pieceTheme.backgroundColor.cgColor

        // 渐变效果
        if pieceTheme.useGradient {
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = backgroundLayer.bounds
            gradientLayer.cornerRadius = size / 2
            gradientLayer.colors = [
                pieceTheme.gradientStartColor.cgColor,
                pieceTheme.gradientEndColor.cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            backgroundLayer.addSublayer(gradientLayer)
        }

        // 边框
        backgroundLayer.borderWidth = pieceTheme.borderWidth
        backgroundLayer.borderColor = pieceTheme.borderColor.cgColor

        // 阴影
        backgroundLayer.shadowColor = NSColor.black.cgColor
        backgroundLayer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundLayer.shadowRadius = pieceTheme.shadowRadius
        backgroundLayer.shadowOpacity = Float(pieceTheme.shadowOpacity)

        // 棋子文字
        let textLayer = CATextLayer()
        let fontSize = size * pieceTheme.fontScale * 0.6
        textLayer.fontSize = fontSize
        textLayer.string = piece.character
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = piece.player == .red ?
            pieceTheme.redColor.cgColor :
            pieceTheme.blackColor.cgColor
        textLayer.frame = CGRect(
            x: 0,
            y: (size - fontSize) / 2 - size * 0.05,
            width: size,
            height: fontSize
        )

        // 字体设置
        if let fontName = pieceTheme.fontName,
           let font = NSFont(name: fontName, size: fontSize) {
            textLayer.font = font
        }

        // 文字效果
        switch pieceTheme.textStyle {
        case .outline:
            textLayer.foregroundColor = NSColor.white.cgColor
            // 使用CATextLayer无法实现描边，这里使用简化方案
        case .filled:
            break
        case .embossed:
            textLayer.shadowColor = NSColor.black.cgColor
            textLayer.shadowOffset = CGSize(width: 0, height: -1)
            textLayer.shadowOpacity = 0.5
        case .simple:
            textLayer.shadowOpacity = 0
        }

        // 组装图层
        containerLayer.addSublayer(backgroundLayer)
        containerLayer.addSublayer(textLayer)

        // 选中效果（如果选中）
        if position == selectedPosition {
            addSelectionEffect(to: containerLayer, size: size)
        }

        // 最后一步标记
        if let lastMove = lastMove,
           (lastMove.from == position || lastMove.to == position) {
            addLastMoveIndicator(to: containerLayer, size: size)
        }

        return containerLayer
    }

    private func addSelectionEffect(to layer: CALayer, size: CGFloat) {
        let selectionLayer = CALayer()
        selectionLayer.frame = CGRect(x: -3, y: -3, width: size + 6, height: size + 6)
        selectionLayer.cornerRadius = (size + 6) / 2
        selectionLayer.borderWidth = 3
        selectionLayer.borderColor = NSColor.systemYellow.cgColor
        selectionLayer.shadowColor = NSColor.systemYellow.cgColor
        selectionLayer.shadowOffset = .zero
        selectionLayer.shadowRadius = 5
        selectionLayer.shadowOpacity = 0.8

        // 脉冲动画
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.fromValue = 0.6
        pulseAnimation.toValue = 1.0
        pulseAnimation.duration = 0.6
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        selectionLayer.add(pulseAnimation, forKey: "pulse")

        layer.addSublayer(selectionLayer)
        selectedPieceLayer = selectionLayer
    }

    private func addLastMoveIndicator(to layer: CALayer, size: CGFloat) {
        let indicatorLayer = CALayer()
        indicatorLayer.frame = CGRect(x: -2, y: -2, width: size + 4, height: size + 4)
        indicatorLayer.cornerRadius = (size + 4) / 2
        indicatorLayer.borderWidth = 2
        indicatorLayer.borderColor = NSColor.systemOrange.cgColor
        indicatorLayer.opacity = 0.7

        layer.addSublayer(indicatorLayer)
    }

    // MARK: - 高亮层

    private func redrawHighlights() {
        // 清除旧高亮
        highlightsLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // 绘制可移动位置指示
        for position in validMoves {
            let highlightLayer = createValidMoveIndicator(at: position)
            highlightsLayer.addSublayer(highlightLayer)
        }
    }

    private func createValidMoveIndicator(at position: Position) -> CALayer {
        let screenPos = screenPosition(for: position)
        let indicatorSize = pieceSize * 0.3

        let layer = CALayer()
        layer.frame = CGRect(
            x: screenPos.x - indicatorSize / 2,
            y: screenPos.y - indicatorSize / 2,
            width: indicatorSize,
            height: indicatorSize
        )

        // 检查该位置是否有棋子（可以吃子）
        let hasPiece = pieces[position] != nil

        if hasPiece {
            // 吃子指示器（圆环）
            layer.borderWidth = 3
            layer.borderColor = boardTheme.validMoveColor.cgColor
            layer.cornerRadius = indicatorSize / 2
        } else {
            // 可移动位置指示器（圆点）
            layer.backgroundColor = boardTheme.validMoveColor.cgColor
            layer.cornerRadius = indicatorSize / 2
        }

        return layer
    }

    // MARK: - 将军提示

    private func updateCheckIndicator() {
        guard isKingInCheck, let checkPos = checkPosition else {
            checkIndicatorLayer.opacity = 0
            return
        }

        checkIndicatorLayer.opacity = 1

        // 清除旧内容
        checkIndicatorLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let screenPos = screenPosition(for: checkPos)
        let warningSize = pieceSize * 1.5

        // 创建脉冲警告圈
        let warningLayer = CALayer()
        warningLayer.frame = CGRect(
            x: screenPos.x - warningSize / 2,
            y: screenPos.y - warningSize / 2,
            width: warningSize,
            height: warningSize
        )
        warningLayer.backgroundColor = boardTheme.checkColor.cgColor
        warningLayer.cornerRadius = warningSize / 2
        warningLayer.opacity = 0.3

        // 脉冲动画
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.3
        pulseAnimation.duration = 0.5
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        warningLayer.add(pulseAnimation, forKey: "checkPulse")

        // 透明度动画
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.3
        opacityAnimation.toValue = 0.6
        opacityAnimation.duration = 0.5
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity
        warningLayer.add(opacityAnimation, forKey: "checkOpacity")

        checkIndicatorLayer.addSublayer(warningLayer)

        // 添加"将军"文字
        let textLayer = CATextLayer()
        textLayer.string = "将军!"
        textLayer.fontSize = 14
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = boardTheme.checkColor.cgColor
        textLayer.frame = CGRect(
            x: screenPos.x - 30,
            y: screenPos.y - pieceSize,
            width: 60,
            height: 20
        )

        // 文字闪烁动画
        let textBlinkAnimation = CABasicAnimation(keyPath: "opacity")
        textBlinkAnimation.fromValue = 1.0
        textBlinkAnimation.toValue = 0.3
        textBlinkAnimation.duration = 0.3
        textBlinkAnimation.autoreverses = true
        textBlinkAnimation.repeatCount = .infinity
        textLayer.add(textBlinkAnimation, forKey: "textBlink")

        checkIndicatorLayer.addSublayer(textLayer)
    }

    // MARK: - 手势处理

    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        let location = gesture.location(in: self)

        if let position = boardPosition(for: location) {
            delegate?.boardView(self, didSelectPosition: position)
        }
    }

    @objc func handleRightClick(_ gesture: NSClickGestureRecognizer) {
        delegate?.boardViewDidCancelSelection(self)
    }

    @objc func handleDoubleClick(_ gesture: NSClickGestureRecognizer) {
        delegate?.boardViewDidRequestUndo(self)
    }

    @objc func handlePan(_ gesture: NSPanGestureRecognizer) {
        // 拖拽移动棋子
        let location = gesture.location(in: self)

        switch gesture.state {
        case .began:
            // 开始拖拽
            if let position = boardPosition(for: location) {
                // 记录起始位置
                objc_setAssociatedObject(gesture, "dragStartPosition", position, .OBJC_ASSOCIATION_RETAIN)
            }

        case .ended:
            // 结束拖拽
            if let startPosition = objc_getAssociatedObject(gesture, "dragStartPosition") as? Position,
               let endPosition = boardPosition(for: location) {
                delegate?.boardView(self, didDragPieceFrom: startPosition, to: endPosition)
            }

        default:
            break
        }
    }

    @objc func handleMagnify(_ gesture: NSMagnificationGestureRecognizer) {
        let scale = 1.0 + gesture.magnification
        delegate?.boardView(self, didChangeZoomScale: CGFloat(scale))
    }

    // MARK: - 辅助方法

    /// 将棋盘坐标转换为屏幕坐标
    private func screenPosition(for position: Position) -> CGPoint {
        return CGPoint(
            x: boardOrigin.x + CGFloat(position.x) * cellSize,
            y: boardOrigin.y + CGFloat(9 - position.y) * cellSize  // 翻转Y轴
        )
    }

    /// 将屏幕坐标转换为棋盘坐标
    private func boardPosition(for screenPoint: CGPoint) -> Position? {
        let relativeX = screenPoint.x - boardOrigin.x
        let relativeY = screenPoint.y - boardOrigin.y

        let x = Int(round(relativeX / cellSize))
        let y = 9 - Int(round(relativeY / cellSize))  // 翻转Y轴

        let position = Position(x: x, y: y)
        return position.isValid() ? position : nil
    }
}

// MARK: - 颜色转换扩展

extension ColorComponents {
    var cgColor: CGColor {
        return nsColor.cgColor
    }

    var nsColor: NSColor {
        if #available(macOS 11.0, *) {
            return NSColor(
                red: red,
                green: green,
                blue: blue,
                alpha: opacity
            )
        } else {
            return NSColor(
                calibratedRed: red,
                green: green,
                blue: blue,
                alpha: opacity
            )
        }
    }
}
