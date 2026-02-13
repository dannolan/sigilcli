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

    @Option(name: [.short, .long], help: "Output file path (or directory with --all-weights/--batch).")
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

    @Flag(name: .long, help: "Output as JSON instead of raw SVG.")
    var json = false

    @Flag(name: [.short, .long], help: "Suppress status messages.")
    var quiet = false

    @Option(name: .long, parsing: .remaining, help: "Fuzzy search for symbols matching all terms.")
    var search: [String] = []

    @Flag(name: .long, help: "Read symbol names from stdin, one per line. Requires -o <directory>.")
    var batch = false

    func validate() throws {
        let hasSearch = !search.isEmpty
        if !list && !hasSearch && !batch && symbolName == nil {
            throw ValidationError("Provide a symbol name, --list, --search, or --batch.")
        }
        if allWeights && output == nil {
            throw ValidationError("--all-weights requires -o <directory> for output.")
        }
        if batch && output == nil {
            throw ValidationError("--batch requires -o <directory> for output.")
        }
    }

    func run() throws {
        let catalog = try CoreUICatalog()

        // --search
        if !search.isEmpty {
            let allNames = catalog.allSymbolNames()
            let results = SymbolSearch.search(terms: search, in: allNames)
            if json {
                let data = try JSONSerialization.data(
                    withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
                print(String(data: data, encoding: .utf8)!)
            } else {
                for name in results { print(name) }
            }
            return
        }

        // --list
        if list {
            let names = catalog.allSymbolNames()
            if json {
                let data = try JSONSerialization.data(
                    withJSONObject: names, options: [.prettyPrinted, .sortedKeys])
                print(String(data: data, encoding: .utf8)!)
            } else {
                for name in names { print(name) }
            }
            return
        }

        let symbolScale = try resolveScale()
        let fillColor = color ?? "currentColor"

        // --batch
        if batch {
            let names = readStdinLines()
            try exportBatch(
                catalog: catalog, names: names, scale: symbolScale, fillColor: fillColor)
            return
        }

        guard let name = symbolName else { return }

        if allWeights {
            try exportAllWeights(
                catalog: catalog, name: name, scale: symbolScale, fillColor: fillColor)
        } else {
            let symbolWeight = try resolveWeight()
            if json {
                try outputJSON(
                    catalog: catalog, name: name, weight: symbolWeight, scale: symbolScale,
                    fillColor: fillColor)
            } else {
                let svg = try renderSVG(
                    catalog: catalog, name: name, weight: symbolWeight, scale: symbolScale,
                    fillColor: fillColor)
                try writeSVG(svg, to: output)
            }
        }
    }

    // MARK: - Resolvers

    private func resolveWeight() throws -> SymbolWeight {
        guard let w = SymbolWeight(rawValue: weight) else {
            throw ValidationError(
                "Invalid weight '\(weight)'. Valid: \(SymbolWeight.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }
        return w
    }

    private func resolveScale() throws -> SymbolScale {
        guard let s = SymbolScale(rawValue: size) else {
            throw ValidationError(
                "Invalid size '\(size)'. Valid: \(SymbolScale.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }
        return s
    }

    // MARK: - Export modes

    private func exportAllWeights(
        catalog: CoreUICatalog, name: String, scale: SymbolScale, fillColor: String
    ) throws {
        let dir = URL(fileURLWithPath: (output! as NSString).expandingTildeInPath)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        if json {
            var results: [[String: Any]] = []
            for w in SymbolWeight.allCases {
                let (svg, width, height) = try renderSVGWithBounds(
                    catalog: catalog, name: name, weight: w, scale: scale, fillColor: fillColor)
                let file = dir.appendingPathComponent("\(name)-\(w.rawValue).svg")
                try svg.write(to: file, atomically: true, encoding: .utf8)
                results.append([
                    "name": name, "weight": w.rawValue, "width": width, "height": height,
                    "file": file.path,
                ])
            }
            let data = try JSONSerialization.data(
                withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
            print(String(data: data, encoding: .utf8)!)
        } else {
            for w in SymbolWeight.allCases {
                let svg = try renderSVG(
                    catalog: catalog, name: name, weight: w, scale: scale, fillColor: fillColor)
                let file = dir.appendingPathComponent("\(name)-\(w.rawValue).svg")
                try svg.write(to: file, atomically: true, encoding: .utf8)
                log("Wrote \(file.lastPathComponent)")
            }
        }
    }

    private func exportBatch(
        catalog: CoreUICatalog, names: [String], scale: SymbolScale, fillColor: String
    ) throws {
        let dir = URL(fileURLWithPath: (output! as NSString).expandingTildeInPath)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let symbolWeight = try resolveWeight()
        var results: [[String: Any]] = []
        var errors: [[String: String]] = []

        for name in names {
            do {
                let (svg, width, height) = try renderSVGWithBounds(
                    catalog: catalog, name: name, weight: symbolWeight, scale: scale,
                    fillColor: fillColor)
                let file = dir.appendingPathComponent("\(name).svg")
                try svg.write(to: file, atomically: true, encoding: .utf8)
                log("Wrote \(file.lastPathComponent)")
                results.append([
                    "name": name, "width": width, "height": height, "file": file.path,
                ])
            } catch {
                log("Skipped \(name): \(error.localizedDescription)")
                errors.append(["name": name, "error": error.localizedDescription])
            }
        }

        if json {
            let output: [String: Any] = [
                "exported": results, "errors": errors, "total": results.count,
            ]
            let data = try JSONSerialization.data(
                withJSONObject: output, options: [.prettyPrinted, .sortedKeys])
            print(String(data: data, encoding: .utf8)!)
        }
    }

    private func outputJSON(
        catalog: CoreUICatalog, name: String, weight: SymbolWeight, scale: SymbolScale,
        fillColor: String
    ) throws {
        let (svg, width, height) = try renderSVGWithBounds(
            catalog: catalog, name: name, weight: weight, scale: scale, fillColor: fillColor)

        if let outputPath = output {
            let url = URL(fileURLWithPath: (outputPath as NSString).expandingTildeInPath)
            try svg.write(to: url, atomically: true, encoding: .utf8)
        }

        let result: [String: Any] = [
            "name": name,
            "weight": weight.rawValue,
            "scale": scale.rawValue,
            "width": width,
            "height": height,
            "svg": svg,
        ]
        let data = try JSONSerialization.data(
            withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        print(String(data: data, encoding: .utf8)!)
    }

    // MARK: - Rendering

    private func renderSVG(
        catalog: CoreUICatalog, name: String, weight: SymbolWeight, scale: SymbolScale,
        fillColor: String
    ) throws -> String {
        let (svg, _, _) = try renderSVGWithBounds(
            catalog: catalog, name: name, weight: weight, scale: scale, fillColor: fillColor)
        return svg
    }

    private func renderSVGWithBounds(
        catalog: CoreUICatalog, name: String, weight: SymbolWeight, scale: SymbolScale,
        fillColor: String
    ) throws -> (svg: String, width: Double, height: Double) {
        let (path, bounds) = try catalog.vectorGlyphPath(
            name: name, weight: weight, scale: scale, pointSize: CGFloat(pointSize))
        // Flip Y in path data so SVG needs no transform
        let serializer = SVGSerializer(precision: precision, flipY: true)
        let pathData = serializer.pathData(from: path)
        // Flipped viewBox: Y origin becomes -(originalY + height)
        let flippedBounds = CGRect(
            x: bounds.origin.x,
            y: -(bounds.origin.y + bounds.height),
            width: bounds.width,
            height: bounds.height
        )
        let document = SVGDocument(pathData: pathData, bounds: flippedBounds, fillColor: fillColor)
        return (document.render(), Double(bounds.width), Double(bounds.height))
    }

    // MARK: - Output

    private func writeSVG(_ svg: String, to outputPath: String?) throws {
        if let outputPath {
            let url = URL(fileURLWithPath: (outputPath as NSString).expandingTildeInPath)
            try svg.write(to: url, atomically: true, encoding: .utf8)
            log("Wrote SVG to \(url.path)")
        } else {
            print(svg)
        }
    }

    private func log(_ message: String) {
        if !quiet {
            FileHandle.standardError.write(Data("\(message)\n".utf8))
        }
    }

    private func readStdinLines() -> [String] {
        var lines: [String] = []
        while let line = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if !line.isEmpty { lines.append(line) }
        }
        return lines
    }
}
