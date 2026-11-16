#!/bin/zsh
# Build and install nhetrinh.app into ~/Applications (quits a running copy first).
set -euo pipefail
cd "${0:A:h}/.."
./_build.sh
osascript -e 'quit app id "io.github.jankylewis.nhetrinh"' 2>/dev/null || true
mkdir -p ~/Applications
rm -rf ~/Applications/nhetrinh.app
cp -R ../build/nhetrinh.app ~/Applications/
echo "installed ~/Applications/nhetrinh.app $(cat VERSION)"
