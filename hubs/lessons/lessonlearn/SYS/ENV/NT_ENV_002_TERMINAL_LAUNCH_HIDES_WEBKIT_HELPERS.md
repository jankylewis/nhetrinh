# NT-ENV-002 — Terminal launch hides WebKit helpers — lesson

id: NT-ENV-002
family: ENV
status: FIXED
date: 2026-11-16
found_by: development (bench measurement, memsum found 1 process)
links: fix=yes lesson=yes evidence=no toolgap=none

## Believed

Summing the app's process and its children gives the app's memory.

## What changed it

`memsum` found 1 process; `responsibility_get_pid_responsible_for_pid` on the WebKit helpers returned the terminal's pid.

## Rule

Measure an app the way the user starts it (`open`), and count processes by responsibility, not parenthood.
