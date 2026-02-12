import AppKit
import CoreGraphics
import Foundation

public final class CoreUICatalog {
    private let catalog: NSObject

    private static let catalogPath =
        "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/Assets.car"

    public init() throws {
        guard let cuiCatalogClass = NSClassFromString("CUICatalog") as? NSObject.Type else {
            throw Symbol2SVGError.coreUINotAvailable
        }

        let url = URL(fileURLWithPath: Self.catalogPath)

        // CUICatalog.init(url:error:) — two-arg initializer
        let selector = NSSelectorFromString("initWithURL:error:")
        guard cuiCatalogClass.instancesRespond(to: selector) else {
            throw Symbol2SVGError.coreUINotAvailable
        }

        // Swift blocks alloc() directly — use perform to call it via ObjC runtime
        guard let allocResult = cuiCatalogClass.perform(NSSelectorFromString("alloc")) else {
            throw Symbol2SVGError.coreUINotAvailable
        }
        let instance = allocResult.takeUnretainedValue()
        let imp = type(of: instance).instanceMethod(for: selector)

        typealias InitMethod = @convention(c) (
            AnyObject, Selector, NSURL, UnsafeMutablePointer<NSError?>?
        ) -> NSObject?

        let typedIMP = unsafeBitCast(imp, to: InitMethod.self)

        var error: NSError?
        guard let result = typedIMP(instance, selector, url as NSURL, &error) else {
            throw Symbol2SVGError.catalogLoadFailed(path: Self.catalogPath)
        }

        self.catalog = result
    }

    public func allSymbolNames() -> [String] {
        let selector = NSSelectorFromString("allImageNames")
        guard catalog.responds(to: selector) else { return [] }

        guard let names = catalog.perform(selector)?.takeUnretainedValue() as? [String] else {
            return []
        }

        // SF Symbol names in CoreGlyphs don't have file extensions
        return names.sorted()
    }

    public func containsSymbol(_ name: String) -> Bool {
        allSymbolNames().contains(name)
    }

    public func vectorGlyphPath(
        name: String,
        weight: SymbolWeight = .regular,
        scale: SymbolScale = .medium,
        pointSize: CGFloat = 100
    ) throws -> (path: CGPath, bounds: CGRect) {
        // namedVectorGlyphWithName:scaleFactor:deviceIdiom:layoutDirection:glyphSize:glyphWeight:glyphPointSize:appearanceName:
        let selector = NSSelectorFromString(
            "namedVectorGlyphWithName:scaleFactor:deviceIdiom:layoutDirection:glyphSize:glyphWeight:glyphPointSize:appearanceName:"
        )

        guard catalog.responds(to: selector) else {
            throw Symbol2SVGError.coreUINotAvailable
        }

        let imp = catalog.method(for: selector)

        typealias GlyphMethod = @convention(c) (
            AnyObject,  // self
            Selector,  // _cmd
            NSString,  // name
            CGFloat,  // scaleFactor
            Int,  // deviceIdiom (0 = macOS)
            Int,  // layoutDirection (0 = LTR)
            Int,  // glyphSize (scale)
            Int,  // glyphWeight
            CGFloat,  // glyphPointSize
            NSString  // appearanceName
        ) -> NSObject?

        let typedIMP = unsafeBitCast(imp, to: GlyphMethod.self)

        guard
            let glyph = typedIMP(
                catalog,
                selector,
                name as NSString,
                1.0,  // scaleFactor
                0,  // macOS idiom
                0,  // LTR
                scale.rawIndex,
                weight.rawIndex,
                pointSize,
                "NSAppearanceNameAqua" as NSString
            )
        else {
            throw Symbol2SVGError.symbolNotFound(name: name)
        }

        // CGPath returns a CGPathRef (CF type, not NSObject) — must call via IMP
        let pathSelector = NSSelectorFromString("CGPath")
        guard glyph.responds(to: pathSelector) else {
            throw Symbol2SVGError.pathExtractionFailed(name: name)
        }

        let pathIMP = glyph.method(for: pathSelector)
        typealias CGPathMethod = @convention(c) (AnyObject, Selector) -> CGPath?
        let typedPathIMP = unsafeBitCast(pathIMP, to: CGPathMethod.self)

        guard let cgPath = typedPathIMP(glyph, pathSelector) else {
            throw Symbol2SVGError.pathExtractionFailed(name: name)
        }

        return (path: cgPath, bounds: cgPath.boundingBoxOfPath)
    }
}
