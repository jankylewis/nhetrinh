#!/bin/zsh
# Run the unit tests (Swift Testing). Extra arguments go to `swift test`.
#
# With Command Line Tools only (no Xcode), SwiftPM sometimes leaves the Swift Testing macro
# plugin path out of the compile command, and the test build fails with
# "plugin for module 'TestingMacros' not found" (NT-GAT-001). Passing the path here makes the
# build the same on every run.
set -euo pipefail
cd "${0:A:h}/.."
TOOLS="$(xcode-select -p)"
PLUGINS="$TOOLS/usr/lib/swift/host/plugins/testing"
if [[ -d "$PLUGINS" ]]; then
  exec swift test -Xswiftc -external-plugin-path -Xswiftc "$PLUGINS#$TOOLS/usr/bin/swift-plugin-server" "$@"
fi
exec swift test "$@"
