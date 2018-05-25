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
    
    var playerTop: Player {
        didSet {
            delegate?.didUpdate(board: board)
        }
    }
    
    var playerBottom: Player {
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
    
    init(playerTop: Player, playerBottom: Player, board: Board = Board(), firstPlayer: Player) {
        self.playerTop = playerTop
        self.playerBottom = playerBottom
        self.currentTurn = Turn(player: firstPlayer)
        self.board = board
        self.playerTop.checkers = board.top
        self.playerBottom.checkers = board.bottom
        self.board.playableCheckers(for: currentTurn.player)
    }
    
    func takeTurn(action: TurnAction) {
        switch action {
        case .start(let moveAction):
            switch moveAction {
            case .select(let coordinate):
                guard let checker = board[coordinate].occupied, checker.side == currentTurn.player.side else { return }
                board.toggleAllSelected()
                board.toggleAllOccupiable()
                board.selectSpace(for: coordinate)
                board.availableMoves(for: checker)
            case .deselect:
                board.toggleAllSelected()
                board.toggleAllOccupiable()
            case .move(let coordinate):
                guard
                    let lastSelected = board.selected?.coordinate,
                    let checker = board[lastSelected].occupied
                    else { return }
                var message = "\(currentTurn.player.name) moves checker from \(lastSelected.description) to \(coordinate.description)"
                board.move(checker: checker, from: lastSelected, to: coordinate)
                if let jumpedChecker = board[coordinate].jumped {
                    board[jumpedChecker.currentCoordinate].occupied = nil
                    if currentTurn.player.side == playerTop.side {
                        playerTop.captured.append(jumpedChecker)
                    } else {
                        playerBottom.captured.append(jumpedChecker)
                    }
                    board[coordinate].jumped = nil
                    message = "\(currentTurn.player.name) jumped checker at \(jumpedChecker.currentCoordinate.description)"
                }
                board.toggleAllSelected()
                board.toggleAllOccupiable()
                print(message)
                currentTurn.playerMoves.append(board)
                takeTurn(action: .end)
            }
        case .end:
            board.toggleAllMoveable()
            let nextPlayer = currentTurn.player.side == playerBottom.side ? playerTop : playerBottom
            timeline.append(currentTurn)
            currentTurn = Turn(player: nextPlayer)
            board.playableCheckers(for: currentTurn.player)
        }
    }
    
}

struct Turn {
    
    var playerMoves: [Board] = []
    var player: Player
    
    init(player: Player) {
        self.player = player
    }
    
}
