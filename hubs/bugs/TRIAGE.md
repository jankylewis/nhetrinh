# Triage — bugs

One row per bug (`NT-BUG-*`); failure reasons and tool gaps are in `../failures/TRIAGE.md`.
Grep the signature in the report or log.

| Id | Signature | Status | First check |
|---|---|---|---|
| NT-BUG-001 | `search cut off at &` | OBSERVED | Query value escapes `& + = ? #`, not just `urlQueryAllowed` (NT-NAV-001) |
| NT-BUG-002 | `Dock icon on a black tile` | OBSERVED | Icon set at runtime via `applicationIconImage`, not only the `.icns` (NT-BLD-001) |
