import CoreGraphics
import Foundation

public struct SVGDocument {
    public let pathData: String
    public let bounds: CGRect
    public let fillColor: String

    public init(pathData: String, bounds: CGRect, fillColor: String = "currentColor") {
        self.pathData = pathData
        self.bounds = bounds
        self.fillColor = fillColor
    }

    public func render() -> String {
        let width = bounds.width
        let height = bounds.height
        let vbX = bounds.origin.x
        let vbY = bounds.origin.y

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="\(fmtVB(vbX)) \(fmtVB(vbY)) \(fmtVB(width)) \(fmtVB(height))" width="\(fmtVB(width))" height="\(fmtVB(height))">
          <path d="\(pathData)" fill="\(fillColor)"/>
        </svg>
        """
    }

    private func fmtVB(_ value: CGFloat) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.3f", value)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
}
