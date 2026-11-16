# NT-TG-001 — No safe Dock readback

id: NT-TG-001
family: UIX
status: OPEN
date: 2026-11-16
source: NT-BUG-002 readback attempt (2026-11-16)
links: fix=no lesson=no evidence=no toolgap=NT-TG-001

## Gap

No tool shows the app's Dock icon as the user sees it. `NSWorkspace.icon(forFile:)` returns the bundle icon on its tile, not the runtime icon,
and a screen capture of the Dock area can include the headmate's private windows (NT-TG-002).

## Workaround

Ask the headmate to look at the Dock, or read `NSApp.applicationIconImage` back from inside the app (not built).

## Wanted

A bench hook that writes the current Dock icon image to a file, compared with `AppIcon.png`.
