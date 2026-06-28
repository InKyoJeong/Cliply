#!/bin/bash
# Generates Resources/AppIcon.icns (and a 1024px preview) from generate_icon.swift.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$ROOT/build/AppIcon.iconset"

rm -rf "$ICONSET"
mkdir -p "$ROOT/Resources" "$ROOT/build"

swift "$ROOT/Scripts/generate_icon.swift" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$ROOT/Resources/AppIcon.icns"
cp "$ICONSET/icon_512x512@2x.png" "$ROOT/Resources/AppIcon.png"

echo "Created Resources/AppIcon.icns and Resources/AppIcon.png"
