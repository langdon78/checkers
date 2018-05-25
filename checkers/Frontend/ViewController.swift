import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var topCheckers: UICollectionView!
    @IBOutlet weak var bottomCheckers: UICollectionView!

    var game: Game! {
        didSet {
            refresh(board: game.board)
        }
    }
    
    @IBOutlet weak var boardView: UIView!
    
    var boardSize: Size {
        return Size(width: 40 * Board.length, height: 40 * Board.length)
    }
    
    override func viewDidLoad() {
        let player1 = Player(name: "James", side: .top)
        let player2 = Player(name: "Wendy", side: .bottom)
        game = Game(playerTop: player1, playerBottom: player2, firstPlayer: player2)
        game.delegate = self
    }
    
    func refresh(board: Board) {
        createBoard(board)
        topCheckers.reloadData()
        bottomCheckers.reloadData()
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
                let spaceView = SpaceView(space: space)
                spaceView.backgroundColor = space.playable ? .black : .red
                spaceView.addTarget(self, action: #selector(selectSpace), for: .touchUpInside)
                boardView.addSubview(spaceView)
                posX += 1
            }
            posY += 1
        }
    }
    
    @objc func selectSpace(_ spaceView: SpaceView) {
        if spaceView.space.highlightStatus == .occupiable {
            game.takeTurn(action: .start(.move(spaceView.coordinate)))
        } else if spaceView.space.highlightStatus == .selected {
            game.takeTurn(action: .start(.deselect(spaceView.coordinate)))
        } else {
            game.takeTurn(action: .start(.select(spaceView.coordinate)))
        }
    }
}

// MARK: GameDelegate methods
extension ViewController: GameDelegate {
    func didUpdate(board: Board) {
        refresh(board: board)
    }
}

// MARK: CollectionView data source
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === topCheckers {
            return game.playerTop.captured.count
        } else {
            return game.playerBottom.captured.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        var checker: Checker?
        if collectionView === topCheckers {
            checker = game.playerTop.captured[indexPath.row]
        } else {
            checker = game.playerBottom.captured[indexPath.row]
        }
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 25,y: 25), radius: CGFloat(12.5), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = checker?.side == .top ? UIColor.white.cgColor : UIColor.red.cgColor
        cell.layer.addSublayer(shapeLayer)
        return cell
    }
    
    
}
