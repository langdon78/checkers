import UIKit

struct Size {
    var width: Int
    var height: Int
}

class SpaceView: UIButton {
    var space: Space
    var coordinate: Coordinate {
        return space.coordinate
    }
    lazy var label: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 20, height: 10))
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 6.0)
        label.text = String.empty
        return label
    }()
    
    init(space: Space) {
        self.space = space
        super.init(frame: CGRect(x: space.coordinate.right * 40, y: space.coordinate.down * 40, width: 40, height: 40))

        
        if space.moveable || space.highlightStatus == .occupiable || space.highlightStatus == .selected {
            label.text = coordinate.description
            self.layer.borderColor = UIColor.white.cgColor
            self.layer.borderWidth = 1
            if space.highlightStatus == .selected {
                self.layer.borderColor = UIColor.green.cgColor
                self.layer.borderWidth = 1
            } else if space.highlightStatus == .occupiable {
                self.layer.borderColor = UIColor.blue.cgColor
                self.layer.borderWidth = 1
            } else {
                self.layer.borderColor = UIColor.white.cgColor
            }
        } else {
            self.layer.borderWidth = 0
        }
        addSubview(label)
        guard let checker = space.occupied else { return }
        self.backgroundColor = checker.side == .top ? .white : .red
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 20,y: 20), radius: CGFloat(10), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = backgroundColor?.cgColor
        layer.addSublayer(shapeLayer)
        if checker.isKing {
            setTitle("K", for: .normal)
            setTitleColor(.black, for: .normal)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
