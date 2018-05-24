import Foundation

public struct Coordinate: Equatable {
    public var right: Int
    public var down: Int
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
    public var movementType: MovementType
}

struct Navigator {
    public static let upperBounds = Board.length
    public static let lowerBounds = 0
    
    public static func move(for direction: Direction, movementType: MovementType) -> Move {
        switch direction {
        case .lowerLeft: return Move(x: -, y: +, movementType: movementType)
        case .lowerRight: return Move(x: +, y: +, movementType: movementType)
        case .upperLeft: return Move(x: -, y: -, movementType: movementType)
        case .upperRight: return Move(x: +, y: -, movementType: movementType)
        }
    }
    
    public static func coordinate(from start: Coordinate, with move: Move) -> Coordinate {
        let horizontalMove = move.x(start.right, move.movementType.rawValue)
        let verticalMove = move.y(start.down, move.movementType.rawValue)
        guard horizontalMove < upperBounds, horizontalMove >= lowerBounds, verticalMove < upperBounds, verticalMove >= lowerBounds else {
            return start
        }
        return Coordinate(right: horizontalMove, down: verticalMove)
    }
    
    public static func boardWithAvailableMoves(for selectedCoordinate: Coordinate, isKing: Bool, board: Board, side: Side) -> Board {
        var board = board
        let directions = availableDirections(for: side, isKing: isKing)
        directions.forEach { direction in
            let move = Navigator.move(for: direction, movementType: .normal)
            let coordinate = Navigator.coordinate(from: selectedCoordinate, with: move)
            if board[coordinate].occupied == nil {
                board[coordinate].occupiable.toggle()
            } else if board[coordinate].occupied?.side != side {
                board = boardWithAvailableJumps(for: selectedCoordinate, in: direction, board: board, side: side)
            }
        }
        return board
    }
    
    private static func boardWithAvailableJumps(for selectedCoordinate: Coordinate, in direction: Direction, board: Board, side: Side) -> Board {
        var board = board
        let move = Navigator.move(for: direction, movementType: .jump)
        let coordinate = Navigator.coordinate(from: selectedCoordinate, with: move)
        if board[coordinate].occupied == nil {
            board[coordinate].occupiable.toggle()
            let jumpedCheckerMove = Navigator.move(for: direction, movementType: .normal)
            let jumpedCheckerCoordinates = Navigator.coordinate(from: selectedCoordinate, with: jumpedCheckerMove)
            board[coordinate].jumped = board[jumpedCheckerCoordinates].occupied
        }
        return board
    }
    
    private static func availableDirections(for side: Side, isKing: Bool) -> [Direction] {
        switch (isKing, side) {
        case (false, .top): return [.lowerLeft, .lowerRight]
        case (false, .bottom): return [.upperLeft, .upperRight]
        default: return [.lowerLeft, .upperLeft, .lowerRight, .upperRight]
        }
    }
}

public protocol Moveable {
    var currentCoordinate: Coordinate { get set }
    mutating func move(direction: Direction, movementType: MovementType)
}
