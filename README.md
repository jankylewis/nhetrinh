# nhetrinh

A very small macOS browser. Just browsing, a vertical tab sidebar, and the basics.
Nothing else: no extensions, no sync, no accounts, no telemetry.

Engine: **WebKit** (built into macOS). Shell: **Swift + AppKit**. No third-party dependencies.
Chosen by measurement against Chromium (CEF): see [`rnd/_bench/results/_RESULTS.md`](rnd/_bench/results/_RESULTS.md).

## Goals

1. **Lightweight**: smallest app, lowest memory. Budget: app process <= 40 MB, one simple tab <= 110 MB, app <= 1 MB.
2. **Fast**: start instantly, render as fast as WebKit allows.
3. **Basic**: new features only when asked for.

## Plan

Phases, gate, budget and decisions: [`hubs/product/plan/_PLAN.md`](hubs/product/plan/_PLAN.md).

## Layout

```
_app/          the app (Swift Package Manager, Command Line Tools only, no Xcode)
  _Sources/    _Nhetrinh (AppKit + WebKit UI), NhetrinhCore (pure logic, unit tested)
  Tests/       Swift Testing
  scripts/     _build.sh, install.sh, check_tree.py, VERSION
  assets/      _icon (Hirono, pixel style)
hubs/          learnings (bugs, failures, lessons, tool gaps) and product (features, plan); read _SCHEMA.md
rnd/           the WebKit vs Chromium benchmark and its results
```

Every folder: exactly one entry starts with `_` (its most critical entry), and at most 5 entries.
`_app/scripts/check_tree.py` checks both, locally and in CI.

## Build

macOS 13+, Apple silicon, Command Line Tools.

```sh
cd _app && swift test            # unit tests
_app/scripts/_build.sh           # -> _app/build/nhetrinh.app
_app/scripts/install.sh          # -> ~/Applications/nhetrinh.app
```

## Shortcuts

⌘T new tab · ⌘W close tab · ⌘L address bar · ⌘R reload · ⌘[ ⌘] back / forward · ⌘1-9 switch tab · ⌘S toggle sidebar

## Icon

Hirono (a Pop Mart character), pixel style, no background: [`_app/assets/_icon`](_app/assets/_icon).
The app also sets its Dock icon at launch, because macOS draws bundle icons on a tile.
