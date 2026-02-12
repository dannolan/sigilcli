import Foundation

public enum Symbol2SVGError: LocalizedError {
    case coreUINotAvailable
    case catalogLoadFailed(path: String)
    case symbolNotFound(name: String)
    case pathExtractionFailed(name: String)

    public var errorDescription: String? {
        switch self {
        case .coreUINotAvailable:
            return "CUICatalog private API is not available. This tool requires macOS with CoreUI framework."
        case .catalogLoadFailed(let path):
            return "Failed to load symbol catalog at: \(path)"
        case .symbolNotFound(let name):
            return "Symbol '\(name)' not found in catalog."
        case .pathExtractionFailed(let name):
            return "Failed to extract vector path for symbol '\(name)'."
        }
    }
}
