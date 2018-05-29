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
                clearHighlights()
                board.selectSpace(for: coordinate)
                currentTurn.availableMoves = board.availableMoves(for: checker)
                print(currentTurn.availableMoves)
            case .deselect:
                clearHighlights()
                currentTurn.availableMoves = nil
            case .move(let coordinate):
                let moves = currentTurn.availableMoves?.selectPath(with: coordinate).reversed()
                
                for move in moves! {
                    let coordinate = move.startingCoordinate
                    guard
                        let lastSelected = board.selected?.coordinate,
                        let checker = board[lastSelected].occupied
                        else { return }
                    print("\(currentTurn.player.name) moves checker from \(lastSelected.description) to \(coordinate.description)")
                    
                    board.move(checker: checker, from: lastSelected, to: coordinate)
                    
                    if board[coordinate].highlightStatus == .occupiableByJump {
                        let jumpableCheckers = Navigator.jumpedCheckers(for: lastSelected, to: coordinate, on: board)
                        jumpableCheckers.forEach { jumpedChecker in
                            board[jumpedChecker.currentCoordinate].occupied = nil
                            if currentTurn.player.side == playerTop.side {
                                playerTop.captured.append(jumpedChecker)
                            } else {
                                playerBottom.captured.append(jumpedChecker)
                            }
                            board.selectSpace(for: coordinate)
                            print("\(currentTurn.player.name) jumped checker at \(jumpedChecker.currentCoordinate.description)")
                        }
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
            let nextPlayer = currentTurn.player.side == playerBottom.side ? playerTop : playerBottom
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
    var availableMoves: Path?
    
    init(player: Player) {
        self.player = player
    }
    
}
