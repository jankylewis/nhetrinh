# NT-TAB-001 — Idle unload ignores playing media

id: NT-TAB-001
family: TAB
status: OPEN
date: 2026-11-16
found_by: development (code read while writing the plan)
signature: background tab stops playing after about 10 minutes
source: _app/_Sources/_Nhetrinh/_Browser/_BrowserWindowController.swift `unloadIdleTabs` (P0; since P1-BUILD-1: `_Browser/Lifecycle/Idle/_IdleUnload.swift`)
observed: not seen live; found by reading the code while writing the plan
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`unloadIdleTabs` unloads every background tab whose `lastActive` is older than 10 minutes.
`lastActive` changes only when the tab is selected. Nothing asks WebKit if the tab is playing
audio or video, so a tab that plays music in the background is unloaded like a silent one.
The same path drops the tab's back / forward history: only the URL and the title are kept.

Not proven: the symptom on a real playing tab (no run has waited 10 minutes with audio).

## Confirm

Play audio in a tab, select another tab, wait past the idle limit: the first row turns dim
and the sound stops.

## Plan

P1 (`hubs/product/plan/M1_DAILY_DRIVER.md`): readback step R11 must fail first on today's
code, then pass after `UnloadPolicy` asks for the media playback state.
Red unit tests first (P1-PREP-1, `DECISIONS.md` D22, commit cba933c):
`_app/Tests/_NhetrinhCoreTests/UnloadPolicyTests.swift`, the table idle time x selected x playing;
a playing tab is never unloaded. They fail on the stub `UnloadPolicy.tabsToUnload` until P1.

P1-BUILD-1 built the fix (`../../../failfix/APP/TAB/NT_TAB_001_IDLE_UNLOAD_IGNORES_PLAYING_MEDIA.md`):
the policy tests are green and R11 passed (22:09). The symptom was never seen on P0's code, so the
status stays OPEN.
