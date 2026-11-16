# M2 — Real sites work (P3, P4, P5)

After M2 nhetrinh does what every site expects from a browser. The gate is in `_PLAN.md`.
The readback tool serves its own local test pages, so these steps do not depend on the network.

## P3 — Page basics: sites must not break (0.4.0, size L, status TODO)

Goal: the things below work. Today each one fails without a message, because a WebKit view
does nothing for them until the app adds the code.

Build (App, the WebKit delegate files in `_Browser/`):
1. JavaScript `alert`, `confirm`, `prompt` as sheets on the window. Today `confirm` answers
   "no" and shows nothing.
2. File upload: `<input type="file">` opens the macOS open panel. Today nothing happens.
3. Load errors: an error page with the reason (offline, name not found, certificate, timeout)
   and a Retry button. Today nothing is shown.
4. HTTP sign-in (Basic, Digest): a user and password sheet. A bad certificate shows the error
   page; there is no "proceed anyway" in v1 (`DECISIONS.md` Q5).
5. Camera and microphone: a permission prompt per site, and the two usage texts in Info.plist.
6. Fullscreen video.
7. Print: File > Print… (⌘P).
8. Links to other apps (`mailto:`, meeting apps and so on): ask, then hand the link to macOS.
9. Web Inspector through the public API (`isInspectable`: inspect from Safari's Develop menu).
   An "Inspect Element" item inside nhetrinh needs a private WebKit key (`DECISIONS.md` Q3).

Core and tests: `ErrorPage.html(for:)` (error code to text); `ExternalScheme` (which schemes
leave the browser; `http`, `https`, `about`, `blob`, `data`, `file` stay).

Readback adds:
- R19 `alert`: the sheet shows the text; OK closes it.
- R20 `confirm`: Cancel makes the page show "false"; OK makes it show "true".
- R21 `prompt`: the typed text reaches the page.
- R22 file input: the panel opens; pick a fixture file; the page shows its name.
- R23 a closed port: the error page with Retry. Start the server, press Retry: the page loads.
- R24 a Basic sign-in page: the sheet; the right password loads the page, a wrong one asks again.
- R25 File > Print…: the print panel opens; cancel.
- R26 a `mailto:` link: the ask sheet appears; cancel; nothing leaves the app.
- Camera, microphone and fullscreen: the readback tries them on a local page. If the macOS
  prompt cannot be driven, the report says "not read back".

Exit: the gate, R1-R26 PASS. Risk R-2 (permission grants after a rebuild) is checked here.

## P4 — Find, zoom, small tools (0.5.0, size M, status TODO)

Goal: find text, zoom per site, and one place for the few settings.

Build:
- Find bar under the toolbar, from Edit > Find > Find… (⌘F), Find Next (⌘G), Find Previous (⇧⌘G).
  Esc or the bar's Close button closes it and gives the focus back to the page. WebKit's find
  API answers found or not found only, so v1 shows no match count.
- Zoom: View > Zoom In (⌘+), Zoom Out (⌘-), Actual Size (⌘0), and pinch. The level is kept per
  site (host). A zoom badge shows in the address bar when the level is not 100 %.
- Core `Prefs`, saved as `prefs.json`: zoom levels, search engine (Google, DuckDuckGo, Bing),
  idle-unload minutes. A corrupt file gives the defaults and the bad file is kept.
- Settings Hub (D19): one small native window, opened with ⌘, (menu nhetrinh > Settings Hub…).
  It holds Appearance (System, Light, Dark: `Prefs` key `appearance`, applied with `NSApp.appearance`,
  nil for System; pages follow `prefers-color-scheme`), Search engine, Unload idle tabs after
  N minutes, and Clear Website Data… (cookies and cache; all, or the last hour; a confirm sheet).

Tests: zoom steps (50 % to 300 %, clamped at both ends); host key (lower case, port ignored);
`Prefs` round trip, corrupt file, missing keys; `appearance` round trip, an unknown value gives
System; the search URL per engine through `AddressParser`.

Readback adds:
- R27 Edit > Find > Find…, set "Example": found; "zzzz": not found. Close button: the bar is gone.
- R28 View > Zoom In twice: the badge shows 125 %. Relaunch: still 125 % on that host, 100 % on another.
- R29 change the search engine: the next search goes to that engine's URL.
- R30 Clear Website Data: a cookie set by a local page is gone.
- R30a nhetrinh > Settings Hub…, Appearance Dark: the window is dark and a local page that reads
  `prefers-color-scheme` shows dark. Relaunch: still dark. Appearance System: the system look again.

Exit: the gate, R1-R30 and R30a PASS.

## P5 — Downloads and links from other apps (0.6.0, size M, status TODO)

Goal: files download to ~/Downloads. A link clicked in another app opens in nhetrinh.

Build:
- Downloads (`WKDownload`), started by a type WebKit cannot show, by
  `Content-Disposition: attachment`, or by `<a download>`. The file goes to `~/Downloads`
  under a free name (Core `DownloadNamer`: `a.pdf`, then `a (1).pdf`).
- Sidebar footer: up to 3 download rows with name, progress and cancel. Click a finished row:
  Finder shows the file. A failed row shows the reason.
- macOS asks once for access to the Downloads folder; Info.plist carries the text for it.
- Links from other apps: Info.plist declares `http` and `https`, and an incoming URL opens as
  a new tab. nhetrinh then shows in System Settings as a possible default browser.
  The readback never changes the headmate's default browser.

Tests: `DownloadNamer` (free name, 1 clash, 2 clashes, no extension, dot file, long name);
`DownloadPolicy` table (type x can show x disposition).

Readback adds:
- R31 a local 1 MB attachment: a row appears; the file is in ~/Downloads with the right size.
- R32 the same file again: saved as `name (1)`.
- R33 a slow 20 MB stream: cancel; no partial file is left.
- R34 click a finished row: Finder is asked to show the file.
- R35 `open -b io.github.jankylewis.nhetrinh <url>`: rows +1 with that URL.
- The readback deletes its own files from ~/Downloads at the end.

Exit: the gate, R1-R35 PASS.
