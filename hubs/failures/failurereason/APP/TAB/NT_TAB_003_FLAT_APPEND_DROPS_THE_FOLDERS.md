# NT-TAB-003 — A flat append drops the folders

id: NT-TAB-003
family: TAB
status: OBSERVED
date: 2026-11-17
found_by: self-test (`aLinkFromAnotherAppKeepsTheFolders` red on the P7-MERGE-1 merge)
signature: aLinkFromAnotherAppKeepsTheFolders
source: _app/_Sources/_Nhetrinh/_Browser/_Window/_BrowserWindowController.swift (`tabs`: get `tree.allTabs`, set `Tree(tabs:)`)
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/BrowserWindowController+Outside.swift (`openIncoming`, P5)
source: _app/Tests/NhetrinhTests/Tabs/Lifecycle/FoldersTests.swift (`aLinkFromAnotherAppKeepsTheFolders`)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

Since P7 the controller's tabs are a tree (`tree`); `tabs` is its flat list, with a setter that puts every
tab at the root (for a seeded launch and the tests). P5, built on a branch without P7, opens a link from
another app with `tabs.append(...)`. On the merge (P7-MERGE-1) that compiles: Swift reads `tabs`, appends,
and sets it back, so the tree is rebuilt flat and every folder is gone. No error, no log.

## Confirm

`FoldersTests.aLinkFromAnotherAppKeepsTheFolders` on the merge before the fix: `folders == ["work"]` failed.
Grep for a mutation of `tabs` in the app: `grep -rn "tabs\.\(append\|insert\|remove\)" _app/_Sources/_Nhetrinh`.
