import Foundation

protocol GameDelegate: class {
    func boardDidUpdate()
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
        board = Board.layoutCheckers(for: board)
        findPlayableCheckers(for: currentTurn.player)
    }
    
    func takeTurn(action: TurnAction) -> Board {
        switch action {
        case .start(let moveAction):
            switch moveAction {
            case .select(let coordinate):
                board = Board.toggleAllSelected(on: board)
                board = Board.toggleAllOccupiable(on: board)
                board = Board.selectSpace(for: coordinate, on: board)
                findMoveableSpaces(for: coordinate)
            case .deselect(let coordinate):
                board = Board.toggleAllOccupiable(on: board)
                findPlayableCheckers(for: currentTurn.player)
                board = Board.selectSpace(for: coordinate, on: board)
            case .move(let coordinate):
                print("moved")
                guard
                    let lastSelected = board.selected?.coordinate,
                    let checker = board[lastSelected].occupied
                    else { return board }
                board = Board.move(checker: checker, on: board, from: lastSelected, to: coordinate)
//
//                checker.move(to: coordinate)
//                board.place(checker)
//                currentTurn.playerMoves.append(moveAction)
//                board.toggleSpaceSelection(for: lastSelected)
//                board = Board.toggleAllOccupiable(on: board)
//                findPlayableCheckers(for: currentTurn.player)
            }
        case .end:
            let nextPlayer = currentTurn.player == playerBottom ? playerTop : playerBottom
            timeline.append(currentTurn)
            currentTurn = Turn(player: nextPlayer)
        }
        return board
    }
    
    func findPlayableCheckers(for player: Player) {
        for checker in board.checkers(for: currentTurn.player.side) {
            Direction.all.forEach { direction in
                let move = Navigator.getMove(direction: direction, numberOfSpaces: 1)
                let coordinate = Navigator.moved(from: checker.currentCoordinate, with: move)
                if board[coordinate].occupied == nil, !board.moveable.contains(board[checker.currentCoordinate]) {
                    board = Board.update(board: board, with: .showMoveable(checker.currentCoordinate))
                }
            }
        }
    }
    
    func findMoveableSpaces(for selectedCoordinate: Coordinate) {
        Direction.all.forEach { direction in
            let move = Navigator.getMove(direction: direction, numberOfSpaces: 1)
            let coordinate = Navigator.moved(from: selectedCoordinate, with: move)
            if board[coordinate].occupied == nil {
                board = Board.update(board: board, with: .showOccupiable(coordinate))
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
