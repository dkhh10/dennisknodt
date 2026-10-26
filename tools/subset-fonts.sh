#!/usr/bin/env bash
#
# Shrinks the self-hosted text fonts (assets/lib/fonts) to the Latin, Latin Extended
# and Vietnamese character sets, the same ranges Google Fonts serves for these fonts.
# Glyphs, hinting and OpenType features are kept, so text renders identically.
# Only the .woff2 files are replaced; browsers that use the .woff/.ttf fallbacks
# still get the full fonts.
#
# Requires: pip install fonttools brotli
#
# Usage: bash tools/subset-fonts.sh [FONTS_DIR]

set -eu

FONTS_DIR="${1:-assets/lib/fonts}"

UNICODES="U+0000-00FF,U+0100-02BA,U+02BB-02FF,U+0300-036F,U+1D00-1DBF,U+1E00-1EFF,\
U+2000-206F,U+20A0-20C0,U+2113,U+2122,U+2190-2193,U+2212,U+2215,U+2C60-2C7F,\
U+A720-A7FF,U+FEFF,U+FFFD"

for font in "$FONTS_DIR"/*/*.woff2; do
  before=$(wc -c < "$font")
  pyftsubset "$font" --unicodes="$UNICODES" --layout-features='*' \
    --flavor=woff2 --output-file="$font.tmp"
  mv "$font.tmp" "$font"
  echo "$(basename "$font"): $((before / 1024)) KB -> $(($(wc -c < "$font") / 1024)) KB"
done
