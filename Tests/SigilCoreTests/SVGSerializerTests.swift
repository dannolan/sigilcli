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
}
