import UIKit

struct Player: CheckerPlayer {
    var name: String
    var side: Side
    var ai: Bool
}

class SettingsViewController: UIViewController {

    @IBOutlet weak var tfPlayerOneName: UITextField!
    @IBOutlet weak var tfPlayerTwoName: UITextField!
    @IBOutlet weak var segSide: UISegmentedControl!
    @IBOutlet weak var swComputer: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func startGame() -> GameManager {
        guard let playerOneName = tfPlayerOneName.text else { return GameManager() }
        let side: Side = segSide.selectedSegmentIndex == 0 ? .top : .bottom
        let player1 = Player(name: playerOneName, side: side, ai: false)
        if let playerTwoName = tfPlayerTwoName.text, !playerTwoName.isEmpty {
            return GameManager(player1: player1, player2: Player(name: playerTwoName, side: side.opposite, ai: !swComputer.isOn))
        }
        return GameManager(player1: player1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gameView = segue.destination as? ViewController {
            gameView.game = startGame()
        }
    }
}
