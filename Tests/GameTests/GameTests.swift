import Foundation
import Testing
@testable import Game

// MARK: - Position Tests

@Test("Position creation and validation")
func testPositionCreation() {
    let pos = Position(x: 4, y: 5)
    #expect(pos.x == 4)
    #expect(pos.y == 5)
    #expect(pos.isValid == true)

    let invalidPos = Position(x: 10, y: 5)
    #expect(invalidPos.isValid == false)
}

@Test("Position distance calculation")
func testPositionDistance() {
    let pos1 = Position(x: 0, y: 0)
    let pos2 = Position(x: 3, y: 4)

    let (dx, dy) = pos1.distance(to: pos2)
    #expect(dx == 3)
    #expect(dy == 4)

    let manhattan = pos1.manhattanDistance(to: pos2)
    #expect(manhattan == 7)
}

@Test("Position palace check")
func testPositionPalace() {
    // 红方九宫格 (3-5, 0-2)
    let redKingPos = Position(x: 4, y: 0)
    #expect(redKingPos.isInPalace(for: .red) == true)

    let outsidePalace = Position(x: 0, y: 0)
    #expect(outsidePalace.isInPalace(for: .red) == false)
}

// MARK: - Piece Tests

@Test("Piece creation and properties")
func testPieceCreation() {
    let redKing = Piece(type: .king, player: .red)
    #expect(redKing.type == .king)
    #expect(redKing.player == .red)
    #expect(redKing.character == "帅")

    let blackKing = Piece(type: .king, player: .black)
    #expect(blackKing.character == "将")

    let redHorse = Piece(type: .horse, player: .red)
    #expect(redHorse.character == "傌")
}

@Test("Piece FEN character")
func testPieceFENCharacter() {
    let redRook = Piece(type: .rook, player: .red)
    #expect(redRook.fenCharacter == "R")

    let blackRook = Piece(type: .rook, player: .black)
    #expect(blackRook.fenCharacter == "r")

    let redKing = Piece(type: .king, player: .red)
    #expect(redKing.fenCharacter == "K")
}

// MARK: - Board Tests

@Test("Board creation and initialization")
func testBoardCreation() {
    let emptyBoard = Board.empty()
    #expect(emptyBoard.pieces(for: .red).count == 0)

    let initialBoard = Board.initial()
    #expect(initialBoard.pieces(for: .red).count == 16)
    #expect(initialBoard.pieces(for: .black).count == 16)
}

@Test("Board piece operations")
func testBoardPieceOperations() {
    var board = Board.empty()

    let pos = Position(x: 4, y: 0)
    let piece = Piece(type: .king, player: .red)

    // 放置棋子
    board.placePiece(piece, at: pos)
    #expect(board.piece(at: pos)?.type == .king)

    // 移动棋子
    let newPos = Position(x: 4, y: 1)
    board.movePiece(from: pos, to: newPos)
    #expect(board.piece(at: pos) == nil)
    #expect(board.piece(at: newPos)?.type == .king)

    // 移除棋子
    let removed = board.removePiece(at: newPos)
    #expect(removed?.type == .king)
    #expect(board.piece(at: newPos) == nil)
}

@Test("Board turn switching")
func testBoardTurnSwitching() {
    var board = Board.initial()
    #expect(board.currentPlayer == .red)

    board.switchTurn()
    #expect(board.currentPlayer == .black)

    board.switchTurn()
    #expect(board.currentPlayer == .red)
}

// MARK: - FEN Parser Tests

@Test("FEN parsing")
func testFENParsing() throws {
    let initialFEN = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1"

    let result = try FENParser.parse(initialFEN)

    #expect(result.currentPlayer == .red)
    #expect(result.halfMoveClock == 0)
    #expect(result.fullMoveNumber == 1)
    #expect(result.board.pieces(for: .red).count == 16)
    #expect(result.board.pieces(for: .black).count == 16)
}

@Test("FEN generation")
func testFENGeneration() {
    let board = Board.initial()
    let fen = FENParser.toFEN(board: board, halfMoveClock: 0, fullMoveNumber: 1)

    let expectedPrefix = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1"
    #expect(fen == expectedPrefix)
}

@Test("FEN round-trip")
func testFENRoundTrip() throws {
    let originalBoard = Board.initial()
    let fen = FENParser.toFEN(board: originalBoard)
    let result = try FENParser.parse(fen)

    // 验证棋子数量相同
    #expect(result.board.pieces(for: .red).count == originalBoard.pieces(for: .red).count)
    #expect(result.board.pieces(for: .black).count == originalBoard.pieces(for: .black).count)
}

// MARK: - Movement Rules Tests

@Test("King movement rules")
func testKingMovement() {
    var board = Board.empty()
    let kingPos = Position(x: 4, y: 0)
    board.placePiece(Piece(type: .king, player: .red), at: kingPos)

    // 在九宫格内的合法移动
    let legalMove = Position(x: 4, y: 1)
    let isLegal = MovementRules.isMoveLegal(
        piece: board.piece(at: kingPos)!,
        from: kingPos,
        to: legalMove,
        on: board
    )
    #expect(isLegal == true)

    // 九宫格外的非法移动
    let illegalMove = Position(x: 6, y: 0)
    let isIllegal = MovementRules.isMoveLegal(
        piece: board.piece(at: kingPos)!,
        from: kingPos,
        to: illegalMove,
        on: board
    )
    #expect(isIllegal == false)
}

@Test("Horse movement rules - basic and blocking")
func testHorseMovement() {
    var board = Board.empty()
    let horsePos = Position(x: 1, y: 0)
    board.placePiece(Piece(type: .horse, player: .red), at: horsePos)

    // 合法的"日"字移动
    let legalMove = Position(x: 2, y: 2)
    let isLegal = MovementRules.isMoveLegal(
        piece: board.piece(at: horsePos)!,
        from: horsePos,
        to: legalMove,
        on: board
    )
    #expect(isLegal == true)

    // 蹩马腿的情况
    let blockingPiece = Position(x: 1, y: 1)
    board.placePiece(Piece(type: .pawn, player: .red), at: blockingPiece)

    let isBlocked = MovementRules.isMoveLegal(
        piece: board.piece(at: horsePos)!,
        from: horsePos,
        to: legalMove,
        on: board
    )
    #expect(isBlocked == false)
}

// MARK: - Game Controller Tests

@Test("Game controller initialization")
func testGameControllerInit() {
    let game = GameController()

    #expect(game.currentPlayer == .red)
    #expect(game.canUndo == false)
    #expect(game.isGameEnded == false)
}

@Test("Game controller move execution")
func testGameControllerMove() {
    let game = GameController()

    let from = Position(x: 4, y: 3)  // 兵
    let to = Position(x: 4, y: 4)   // 前进一格

    let result = game.makeMove(from: from, to: to)

    #expect(result.isSuccess == true)
    #expect(game.currentPlayer == .black)  // 轮到黑方
    #expect(game.canUndo == true)
    #expect(game.lastMove != nil)
}

@Test("Game controller undo")
func testGameControllerUndo() {
    let game = GameController()

    // 先走一步
    let from = Position(x: 4, y: 3)
    let to = Position(x: 4, y: 4)
    _ = game.makeMove(from: from, to: to)

    // 悔棋
    let undoResult = game.undo()

    #expect(undoResult == true)
    #expect(game.currentPlayer == .red)  // 回到红方
    #expect(game.canUndo == false)
}

@Test("Game controller FEN export/import")
func testGameControllerFEN() {
    let game = GameController()

    // 导出初始FEN
    let initialFEN = game.currentFEN
    #expect(initialFEN.contains("rnbakabnr"))

    // 走一步
    _ = game.makeMove(from: Position(x: 4, y: 3), to: Position(x: 4, y: 4))

    // 导出新的FEN
    let newFEN = game.currentFEN
    #expect(newFEN != initialFEN)

    // 导入FEN
    let newGame = GameController()
    let loadResult = newGame.loadFromFEN(newFEN)
    #expect(loadResult == true)
}

@Test("Game controller position info")
func testGameControllerPositionInfo() {
    let game = GameController()
    let info = game.getPositionInfo()

    #expect(info.fen.contains("rnbakabnr"))
    #expect(info.currentPlayer == .red)
    #expect(info.moveCount == 0)
    #expect(info.isCheck == false)
}

@Test("Game controller UCI command generation")
func testGameControllerUCI() {
    let game = GameController()

    let uciCommand = game.generateUCIPositionCommand()
    #expect(uciCommand.hasPrefix("position fen"))

    // 走一步
    _ = game.makeMove(from: Position(x: 4, y: 3), to: Position(x: 4, y: 4))

    let newUCI = game.generateUCIPositionCommand()
    #expect(newUCI.contains("moves"))
}
