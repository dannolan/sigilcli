# sigil

Extract Apple system symbols as clean SVG vectors from the command line.

There's no public API to get vector paths out of Apple's system symbol catalog. **sigil** uses private CoreUI APIs to extract the actual `CGPath` data and serialize it to SVG. Pure vectors, no rasterization, no intermediate bitmaps.

8,000+ symbols. 9 weights. One command.

## Install

### Homebrew

```
brew tap dannolan/tools
brew install sigil
```

### From source

```
git clone https://github.com/dannolan/sigil.git
cd sigil
make install
```

## Usage

```bash
# SVG to stdout
sigil star.fill

# Write to file
sigil star.fill -o star.svg

# Bold weight
sigil star.fill --weight bold

# Custom color
sigil heart.fill --color "#FF3B30"

# All 9 weights at once
sigil star.fill --all-weights -o ./star-weights/

# List every available symbol
sigil --list

# Search symbols
sigil --list | grep arrow
```

## Options

```
ARGUMENTS:
  <symbol-name>           Symbol name (e.g. 'star.fill')

OPTIONS:
  -o, --output            Output file path (or directory with --all-weights)
  -w, --weight            ultralight | thin | light | regular | medium | semibold | bold | heavy | black
  -s, --size              small | medium | large
  -c, --color             Fill color (e.g. '#FF0000', 'red'). Defaults to 'currentColor'
  --point-size             Point size for the glyph (default: 100)
  --precision             Decimal precision for path coordinates (default: 3)
  --all-weights           Export all 9 weights as separate files
  --list                  List all available symbol names
```

## Requirements

- macOS 13+
- Xcode Command Line Tools (for building from source)

## How it works

Apple ships every system symbol as vector glyph data inside `CoreGlyphs.bundle`. The public `NSImage(systemSymbolName:)` API only gives you rasterized output. **sigil** loads the asset catalog directly via the private `CUICatalog` class, calls `namedVectorGlyphWithName:...` to get a `CUINamedVectorGlyph`, extracts the `CGPath`, and walks its elements to build an SVG `<path>` element.

The output uses `fill="currentColor"` by default so your SVGs inherit color from CSS — drop them straight into a web project and style with `color:`.

## License

MIT
