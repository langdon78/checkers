import Foundation

protocol GameDelegate: class {
    func boardDidUpdate()
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

class Game {
    var timeline: [Turn] = []
    var currentTurn: Turn
    
    var playerTop: Player
    var playerBottom: Player
    var board: Board {
        didSet {
            delegate?.boardDidUpdate()
        }
    }
    
    weak var delegate: GameDelegate?
    
    init(playerTop: Player, playerBottom: Player) {
        self.playerTop = playerTop
        self.playerBottom = playerBottom
        self.currentTurn = Turn(player: playerBottom)
        
        self.board = Board()

        self.playerTop.checkers = board.top
        self.playerBottom.checkers = board.bottom
        board.layoutCheckers()
        findPlayableCheckers(for: currentTurn.player)
    }
    
    func takeTurn(action: TurnAction) -> Board {
        switch action {
        case .start(let moveAction):
            switch moveAction {
            case .select(let coordinate):
                guard let checker = board[coordinate].occupied, checker.side == currentTurn.player.side else { return board }
                board.toggleAllSelected()
                board.toggleAllOccupiable()
                board.selectSpace(for: coordinate)
                board.availableMoves(for: checker)
            case .deselect(let coordinate):
                board.selectSpace(for: coordinate)
                board.toggleAllOccupiable()
                findPlayableCheckers(for: currentTurn.player)
            case .move(let coordinate):
                guard
                    let lastSelected = board.selected?.coordinate,
                    let checker = board[lastSelected].occupied
                    else { return board }
                board.move(checker: checker, from: lastSelected, to: coordinate)
                if let jumpedChecker = board[coordinate].jumped {
                    board[jumpedChecker.currentCoordinate].occupied = nil
                }
                board = takeTurn(action: .start(.deselect(lastSelected)))
                board = takeTurn(action: .end)
            }
        case .end:
            board.toggleAllMoveable()
            let nextPlayer = currentTurn.player == playerBottom ? playerTop : playerBottom
            timeline.append(currentTurn)
            currentTurn = Turn(player: nextPlayer)
            findPlayableCheckers(for: currentTurn.player)
        }
        return board
    }
    
    //TODO: Move to Navigator and fix when near opposing checker
    func findPlayableCheckers(for player: Player) {
        let playerCheckers = board.checkers(for: currentTurn.player.side)
        for checker in playerCheckers {
            Direction.all.forEach { direction in
                let move = Navigator.move(for: direction, numberOfSpaces: 1)
                let coordinate = Navigator.coordinate(from: checker.currentCoordinate, with: move)
                if board[coordinate].occupied == nil, !board.moveable.contains(board[checker.currentCoordinate]) {
                    board[checker.currentCoordinate].moveable.toggle()
                }
            }
        }
    }
}

struct Turn {
    var playerMoves: [MoveAction] = []
    var lastPlayerMove: MoveAction? {
        return playerMoves.last
    }
    var player: Player
    
    init(player: Player) {
        self.player = player
    }
}
