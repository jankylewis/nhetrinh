#!/bin/zsh
# Build MVP B (AppKit + Chromium/CEF) into build/nhetrinh-b.app. Needs vendor/cef + its wrapper lib.
set -euo pipefail
cd "${0:A:h}"
CEF=vendor/cef
APP=build/nhetrinh-b.app
FLAGS=(-std=c++20 -fobjc-arc -O2 -fno-rtti -fno-exceptions -mmacosx-version-min=13.0 -arch arm64 -I"$CEF")
WRAP="$CEF/build/libcef_dll_wrapper/libcef_dll_wrapper.a"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks" build/obj
clang++ "${FLAGS[@]}" src/main.mm "$WRAP" -framework Cocoa -o "$APP/Contents/MacOS/nhetrinh-b"
clang++ "${FLAGS[@]}" src/helper.mm "$WRAP" -framework Cocoa -o build/obj/helper
ditto "$CEF/Release/Chromium Embedded Framework.framework" "$APP/Contents/Frameworks/Chromium Embedded Framework.framework"

plist() {  # name exe id extra
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$1</string>
  <key>CFBundleExecutable</key><string>$2</string>
  <key>CFBundleIdentifier</key><string>$3</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.0.1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  $4
</dict></plist>
PLIST
}

for suffix in "" " (GPU)" " (Renderer)" " (Plugin)" " (Alerts)"; do
  name="nhetrinh-b Helper$suffix"
  id="dev.nhetrinh.rnd.b.helper$(echo "$suffix" | tr -d ' ()' | tr 'A-Z' 'a-z' | sed 's/^./.&/')"
  dir="$APP/Contents/Frameworks/$name.app/Contents"
  mkdir -p "$dir/MacOS"
  cp build/obj/helper "$dir/MacOS/$name"
  plist "$name" "$name" "$id" "<key>LSUIElement</key><true/>" > "$dir/Info.plist"
done
plist nhetrinh-b nhetrinh-b dev.nhetrinh.rnd.b "<key>NSPrincipalClass</key><string>NhtApp</string>" > "$APP/Contents/Info.plist"
strip -x "$APP/Contents/MacOS/nhetrinh-b"
mkdir -p "$APP/Contents/Resources" && cp ../../assets/icon/AppIcon.icns ../../assets/icon/AppIcon.png "$APP/Contents/Resources/"
codesign --force --deep --sign - "$APP"
du -sh "$APP"
