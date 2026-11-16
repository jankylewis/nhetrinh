# NT-GAT-005 — R2 measured a pinned copy of the app — fix

id: NT-GAT-005
family: GAT
status: FIXED
date: 2026-11-16
source: _app/_Sources/NhetrinhReadback/Driver/DockIcon.swift (`DockItem`, `items()`, `launchedItem(_:app:)`)
source: _app/_Sources/NhetrinhReadback/Driver/_AX.swift (`flag`, `url`)
source: _app/_Sources/NhetrinhReadback/_Steps/SystemSteps.swift `dockIconHasNoTile`
source: _app/Tests/NhetrinhReadbackTests/DockRingTests.swift `r2MeasuresOnlyTheLaunchedApp` (6 cases)
links: fix=yes lesson=no evidence=yes toolgap=none

## Fix that holds

R2 reads every Dock item on screen with two Accessibility attributes: `AXIsApplicationRunning`
and `AXURL`, the bundle the item stands for. `DockIcon.launchedItem` keeps only the items of the
launched app's bundle (paths compared after standardizing and resolving links; `AXURL` ends with
a slash) that are running. One item: R2 measures it. None: NOT READ BACK, with counts as the
reason (items of the bundle, running items, items read), never a path. More than one: FAIL.
The title is no longer read. Cases: the running app then a pinned copy not running (the
P0-RUN-1 shape); the app pinned but not running; a running copy of another bundle; two running
items of the launched bundle; a running item without a URL; no item.

## The wrong fixes

Take the first item titled nhetrinh: right only while the copy is pinned after the app.
Take the running item by title: a copy of another bundle can run too (`copyAlsoRunning`).
Unpin the copy: the next stray build in the Dock brings the failure back.

## Proof

Red first: with `launchedItem` still `items.last`, `_app/scripts/test.sh` recorded 5 issues in
`r2MeasuresOnlyTheLaunchedApp` (all but `none`). Green after. Mutation on the final tests: the
running filter replaced by the last item fails the same 5 cases.
Not proven: the values of `AXIsApplicationRunning` and `AXURL` on the real Dock, and R2 on the
real Dock. The readback app is not rebuilt yet: a rebuild costs the headmate a new grant (R-2),
so the matemaster batches one rebuild.

## Proof on master (0f99aee)

Red-first tests green in CI run 43885459211 (PR #1, head 402adec, the same tree as master 0f99aee); `hubs/failures/evidence/readback/_LATEST.md` (2026-11-16 21:24, PASS 8 of 8; app 0.1.0 built from fba7d9e, whose app sources equal master 0f99aee), R2: `captured the Dock item (34 x 22 pt)`. Not proven: a pinned copy in the Dock at 21:24.
