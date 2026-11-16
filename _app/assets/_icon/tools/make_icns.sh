#!/bin/zsh
# _AppIcon.png (1024, transparent) -> bundle/AppIcon.icns (Finder, Launchpad).
# 16, 32 and 64 px are smoothed by sips (a nearest-neighbour downscale would drop grid cells);
# 128 px and up are the 80 px grid drawn nearest-neighbour (tools/nearest.swift): the hard pixels of the
# master at a third of the old size (NT-PRF-003). The result is checked against the master, pixel for pixel.
set -euo pipefail
cd "${0:A:h}/.."
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
swiftc -O tools/nearest.swift -o "$WORK/nearest"
mkdir "$WORK/AppIcon.iconset"
for s in 16 32; do
  sips -z $s $s _AppIcon.png --out "$WORK/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) _AppIcon.png --out "$WORK/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
for s in 128 256 512; do
  "$WORK/nearest" draw _AppIcon.png "$WORK/AppIcon.iconset/icon_${s}x${s}.png" $s
  "$WORK/nearest" draw _AppIcon.png "$WORK/AppIcon.iconset/icon_${s}x${s}@2x.png" $((s*2))
done
iconutil -c icns "$WORK/AppIcon.iconset" -o bundle/AppIcon.icns
iconutil -c iconset bundle/AppIcon.icns -o "$WORK/check.iconset"
"$WORK/nearest" check _AppIcon.png "$WORK/check.iconset"
echo "bundle/AppIcon.icns $(stat -f %z bundle/AppIcon.icns) bytes"
