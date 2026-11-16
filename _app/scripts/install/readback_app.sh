#!/bin/zsh
# Wrap the release nhetrinh-readback binary into ~/Applications/nhetrinh-readback.app.
# macOS grants Accessibility per app: a terminal's grant does not reach a session it starts
# (NT-TG-003). The headmate grants this app once; it then runs the readback with its own grant.
#
#   readback_app.sh              build and install, only when the readback code changed
#   readback_app.sh run [flags]  also run it (flags as for nhetrinh-readback: --steps, --app);
#                                exits with the readback's own exit code
#
# An ad-hoc signature changes with every rebuild, and macOS then drops the grants (risk R-2, seen
# 2026-11-16). So the app is signed with the local identity of signing.sh when it exists (ad hoc
# otherwise), and rebuilt only when the hash of the readback's sources and of that identity
# changes (kept as NHTSourceHash). Creating the identity is the headmate's step: signing.sh create.
set -euo pipefail
cd "${0:A:h}/../.."
REPO="${PWD:h}"
APP=~/Applications/nhetrinh-readback.app
SIGN=$(scripts/install/signing.sh identity)  # SHA-1 of the local identity, or empty: ad hoc
SOURCES=$(find Package.swift _Sources/NhetrinhReadback -type f -name '*.swift' -print0 | LC_ALL=C sort -z \
  | xargs -0 shasum -a 256)
[[ -z "$SIGN" ]] || SOURCES+=$'\n'"signing $SIGN"  # without an identity the hash stays as before
HASH=$(print -r -- "$SOURCES" | shasum -a 256 | cut -c1-16)
INSTALLED=$(/usr/libexec/PlistBuddy -c 'Print :NHTSourceHash' "$APP/Contents/Info.plist" 2>/dev/null || true)

if [[ "$INSTALLED" == "$HASH" && -x "$APP/Contents/MacOS/nhetrinh-readback" ]]; then
  echo "unchanged $APP (source hash $HASH); not rebuilt, the grant stays"
else
  swift build -c release --arch arm64 --product nhetrinh-readback
  BIN=$(swift build -c release --arch arm64 --show-bin-path)
  BUILT=build/nhetrinh-readback.app
  rm -rf "$BUILT"
  mkdir -p "$BUILT/Contents/MacOS"
  cp "$BIN/nhetrinh-readback" "$BUILT/Contents/MacOS/nhetrinh-readback"
  strip -x "$BUILT/Contents/MacOS/nhetrinh-readback"
  cat > "$BUILT/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>nhetrinh-readback</string>
  <key>CFBundleIdentifier</key><string>io.github.jankylewis.nhetrinh.readback</string>
  <key>CFBundleExecutable</key><string>nhetrinh-readback</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$(cat scripts/VERSION)</string>
  <key>NHTSourceHash</key><string>$HASH</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
  codesign --force --sign "${SIGN:--}" "$BUILT"
  echo "signed with ${SIGN:+the local identity $SIGN}${SIGN:-an ad-hoc signature (no local identity: signing.sh)}"
  mkdir -p ~/Applications
  rm -rf "$APP"
  cp -R "$BUILT" "$APP"
  echo "installed $APP (source hash $HASH); macOS may ask for the Accessibility grant again (R-2)"
fi

[[ "${1:-}" == "run" ]] || exit 0
shift
# `open` passes no stdout and returns 0 whatever the app's exit code (NT-TG-003): the app writes
# both to the log, the code as its last line `exit: <code>`.
LOG=$(mktemp -t nhetrinh-readback)
open -W -n "$APP" --args --evidence "$REPO" --log "$LOG" "$@"
cat "$LOG"
CODE=$(tail -n 1 "$LOG" | sed -n 's/^exit: \([0-9]*\)$/\1/p')
rm -f "$LOG"
[[ -n "$CODE" ]] || { echo "no exit line in the log: the readback stopped early (NOT READ BACK)" >&2; exit 2; }
exit "$CODE"
