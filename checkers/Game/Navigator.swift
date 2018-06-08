import Foundation

public struct Coordinate: Equatable, CustomStringConvertible, Hashable {
    
    struct AlphaCoordinate: Equatable, Hashable {
        var hashValue: Int {
            return values.count
        }
        let values = ["A","B","C","D","E","F","G","H"]
        subscript(_ index: Int) -> String {
            guard index >= 0, index < values.count else { return "" }
            return values[index]
        }
        subscript(_ char: String) -> Int? {
            guard let index = values.index(where: { $0 == char }) else { return nil }
            return index
        }
    }
    
    public var right: Int
    public var down: Int
    
    public var description: String {
        return "[\(right), \(down)]"
    }
    
    var alpha = AlphaCoordinate()
    
    public var displayable: String {
        return "\(alpha[right])\(down+1)"
    }
    
    init(right: Int, down: Int) {
        self.right = right
        self.down = down
    }
    
    init?(value: String) {
        guard value.count > 0, value.count < 3 else { return nil }
        guard
            let firstChar = value.uppercased().first,
            let right = alpha[String(firstChar)],
            let lastChar = value.last,
            let down = Int(String(lastChar)) else { return nil }
        self = Coordinate(right: right, down: down-1)
    }
    
}

public typealias AxialDirection = (Int,Int) -> Int

public enum Direction: Equatable {
    
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
    
    var opposite: Direction {
        switch self {
        case .lowerLeft: return .upperRight
        case .lowerRight: return .upperLeft
        case .upperLeft: return .lowerRight
        case .upperRight: return .lowerLeft
        }
    }
    
}

public enum MovementType: Equatable {
    
    case normal
    case jump(Checker)
    
    var rawValue: Int {
        switch self {
        case .normal:
            return 1
        default:
            return 2
        }
    }

}

public struct Location {
    
    public var x: AxialDirection
    public var y: AxialDirection
    public var movementType: MovementType
    
}

struct Move: Equatable {
    
    var startingCoordinate: Coordinate
    var direction: Direction
    var movementType: MovementType
    var endingCoordinate: Coordinate? {
        return Navigator.coordinate(with: Move(startingCoordinate: startingCoordinate, direction: direction, movementType: movementType))
    }
    
}

struct Path {
    
    private var last: Coordinate? {
        return moves.last?.endingCoordinate
    }
    var head: [Move] {
        return Array(moves.prefix(through: moves.count-2))
    }
    var moves: [Move]
    
    init(moves: [Move]) {
        self.moves = moves
    }
    
    init(move: Move) {
        self.init(moves: [move])
    }
    
    func match(with coordinate: Coordinate) -> Bool {
        return last == coordinate
    }
    
    mutating func adding(_ move: Move) {
        moves.forEach { item in
            if move.startingCoordinate == item.endingCoordinate {
                moves.append(move)
            } else if move.endingCoordinate == item.startingCoordinate {
                moves.prepend(move)
            }
        }
    }
    
    func add(_ move: Move) -> Path {
        var path = self
        path.adding(move)
        return path
    }
    
}

struct Navigator {
    
    private static let upperBounds = Board.upperBounds
    private static let lowerBounds = Board.lowerBounds
    
}

// MARK: - Public API
extension Navigator {
    
    public static func availableMoves(with checker: Checker, for selectedCoordinate: Coordinate, board: Board, moves: [Move] = []) -> [Move] {
        var moves = moves.isEmpty ? possibleMoves(with: checker, from: selectedCoordinate, on: board) : moves
        for move in moves {
            if move.movementType != .normal, let endingCoordinate = move.endingCoordinate {
                let nextMovesAfterJump = possibleMoves(with: checker, from: endingCoordinate, on: board)
                // Filter out moves towards direction where coming from
                let validMoves = nextMovesAfterJump.filter { $0.direction != move.direction.opposite }
                if validMoves.isEmpty { continue }
                moves.append(contentsOf: availableMoves(with: checker, for: endingCoordinate, board: board, moves: validMoves))
            }
        }
        return moves
    }
    
    public static func playableCheckers(for player: CheckerPlayer, with board: Board) -> [Coordinate] {
        let playerCheckers = board.checkers(for: player.side)
        return playerCheckers.compactMap { checker in
            let moves = possibleMoves(with: checker, from: checker.currentCoordinate, on: board)
            guard !moves.isEmpty else { return nil }
            return checker.currentCoordinate
        }
    }
    
    public static func findPaths(for moves: [Move]) -> [Path] {
        var result: [Path] = []
        for move in moves {
            result = result.map { $0.add(move) }
            // If coordinate not associated with existing path, make new path
            let flattened = result.flatMap { $0.moves }
            if !flattened.contains(move) {
                result.append(Path(move: move))
            }
        }
        // Create path points for single jumps when multiple jumps are allowed
        result
            .flatMap { $0.head }
            .forEach {
                result.append(Path(move: $0))
        }
        return result
    }
    
}

// MARK: - Implementation
extension Navigator {
    
    fileprivate static func coordinate(with move: Move) -> Coordinate? {
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
    
    private static func possibleMoves(with playerChecker: Checker, from coordinate: Coordinate, on board: Board) -> [Move] {
        let directions = availableDirections(for: playerChecker.side, isKing: playerChecker.isKing)
        return directions.compactMap { direction in
            let move = Move(startingCoordinate: coordinate, direction: direction, movementType: .normal)
            if let spacePlus1 = Navigator.coordinate(with: move) {
                if let jumpableChecker = board[spacePlus1].occupied,
                jumpableChecker.side != playerChecker.side {
                    let nextMove = Move(startingCoordinate: spacePlus1, direction: direction, movementType: .normal)
                    if let spacePlus2 = Navigator.coordinate(with: nextMove),
                        board[spacePlus2].isOpen {
                        return Move(startingCoordinate: coordinate, direction: direction, movementType: .jump(jumpableChecker))
                    }
                    // Normal move
                } else if board[spacePlus1].isOpen && !board[coordinate].isOpen {
                    return move
                }
            }
            return nil
        }
    }
    
    private static func availableDirections(for side: Side, isKing: Bool) -> [Direction] {
        switch (isKing, side) {
        case (false, .top): return [.lowerLeft, .lowerRight]
        case (false, .bottom): return [.upperLeft, .upperRight]
        default: return [.lowerLeft, .upperLeft, .lowerRight, .upperRight]
        }
    }
    
}
