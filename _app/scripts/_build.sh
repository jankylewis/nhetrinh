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
  <key>CFBundleURLTypes</key>
  <array><dict>
    <key>CFBundleURLName</key><string>Web site URL</string>
    <key>CFBundleTypeRole</key><string>Viewer</string>
    <key>CFBundleURLSchemes</key><array><string>http</string><string>https</string></array>
  </dict></array>
</dict></plist>
PLIST
# Signature (P9-REMEMBER, NT-BLD-006): the local identity of install/signing.sh when it exists, so the next build
# reads the Keychain sign-ins the last one kept (an ad-hoc signature is new every build); else ad hoc (GitHub CI).
SIGN=$(scripts/install/signing.sh identity)  # SHA-1, or empty
codesign --force --sign "${SIGN:--}" "$APP"
SIGNED=$(codesign -dvv "$APP" 2>&1)
if [[ -n "$SIGN" ]]; then
  grep -qx 'Authority=nhetrinh local signing' <<<"$SIGNED" \
    || { echo "error: not signed by the local identity" >&2; exit 1; }
  echo "signed with the local identity 'nhetrinh local signing' ($SIGN)"
else
  grep -qx 'Signature=adhoc' <<<"$SIGNED" || { echo "error: no identity, yet the signature is not ad hoc" >&2; exit 1; }
  echo "signed ad hoc (no local identity: install/signing.sh); Keychain sign-ins may not survive the next build"
fi
echo "$APP $(du -sh "$APP" | cut -f1)"
