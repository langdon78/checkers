import Foundation

public struct Coordinate: Equatable, CustomStringConvertible {
    
    public var right: Int
    public var down: Int

    public var description: String {
        return "[\(right), \(down)]"
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

public struct Location {
    
    public var x: AxialDirection
    public var y: AxialDirection
    public var movementType: MovementType
    
}

struct Navigator {
    
    private static let upperBounds = Board.upperBounds
    private static let lowerBounds = Board.lowerBounds
    
}

// MARK: - Public API
extension Navigator {
    
    public static func boardWithAvailableMoves(
            for selectedCoordinate: Coordinate,
            isKing: Bool,
            board: Board,
            side: Side,
            movementType: MovementType
        ) -> Board {
        
        var board = board
        let directions = availableDirections(for: side, isKing: isKing)
        
        directions.forEach { direction in
            evaluateSpace(for: selectedCoordinate, on: board, with: direction, movementType: movementType, side: side) { (coordinate, movementType) in
                // Retrieve jumped checker and store in landed space
                if movementType == .jump {
                    let jumpedCheckerCoordinate = Navigator.coordinate(from: selectedCoordinate, for: direction, with: .normal)
                    board[coordinate].jumped = board[jumpedCheckerCoordinate].occupied
                }
                board[coordinate].highlightStatus = .occupiable
                return true
            }
        }
        return board
    }
    
    public static func boardWithPlayableCheckers(for player: Player, with board: Board) -> Board {
        var board = board
        let playerCheckers = board.checkers(for: player.side)
        for checker in playerCheckers {
            for direction in availableDirections(for: checker.side, isKing: checker.isKing) {
                let toggled = evaluateSpace(for: checker.currentCoordinate, on: board, with: direction, movementType: .normal, side: checker.side) { (coordinate, _) in
                    board[checker.currentCoordinate].moveable.toggle()
                    return true
                }
                if toggled { break }
            }
        }
        return board
    }
    
}

// MARK: - Implementation
extension Navigator {
    
    private static func coordinate(from start: Coordinate, for direction: Direction, with movementType: MovementType) -> Coordinate {
        let location = Navigator.location(for: direction, movementType: movementType)
        let horizontalMove = location.x(start.right, location.movementType.rawValue)
        let verticalMove = location.y(start.down, location.movementType.rawValue)
        guard horizontalMove <= upperBounds, horizontalMove >= lowerBounds, verticalMove <= upperBounds, verticalMove >= lowerBounds else {
            return start
        }
        return Coordinate(right: horizontalMove, down: verticalMove)
    }
    
    private static func location(for direction: Direction, movementType: MovementType) -> Location {
        switch direction {
        case .lowerLeft: return Location(x: -, y: +, movementType: movementType)
        case .lowerRight: return Location(x: +, y: +, movementType: movementType)
        case .upperLeft: return Location(x: -, y: -, movementType: movementType)
        case .upperRight: return Location(x: +, y: -, movementType: movementType)
        }
    }
    
    @discardableResult private static func evaluateSpace(
            for selectedCoordinate: Coordinate,
            on board: Board,
            with direction: Direction,
            movementType: MovementType,
            side: Side,
            action: (Coordinate, MovementType) -> Bool
        ) -> Bool {
        
        let coordinate = Navigator.coordinate(from: selectedCoordinate, for: direction, with: movementType)
        if board[coordinate].occupied == nil {
            return action(coordinate, movementType)
        } else if board[coordinate].occupied?.side != side && movementType == .normal {
            return evaluateSpace(for: selectedCoordinate, on: board, with: direction, movementType: .jump, side: side, action: action)
        }
        return false
    }
    
    private static func availableDirections(for side: Side, isKing: Bool) -> [Direction] {
        switch (isKing, side) {
        case (false, .top): return [.lowerLeft, .lowerRight]
        case (false, .bottom): return [.upperLeft, .upperRight]
        default: return [.lowerLeft, .upperLeft, .lowerRight, .upperRight]
        }
    }
    
}
