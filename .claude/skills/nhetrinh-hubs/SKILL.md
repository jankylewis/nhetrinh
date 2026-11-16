---
name: nhetrinh-hubs
description: "Write nhetrinh's hub entries (bug, failure, fix, lesson, tool gap, evidence, feature) in the same change, from hubs/_SCHEMA.md."
---

# nhetrinh-hubs

Every learning of nhetrinh lives under `hubs/`. The rules are in `hubs/_SCHEMA.md`; this skill
says when to write each entry and how. One id joins many hubs: build the path, never search.

## When

| You met | Write |
|---|---|
| A symptom a user meets in the app | `bugfacing` entry (`NT-BUG-nnn`) + a row in `bugs/TRIAGE.md` |
| The fix of that bug | `bugfix` entry, same path as its `bugfacing` |
| A mechanism (from a bug, test, CI run, benchmark, readback) | `failurereason` (`NT-<FAM>-nnn`) + a row in `failures/TRIAGE.md` |
| A fix that holds, with proof | `failfix`, same path as its `failurereason` |
| A belief that was wrong | `lessonlearn`, same path as its `failurereason` |
| A missing or broken tool | `toolgap` (`NT-TG-nnn`) + a row in `failures/TRIAGE.md` |
| Kept evidence (log, report, verdict file) | a row in `failures/evidence/_INDEX.md` |
| A shipped feature | a row in `product/features/S<nn>.md` (`NT-FEAT-nnn`) |

Write them in the same commit or PR as the fix or the feature. A fix without its entries is not
done. Never make an empty hub file to complete a set: no `failfix` file means no proven fix.

## Paths

| Hub | Path |
|---|---|
| `bugs/bugfacing/`, `bugs/bugfix/` | `C<n>/D<n>/S<nn>/NT_BUG_<nnn>_<SLUG>.md` |
| `failures/failurereason/`, `failfix/`, `lessons/lessonlearn/` | `<LAYER>/<FAM>/NT_<FAM>_<nnn>_<SLUG>.md` |
| `lessons/toolgap/` | `NT_TG_<nnn>_<SLUG>.md` (shelved past 4) |

| Layer | Families |
|---|---|
| `APP` | `UIX` window, sidebar, menus, Dock icon; `NAV` address, navigation, search; `TAB` tab lifecycle |
| `SYS` | `PRF` speed, memory, budget; `ENV` the machine, processes, measurement |
| `SHIP` | `BLD` build, bundle, install, release; `CIP` CI differs from local; `GAT` tests, gates |

Shelves: `S01` = ids 001-004, `S02` = 005-008. Drawers: `D1/` = `S01`-`S03`.
Cabinets: `C1/` = `D1`-`D4`. Bugs are always shelved; a family folder is shelved past 4 ids.
Make a folder only when an entry needs it. Every folder has one `_INDEX.md` and at most 4 other
entries; add the new entry's row to the `_INDEX.md` of its folder (and of new parent folders).

## How

1. Check both TRIAGE files for the next free id. Ids are never reused.
2. Head of every entry: title `# <id> — <short name>` (fix: `— fix`, lesson: `— lesson`), then:

   ```
   id: NT-GAT-001
   family: GAT
   status: OPEN | OBSERVED | FIXED
   date: <first seen, YYYY-MM-DD>
   signature: <exact text to grep>      (failurereason and bugfacing only)
   source: <tracked path + line, commit, or report>   (one line per source)
   observed: <what was seen outside the repo, sanitized>
   links: fix=<yes|no> lesson=<yes|no> evidence=<yes|no> toolgap=<NT-TG-nnn|none>
   cause: <NT-FAM-nnn>                  (bugfacing only, when proven)
   ```

3. Body: copy the sections of an entry in the same hub. Today `failurereason` has Mechanism,
   Confirm, Fix; `failfix` Fix that holds, Wrong fixes, Proof; `lessonlearn` Believed, What
   changed it, Rule.
4. Status:

   | Status | Means |
   |---|---|
   | `OPEN` | cause not proven; write "not proven" for each unproven part |
   | `OBSERVED` | proven by a cited source; fix not on `master` or not proven |
   | `FIXED` | fix on `master` AND a cited proof: red-first test then green, gate run, readback |

5. Run `python3 _app/scripts/conventions/_check.py`: `.md` 100 lines, folder limits.

## Laws

- Every claim cites a source. No invented case, no guessed cause. Write "not proven".
- Public repo: no secrets, tokens, e-mails, person names, work names or absolute personal
  paths. Name people by role (`headmate`).
