# NT-GAT-002 — Readback tool had no tests — lesson

id: NT-GAT-002
family: GAT
status: FIXED
date: 2026-11-16
found_by: development (P0 brief P0-HAR-3: the readback tool had no tests)
links: fix=yes lesson=yes evidence=no toolgap=none

## Believed

The readback is the check of the app, so it needs no check of its own.

## What changed it

The P0 brief named it a defect. The conventions checker already had its own tests
(`_app/scripts/conventions/test_rules.py`); the readback had none, and its R2 rule had never run.

## Rule

The checker of the app needs its own red-first tests, like the conventions checker has. Show
that each test can fail (break the rule once, see it red), then keep it green.
