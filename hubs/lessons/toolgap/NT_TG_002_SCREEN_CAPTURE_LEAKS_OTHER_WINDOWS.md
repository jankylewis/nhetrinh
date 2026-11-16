# NT-TG-002 — Screen capture leaks other windows

id: NT-TG-002
family: UIX
status: OPEN
date: 2026-11-16
source: MVP B screenshot attempt (2026-11-16): a region capture caught another app's window instead of nhetrinh
links: fix=no lesson=no evidence=no toolgap=NT-TG-002

## Gap

`screencapture -R` captures whatever is on screen in that region, including private windows of other apps.

## Workaround

Do not capture screen regions. Delete any capture that shows another app at once.

## Wanted

Capture one window by id (`screencapture -l <windowid>`, id from `CGWindowListCopyWindowInfo` for our pid).
