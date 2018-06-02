import Foundation

protocol GameManagerDelegate: class {
    
    func gameStarted()
    func gameOver(winner: Player, loser: Player)
    
}

protocol GameManagerBoardDelegate: class {
    
    func board(updated board: Board)
    func board(updatedAt spaces: [Space])

}

extension GameManagerBoardDelegate {
    
    func board(updated board: Board) {}
    func board(updatedAt spaces: [Space]) {}
    
}

protocol GameManagerTurnDelegate: class {
    
    func messageLog(_ message: String)
    func turnAction(_ turnAction: TurnAction)
    
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
    
    init(name: String, side: Side) {
        self.name = name
        self.side = side
    }
    
}

class GameManager {
    
    var timeline: [Turn] = []
    var currentTurn: Turn {
        didSet {
            if currentTurn.player.captured.count == 12 {
                gameAction(with: .end(currentTurn.player))
            }
        }
    }
    
    var playerOne: Player {
        didSet {
            boardDelegate?.board(updated: board)
        }
    }
    
    var playerTwo: Player {
        didSet {
            boardDelegate?.board(updated: board)
        }
    }
    
    var board: Board {
        didSet {
            let spaces = oldValue.spaceDiff(for: board)
            boardDelegate?.board(updatedAt: spaces)
//            delegate?.board(updated: board)
        }
    }
    
    weak var boardDelegate: GameManagerBoardDelegate?
    weak var turnDelegate: GameManagerTurnDelegate?
    weak var gameDelegate: GameManagerDelegate?
    
    init(playerOne: Player, playerTwo: Player, board: Board = Board(), firstPlayer: Player) {
        self.playerOne = playerOne
        self.playerTwo = playerTwo
        self.board = board
        self.currentTurn = Turn(player: firstPlayer, boardAtStartOfTurn: board)
    }
    
    func gameAction(with gameAction: GameAction) {
        switch gameAction {
        case .start:
            self.playerOne.checkers = playerOne.side == .top ? board.top : board.bottom
            self.playerTwo.checkers = playerTwo.side == .top ? board.top : board.bottom
            self.board.playableCheckers(for: currentTurn.player)
            gameDelegate?.gameStarted()
        case .end(let winner):
            let loser = playerOne.side == winner.side ? playerOne : playerTwo
            gameDelegate?.gameOver(winner: winner, loser: loser)
        }
    }
    
    func takeTurn(action: TurnAction) {
        turnDelegate?.turnAction(action)
        
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
                print("\(currentTurn.player.name) moves checker from \(lastSelected.description) to \(coordinate.description)")
                
                board.move(checker: checker, from: lastSelected, to: coordinate)
                if case .jump(let checker) = move.movementType {
                    if currentTurn.player.side == playerOne.side {
                        playerOne.captured.append(checker)
                    } else {
                        playerTwo.captured.append(checker)
                    }
                    
                    board[checker.currentCoordinate].occupied = nil
                    board.selectSpace(for: coordinate)
                    print("\(currentTurn.player.name) jumped checker at \(checker.currentCoordinate.description)")
                }
                
                if board.occupiableByJump.isEmpty {
                    clearHighlights()
                    takeTurn(action: .end)
                }
            }
        case .end:
            currentTurn.boardAtEndOfTurn = board
            board.toggleAllMoveable()
            timeline.append(currentTurn)
            let nextPlayer = currentTurn.player.side == playerTwo.side ? playerOne : playerTwo
            currentTurn = Turn(player: nextPlayer, boardAtStartOfTurn: board)
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
