# Readback — latest run

date: 2026-11-16 19:51 +07:00
app: ~/Applications/nhetrinh.app, version 0.1.0, built from commit fba7d9e
verdict: FAIL (1 passed, 6 failed, 1 not read back)

A step acts on the app through the Accessibility API, as a user would, and says what it saw.
NOT READ BACK means the step could not run. It is never counted as passed.

| Step | Verdict | What the readback did and saw |
|---|---|---|
| R1 the window opens with the sidebar and the address bar | FAIL | no element `nhetrinh.sidebar` in the window |
| R2 the Dock icon has no tile | NOT READ BACK | no running Dock item of the launched app: 0 of its bundle (none running), 0 running of 0 items read |
| R3 an address loads its page | FAIL | no element `nhetrinh.address` in the window |
| R4 words in the address bar become one search | FAIL | no element `nhetrinh.address` in the window |
| R5 New Tab and Close Tab change the sidebar | FAIL | no element `nhetrinh.sidebar` in the window |
| R6 selecting another row shows that tab | FAIL | no element `nhetrinh.address` in the window |
| R7 tabs that were not opened cost no page process | FAIL | started with 3 tabs; the sidebar has -1 row(s) |
| R8 the lightness budget holds | PASS | one simple tab (example.com), 6 s after load: app judged on the highest of 9 samples 1 s apart: 29.1 MB (max 40); app + 5 helpers judged on the median of 9: 86.6 MB (max 110), highest 87.1 MB; last 4 samples all over 110 MB: no; idle CPU 0.2 % (max 2); bundle 520 KB (max 1024) |
