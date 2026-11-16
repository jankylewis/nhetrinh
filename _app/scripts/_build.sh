#!/bin/zsh
# Build nhetrinh.app (release) into _app/build/. Needs Command Line Tools only (no Xcode).
set -euo pipefail
cd "${0:A:h}/.."
VERSION=$(cat scripts/VERSION)
# The commit this build comes from; "+" marks files changed since that commit (the readback reports it).
COMMIT="$(git rev-parse --short HEAD)$(git diff --quiet HEAD -- . || echo +)"
swift build -c release --arch arm64 --product Nhetrinh
BIN=$(swift build -c release --arch arm64 --show-bin-path)
APP=build/nhetrinh.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/Nhetrinh" "$APP/Contents/MacOS/nhetrinh"
strip -x "$APP/Contents/MacOS/nhetrinh"
cp assets/_icon/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp assets/_icon/_AppIcon.png "$APP/Contents/Resources/AppIcon.png"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>nhetrinh</string>
  <key>CFBundleDisplayName</key><string>nhetrinh</string>
  <key>CFBundleIdentifier</key><string>io.github.jankylewis.nhetrinh</string>
  <key>CFBundleExecutable</key><string>nhetrinh</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>NHTCommit</key><string>$COMMIT</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
echo "$APP $(du -sh "$APP" | cut -f1)"
