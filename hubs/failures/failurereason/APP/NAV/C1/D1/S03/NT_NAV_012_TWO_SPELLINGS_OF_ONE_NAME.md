# NT-NAV-012 — Two spellings of one name

id: NT-NAV-012
family: NAV
status: OBSERVED
date: 2026-11-17
signature: sameFileIgnoresCaseAndNormalization
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift (`reserve`)
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/_DownloadNamer.swift (`key`)
source: nhetrinh_wt/REVIEW_P5.md (P5-REVIEW, outside the repository)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`reserved` compared names exactly; ~/Downloads (APFS by default) ignores case and Unicode normalization, so `Report.pdf` and `report.pdf` chosen in the same short window were one file.

## Confirm

From the code (P5-REVIEW F8); not reproduced (the window closes once WebKit makes the file).
