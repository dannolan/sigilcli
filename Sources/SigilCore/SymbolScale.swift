import Foundation

public enum SymbolScale: String, CaseIterable, Sendable {
    case small
    case medium
    case large

    public var rawIndex: Int {
        switch self {
        case .small: return 0
        case .medium: return 1
        case .large: return 2
        }
    }
}
