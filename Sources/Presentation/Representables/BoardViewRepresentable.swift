import SwiftUI
import AppKit

// MARK: - BoardViewRepresentable

/// NSViewRepresentable 包装器，桥接 SwiftUI 和 AppKit BoardNSView
/// 处理手势转发（点击、拖拽）
struct BoardViewRepresentable: NSViewRepresentable {

    @Bindable var viewModel: BoardViewModel
    var boardTheme: BoardThemeConfig
    var pieceTheme: PieceThemeConfig
    var isDarkMode: Bool = false

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> BoardNSView {
        let boardView = BoardNSView()
        boardView.delegate = context.coordinator
        boardView.boardTheme = boardTheme
        boardView.pieceTheme = pieceTheme
        boardView.isDarkMode = isDarkMode

        // 配置手势识别
        setupGestures(for: boardView)

        return boardView
    }

    func updateNSView(_ nsView: BoardNSView, context: Context) {
        // 更新视图模型引用
        context.coordinator.viewModel = viewModel

        // 更新主题
        nsView.boardTheme = boardTheme
        nsView.pieceTheme = pieceTheme
        nsView.isDarkMode = isDarkMode

        // 更新棋盘状态
        nsView.updateBoardState(
            pieces: viewModel.pieces,
            selectedPosition: viewModel.selectedPosition,
            validMoves: viewModel.validMoves,
            lastMove: viewModel.lastMove,
            isKingInCheck: viewModel.isKingInCheck,
            checkPosition: viewModel.checkPosition
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - 手势配置

    private func setupGestures(for boardView: BoardNSView) {
        // 点击手势（选子/移动）
        let clickGesture = NSClickGestureRecognizer(target: boardView, action: #selector(BoardNSView.handleClick(_:)))
        clickGesture.buttonMask = 1 // 左键
        boardView.addGestureRecognizer(clickGesture)

        // 右键取消选择
        let rightClickGesture = NSClickGestureRecognizer(target: boardView, action: #selector(BoardNSView.handleRightClick(_:)))
        rightClickGesture.buttonMask = 2 // 右键
        boardView.addGestureRecognizer(rightClickGesture)

        // 拖拽手势
        let panGesture = NSPanGestureRecognizer(target: boardView, action: #selector(BoardNSView.handlePan(_:)))
        boardView.addGestureRecognizer(panGesture)

        // 双击悔棋
        let doubleClickGesture = NSClickGestureRecognizer(target: boardView, action: #selector(BoardNSView.handleDoubleClick(_:)))
        doubleClickGesture.numberOfClicksRequired = 2
        boardView.addGestureRecognizer(doubleClickGesture)

        // 捏合缩放
        let magnifyGesture = NSMagnificationGestureRecognizer(target: boardView, action: #selector(BoardNSView.handleMagnify(_:)))
        boardView.addGestureRecognizer(magnifyGesture)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, BoardNSViewDelegate {
        var viewModel: BoardViewModel

        init(viewModel: BoardViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - BoardNSViewDelegate

        func boardView(_ boardView: BoardNSView, didSelectPosition position: Position) {
            viewModel.selectPosition(position)
        }

        func boardView(_ boardView: BoardNSView, didDragPieceFrom from: Position, to: Position) {
            viewModel.handleDrag(from: from, to: to)
        }

        func boardViewDidCancelSelection(_ boardView: BoardNSView) {
            viewModel.clearSelection()
        }

        func boardViewDidRequestUndo(_ boardView: BoardNSView) {
            viewModel.undoMove()
        }

        func boardView(_ boardView: BoardNSView, didChangeZoomScale scale: CGFloat) {
            viewModel.setZoomScale(scale)
        }
    }
}

// MARK: - BoardNSViewDelegate

/// BoardNSView 的委托协议
protocol BoardNSViewDelegate: AnyObject {
    func boardView(_ boardView: BoardNSView, didSelectPosition position: Position)
    func boardView(_ boardView: BoardNSView, didDragPieceFrom from: Position, to: Position)
    func boardViewDidCancelSelection(_ boardView: BoardNSView)
    func boardViewDidRequestUndo(_ boardView: BoardNSView)
    func boardView(_ boardView: BoardNSView, didChangeZoomScale scale: CGFloat)
}
