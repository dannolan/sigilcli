# sigil

Extract 8,000+ Apple system symbols as clean SVG vectors from the command line.

9 weights. Custom colors. Batch export. JSON mode. One command.

## Install

### Homebrew

```
brew tap dannolan/tools
brew install sigilcli
```

### From source

```
git clone https://github.com/dannolan/sigilcli.git
cd sigilcli
make install
```

## Quick start

```bash
# Get an SVG to stdout
sigil star.fill

# Save to a file
sigil star.fill -o star.svg
```

## Weights

Every symbol comes in 9 weights — from ultralight to black.

```bash
sigil star.fill --weight ultralight -o star-ultralight.svg
sigil star.fill --weight bold -o star-bold.svg
sigil star.fill --weight black -o star-black.svg
```

Export all 9 at once into a directory:

```bash
sigil star.fill --all-weights -o ./star-weights/
# Outputs: star.fill-ultralight.svg, star.fill-thin.svg, ... star.fill-black.svg
```

## Colors

By default SVGs use `currentColor` so they inherit color from CSS. Or set a specific color:

```bash
sigil heart.fill --color "#FF3B30" -o heart.svg
sigil cloud.fill --color royalblue -o cloud.svg
```

Combine with `--all-weights` to get every weight in a color:

```bash
sigil star.fill --all-weights --color "#FF9500" -o ./orange-stars/
```

## Finding symbols

```bash
# List everything
sigil --list

# Fuzzy search — matches all terms
sigil --search arrow right
sigil --search cloud fill

# Pipe-friendly search
sigil --list | grep heart

# Count them all
sigil --list | wc -l
```

## Batch export

Pipe a list of symbol names via stdin to export them all at once:

```bash
echo "star.fill\nheart.fill\ncloud.fill" | sigil --batch -o ./icons/
```

Skips symbols that don't exist and reports errors without stopping.

## JSON mode

Add `--json` to any command for structured output — useful for scripting and AI agents.

```bash
# Single symbol
sigil star.fill --json
```
```json
{
  "name": "star.fill",
  "weight": "regular",
  "scale": "medium",
  "width": 84.14,
  "height": 80.38,
  "svg": "<svg ...>"
}
```

```bash
# Batch with JSON report
echo "star.fill\nheart.fill" | sigil --batch --json -o ./icons/
```
```json
{
  "exported": [
    { "name": "star.fill", "width": 84.14, "height": 80.38, "file": "./icons/star.fill.svg" },
    { "name": "heart.fill", "width": 75.24, "height": 69.35, "file": "./icons/heart.fill.svg" }
  ],
  "errors": [],
  "total": 2
}
```

```bash
# Search as JSON
sigil --search arrow right --json

# List as JSON
sigil --list --json
```

## Quiet mode

Suppress status messages with `--quiet` / `-q` — only SVG output goes to stdout:

```bash
sigil star.fill -o star.svg --quiet
```

## All options

```
ARGUMENTS:
  <symbol-name>           Symbol name (e.g. 'star.fill')

OPTIONS:
  -o, --output            Output file path (or directory with --all-weights/--batch)
  -w, --weight            ultralight | thin | light | regular | medium |
                          semibold | bold | heavy | black (default: regular)
  -s, --size              small | medium | large (default: medium)
  -c, --color             Fill color, any CSS value (default: currentColor)
  --point-size            Point size for the glyph (default: 100)
  --precision             Decimal precision for coordinates (default: 3)
  --all-weights           Export all 9 weights as separate files
  --list                  List all available symbol names
  --search <terms...>     Fuzzy search for symbols matching all terms
  --batch                 Read symbol names from stdin, one per line
  --json                  Output as JSON instead of raw SVG
  -q, --quiet             Suppress status messages
```

## Requirements

- macOS 13+
- Xcode Command Line Tools (for building from source)

## License

MIT
