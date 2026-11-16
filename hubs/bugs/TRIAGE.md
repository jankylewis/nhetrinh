# Triage — bugs

One row per bug (`NT-BUG-*`); failure reasons and tool gaps are in `../failures/TRIAGE.md`.
Grep the signature in the report or log.

| Id | Signature | Status | First check |
|---|---|---|---|
| NT-BUG-001 | `search cut off at &` | FIXED | Query value escapes `& + = ? #`, not just `urlQueryAllowed` (NT-NAV-001) |
| NT-BUG-002 | `Dock icon on a black tile` | FIXED | Icon set at runtime via `applicationIconImage`, not only the `.icns` (NT-BLD-001) |
| NT-BUG-003 | `after New Tab the sidebar has 1 rows, not 2` | FIXED | Does the menu item have a target? With no key window a nil target reaches nobody (NT-UIX-001) |
| NT-BUG-004 | `the selected tab stays` | OBSERVED | Closing a row that is not selected must keep the selection (NT-UIX-002) |
