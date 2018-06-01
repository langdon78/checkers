import Foundation

protocol GameDelegate: class {
    
    func didUpdate(board: Board)

}

enum TurnAction {
    
    case start(MoveAction)
    case end

}

enum MoveAction {
    
    case select(Coordinate)
    case deselect(Coordinate)
    case move(Coordinate)

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

class Game {
    
    var timeline: [Turn] = []
    var currentTurn: Turn
    
    var playerOne: Player {
        didSet {
            delegate?.didUpdate(board: board)
        }
    }
    
    var playerTwo: Player {
        didSet {
            delegate?.didUpdate(board: board)
        }
    }
    
    var board: Board {
        didSet {
            delegate?.didUpdate(board: board)
        }
    }
    
    weak var delegate: GameDelegate?
    
    init(playerOne: Player, playerTwo: Player, board: Board = Board(), firstPlayer: Player) {
        self.playerOne = playerOne
        self.playerTwo = playerTwo
        self.currentTurn = Turn(player: firstPlayer)
        self.board = board
        self.playerOne.checkers = board.top
        self.playerTwo.checkers = board.bottom
        self.board.playableCheckers(for: currentTurn.player)
    }
    
    func takeTurn(action: TurnAction) {
        switch action {
        case .start(let moveAction):
            switch moveAction {
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
                    
                    currentTurn.playerMoves.append(board)
                    if board.occupiableByJump.isEmpty {
                        clearHighlights()
                        takeTurn(action: .end)
                    }
                }
  
            }
        case .end:
            board.toggleAllMoveable()
            let nextPlayer = currentTurn.player.side == playerTwo.side ? playerOne : playerTwo
            timeline.append(currentTurn)
            currentTurn = Turn(player: nextPlayer)
            board.playableCheckers(for: currentTurn.player)
        }
    }
    
    private func clearHighlights() {
        board.toggleAllSelected()
        board.toggleAllOccupiable()
    }
    
}

struct Turn {
    
    var playerMoves: [Board] = []
    var player: Player
    var availableMoves: [Move]?
    
    init(player: Player) {
        self.player = player
    }
    
}
