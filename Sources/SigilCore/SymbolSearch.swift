import Foundation

public struct SymbolSearch {
    public static func search(terms: [String], in symbols: [String]) -> [String] {
        let lowered = terms.map { $0.lowercased() }

        let scored = symbols.compactMap { name -> (String, Int)? in
            let nameLower = name.lowercased()
            var score = 0

            for term in lowered {
                if nameLower.contains(term) {
                    score += 1
                    // Bonus for matching at a component boundary (after a dot)
                    let components = nameLower.split(separator: ".")
                    for component in components {
                        if component == term { score += 2 }
                        else if component.hasPrefix(term) { score += 1 }
                    }
                } else {
                    return nil // all terms must match
                }
            }

            return (name, score)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }
}
