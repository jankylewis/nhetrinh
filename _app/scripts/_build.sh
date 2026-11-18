#!/bin/zsh
# Build nhetrinh.app (release) into _app/build/. Needs Command Line Tools only (no Xcode).
set -euo pipefail
cd "${0:A:h}/.."
VERSION=$(cat scripts/VERSION)
# The commit this build comes from; "+" marks files changed since that commit (the readback reports it).
COMMIT="$(git rev-parse --short HEAD)$(git diff --quiet HEAD -- . || echo +)"
# Size (NT-PRF-005): -Osize, and no exported symbols (an app has no plugins: NhetrinhCore's `public`
# API need not be exported). SwiftPM's release link already passes -dead_strip. NHT_OPT=-O compares.
OPT=${NHT_OPT:--Osize}
[[ "$OPT" == "-Osize" || "$OPT" == "-O" ]] || { echo "error: NHT_OPT is -Osize or -O, not $OPT" >&2; exit 1; }
swift build -c release --arch arm64 --product Nhetrinh -Xswiftc "$OPT" -Xlinker -no_exported_symbols
BIN=$(swift build -c release --arch arm64 --show-bin-path)
APP=build/nhetrinh.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/Nhetrinh" "$APP/Contents/MacOS/nhetrinh"
strip -x "$APP/Contents/MacOS/nhetrinh"
# Every Mach-O executable carries __mh_execute_header; older linkers list it as exported.
EXPORTS=$(nm -gU "$APP/Contents/MacOS/nhetrinh" | grep -vc ' __mh_execute_header$' || true)
if (( EXPORTS != 0 )); then
  echo "error: the app exports $EXPORTS symbols; 0 expected (NT-PRF-005):" >&2
  nm -gU "$APP/Contents/MacOS/nhetrinh" | grep -v ' __mh_execute_header$' >&2
  exit 1
fi
cp assets/_icon/bundle/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
# The app decodes this PNG for the Dock at launch: 1024 px cost 33 MB, 256 px nothing (NT-PRF-001).
DOCK=assets/_icon/bundle/_DockIcon.png
SIDE=$(sips -g pixelWidth "$DOCK" | awk '/pixelWidth/ {print $2}')
(( SIDE <= 256 )) || { echo "error: $DOCK is $SIDE px; the Dock icon is at most 256 px (NT-PRF-001)" >&2; exit 1; }
cp "$DOCK" "$APP/Contents/Resources/AppIcon.png"
# P5: http and https make nhetrinh a possible default browser (links from other apps open as tabs);
# the build never makes it the default. macOS asks once for ~/Downloads with the text below.
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
  <key>NSCameraUsageDescription</key>
  <string>A website asks to use the camera. nhetrinh asks you first, for each site.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>A website asks to use the microphone. nhetrinh asks you first, for each site.</string>
  <key>NSDownloadsFolderUsageDescription</key>
  <string>nhetrinh saves the files you download in your Downloads folder.</string>
  <key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsArbitraryLoadsInWebContent</key><true/></dict>
  <key>CFBundleURLTypes</key>
  <array><dict>
    <key>CFBundleURLName</key><string>Web site URL</string>
    <key>CFBundleTypeRole</key><string>Viewer</string>
    <key>CFBundleURLSchemes</key><array><string>http</string><string>https</string></array>
  </dict></array>
</dict></plist>
PLIST
# NT-BUG-019: without this key ATS refuses plain http (-1022) to every name but localhost (and, as recalled from
# Apple's docs, not proven: unqualified and .local names); IP addresses pass.
# Web content only: the app's own loads stay under ATS, and nothing else in the dict is relaxed.
ATS=$(plutil -extract NSAppTransportSecurity json -o - "$APP/Contents/Info.plist" 2>/dev/null || true)
[[ "$ATS" == '{"NSAllowsArbitraryLoadsInWebContent":true}' ]] || {
  echo "error: Info.plist NSAppTransportSecurity is '$ATS'; NSAllowsArbitraryLoadsInWebContent only (NT-BUG-019)" >&2
  exit 1
}
codesign --force --sign - "$APP"
echo "$APP $(du -sh "$APP" | cut -f1)"
