# NT-GAT-001 — Plain swift test loses the Swift Testing plugin — lesson

id: NT-GAT-001
family: GAT
status: FIXED
date: 2026-11-16
links: fix=yes lesson=yes evidence=no toolgap=none

## Believed

`swift test` builds the same way on every run, so a red test build means a code error.

## What changed it

The same tree failed 2 of 4 plain runs and passed the others. `swift test -v` showed that the
compile command of a failing run had no plugin flag.

## Rule

When a build fails with no code change, compare the compile command (`-v`) of a red run and a
green run before you change code. Then pin the flag in a script, and call only the script.
