import UIKit

class ViewController: UIViewController {

    var game: Game! {
        didSet {
            refresh()
        }
    }
    
    @IBOutlet weak var boardView: UIView!
    
    var boardSize: Size {
        return Size(width: 40 * Board.length, height: 40 * Board.length)
    }
    
    override func viewDidLoad() {
        let player1 = Player(name: "James", side: .top)
        let player2 = Player(name: "Wendy", side: .bottom)
        game = Game(playerTop: player1, playerBottom: player2)
        game.delegate = self
    }
    
    func refresh() {
        createBoard(game.board)
    }
    
    func createBoard(_ board: Board) {
        boardView.subviews.forEach {
            $0.removeFromSuperview()
        }
        boardView.layer.borderColor = UIColor.black.cgColor
        boardView.layer.borderWidth = 2
        var posY = 0
        for row in board.spaces {
            var posX = 0
            for space in row {
                let spaceView = SpaceView(coordinate: Coordinate(right: posX, down: posY), space: space)
                spaceView.backgroundColor = space.playable ? .black : .red
                spaceView.addTarget(self, action: #selector(selectSpace), for: .touchUpInside)
                boardView.addSubview(spaceView)
                posX += 1
            }
            posY += 1
        }
    }
    
    @objc func selectSpace(_ space: SpaceView) {
        if space.space.occupiable {
            game.board = game.takeTurn(action: .start(.move(space.coordinate)))
        } else if space.space.selected {
            game.board = game.takeTurn(action: .start(.deselect(space.coordinate)))
        } else {
            game.board = game.takeTurn(action: .start(.select(space.coordinate)))
        }
    }
}

// MARK: GameDelegate methods
extension ViewController: GameDelegate {
    func boardDidUpdate() {
        refresh()
    }
}
