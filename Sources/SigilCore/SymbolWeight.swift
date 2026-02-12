import Foundation

public enum SymbolWeight: String, CaseIterable, Sendable {
    case ultralight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black

    public var rawIndex: Int {
        switch self {
        case .ultralight: return 0
        case .thin: return 1
        case .light: return 2
        case .regular: return 3
        case .medium: return 4
        case .semibold: return 5
        case .bold: return 6
        case .heavy: return 7
        case .black: return 8
        }
    }
}
