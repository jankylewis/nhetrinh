# NT-TAB-003 — A flat append drops the folders — fix

id: NT-TAB-003
family: TAB
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/BrowserWindowController+Outside.swift (`tree.insert(_:atFlat:)`)
source: _app/Tests/NhetrinhTests/Tabs/Lifecycle/FoldersTests.swift (`aLinkFromAnotherAppKeepsTheFolders`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P7-MERGE-1, not on master)

`openIncoming` inserts through the tree: `tree.insert(tab, atFlat: tabs.count)`, the root's end, as File >
New Tab does. The setter's comment says it drops the folders.

## Wrong fixes

Removing the `tabs` setter: every app test seeds its tabs through it. Not done; the grep above is the check.

## Proof

Red first on the merge (1 issue), green after the fix: `test.sh` 65 + 91 + 134 passed. Readback: R39-R43.
