import UIKit

class CoordinateLabelView: UIView {
    
    let label: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.alpha = 0.7
        return label
    }()
    
    init(coordinateLabelText: String, col: Int, row: Int) {
        if row == 0 {
            super.init(frame: CGRect(x: (col * 40) - 20, y: 0, width: 40, height: 20))
        } else {
            super.init(frame: CGRect(x: 0, y: (row * 40) - 20, width: 20, height: 40))
        }
        label.frame = bounds
        label.text = coordinateLabelText
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
