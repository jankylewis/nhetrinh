# nhetrinh

A very small macOS browser. Just browsing, a vertical tab sidebar, and the basics.
Nothing else: no extensions, no sync, no accounts, no telemetry.

Engine: **WebKit** (built into macOS). Shell: **Swift + AppKit**. No third-party dependencies.
Chosen by measurement against Chromium (CEF): see [`hubs/product/rnd/_bench/results/_RESULTS.md`](hubs/product/rnd/_bench/results/_RESULTS.md).

## Goals

1. **Lightweight**: smallest app, lowest memory. Budget: app process <= 40 MB, one simple tab <= 110 MB, app <= 1 MB.
2. **Fast**: start instantly, render as fast as WebKit allows.
3. **Basic**: new features only when asked for.

## Plan

Phases, gate, budget and decisions: [`hubs/product/plan/_PLAN.md`](hubs/product/plan/_PLAN.md).

## Layout

```
CLAUDE.md      briefing for every agent: the laws and the commands
_app/          the app (Swift Package Manager, Command Line Tools only, no Xcode)
  _Sources/    _Nhetrinh (AppKit + WebKit UI), NhetrinhCore (pure logic, unit tested),
               NhetrinhReadback (the readback tool)
  Tests/       Swift Testing tests of NhetrinhCore and of the readback tool's pure parts
  scripts/     _build.sh, install/_install.sh, test.sh, conventions/ (the checker), VERSION
  assets/      _icon (Hirono, pixel style)
hubs/          learnings (bugs, failures, lessons, tool gaps) and product (features, plan, rnd);
               read _SCHEMA.md
  product/rnd/ the WebKit vs Chromium benchmark and its results
.claude/       agent skills: nhetrinh-develop, nhetrinh-readback, nhetrinh-hubs, nhetrinh-ship
```

Conventions are checked by tool, locally and in CI: `_app/scripts/conventions/_check.py`.
Every folder: exactly one entry starts with `_` (its most critical entry), and at most 5 entries.
`.md` 100 lines; code 150 lines and 120 characters a line; function 30 lines and 5 parameters;
no force unwrap, `try!` or `as!`; no package dependency.

## Build

macOS 13+, Apple silicon, Command Line Tools. From the repository root:

```sh
python3 _app/scripts/conventions/_check.py                               # conventions: 0 violations
python3 -m unittest discover -s _app/scripts/conventions -p 'test_*.py'  # the checker's own tests
_app/scripts/test.sh             # unit tests (not plain `swift test`: NT-GAT-001)
_app/scripts/_build.sh           # -> _app/build/nhetrinh.app
_app/scripts/install/_install.sh          # -> ~/Applications/nhetrinh.app
cd _app && swift run nhetrinh-readback   # use the installed app as its end user
```

The readback drives the installed app through the Accessibility API and needs that
permission for the terminal. A full run writes its verdict to
[`hubs/failures/evidence/readback/_LATEST.md`](hubs/failures/evidence/readback/_LATEST.md).

## Shortcuts

⌘T new tab · ⌘W close tab · ⌘L address bar · ⌘R reload · ⌘[ ⌘] back / forward · ⌘1-9 switch tab · ⌘S toggle sidebar

## Icon

Hirono (a Pop Mart character), pixel style, no background: [`_app/assets/_icon`](_app/assets/_icon).
The app also sets its Dock icon at launch, because macOS draws bundle icons on a tile.
