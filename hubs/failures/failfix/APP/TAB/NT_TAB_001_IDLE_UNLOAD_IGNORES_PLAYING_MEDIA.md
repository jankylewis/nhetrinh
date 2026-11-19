# NT-TAB-001 — Idle unload ignores playing media — fix

id: NT-TAB-001
family: TAB
status: OPEN
date: 2026-11-16
source: _app/_Sources/NhetrinhCore/Tabs/Lifecycle/UnloadPolicy.swift (`tabsToUnload`: a playing tab is never named)
source: _app/_Sources/_Nhetrinh/_Browser/Lifecycle/Idle/_IdleUnload.swift (`unloadIdleTabs`, `requestMediaPlaybackState`)
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift (`select`: `lastActive` when left)
source: _app/Tests/_NhetrinhCoreTests/Tabs/Lifecycle/UnloadPolicyTests.swift (table of 12 + 2 edges, P1-PREP-1)
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/UnloadSteps.swift (`playingTabStaysLoaded`, R11)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (built in P1-BUILD-1, not read back)

1. `UnloadPolicy.tabsToUnload` names a tab only when it is loaded, not selected, not playing,
   and idle for longer than the limit (exactly at the limit is not yet idle).
2. The app runs the policy once on time alone, then asks WebKit `requestMediaPlaybackState`
   for each tab it named, and runs the policy again on the tabs as they are when every answer is
   in. `.playing` keeps the tab; a tab that was not asked counts as playing (kept until the next
   check). A kept tab writes `idle unload: a tab plays media; it stays loaded` to the log.
3. `lastActive` is also set when a tab is left, so a tab used for an hour is not idle at once.
4. At unload the tab keeps `interactionState`; at the next load it gets it back (history, scroll).

The check runs a fifth of the limit apart (60 s for 10 min). `NHT_UNLOAD_AFTER_S` shortens the
limit for the readback (R11, R12: 5 s).

## Wrong fix

Never unloading a tab that ever played: a paused or ended player would hold its page process
for good. WebKit's answer is read at each check instead.

## Proof

Red first: the 14 `UnloadPolicyTests` cases failed on the stub (P1-PREP-1); green after the fix
(`_app/scripts/test.sh`, P1-BUILD-1).
Readback 2026-11-16 22:09, installed build cb22afe: R11 PASS (the silent background tab was
unloaded; the playing one stayed loaded and playing 10 s past that), R12 PASS. Not kept as a file
(`--steps` run). Not proven: that R11 fails on P0's code (it needs a P0 rebuild with a 5 s limit).
