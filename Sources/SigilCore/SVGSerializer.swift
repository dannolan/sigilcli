import CoreGraphics
import Foundation

public struct SVGSerializer {
    public let precision: Int
    public let flipY: Bool

    public init(precision: Int = 3, flipY: Bool = false) {
        self.precision = precision
        self.flipY = flipY
    }

    public func pathData(from cgPath: CGPath) -> String {
        var components: [String] = []

        cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            switch element.type {
            case .moveToPoint:
                let p = element.points[0]
                components.append("M\(fmt(p.x)),\(fmtY(p.y))")
            case .addLineToPoint:
                let p = element.points[0]
                components.append("L\(fmt(p.x)),\(fmtY(p.y))")
            case .addQuadCurveToPoint:
                let cp = element.points[0]
                let p = element.points[1]
                components.append("Q\(fmt(cp.x)),\(fmtY(cp.y)) \(fmt(p.x)),\(fmtY(p.y))")
            case .addCurveToPoint:
                let cp1 = element.points[0]
                let cp2 = element.points[1]
                let p = element.points[2]
                components.append("C\(fmt(cp1.x)),\(fmtY(cp1.y)) \(fmt(cp2.x)),\(fmtY(cp2.y)) \(fmt(p.x)),\(fmtY(p.y))")
            case .closeSubpath:
                components.append("Z")
            @unknown default:
                break
            }
        }

        return components.joined(separator: "")
    }

    private func fmtY(_ value: CGFloat) -> String {
        fmt(flipY ? -value : value)
    }

    private func fmt(_ value: CGFloat) -> String {
        let rounded = (value * pow(10, CGFloat(precision))).rounded() / pow(10, CGFloat(precision))
        // Whole number — no decimal point needed
        if rounded == rounded.rounded() {
            return String(format: "%.0f", rounded)
        }
        // Has fractional part — format with precision, strip trailing decimal zeros
        return String(format: "%.\(precision)f", rounded)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
}
