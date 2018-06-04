import Foundation

protocol GameManagerDelegate: class {
    
    func gameStarted(board: Board)
    func gameOver(winner: Player, loser: Player)
    
}

protocol GameManagerBoardDelegate: class {
    
    func board(updatedAt spaces: [Space])

}

protocol GameManagerTurnDelegate: class {
    
    func messageLog(_ message: String)
    func turnAction(_ turnAction: TurnAction, for turn: Turn)
    func player(updated player: Player)
    
}

enum TurnAction {
    
    case start
    case select(Coordinate)
    case deselect(Coordinate)
    case move(Coordinate)
    case end

}

enum GameAction {
    
    case start
    case end(Player)
    
}

enum Side {
    
    case top
    case bottom

}

struct Player: Equatable {
    
    var name: String
    var side: Side
    var checkers: [Checker] = []
    var captured: [Checker] = []
    
    init(name: String, side: Side, board: Board) {
        self.name = name
        self.side = side
        self.checkers = board.checkers(for: side)
    }
    
}

struct GameConfig {
    
    var player1Name: String
    var player1Side: Side
    var player2Name: String
    var player2Side: Side
    var firstTurn: Side
    
}

class GameManager {
    
    var timeline: [Turn] = []
    var currentTurn: Turn {
        didSet {
            updateCapturedList()
            checkGameOver()
        }
    }
    
    var playerOne: Player {
        didSet {
            turnDelegate?.player(updated: playerOne)
        }
    }

    var playerTwo: Player {
        didSet {
            turnDelegate?.player(updated: playerTwo)
        }
    }
    
    private var board: Board {
        didSet {
            let spaces = oldValue.spaceDiff(for: board)
            boardDelegate?.board(updatedAt: spaces)
        }
    }
    
    weak var boardDelegate: GameManagerBoardDelegate?
    weak var turnDelegate: GameManagerTurnDelegate?
    weak var gameDelegate: GameManagerDelegate?
    
    init(gameConfig: GameConfig, board: Board = Board()) {
        self.playerOne = Player(name: gameConfig.player1Name, side: gameConfig.player1Side, board: board)
        self.playerTwo = Player(name: gameConfig.player2Name, side: gameConfig.player2Side, board: board)
        self.board = board
        self.currentTurn = Turn(player: playerOne.side == gameConfig.firstTurn ? playerOne : playerTwo, boardAtStartOfTurn: board)
    }
    
    public func begin() {
        gameAction(with: .start)
    }
    
    public func newGame() -> GameManager {
        let gameConfig = GameConfig(player1Name: playerOne.name, player1Side: playerOne.side, player2Name: playerTwo.name, player2Side: playerTwo.side, firstTurn: .top)
        return GameManager(gameConfig: gameConfig)
    }
    
    private func gameAction(with gameAction: GameAction) {
        switch gameAction {
        case .start:
            self.board.playableCheckers(for: currentTurn.player)
            gameDelegate?.gameStarted(board: board)
        case .end(let winner):
            let loser = playerOne.side == winner.side ? playerOne : playerTwo
            gameDelegate?.gameOver(winner: winner, loser: loser)
        }
    }
    
    private func player(for side: Side) -> Player {
        return playerOne.side == side ? playerOne : playerTwo
    }
    
    private func checkGameOver() {
        if currentTurn.player.captured.count == 12 {
            gameAction(with: .end(currentTurn.player))
        }
    }
    
    private func updateCapturedList() {
        if currentTurn.player.side == playerOne.side {
            playerOne.captured = currentTurn.player.captured
        } else {
            playerTwo.captured = currentTurn.player.captured
        }
    }
    
    func takeTurn(action: TurnAction) {
        turnDelegate?.turnAction(action, for: currentTurn)
        
        switch action {
        case .start:
            currentTurn.boardAtStartOfTurn = board
            board.playableCheckers(for: currentTurn.player)
        case .select(let coordinate):
            guard let checker = board[coordinate].occupied, checker.side == currentTurn.player.side else { return }
            clearHighlights()
            board.selectSpace(for: coordinate)
            currentTurn.availableMoves = board.availableMoves(for: checker)
        case .deselect:
            clearHighlights()
            currentTurn.availableMoves = nil
        case .move(let coordinate):
            guard let moves = currentTurn.availableMoves else { return }
            let paths = Navigator.findPaths(for: moves)
            guard let path = paths.first(where: { $0.match(with: coordinate) }) else { return }
            
            for move in path.moves {
                guard
                    let coordinate = move.endingCoordinate,
                    let lastSelected = board.selected?.coordinate,
                    let checker = board[lastSelected].occupied
                    else { return }
                turnDelegate?.messageLog("\(currentTurn.player.name) moves checker from \(lastSelected.displayable) to \(coordinate.displayable)")
                
                board.move(checker: checker, from: lastSelected, to: coordinate)
                // TODO: Update checkers; change win criteria to checkers.count == 0
                if board[coordinate].occupied?.isKing == true {
                    if currentTurn.player == playerOne {
                        playerTwo.captured.removeLast()
                    } else {
                        playerOne.captured.removeLast()
                    }
                }
                if case .jump(let checker) = move.movementType {
                    currentTurn.player.captured.append(checker)
                    board[checker.currentCoordinate].occupied = nil
                    board.selectSpace(for: coordinate)
                    turnDelegate?.messageLog("\(currentTurn.player.name) jumped checker at \(checker.currentCoordinate.displayable)")
                }
                
                if board.occupiableByJump.isEmpty || move.movementType == .normal {
                    clearHighlights()
                    takeTurn(action: .end)
                } else {
                    board.toggleAllOccupiable()
                    guard let newSelected = board.selected?.coordinate, let checker = board[newSelected].occupied else { return }
                    currentTurn.availableMoves = board.availableMoves(for: checker, continueJump: true)
                }
            }
        case .end:
            currentTurn.boardAtEndOfTurn = board
            board.toggleAllMoveable()
            timeline.append(currentTurn)
            let nextPlayer = currentTurn.player.side == playerTwo.side ? playerOne : playerTwo
            currentTurn = Turn(player: nextPlayer, boardAtStartOfTurn: board)
            takeTurn(action: .start)
        }
    }
    
    private func clearHighlights() {
        board.toggleAllSelected()
        board.toggleAllOccupiable()
    }
    
}

struct Turn {
    
    var boardAtStartOfTurn: Board
    var boardAtEndOfTurn: Board?
    var player: Player
    var availableMoves: [Move]?
    
    init(player: Player, boardAtStartOfTurn: Board) {
        self.player = player
        self.boardAtStartOfTurn = boardAtStartOfTurn
    }
    
}
