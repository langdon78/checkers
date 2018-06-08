import Foundation

protocol GameManagerDelegate: class {
    
    func gameStarted(board: Board)
    func gameOver(winner: CheckerPlayer, loser: CheckerPlayer)
    
}

protocol GameManagerBoardDelegate: class {
    
    func board(updatedAt spaces: [Space])
    func board(updated board: Board)

}

extension GameManagerDelegate {
    
    func board(updatedAt spaces: [Space]) {}
    func board(updated board: Board) {}
    
}

protocol GameManagerTurnDelegate: class {
    
    func messageLog(_ message: String)
    func turnAction(_ turnAction: TurnAction, for turn: Turn)
    func player(updated player: CheckerPlayer)
    
}

enum TurnAction {
    
    case start
    case select(Coordinate)
    case deselect(Coordinate)
    case move(Coordinate)
    case direcMove(Coordinate, Coordinate)
    case end

}

enum GameAction {
    
    case start
    case end(CheckerPlayer)
    
}

enum Side{
    
    case top
    case bottom
    
    var opposite: Side {
        return self == .top ? .bottom : .top
    }

}

protocol CheckerPlayer {
    var name: String { get set }
    var side: Side { get set }
    var ai: Bool { get set }
}

extension CheckerPlayer {
    
    func checkers(from board: Board) -> Int {
        return board.checkers(for: side).count
    }
    
    func captured(from board: Board) -> Int {
        return 12 - (board.checkers(for: side.opposite)).count
    }
    
}

struct DefaultPlayer: CheckerPlayer, Equatable {

    var name: String
    var side: Side
    var ai: Bool

}

struct Turn {
    
    var boardAtStartOfTurn: Board
    var boardAtEndOfTurn: Board?
    var player: CheckerPlayer
    var availableMoves: [Move]?
    
    init(player: CheckerPlayer, boardAtStartOfTurn: Board) {
        self.player = player
        self.boardAtStartOfTurn = boardAtStartOfTurn
    }
    
}

class GameManager {
    
    var timeline: [Turn] = []
    var currentTurn: Turn {
        didSet {
            checkGameOver()
        }
    }
    
    var playerOne: CheckerPlayer
    var playerTwo: CheckerPlayer
    
    var playerOneCapturedCount: Int {
        return playerOne.captured(from: board)
    }
    
    var playerTwoCapturedCount: Int {
        return playerTwo.captured(from: board)
    }
    
    private var board: Board {
        didSet {
            let spaces = oldValue.spaceDiff(for: board)
            boardDelegate?.board(updatedAt: spaces)
            boardDelegate?.board(updated: board)
        }
    }
    
    weak var boardDelegate: GameManagerBoardDelegate?
    weak var turnDelegate: GameManagerTurnDelegate?
    weak var gameDelegate: GameManagerDelegate?
    
    init(board: Board = Board(),
         player1: CheckerPlayer = DefaultPlayer(name: "Player1", side: .bottom, ai: false),
         player2: CheckerPlayer = DefaultPlayer(name: "Computer Jones", side: .top, ai: true)) {
        self.playerOne = player1
        self.playerTwo = player2
        self.board = board
        self.currentTurn = Turn(player: playerOne, boardAtStartOfTurn: board)
    }
    
    public func begin() {
        gameAction(with: .start)
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
    
    private func player(for side: Side) -> CheckerPlayer {
        return playerOne.side == side ? playerOne : playerTwo
    }
    
    private func checkGameOver() {
        if currentTurn.player.captured(from: board) == 12 {
            gameAction(with: .end(currentTurn.player))
        }
    }
    
    func takeTurn(action: TurnAction) {
        turnDelegate?.turnAction(action, for: currentTurn)
        switch action {
        case .start:
            startTurn()
        case .select(let coordinate):
            selectSpace(at: coordinate)
        case .deselect:
            deselectSelectedSpace()
        case .move(let coordinate):
            moveSelected(to: coordinate)
        case .direcMove(let current, let new):
            selectSpace(at: current)
            moveSelected(to: new)
        case .end:
            endTurn()
        }
    }
    
    private func clearHighlights() {
        board.toggleAllSelected()
        board.toggleAllOccupiable()
    }
    
    private func startTurn() {
        currentTurn.boardAtStartOfTurn = board
        board.playableCheckers(for: currentTurn.player)
        if currentTurn.player.ai {
            executeAI()
        }
    }
    
    private func executeAI() {
        var randomIndex = Int(arc4random_uniform(UInt32(board.moveable.count)))
        guard randomIndex >= 0 else { return }
        let moveable = board.moveable[randomIndex]
        takeTurn(action: .select(moveable.coordinate))
        guard let availableMoves = currentTurn.availableMoves else { return }
        randomIndex = Int(arc4random_uniform(UInt32(availableMoves.count)))
        let move = currentTurn.availableMoves?[randomIndex]
        guard let coordinate = move?.endingCoordinate else { return }
        takeTurn(action: .move(coordinate))
    }
    
    private func endTurn() {
        currentTurn.boardAtEndOfTurn = board
        board.toggleAllMoveable()
        timeline.append(currentTurn)
        let nextPlayer = currentTurn.player.side == playerTwo.side ? playerOne : playerTwo
        currentTurn = Turn(player: nextPlayer, boardAtStartOfTurn: board)
        takeTurn(action: .start)
    }
    
    private func selectSpace(at coordinate: Coordinate) {
        guard let checker = board[coordinate].occupied, checker.side == currentTurn.player.side else { return }
        clearHighlights()
        board.toggleAllMoveable()
        board.selectSpace(for: coordinate)
        currentTurn.availableMoves = board.availableMoves(for: checker)
    }
    
    private func deselectSelectedSpace() {
        clearHighlights()
        board.playableCheckers(for: currentTurn.player)
        currentTurn.availableMoves = nil
    }
    
    private func moveSelected(to coordinate: Coordinate) {
        guard let moves = currentTurn.availableMoves,
            let path = board.paths(for: moves, at: coordinate) else { return }
        
        for move in path.moves {
            guard
                let coordinate = move.endingCoordinate,
                let lastSelected = board.selected?.coordinate,
                let checker = board[lastSelected].occupied
                else { return }
            
            turnDelegate?.messageLog("\(currentTurn.player.name) moves checker from \(lastSelected.displayable) to \(coordinate.displayable)")
            board.move(checker: checker, from: lastSelected, to: coordinate)
            if case .jump(let checker) = move.movementType {
                handleJump(for: checker, to: coordinate)
            }
            evaluateEndTurn(for: move)
        }
    }
    
    private func handleJump(for checker: Checker, to coordinate: Coordinate) {
        turnDelegate?.player(updated: player(for: checker.side))
        board[checker.currentCoordinate].occupied = nil
        board.selectSpace(for: coordinate)
        turnDelegate?.messageLog("\(currentTurn.player.name) jumped \(currentTurn.player.side == playerOne.side ? playerTwo.name : playerOne.name) at \(checker.currentCoordinate.displayable)")
    }
    
    private func evaluateEndTurn(for move: Move) {
        if board.occupiableByJump.isEmpty || move.movementType == .normal {
            clearHighlights()
            takeTurn(action: .end)
        } else {
            board.toggleAllOccupiable()
            guard let newSelected = board.selected?.coordinate, let checker = board[newSelected].occupied else { return }
            currentTurn.availableMoves = board.availableMoves(for: checker, continueJump: true)
        }
    }
    
}
