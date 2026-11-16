# NT-PRF-001 — Dock icon decoded at 1024 px — fix

id: NT-PRF-001
family: PRF
status: OBSERVED
date: 2026-11-16
source: _app/assets/_icon/bundle/_DockIcon.png (256 x 256, made by `tools/shrink.swift`)
source: _app/scripts/_build.sh (ships `_DockIcon.png` as `AppIcon.png`; stops on a Dock icon over 256 px)
source: hubs/failures/evidence/prf/_NT_PRF_001_RUNS.jsonl (label `F_256_rb_ex`)
links: fix=yes lesson=no evidence=yes toolgap=none

## Fix that holds

Ship a 256 x 256 px Dock icon, made from `_app/assets/_icon/_AppIcon.png` with nearest-neighbour
scaling, so the pixel look stays. The 1024 px master stays for the `.icns` (Finder, Launchpad).
`_build.sh` reads the PNG width and stops the build when it is over 256 px: the family guard,
so a large runtime image cannot come back into the bundle unseen.

## The wrong fix

512 px, the size the Dock draws at its largest (256 pt): the app process measured 41.4-44.6 MB,
still over the 40 MB budget. At 256 px the Dock scales the icon up only at its largest sizes.

## Proof

Fixed build, R8 conditions (example.com, profile readback), 5 runs:
app 34.1-36.5 MB (budget 40), app + 5 helpers 94.3-96.6 MB (budget 110), bundle 520 KB.
Before: app 59.2-61.0 MB, total 117.4-151.6 MB.

Not proven yet: the readback R8 on the installed app (not run by this seat), and that the
Dock still shows the icon without a tile at 256 px (R2).
