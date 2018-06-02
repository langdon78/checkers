import Foundation

// MARK: Simple toggle method

extension Bool {
    
    mutating func toggle() {
        self = !self
    }
    
}

// MARK: Avoid using literal empty string

extension String {
    
    static var empty: String {
        return ""
    }
    
}

// MARK: Add element to beginning of collection

extension Array {
    
    mutating func prepend(_ element: Element) {
        var reversed = Array(self.reversed())
        reversed.append(element)
        self = reversed.reversed()
    }
    
}

// MARK: Filter one array by contents of another

extension Array {
    
    func filter<Array2>(with array2: Array2, _ filter: (Element, Array2.Element) -> Bool) -> Array where Array2: Collection {
        var result: Array = []
        for element in self {
            for element2 in array2 {
                if filter(element, element2) {
                    result.append(element)
                }
            }
        }
        return result
    }
    
}
