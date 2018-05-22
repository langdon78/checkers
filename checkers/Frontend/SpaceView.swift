import UIKit

struct Size {
    var width: Int
    var height: Int
}

class SpaceView: UIButton {
    var coordinate: Coordinate
    var space: Space
    
    init(coordinate: Coordinate, space: Space) {
        self.coordinate = coordinate
        self.space = space
        super.init(frame: CGRect(x: coordinate.right * 40, y: coordinate.down * 40, width: 40, height: 40))

        
        if space.moveable || space.occupiable || space.selected {
            self.layer.borderColor = UIColor.white.cgColor
            self.layer.borderWidth = 1
            if space.selected {
                self.layer.borderColor = UIColor.green.cgColor
                self.layer.borderWidth = 1
            } else {
                self.layer.borderColor = UIColor.white.cgColor
            }
        } else {
            self.layer.borderWidth = 0
        }
        
        guard let checker = space.occupied else { return }
        self.backgroundColor = checker.side == .top ? .white : .red
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 20,y: 20), radius: CGFloat(10), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = backgroundColor?.cgColor
        layer.addSublayer(shapeLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
