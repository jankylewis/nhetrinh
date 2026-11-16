# NT-BUG-007 — A call in a background tab is unloaded

id: NT-BUG-007
family: TAB
status: OBSERVED
date: 2026-11-17
signature: aCapturingTabIsKept
source: _app/_Sources/NhetrinhCore/Tabs/Lifecycle/UnloadPolicy.swift on p6/memory 96130c6 (`tabsToUnload`)
source: _app/Tests/_NhetrinhCoreTests/Tabs/Lifecycle/PressurePolicyTests.swift `aCapturingTabIsKept`
observed: found by the P4/P6 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Join a call in a tab with the camera or the microphone on, muted, with no sound playing; use another tab.

Expected: the call goes on (ruling F3: a capturing tab is kept at every level, like a playing one).
Actual: from the code: after 1 min at a memory warning, at once at critical, after N min idle, the tab is unloaded and the call ends.
