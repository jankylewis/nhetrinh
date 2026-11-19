# NT-BUG-024 — A page scrolls sideways but not up and down

id: NT-BUG-024
family: UIX
status: NOT_A_BUG
date: 2026-11-18
signature: can scroll horizontally, cannot scroll vertically
source: the headmate's report and withdrawal, 2026-11-18 (matemaster session, outside the repository)
observed: reported by the headmate on the installed app, 2026-11-18; no screen capture kept
found_by: headmate (2026-11-18, "i can scroll horizontally, but cannot scroll vertically right now")
links: fix=no lesson=no evidence=no toolgap=none

## Steps

On one page, scroll with the trackpad or the mouse wheel.

Expected: the page scrolls up and down.
Reported: it scrolled sideways only.

## Outcome

The headmate withdrew it while the matemaster was reading nhetrinh's scroll, gesture and zoom code: "it is not
bug, my bad". No nhetrinh code was changed. What blocked the scroll was not recorded (not proven). If it comes
back, check first whether the page itself (an inner scroll area, a modal) holds the scroll, in another browser too.
