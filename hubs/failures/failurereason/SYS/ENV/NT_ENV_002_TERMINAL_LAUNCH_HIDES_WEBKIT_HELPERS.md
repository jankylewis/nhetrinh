# NT-ENV-002 — Terminal launch hides WebKit helpers

id: NT-ENV-002
family: ENV
status: FIXED
date: 2026-11-16
signature: memsum procs=1 for a WebKit app
source: rnd/_bench/memsum.c (`responsibility_get_pid_responsible_for_pid`)
source: rnd/_bench/_bench.py `launch` (uses `open -n -F`)
links: fix=yes lesson=yes evidence=no toolgap=none

## Mechanism

WebKit's helpers (WebContent, Networking, GPU) are XPC services, not children. macOS charges them to the *responsible* process.
Started from a terminal, the responsible process is the terminal, so the app's memory looked like 35 MB instead of 145 MB.

## Fix

Launch through LaunchServices (`open`), like a Dock click: the app is responsible for its helpers; memsum then finds 6 processes.
