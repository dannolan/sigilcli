import CoreGraphics
import Testing

@testable import SigilCore

@Suite("SVGSerializer")
struct SVGSerializerTests {
    @Test("Serializes moveTo and lineTo")
    func moveAndLine() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 10, y: 20))
        path.addLine(to: CGPoint(x: 30, y: 40))
        path.closeSubpath()

        let serializer = SVGSerializer(precision: 1)
        let d = serializer.pathData(from: path)
        #expect(d == "M10,20L30,40Z")
    }

    @Test("Serializes cubic curve")
    func cubicCurve() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addCurve(
            to: CGPoint(x: 100, y: 100),
            control1: CGPoint(x: 25, y: 50),
            control2: CGPoint(x: 75, y: 50)
        )

        let serializer = SVGSerializer(precision: 0)
        let d = serializer.pathData(from: path)
        #expect(d == "M0,0C25,50 75,50 100,100")
    }

    @Test("Serializes quad curve")
    func quadCurve() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(to: CGPoint(x: 100, y: 0), control: CGPoint(x: 50, y: 80))

        let serializer = SVGSerializer(precision: 0)
        let d = serializer.pathData(from: path)
        #expect(d == "M0,0Q50,80 100,0")
    }

    @Test("Respects precision")
    func precision() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 1.23456, y: 7.89012))

        let s2 = SVGSerializer(precision: 2)
        #expect(s2.pathData(from: path) == "M1.23,7.89")

        let s5 = SVGSerializer(precision: 5)
        #expect(s5.pathData(from: path) == "M1.23456,7.89012")
    }

    @Test("Empty path produces empty string")
    func emptyPath() {
        let path = CGMutablePath()
        let serializer = SVGSerializer()
        #expect(serializer.pathData(from: path) == "")
    }

    @Test("SVGDocument renders valid SVG")
    func documentRender() {
        let doc = SVGDocument(
            pathData: "M0,0L100,0L100,100L0,100Z",
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100)
        )
        let svg = doc.render()
        #expect(svg.contains("viewBox=\"0 0 100 100\""))
        #expect(svg.contains("fill=\"currentColor\""))
        #expect(svg.contains("scale(1,-1)"))
        #expect(svg.contains("<path"))
    }

    @Test("SVGDocument respects custom fill color")
    func customFillColor() {
        let doc = SVGDocument(
            pathData: "M0,0L10,10Z",
            bounds: CGRect(x: 0, y: 0, width: 10, height: 10),
            fillColor: "#FF3B30"
        )
        let svg = doc.render()
        #expect(svg.contains("fill=\"#FF3B30\""))
        #expect(!svg.contains("currentColor"))
    }
}

@Suite("SymbolSearch")
struct SymbolSearchTests {
    let symbols = [
        "arrow.right",
        "arrow.right.circle",
        "arrow.right.circle.fill",
        "arrow.left",
        "arrow.left.circle",
        "arrow.up.right",
        "star.fill",
        "heart.fill",
        "cloud.fill",
    ]

    @Test("Single term matches all containing symbols")
    func singleTerm() {
        let results = SymbolSearch.search(terms: ["arrow"], in: symbols)
        #expect(results.count == 6)
        #expect(results.allSatisfy { $0.contains("arrow") })
    }

    @Test("Multiple terms require all to match")
    func multipleTerms() {
        let results = SymbolSearch.search(terms: ["arrow", "circle"], in: symbols)
        #expect(results.count == 3)
        #expect(results.allSatisfy { $0.contains("arrow") && $0.contains("circle") })
    }

    @Test("Exact component matches rank higher")
    func exactComponentRanking() {
        let results = SymbolSearch.search(terms: ["right"], in: symbols)
        // "arrow.right" has an exact component match, should rank above "arrow.up.right"
        #expect(results.first == "arrow.right")
    }

    @Test("No matches returns empty")
    func noMatches() {
        let results = SymbolSearch.search(terms: ["zzzzz"], in: symbols)
        #expect(results.isEmpty)
    }

    @Test("Search is case insensitive")
    func caseInsensitive() {
        let results = SymbolSearch.search(terms: ["ARROW", "RIGHT"], in: symbols)
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.contains("arrow") && $0.contains("right") })
    }
}

@Suite("CoreUICatalog")
struct CoreUICatalogTests {
    @Test("Loads catalog and lists symbols")
    func listSymbols() throws {
        let catalog = try CoreUICatalog()
        let names = catalog.allSymbolNames()
        #expect(names.count > 5000)
        #expect(names.contains("star.fill"))
        #expect(names.contains("heart.fill"))
    }

    @Test("Extracts vector path for known symbol")
    func extractPath() throws {
        let catalog = try CoreUICatalog()
        let (path, bounds) = try catalog.vectorGlyphPath(name: "star.fill")
        #expect(!path.isEmpty)
        #expect(bounds.width > 0)
        #expect(bounds.height > 0)
    }

    @Test("Throws for unknown symbol")
    func unknownSymbol() throws {
        let catalog = try CoreUICatalog()
        #expect(throws: Symbol2SVGError.self) {
            try catalog.vectorGlyphPath(name: "this.symbol.does.not.exist.ever")
        }
    }

    @Test("Different weights produce different paths")
    func weightsDiffer() throws {
        let catalog = try CoreUICatalog()
        let (_, lightBounds) = try catalog.vectorGlyphPath(
            name: "star.fill", weight: .ultralight)
        let (_, blackBounds) = try catalog.vectorGlyphPath(
            name: "star.fill", weight: .black)
        // Black weight should be wider than ultralight
        #expect(blackBounds.width > lightBounds.width)
    }
}
