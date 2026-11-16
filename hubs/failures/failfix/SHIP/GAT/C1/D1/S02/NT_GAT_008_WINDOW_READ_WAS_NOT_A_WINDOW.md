# NT-GAT-008 — the window read was not a window — fix

id: NT-GAT-008
family: GAT
status: OPEN
date: 2026-11-16
source: `_app/_Sources/NhetrinhReadback/_Steps/Step.swift` `WindowRole.pick`
source: `_app/_Sources/NhetrinhReadback/Driver/AppSession.swift` `window()`
source: `_app/Tests/NhetrinhReadbackTests/_Dock/EmptyReadsTests.swift` `windowIsPickedByRole` (5 cases)
links: fix=yes lesson=no evidence=yes toolgap=NT-TG-003

## Fix that holds

`window()` waits up to 10 s for an element of `AXWindows` with the role AXWindow and acts only on
it. Nothing read: FAIL `no window after 10 s`, as before. Elements read but none a window: NOT READ
BACK, naming the roles read, never a FAIL of the app. Red first by mutation: with `pick` put back
to the old rule (the first element, any role) 3 of the 5 cases fail (P0-FIX-7).

## Wrong fix

Looking for the cause in the readback's code: the diff 5f2592e..d76fce8 holds no AX change. And
taking an AXWindow from `AXChildren` instead would hide a tree that is read wrong.

Not proven on the app: no rebuild, no run since. The cause of the wrong read stays open (NT-TG-003).
