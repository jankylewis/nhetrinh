# NT-ENV-001 — Bench burst peaked the machine — lesson

id: NT-ENV-001
family: ENV
status: OBSERVED
date: 2026-11-16
found_by: headmate (2026-11-16, "dont make my machine peak!", Activity Monitor screenshot)
links: fix=no lesson=yes evidence=yes toolgap=none

## Believed

A 30-tab memory test is a normal benchmark step; the machine is free while it runs.

## What changed it

The headmate's Activity Monitor screenshot during `tabs30`.

## Rule

The headmate works on this machine during every run. Load pages one at a time, cap engine processes (~10), run at background priority, and ask before anything that holds a core for minutes.
