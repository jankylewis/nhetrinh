#!/bin/zsh
# Download + unpack the pinned CEF (Chromium) build and its C++ wrapper lib into vendor/cef.
set -euo pipefail
cd "${0:A:h}"
NAME='cef_binary_156.0.30+g6028375+chromium-156.0.8078.96_macosarm64_minimal.tar.bz2'
SHA1='6393d8a838d3b29f6b6939b970b5931dde2082aa'
[[ -d vendor/cef/Release ]] && { echo "vendor/cef present"; exit 0; }
mkdir -p vendor
curl -4 -fsS -m 1800 -o vendor/cef.tar.bz2 "https://cef-builds.spotifycdn.com/${NAME//+/%2B}"
echo "$SHA1  vendor/cef.tar.bz2" | shasum -a 1 -c -
tar xjf vendor/cef.tar.bz2 -C vendor && rm vendor/cef.tar.bz2
mv vendor/cef_binary_* vendor/cef
cmake -S vendor/cef -B vendor/cef/build -G "Unix Makefiles" -DPROJECT_ARCH=arm64 -DCMAKE_BUILD_TYPE=Release >/dev/null
make -C vendor/cef/build -j4 libcef_dll_wrapper >/dev/null
echo "CEF ready: $NAME"
