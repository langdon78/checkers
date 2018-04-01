import Foundation

struct Player: Equatable {
    var name: String
    var side: Side
    var checkers: [Checker] = []
    var captured: [Checker] = []
    
    init(name: String, side: Side) {
        self.name = name
        self.side = side
    }
}

extension Bool {
    mutating func toggle() {
        self = !self
    }
}

enum Side {
    case top
    case bottom
}

enum TurnAction {
    case start(MoveAction)
    case end
}

enum MoveAction {
    case select(Coordinate)
    case deselect(Coordinate)
    case move(Coordinate)
}

struct Checker: Moveable, Equatable {
    var currentCoordinate: Coordinate
    var side: Side
    var isKing: Bool = false
    
    mutating func move(direction: Direction, movementType: MovementType = .normal) {
        let move = Navigator.getMove(direction: direction, numberOfSpaces: movementType.rawValue)
        currentCoordinate = Navigator.moved(from: currentCoordinate, with: move)
    }
    
    mutating func move(to coordinates: Coordinate) {
        currentCoordinate = coordinates
    }
}

struct Space: Equatable {
    var playable: Bool
    var occupied: Checker?
    var selected: Bool = false
    var moveable: Bool = false
    var occupiable: Bool = false
    var coordinate: Coordinate
    
    init(playable: Bool, coordinate: Coordinate) {
        self.playable = playable
        self.coordinate = coordinate
    }
    
    init(playable: Bool, occupied: Checker?, coordinate: Coordinate) {
        self.playable = playable
        self.occupied = occupied
        self.coordinate = coordinate
    }
}

indirect enum BoardAction {
    case showOccupiable(Coordinate)
    case showMoveable(Coordinate)
    case select(Coordinate)
    case occupy(Coordinate, Checker)
    case remove(Coordinate)
    case clear(BoardAction)
}

struct Board {
    static var topStartingCoordinates: [Coordinate] {
        return [
            (1,0),
            (3,0),
            (5,0),
            (7,0),
            (0,1),
            (2,1),
            (4,1),
            (6,1),
            (1,2),
            (3,2),
            (5,2),
            (7,2),
        ].map { Coordinate(right: $0.0, down: $0.1)}
    }
    static var BottomStartingCoordinates: [Coordinate] {
        return [
            (0,5),
            (2,5),
            (4,5),
            (6,5),
            (1,6),
            (3,6),
            (5,6),
            (7,6),
            (0,7),
            (2,7),
            (4,7),
            (6,7),
            ].map { Coordinate(right: $0.0, down: $0.1)}
    }
    
    static var length = 8
    var spaces: [[Space]] = []
    
    var occupiable: [Space] {
        return spaces
            .flatMap { $0 }
            .filter { $0.occupiable }
    }
    var moveable: [Space] {
        return spaces
            .flatMap { $0 }
            .filter { $0.moveable }
    }
    var selected: Space? {
        return spaces
            .flatMap { $0 }
            .filter { $0.selected }
            .last
    }
    
    var top: [Checker] {
        return spaces
            .flatMap { $0 }
            .filter { $0.occupied?.side == .top }
            .compactMap { $0.occupied }
    }
    
    var bottom: [Checker] {
        return spaces
            .flatMap { $0 }
            .filter { $0.occupied?.side == .bottom }
            .compactMap { $0.occupied }
    }
    
    subscript(x: Int, y: Int) -> Space {
        return spaces[y][x]
    }
    subscript(c: Coordinate) -> Space {
        get {
            return spaces[c.down][c.right]
        }
        set {
            spaces[c.down][c.right] = newValue
        }
    }
    
    init() {
        self.spaces = generate()
    }
    
    private func coordinate(for space: Space) -> Coordinate {
        return space.coordinate
    }
    
    static func selectSpace(for coordinate: Coordinate, on board: Board) -> Board {
        var updatedBoard = board
        if let selected = board.selected, selected.coordinate != coordinate {
            updatedBoard = Board.toggleAllSelected(on: board)
        }
        return Board.update(board: &updatedBoard, with: .select(coordinate))
    }
    
    static func move(checker: Checker, on board: Board, from: Coordinate, to: Coordinate) -> Board {
        var board = board
        board = update(board: &board, with: .remove(from))
        board = update(board: &board, with: .occupy(to, checker))
        return board
    }
    
    static func toggleAllSelected(on board: Board) -> Board {
        var updatedBoard = board
        return board.selected
            .flatMap { Board.update(board: &updatedBoard, with: .clear(.select($0.coordinate))) } ?? board
    }
    
    static func toggleAllMoveable(on board: Board) -> Board {
        var updatedBoard = board
        return board.moveable
            .map { Board.update(board: &updatedBoard, with: .clear(.showMoveable($0.coordinate))) }
            .last ?? board
    }
    
    static func toggleAllOccupiable(on board: Board) -> Board {
        var updatedBoard = board
        return board.occupiable
            .map { Board.update(board: &updatedBoard, with: .clear(.showOccupiable($0.coordinate))) }
            .last ?? board
    }
    
    private func generate() -> [[Space]] {
        var row: [Space] = []
        var spaces: [[Space]] = []
        var playable = false
        for x in 1...Board.length {
            for y in 1...Board.length {
                row.append(Space(playable: !playable, coordinate: Coordinate(right: y, down: x)))
                playable = !playable
            }
            spaces.append(row)
            playable = !playable
            row = []
        }
        return spaces
    }
    
    static func layoutCheckers(for board: Board) -> Board {
        var updatedBoard = board
        let topCheckers = topStartingCoordinates
            .map { Checker(currentCoordinate: $0, side: .top, isKing: false) }
        let bottomCheckers = BottomStartingCoordinates
            .map { Checker(currentCoordinate: $0, side: .bottom, isKing: false) }
        let checkers = topCheckers + bottomCheckers
        checkers
            .forEach { updatedBoard = Board.update(board: &updatedBoard, with: .occupy($0.currentCoordinate, $0))}
        return updatedBoard
    }
    
    static private func updateSpace(on board: Board, for coordinate: Coordinate, with update: (inout Space) -> Void) -> Board {
        var board = board
        update(&board[coordinate])
        return board
    }
    
    static func update(board: inout Board, with action: BoardAction) -> Board {
        switch action {
        case .select(let coordinate):
            return updateSpace(on: board, for: coordinate) { space in
                space.selected.toggle()
            }
        case .showMoveable(let coordinate):
            return updateSpace(on: board, for: coordinate) { space in
                space.moveable.toggle()
            }
        case .showOccupiable(let coordinate):
            return updateSpace(on: board, for: coordinate) { space in
                space.occupiable.toggle()
            }
        case .occupy(let coordinate, let checker):
            return updateSpace(on: board, for: coordinate) { space in
                space.occupied = checker
            }
        case .remove(let coordinate):
            return updateSpace(on: board, for: coordinate) { space in
                space.occupied = nil
            }
        case .clear(let action):
            switch action {
            case .showOccupiable( _): return Board.update(board: &board, with: action)
            case .showMoveable( _): return Board.update(board: &board, with: action)
            case .select( _): return Board.update(board: &board, with: action)
            default:
                return board
            }
        }
    }
}
