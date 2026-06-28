#!/bin/bash
# Builds Cliply.app (release) into ./build, ready to run or drag to /Applications.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Make the icon if it is missing.
if [[ ! -f "$ROOT/Resources/AppIcon.icns" ]]; then
    bash "$ROOT/Scripts/make_icon.sh"
fi

echo "Building release binary…"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/Cliply"

APP="$ROOT/build/Cliply.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/Cliply"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc sign so macOS lets it run locally without Gatekeeper complaints.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "Built $APP"
echo "Run it with:  open \"$APP\""
echo "Install it with:  cp -R \"$APP\" /Applications/"
