# hubs — schema and join key

Every learning of nhetrinh lives under `hubs/`: every bug, failure, fix, lesson,
tool gap and shipped feature. Pattern taken from backback's hubs (one id, many hubs:
build the path, never search); ids and families are nhetrinh's own.

## Hubs

| Hub | Path | Answers |
|---|---|---|
| `bugs/bugfacing/` | `C<n>/D<n>/S<nn>/NT_BUG_<nnn>_<SLUG>.md` | what the user faced: steps, expected, actual, status |
| `bugs/bugfix/` | same path as bugfacing | the change, the commit, the red-first test, the proof |
| `failures/failurereason/` | `<LAYER>/<FAM>/NT_<FAM>_<nnn>_<SLUG>.md` | the mechanism, how it shows, how to confirm it |
| `failures/failfix/` | same path as failurereason | the fix that holds, the wrong fix, the proof |
| `failures/evidence/` | `_INDEX.md` rows (a file only past 3 paths) | PATHS to kept evidence, what to capture next time |
| `lessons/lessonlearn/` | same path as failurereason | who believed what, what changed it, the rule left |
| `lessons/toolgap/` | `NT_TG_<nnn>_<SLUG>.md` (shelved past 4) | missing or broken tool, workaround, status |
| `product/features/` | `S<nn>.md` rows (40 a shelf) | what the app can do: feature, commit, date, the bug it closed |
| `product/plan/` | `_PLAN.md` + one file per milestone | what comes next: phases, exit criteria, decisions |

A bug is a symptom a user meets in the app (`NT-BUG-nnn`, global numbers).
A failure is a mechanism: a cause found in a bug, test, CI run, benchmark or
readback (`NT-<FAM>-nnn`). A bug links to its cause with `cause:`.
`bugs/TRIAGE.md` has one row per bug, `failures/TRIAGE.md` one per failure reason
and tool gap: read them first. `product/features/` lists every shipped feature (`NT-FEAT-nnn`); `product/plan/` is the plan.

## Layers and families

| Layer | Code | Family |
|---|---|---|
| `APP` | `UIX` | window, sidebar, toolbar, menus, keys, Dock icon |
| `APP` | `NAV` | address bar, navigation, popups, search |
| `APP` | `TAB` | tab lifecycle: lazy load, unload, session restore |
| `SYS` | `PRF` | speed, memory, the lightness budget |
| `SYS` | `ENV` | the machine: load, processes, measurement setup |
| `SHIP` | `BLD` | build, `.app` bundle, icon, install, release |
| `SHIP` | `CIP` | GitHub CI differs from the local machine |
| `SHIP` | `GAT` | tests, gates, budget checks |

## Folders

Every folder holds at most 5 entries, exactly one of them starting with `_`: its most
critical entry. In a hub folder that is `_INDEX.md`, so a folder has at most 4 other entries. Shelves: `S01` = ids 001-004, `S02` = 005-008, and so on. Drawers:
`D1/` = `S01`-`S03`, `D2/` = `S04`-`S07`. Cabinets: `C1/` = `D1`-`D4`. Bugs are always
shelved (`C<n>/D<n>/S<nn>/`); a family folder or `toolgap/` is shelved past 4 ids.
Folders are made only when an entry needs them.

## Entry head

Title `# <id> — <short name>`, then one line each:

```
id: NT-NAV-001            (or NT-BUG-001, NT-TG-001)
family: NAV
status: OPEN | OBSERVED | FIXED
date: <first seen, YYYY-MM-DD>
signature: <exact text to grep in a log or report; failurereason and bugfacing only>
source: <tracked path + line, commit, or report>   (one per source)
observed: <what was seen outside the repo, sanitized, no personal paths>
links: fix=<yes|no> lesson=<yes|no> evidence=<yes|no> toolgap=<NT-TG-nnn|none>
cause: <NT-FAM-nnn>       (bugfacing only, when proven)
```

| Status | Means |
|---|---|
| `OPEN` | Cause not proven. Write "not proven" for each unproven part. |
| `OBSERVED` | Proven by a cited source; fix not on `master` or not proven. |
| `FIXED` | Fix on `master` AND a cited proof: red-first test then green, gate run, readback. |

## Laws

1. Every bug report, red CI, benchmark failure or false claim gets its entries in the
   same commit/PR that fixes it; a fix without its entries is not done.
2. Never make an empty hub file to complete a set: a missing `failfix` file means no proven fix.
3. Every claim cites a source. No invented case, no guessed cause.
4. Public repo: no secrets, tokens, e-mails, person names, work names or absolute
   personal paths. Name people by role (`headmate`).
5. Ids are never reused. Check both TRIAGE files before giving a new id.
6. Every feature gets its `product/features/` row in the same commit/PR that ships it.
