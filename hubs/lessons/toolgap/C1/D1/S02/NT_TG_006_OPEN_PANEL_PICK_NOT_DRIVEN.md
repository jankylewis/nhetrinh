# NT-TG-006 — Open panel pick not driven

id: NT-TG-006
family: GAT
status: OPEN
date: 2026-11-16
found_by: development (P3-REVIEW P4)
signature: picking a file in the panel: not read back
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/Pages/Basics/PanelSteps.swift (`fileInput`, R22)
source: hubs/product/plan/M2_REAL_SITES_WORK.md R22 (before the ruling: "pick a fixture file; the page shows its name")
source: _app/Tests/NhetrinhTests/Page/UploadTests.swift, _app/Tests/NhetrinhReadbackTests/Steps/Tabs/Basics/PanelStepsTests.swift
links: fix=no lesson=no evidence=no toolgap=NT-TG-006

## Gap

The open panel runs outside the app (the system's panel process): the probe can see it and press
Cancel, not pick a file. R22 PASSes with the pick said "not read back" in its line, so a broken
`completionHandler(panel.urls)` would pass (P3-REVIEW P4).

## Workaround

Ruling (matemaster, after P3-FIX-1), as R17's ⌘-click: R22 reads back that the open panel is shown for
the page's input and that Cancel gives the page nothing chosen ("file: cancel", or the title unchanged;
"file: <name>" is a FAIL). The file choice is the unit test `UploadTests`: a chosen URL fed to the
upload completion (`uploadAnswer`) reaches the page, several in order; Cancel, `.abort` (S1) and Open
with no file give nil. R22's line ends "file choice: unit test only" (`PanelSteps.fileChoiceUnitOnly`).
Proof: mutations of `uploadAnswer` and of the Cancel check turn the tests red (P3-FIX-2, test.sh).
Not read back yet. The gap stays: the system's panel cannot be driven.
