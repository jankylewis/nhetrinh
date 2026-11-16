# NT-PRF-001 — Dock icon decoded at 1024 px

id: NT-PRF-001
family: PRF
status: OBSERVED
date: 2026-11-16
signature: R8 the lightness budget holds | FAIL | one simple tab (example.com): app 60.0 MB (max 40)
source: hubs/failures/evidence/readback/_LATEST.md (R8 row)
source: _app/_Sources/_Nhetrinh/AppDelegate.swift `setDockIcon` (sets `NSApp.applicationIconImage`)
source: hubs/failures/evidence/prf/_NT_PRF_001_RUNS.jsonl (32 runs, taken with `measure.py` there)
observed: `footprint -p` of the MVP A app process: `32 MB CG Image` in 3 regions, of a 68 MB total
links: fix=yes lesson=no evidence=yes toolgap=none

## Mechanism

At launch the app sets its Dock icon at runtime (NT-BLD-001) from the 1024 x 1024 `AppIcon.png`.
AppKit keeps decoded copies of that image in the app process: about 33 MB, not the 4 MB of one copy.
Why there are about 8 copies' worth is not proven.

## One variable at a time

App launched via `open -n -F`, one tab, measured 6 s after its page process (as R8). Median of n runs, MB.

| Variable | Run A | Run B | App A / B | Total A / B |
|---|---|---|---|---|
| icon (MVP A, local page) | with 1024 px | without | 68.3 / 34.0 | 122.8 / 88.6 |
| icon (app, example.com, readback) | with 1024 px | without | 59.4 / 26.7 | 147.4 / 92.8 |
| icon size (same) | 512 px | 256 px | 43.3 / 35.4 | 106.7 / 95.4 |
| profile (no icon, example.com) | readback | default | 26.7 / 33.7 | 92.8 / 94.0 |
| page (no icon, readback) | example.com | local | 26.7 / 34.1 | 92.8 / 91.8 |
| page (MVP A, with icon) | example.com | local | 66.8 / 68.3 | 127.1 / 122.8 |
| build and code since b07f437 (no icon, local) | MVP A, swiftc -O -wmo | app, SwiftPM | 34.0 / 34.1 | 88.6 / 91.8 |

- The icon is the only variable that moves the app process past noise (about 7 MB between runs).
- Page: example.com costs about 3 MB more in WebContent and GPU than the local page (26 vs 23, 19 vs 16.5).
- Build and code were not separated: together they cost about nothing, so neither is a cause.
- The R&D rows (34.5 / 95.7) match the app without the runtime icon. Commit ff3ae8c already
  had the icon code, so those rows likely came from a build without it: not proven.

## Confirm

`footprint -p <pid>` of the running app: a `CG Image` row of tens of MB means a large decoded image.
Or remove `Contents/Resources/AppIcon.png` from a copy, re-sign it, and measure both.

## Related, not this cause

In 5 of 32 runs the GPU helper alone was 45-118 MB (with and without the icon). See NT-PRF-002.
