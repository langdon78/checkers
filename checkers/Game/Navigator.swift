import Foundation

public struct Coordinate: Equatable, CustomStringConvertible, Hashable {
    
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

struct Move {
    var startingCoordinate: Coordinate
    var direction: Direction
    var movementType: MovementType
    var endingCoordinate: Coordinate? {
        return Navigator.coordinate(with: Move(startingCoordinate: startingCoordinate, direction: direction, movementType: movementType))
    }
}

struct Path {
    var paths: [Int: [Move]]
    var nextIndex: Int {
        guard let highestIndex = paths.sorted(by: { $0.key > $1.key }).first else { return 0 }
        return highestIndex.key + 1
    }
    
    func continuedPaths(coordinate: Coordinate?) -> [Int] {
        return paths
            .filter { path in
            guard let lastCoordinate = path.value.last?.startingCoordinate else { return false }
            return coordinate == lastCoordinate
            }.map {
                $0.key
        }
    }
    
    func selectPath(with coordinate: Coordinate) -> [Move] {
        guard let path = paths
            .filter({ $0.value
                .contains(where: {$0.startingCoordinate == coordinate }) })
            .first?.value
            else { return [] }
        return path
    }
    
    mutating func add(move: Move) {
        let keys = continuedPaths(coordinate: move.endingCoordinate)
        if keys.isEmpty {
            paths.updateValue([move], forKey: nextIndex)
        } else {
            for key in keys {
                var moves = paths[key]!
                moves.append(move)
                paths.updateValue(moves, forKey: key)
            }
        }
    }
}

// MARK: - Public API
extension Navigator {
    
    public static func boardWithAvailableMoves(
            for selectedCoordinate: Coordinate,
            isKing: Bool,
            board: Board,
            side: Side,
            movementType: MovementType,
            path: Path
        ) -> Path {
        
        var path = path
        let directions = availableDirections(for: side, isKing: isKing)
        
        directions.forEach { direction in
            evaluateSpace(for: selectedCoordinate, on: board, with: direction, movementType: movementType, side: side) { (coordinate, movementType) in
                if movementType == .jump {
                    let move = Move(startingCoordinate: selectedCoordinate, direction: direction, movementType: .normal)
                    guard
                        let jumpedCheckerCoordinate = Navigator.coordinate(with: move),
                        let _ = board[jumpedCheckerCoordinate].occupied
                        else { return false }
                    path = boardWithAvailableMoves(for: coordinate, isKing: isKing, board: board, side: side, movementType: .jump, path: path)
                }
                
                let move = Move(startingCoordinate: coordinate, direction: direction, movementType: movementType)
                path.add(move: move)
                return true
            }
        }
        return path
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
    
    public static func movementType(from starting: Coordinate, to ending: Coordinate) -> MovementType {
         return MovementType(rawValue: abs(starting.right - ending.right)) ?? .jump
    }
    
    public static func jumpedCheckers(for starting: Coordinate, to ending: Coordinate, on board: Board, checkers: [Checker] = []) -> [Checker] {
        var checkers = checkers
        let moveDirection = direction(from: starting, to: ending)
        let move = Move(startingCoordinate: starting, direction: moveDirection, movementType: .normal)
        guard let moveCoordinate = coordinate(with: move) else { return checkers }
        guard let checker = board[moveCoordinate].occupied else {
            if starting == ending {
                return checkers
            } else {
                return jumpedCheckers(for: moveCoordinate, to: ending, on: board, checkers: checkers)
            }
        }
        checkers.append(checker)
        return checkers
    }
    
}

// MARK: - Implementation
extension Navigator {
    
    static func coordinate(with move: Move) -> Coordinate? {
        let location = Navigator.location(for: move.direction, movementType: move.movementType)
        let horizontalMove = location.x(move.startingCoordinate.right, location.movementType.rawValue)
        let verticalMove = location.y(move.startingCoordinate.down, location.movementType.rawValue)
        guard
            horizontalMove <= upperBounds,
            horizontalMove >= lowerBounds,
            verticalMove <= upperBounds,
            verticalMove >= lowerBounds
            else { return nil }
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
    
    private static func direction(from starting: Coordinate, to ending: Coordinate) -> Direction {
        let down = starting.down > ending.down
        let right = starting.right > ending.right
        switch (down, right) {
        case (true, true): return .upperLeft
        case (true, false): return .upperRight
        case (false, true): return .lowerLeft
        case (false, false): return .lowerRight
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
        
        // Get new coordinate based on direction and movement type
        let move = Move(startingCoordinate: selectedCoordinate, direction: direction, movementType: movementType)
        guard let coordinate = Navigator.coordinate(with: move) else { return false }
        
        // If new location is free, execute action
        // otherwise if occupied by opposing player and not a jump,
        // recurse with jump movement type
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
