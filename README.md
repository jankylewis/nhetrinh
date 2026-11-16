# nhetrinh

A very small macOS browser. Just browsing, a vertical tab sidebar, and the basics.
Nothing else: no extensions, no sync, no accounts, no telemetry.

> Status: R&D. Two MVPs are built and benchmarked against each other; the winner becomes nhetrinh v1.

## Goals

1. **Lightweight**: the smallest app and the lowest memory we can get.
2. **Fast**: start instantly, render pages as fast as the engine allows.
3. **Basic**: address bar, back / forward / reload, vertical tabs, shortcuts. New features only on request.

## R&D: which stack?

| | MVP A | MVP B |
|---|---|---|
| Engine | WebKit (built into macOS) | Chromium (CEF, bundled) |
| Shell | Swift + AppKit | Objective-C++ + AppKit |
| Code | [`rnd/a_webkit`](rnd/a_webkit) | [`rnd/b_cef`](rnd/b_cef) |

Both MVPs have the same features: a window with a vertical tab sidebar, address bar (URL or search),
back / forward / reload, new / close / switch tab, popups open as tabs, lazy tabs (a tab's engine
process starts only when you first open it), unloading of tabs idle for 10 minutes, and the same shortcuts
(⌘T ⌘W ⌘L ⌘R ⌘[ ⌘] ⌘1-9 ⌘S).

The benchmark ([`rnd/bench`](rnd/bench)) launches each app via LaunchServices like a Dock click,
one app at a time, A/B alternating, and waits until all helper processes have exited
before the next run. Memory = `phys_footprint` (Activity Monitor's "Memory") summed over the app
**and every helper process** (WebKit XPC services, Chromium helpers).

Results: [`rnd/bench/results/RESULTS.md`](rnd/bench/results/RESULTS.md).

## Build

macOS 13+, Apple silicon, Command Line Tools (Xcode not required).

```sh
rnd/a_webkit/build.sh          # -> rnd/a_webkit/build/nhetrinh-a.app
rnd/b_cef/fetch_cef.sh         # one-time: pinned Chromium build (~135 MB download)
rnd/b_cef/build.sh             # -> rnd/b_cef/build/nhetrinh-b.app
clang -O2 -o rnd/bench/memsum rnd/bench/memsum.c
python3 -I rnd/bench/bench.py  # ~40 min; windows open and close
python3 -I rnd/bench/summarize.py
```

## Icon

Hirono (a Pop Mart character) in pixel style, no background: [`assets/icon`](assets/icon).
`lift.swift` cuts the subject out of the photo (macOS Vision), `pixelate.swift` turns it into
80x80 pixel art with hard edges, `make_icns.sh` builds the `.icns`.
The app also sets its Dock icon at launch (`NSApp.applicationIconImage`), because macOS draws
bundle icons on a tile, while a runtime icon is drawn as-is.
