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
            if messageQueue.count > 0 {
                messageTableView.scrollToRow(at: IndexPath(row: messageQueue.count-1, section: 0), at: .bottom, animated: true)
            }
        }
    }
    
    @IBOutlet weak var boardView: UIView!
    
    var boardSize: Size {
        return Size(width: 40 * Board.length, height: 40 * Board.length)
    }
    
    override func viewDidLoad() {
        startGame()
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
        let topRow = Coordinate.AlphaCoordinate().values
        topRow.enumerated().forEach { (index, letter) in
            boardView.addSubview(CoordinateLabelView(coordinateLabelText: letter, col: index+1, row: 0))
        }
        boardView.backgroundColor = .clear
        
        for row in board.spaces {
            for space in row {
                let rowLabel = String(space.coordinate.down+1)
                let coordinateView = CoordinateLabelView(coordinateLabelText: rowLabel, col: 0, row: space.coordinate.down+1)
                boardView.addSubview(coordinateView)
                let spaceView = self.spaceView(for: space)
                boardView.addSubview(spaceView)
            }
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
    
    private func startGame() {
        player1Label.text = game.playerOne.name
        player2Label.text = game.playerTwo.name
        setDelegates()
        game.begin()
        topCheckers.reloadData()
        bottomCheckers.reloadData()
        messageQueue.removeAll()
    }
    
    private func restartGame() {
        game = GameManager()
        startGame()
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
    
    func gameOver(winner: CheckerPlayer, loser: CheckerPlayer) {
        print("\(winner.name) Wins!!")
        let alert = UIAlertController(title: "Game Over", message: "\(winner.name) Wins!!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Play Again?", style: .default, handler: { [weak self] alert in
            self?.restartGame()

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
    
    func player(updated player: CheckerPlayer) {
        topCheckers.reloadData()
        bottomCheckers.reloadData()
    }
    
}

// MARK: - CollectionView data source
extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === topCheckers {
            return game.playerOneCapturedCount
        } else {
            return game.playerTwoCapturedCount
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 25,y: 25), radius: CGFloat(12.5), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = checkerColor(for: collectionView, player1Side: game.playerOne.side)
        cell.layer.addSublayer(shapeLayer)
        return cell
    }
    
    private func checkerColor(for collectionView: UICollectionView, player1Side: Side) -> CGColor {
        switch (collectionView, player1Side) {
        case (topCheckers, .top): return UIColor.red.cgColor
        case (topCheckers, .bottom): return UIColor.white.cgColor
        case (bottomCheckers, .top): return UIColor.white.cgColor
        case (bottomCheckers, .bottom): return UIColor.red.cgColor
        default: return UIColor.black.cgColor
        }
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
        cell.textLabel?.numberOfLines = 3
        cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        return cell
    }
    
}
