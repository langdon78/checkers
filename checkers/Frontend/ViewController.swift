import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var topCheckers: UICollectionView!
    @IBOutlet weak var bottomCheckers: UICollectionView!
    @IBOutlet weak var player1Label: UILabel!
    @IBOutlet weak var player2Label: UILabel!
    @IBOutlet weak var messageTableView: UITableView!
    
    var game: GameManager!
    var messageQueue: [String] = [] {
        didSet {
            messageTableView.reloadData()
            messageTableView.scrollToRow(at: IndexPath(row: messageQueue.count-1, section: 0), at: .bottom, animated: true)
        }
    }
    
    @IBOutlet weak var boardView: UIView!
    
    var boardSize: Size {
        return Size(width: 40 * Board.length, height: 40 * Board.length)
    }
    
    override func viewDidLoad() {
        let gameConfig = GameConfig(player1Name: "James", player1Side: .top, player2Name: "Wendy", player2Side: .bottom, firstTurn: .top)
        game = GameManager(gameConfig: gameConfig)
        player1Label.text = game.playerOne.name
        player2Label.text = game.playerTwo.name
        setDelegates()
        game.begin()
    }
    
    func setDelegates() {
        game.boardDelegate = self
        game.gameDelegate = self
        game.turnDelegate = self
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
                let spaceView = self.spaceView(for: space)
                boardView.addSubview(spaceView)
                posX += 1
            }
            posY += 1
        }
    }
    
    private func spaceView(for space: Space) -> SpaceView {
        let spaceView = SpaceView(space: space)
        spaceView.backgroundColor = space.playable ? .black : .red
        spaceView.addTarget(self, action: #selector(selectSpace), for: .touchUpInside)
        spaceView.tag = space.uniqueLocationKey
        return spaceView
    }
    
    private func updateBoard(for spaces: [Space]) {
        for space in spaces {
            let spaceView = self.spaceView(for: space)
            if let oldView = boardView.subviews.first(where: {$0.tag == space.coordinate.hashValue}) {
                boardView.insertSubview(spaceView, aboveSubview: oldView)
                oldView.removeFromSuperview()
            }
        }
    }
    
    @objc func selectSpace(_ spaceView: SpaceView) {
        switch spaceView.space.highlightStatus {
        case .occupiable,.occupiableByJump:
            game.takeTurn(action: .move(spaceView.coordinate))
        case .selected:
            game.takeTurn(action: .deselect(spaceView.coordinate))
        default:
            game.takeTurn(action: .select(spaceView.coordinate))
        }
    }
}

// MARK: Board delegate methods

extension ViewController: GameManagerBoardDelegate {
    
    func board(updatedAt spaces: [Space]) {
        updateBoard(for: spaces)
    }
    
    func board(updatedWith message: String) {
        print(message)
    }

}

// MARK: Game delegate methods

extension ViewController: GameManagerDelegate {
    
    func gameStarted(board: Board) {
        createBoard(board)
    }
    
    func gameOver(winner: Player, loser: Player) {
        print("\(winner.name) Wins!!")
        let alert = UIAlertController(title: "Game Over", message: "\(winner.name) Wins!!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Play Again?", style: .default, handler: { [weak self] alert in
            self?.game = self?.game.newGame()
            self?.setDelegates()
            self?.game.begin()
            self?.topCheckers.reloadData()
            self?.bottomCheckers.reloadData()
            self?.messageQueue.removeAll()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK: Turn delegate methods

extension ViewController: GameManagerTurnDelegate {
    
    func messageLog(_ message: String) {
        messageQueue.append(message)
    }
    
    func turnAction(_ turnAction: TurnAction, for: Turn) {
        print(turnAction)
    }
    
    func player(updated player: Player) {
        topCheckers.reloadData()
        bottomCheckers.reloadData()
    }
    
}

// MARK: - CollectionView data source
extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === topCheckers {
            return game.playerOne.captured.count
        } else {
            return game.playerTwo.captured.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        var checker: Checker?
        if collectionView === topCheckers {
            checker = game.playerOne.captured[indexPath.row]
        } else {
            checker = game.playerTwo.captured[indexPath.row]
        }
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 25,y: 25), radius: CGFloat(12.5), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = checker?.side == .top ? UIColor.white.cgColor : UIColor.red.cgColor
        cell.layer.addSublayer(shapeLayer)
        return cell
    }
    
}

// MARK: - Table View data source
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageQueue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = messageQueue[indexPath.row]
        return cell
    }
    
}
