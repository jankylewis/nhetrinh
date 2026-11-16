#!/bin/zsh
# Build MVP A (Swift + AppKit + WKWebView) into build/nhetrinh-a.app. No Xcode needed.
set -euo pipefail
cd "${0:A:h}"
APP=build/nhetrinh-a.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -wmo -target arm64-apple-macos13.0 \
  -framework AppKit -framework WebKit \
  Sources/*.swift -o "$APP/Contents/MacOS/nhetrinh-a"
strip -x "$APP/Contents/MacOS/nhetrinh-a"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>nhetrinh-a</string>
  <key>CFBundleIdentifier</key><string>dev.nhetrinh.rnd.a</string>
  <key>CFBundleExecutable</key><string>nhetrinh-a</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.0.1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
mkdir -p "$APP/Contents/Resources" && cp ../../assets/icon/AppIcon.icns ../../assets/icon/AppIcon.png "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
du -sh "$APP"
