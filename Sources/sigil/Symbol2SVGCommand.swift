import ArgumentParser
import Foundation
import SigilCore

@main
struct SigilCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sigil",
        abstract: "Extract Apple system symbols as clean SVG vectors.",
        discussion: """
            Extracts vector path data from the system symbol catalog
            and outputs clean SVG. Pure vectors, no rasterization.
            """
    )

    @Argument(help: "Symbol name (e.g. 'star.fill').")
    var symbolName: String?

    @Option(name: [.short, .long], help: "Output file path (or directory with --all-weights). Defaults to stdout.")
    var output: String?

    @Option(name: [.short, .long], help: "Symbol weight: ultralight, thin, light, regular, medium, semibold, bold, heavy, black.")
    var weight: String = "regular"

    @Option(name: [.short, .long], help: "Symbol scale: small, medium, large.")
    var size: String = "medium"

    @Option(name: .long, help: "Point size for the symbol glyph.")
    var pointSize: Double = 100

    @Option(name: .long, help: "Decimal precision for SVG path coordinates.")
    var precision: Int = 3

    @Option(name: [.short, .long], help: "Fill color (e.g. '#FF0000', 'red'). Defaults to 'currentColor'.")
    var color: String?

    @Flag(name: .long, help: "Export all 9 weights as separate files.")
    var allWeights = false

    @Flag(name: .long, help: "List all available symbol names.")
    var list = false

    func validate() throws {
        if !list && symbolName == nil {
            throw ValidationError("Provide a symbol name or use --list.")
        }
        if allWeights && output == nil {
            throw ValidationError("--all-weights requires -o <directory> for output.")
        }
    }

    func run() throws {
        let catalog = try CoreUICatalog()

        if list {
            let names = catalog.allSymbolNames()
            for name in names {
                print(name)
            }
            return
        }

        guard let name = symbolName else { return }

        guard let symbolScale = SymbolScale(rawValue: size) else {
            throw ValidationError(
                "Invalid size '\(size)'. Valid: \(SymbolScale.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }

        let fillColor = color ?? "currentColor"

        if allWeights {
            try exportAllWeights(
                catalog: catalog, name: name, scale: symbolScale, fillColor: fillColor
            )
        } else {
            guard let symbolWeight = SymbolWeight(rawValue: weight) else {
                throw ValidationError(
                    "Invalid weight '\(weight)'. Valid: \(SymbolWeight.allCases.map(\.rawValue).joined(separator: ", "))"
                )
            }
            let svg = try renderSVG(
                catalog: catalog, name: name, weight: symbolWeight, scale: symbolScale,
                fillColor: fillColor
            )
            try writeSVG(svg, to: output)
        }
    }

    private func exportAllWeights(
        catalog: CoreUICatalog, name: String, scale: SymbolScale, fillColor: String
    ) throws {
        let dir = URL(fileURLWithPath: (output! as NSString).expandingTildeInPath)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        for w in SymbolWeight.allCases {
            let svg = try renderSVG(
                catalog: catalog, name: name, weight: w, scale: scale, fillColor: fillColor
            )
            let file = dir.appendingPathComponent("\(name)-\(w.rawValue).svg")
            try svg.write(to: file, atomically: true, encoding: .utf8)
            print("Wrote \(file.lastPathComponent)")
        }
    }

    private func renderSVG(
        catalog: CoreUICatalog, name: String, weight: SymbolWeight, scale: SymbolScale,
        fillColor: String
    ) throws -> String {
        let (path, bounds) = try catalog.vectorGlyphPath(
            name: name, weight: weight, scale: scale, pointSize: CGFloat(pointSize)
        )
        let serializer = SVGSerializer(precision: precision)
        let pathData = serializer.pathData(from: path)
        let document = SVGDocument(pathData: pathData, bounds: bounds, fillColor: fillColor)
        return document.render()
    }

    private func writeSVG(_ svg: String, to outputPath: String?) throws {
        if let outputPath {
            let url = URL(fileURLWithPath: (outputPath as NSString).expandingTildeInPath)
            try svg.write(to: url, atomically: true, encoding: .utf8)
            print("Wrote SVG to \(url.path)")
        } else {
            print(svg)
        }
    }
}
