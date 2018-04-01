import Foundation

public struct Coordinate {
    public var right: Int
    public var down: Int
    
    public init(right: Int, down: Int) {
        self.right = right
        self.down = down
    }
}

// MARK: Equatable

extension Coordinate: Equatable {
    public static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.down == rhs.down && lhs.right == rhs.right
    }
}

public typealias AxialDirection = (Int,Int) -> Int

public enum Direction {
    case upperRight
    case upperLeft
    case lowerRight
    case lowerLeft
    
    static var all: [Direction] {
        return [
            .upperRight,
            .upperLeft,
            .lowerRight,
            .lowerLeft
        ]
    }
}

public enum MovementType: Int {
    case normal = 1
    case jump
}

public struct Move {
    public var x: AxialDirection
    public var y: AxialDirection
    public var numberOfSpaces: Int
}

public struct Navigator {
    public static let upperBounds = Board.length
    public static let lowerBounds = 0
    
    public static func getMove(direction: Direction, numberOfSpaces: Int) -> Move {
        switch direction {
        case .lowerLeft: return Move(x: -, y: +, numberOfSpaces: numberOfSpaces)
        case .lowerRight: return Move(x: +, y: +, numberOfSpaces: numberOfSpaces)
        case .upperLeft: return Move(x: -, y: -, numberOfSpaces: numberOfSpaces)
        case .upperRight: return Move(x: +, y: -, numberOfSpaces: numberOfSpaces)
        }
    }
    
    public static func moved(from start: Coordinate, with move: Move) -> Coordinate {
        let horizontalMove = move.x(start.right, move.numberOfSpaces)
        let verticalMove = move.y(start.down, move.numberOfSpaces)
        guard horizontalMove < upperBounds, horizontalMove >= lowerBounds, verticalMove < upperBounds, verticalMove >= lowerBounds else {
            print("Out of bounds")
            return start
        }
        return Coordinate(right: horizontalMove, down: verticalMove)
    }
}

public protocol Moveable {
    var currentCoordinate: Coordinate { get set }
    mutating func move(direction: Direction, movementType: MovementType)
}
