# nhetrinh

A very small macOS browser: WebKit (built into macOS), a vertical tab sidebar, and the basics.
No extensions, no sync, no accounts, no telemetry. Lightness first: one simple tab costs about 32 MB
in the app and 90 MB with WebKit's helpers; the app is under 1 MB (`hubs/product/rnd/LIGHTNESS_1_0.md`).

## Install

Apple silicon, macOS 13 or later.

1. From the [Releases](../../releases) page, download `nhetrinh-<version>-arm64.zip` and its `.sha256`.
2. Check it: `shasum -a 256 -c nhetrinh-<version>-arm64.zip.sha256` must print `OK`.
3. Unzip it and move `nhetrinh.app` to Applications.

### The first open

nhetrinh is not notarized (there is no Apple Developer ID), so macOS refuses the first open of a
downloaded copy with a warning. Check the SHA-256 first, then, once:

- macOS 15 or later: open nhetrinh, close the warning, go to System Settings > Privacy & Security,
  and press **Open Anyway** next to "nhetrinh was blocked"; confirm.
- macOS 13 and 14: Control-click nhetrinh.app in Finder, choose **Open**, then **Open**.

After that it opens like any app. To make it your default browser: System Settings > Desktop & Dock >
Default web browser. nhetrinh never changes that setting itself.

## Use

- **Sidebar**: one row per tab. Drag to reorder; hover for the close button; middle-click closes.
  Right-click a tab: New Group…, New Group from Selected Tab…, Move Tab to Group, Move Out of Group,
  Close Tab. Groups nest 4 levels deep; a group's row shows its tab count and its menu has Rename Group…
  (or double-click it), Collapse, New Group Inside…, Move Group to, Ungroup (its tabs and groups move up,
  none closes) and Close Group… (Reopen Closed Tab brings it back). A collapsed group that holds the
  shown tab is bold with a dot.
- **Tabs** come back after a quit. A tab not used for a while gives its memory back and reloads
  when you click it, with its history; a tab that plays sound is kept. When macOS is short of memory,
  nhetrinh unloads background tabs at once.
- **Downloads** go to ~/Downloads; the sidebar footer shows every running one, with Cancel. A click
  on a finished one shows it in Finder. A downloaded file says where it came from (Finder's Get Info,
  "Where from"), and a page that starts a 6th download without a click asks you first.
- **Pages** can ask (alerts, sign-in, camera, a link to another app): always in a sheet on the window.

## Shortcuts

| Keys | Does | Keys | Does |
|---|---|---|---|
| ⌘T | New Tab | ⌘W | Close Tab |
| ⇧⌘T | Reopen Closed Tab | ⌘L | Address bar |
| ⌘R / ⌘. | Reload / Stop | ⌘[ / ⌘] | Back / Forward |
| ⌃⇥ / ⌃⇧⇥ | Next / previous tab | ⌘1-⌘8, ⌘9 | A shown tab, the last one |
| ⌘F, ⌘G, ⇧⌘G | Find, next, previous | ⌘+ / ⌘- / ⌘0 | Zoom in / out / actual size |
| ⌘S | Show or hide the sidebar | ⌘P | Print |
| ⌘, | Settings Hub | ⌘Q | Quit |

⌘1-⌘9 count the tabs you see: a tab inside a collapsed group is skipped. Zoom is kept per site.

## Settings Hub (⌘,)

Appearance (System, Light, Dark) · Sidebar position (Left, Right) · Search engine (Google, DuckDuckGo,
Bing) · Unload idle tabs after N minutes · Clear Website Data… (the last hour, or all). Your tabs and
settings stay on this Mac:
`~/Library/Application Support/nhetrinh/` (`session.json`, `prefs.json`).

## Known limits

- Not notarized: the macOS warning at the first open (above). Apple silicon only.
- No extensions, bookmarks, history list, address-bar suggestions, sync, password manager, private
  window, reader mode or content blocker; one window. These come only when asked for.
- A WebKit app that is not Safari: password autofill from Safari or iCloud may not work, some sites
  refuse its sign-in, and sites that work only in Chrome do not work.
- Find says found or not found, with no match count. Web Inspector: from Safari's Develop menu only.
- A certificate error shows an error page, with no "proceed anyway".
- A camera or microphone answer lasts until quit. A page's question brings its tab to the front
  (NT-TAB-002), and a page may ask to open another app without a click; the sheet asks every time
  (NT-NAV-004).
- In the Dock, a pinned nhetrinh that is not running shows its icon on a tile (D20).
- WebKit's GPU helper can use about 100 MB more for 1 to 3 seconds (NT-PRF-002).

Every open item, with its status: `hubs/bugs/TRIAGE.md` and `hubs/failures/TRIAGE.md`.

## Build from source

Command Line Tools only (no Xcode). From the repository root:

```sh
python3 _app/scripts/conventions/_check.py   # conventions: 0 violations
_app/scripts/test.sh                         # unit tests (not plain `swift test`: NT-GAT-001)
_app/scripts/_build.sh                       # -> _app/build/nhetrinh.app
_app/scripts/install/_install.sh             # -> ~/Applications/nhetrinh.app
cd _app && swift run nhetrinh-readback       # use the installed app as its end user
```

`CLAUDE.md` holds the laws and the map; `hubs/product/plan/_PLAN.md` the phases, the gate and the
budget. A tag `v<version>` runs `.github/workflows/release.yml`: the same checks and build as CI, the
zip, its SHA-256 and the Release, with notes from `hubs/product/features/`.

Engine chosen by measurement against Chromium: `hubs/product/rnd/_bench/results/_RESULTS.md`.
Icon: Hirono (a Pop Mart character), pixel style: `_app/assets/_icon`.
