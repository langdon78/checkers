import Foundation

public struct Checker: Equatable, Hashable {
    
    var currentCoordinate: Coordinate {
        didSet {
            if !isKing {
                switch side {
                case .bottom: isKing = currentCoordinate.down == Board.lowerBounds
                case .top: isKing = currentCoordinate.down == Board.upperBounds
                }
            }
        }
    }
    var side: Side
    var isKing: Bool = false
    var moveable: Bool = false

}

enum SpaceHighlightStatus {
    
    case none
    case selected
    case occupiable
    case occupiableByJump
    
}

struct Space: Equatable, Hashable {
    var hashValue: Int {
        return coordinate.right.hashValue ^ coordinate.down.hashValue ^ playable.hashValue ^ highlightStatus.hashValue ^ (occupied?.hashValue ?? 1) &* 16777619
    }
    var uniqueLocationKey: Int {
        return coordinate.hashValue
    }
    var playable: Bool
    var occupied: Checker? {
        didSet {
            occupied?.currentCoordinate = coordinate
        }
    }
    var highlightStatus: SpaceHighlightStatus = .none
    var coordinate: Coordinate
    
    var isOpen: Bool {
        return occupied == nil
    }
    
    var moveable: Bool {
        get {
            guard let checker = occupied else { return false }
            return checker.moveable
        }
        set {
            occupied?.moveable = newValue
        }
    }
    
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

struct Board {
    
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
    
    var jumpableCheckers: [Coordinate: [Checker]] = [:]
    
    static var length = 8
    static let upperBounds = 7
    static let lowerBounds = 0
    
    var spaces: [[Space]] = []
    
    var occupiable: [Space] {
        return spaces
            .flatMap { $0 }
            .filter { $0.highlightStatus == .occupiable || $0.highlightStatus == .occupiableByJump }
    }
    
    var occupiableByJump: [Space] {
        return spaces
            .flatMap { $0 }
            .filter { $0.highlightStatus == .occupiableByJump }
    }
    
    var moveable: [Space] {
        return spaces
            .flatMap { $0 }
            .filter { $0.moveable }
    }
    
    var selected: Space? {
        return spaces
            .flatMap { $0 }
            .filter { $0.highlightStatus == .selected }
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
    
    init() {
        self.spaces = generate()
        self.layoutCheckers()
    }
    
    func checkers(for side: Side) -> [Checker] {
        switch side {
        case .top:
            return top
        default:
            return bottom
        }
    }
    
    private func coordinate(for space: Space) -> Coordinate {
        return space.coordinate
    }
    
}

// MARK: - Inital Setup
extension Board {
    
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
    
    static var bottomStartingCoordinates: [Coordinate] {
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
    
    mutating func layoutCheckers() {
        let topCheckers = Board.topStartingCoordinates
            .map { Checker(currentCoordinate: $0, side: .top, isKing: false, moveable: false) }
        let bottomCheckers = Board.bottomStartingCoordinates
            .map { Checker(currentCoordinate: $0, side: .bottom, isKing: false, moveable: false) }
        let checkers = topCheckers + bottomCheckers
        checkers
            .forEach { checker in
                self[checker.currentCoordinate].occupied = checker
        }
    }
    
    private func generate() -> [[Space]] {
        var row: [Space] = []
        var spaces: [[Space]] = []
        var playable = true
        for x in 0...Board.length - 1 {
            for y in 0...Board.length - 1 {
                row.append(Space(playable: !playable, coordinate: Coordinate(right: y, down: x)))
                playable = !playable
            }
            spaces.append(row)
            playable = !playable
            row = []
        }
        return spaces
    }
    
}

// MARK: - Public API
extension Board {
    
    public mutating func update(with spaces: [Space]) {
        spaces.forEach { space in
            self[space.coordinate] = space
        }
    }
    
    public mutating func selectSpace(for coordinate: Coordinate) {
        if let selected = selected, selected.coordinate != coordinate {
            toggleAllSelected()
        }
        self[coordinate].highlightStatus = .selected
    }
    
    public mutating func move(checker: Checker, from previousCoordinate: Coordinate, to currentCoordinate: Coordinate) {
        self[previousCoordinate].occupied = nil
        self[previousCoordinate].moveable.toggle()
        self[currentCoordinate].occupied = checker
    }
    
    public mutating func toggleAllSelected() {
        selected
            .flatMap { self[$0.coordinate].highlightStatus = .none }
    }
    
    public mutating func toggleAllMoveable() {
        moveable
            .forEach { self[$0.coordinate].moveable.toggle() }
    }
    
    public mutating func toggleAllOccupiable() {
        occupiable
            .forEach { self[$0.coordinate].highlightStatus = .none }
    }
    
    public mutating func availableMoves(for checker: Checker, continueJump: Bool = false) -> [Move] {
        let moves = Navigator.availableMoves(with: checker, for: checker.currentCoordinate, board: self)
        for move in moves where (continueJump && move.movementType != .normal) || (!continueJump)  {
            if let coordinate = move.endingCoordinate {
                self[coordinate].highlightStatus = move.movementType == .normal ? .occupiable : .occupiableByJump
            }
        }
        return moves
    }
    
    public mutating func playableCheckers(for player: CheckerPlayer) {
        let highlightedCoordinates = Navigator.playableCheckers(for: player, with: self)
        highlightedCoordinates.forEach { coordinate in
            self[coordinate].moveable.toggle()
        }
    }
    
    public func spaceDiff(for board: Board) -> [Space] {
        let oldSpaces = Set<Space>(self.spaces.flatMap { $0 })
        let newSpaces = Set<Space>(board.spaces.flatMap { $0 })
        return Array(newSpaces.subtracting(oldSpaces))
    }
    
}
