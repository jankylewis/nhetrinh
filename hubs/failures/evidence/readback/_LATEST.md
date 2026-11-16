# Readback — latest run

date: 2026-11-16 19:40 +07:00
app: ~/Applications/nhetrinh.app, version 0.1.0, built from commit fba7d9e
verdict: FAIL (7 passed, 1 failed, 0 not read back)

A step acts on the app through the Accessibility API, as a user would, and says what it saw.
NOT READ BACK means the step could not run. It is never counted as passed.

| Step | Verdict | What the readback did and saw |
|---|---|---|
| R1 the window opens with the sidebar and the address bar | PASS | window "www.google.com"; sidebar 182 pt wide with 1 row(s); address bar present |
| R2 the Dock icon has no tile | FAIL | the Dock item does not show the bare icon: silhouette agreement 76 %, icon at 84 % of the Dock item; capture and numbers kept (--keep-capture) |
| R3 an address loads its page | PASS | typed example.com and confirmed; title "Example Domain", address bar "https://example.com/" |
| R4 words in the address bar become one search | PASS | typed `rock & roll` and confirmed; the address bar held "https://www.google.com/search?q=rock%20%26%20roll" |
| R5 New Tab and Close Tab change the sidebar | PASS | File > New Tab (⌘T): rows 1 to 2; File > Close Tab (⌘W): back to 1 |
| R6 selecting another row shows that tab | PASS | two tabs; selecting the row above showed example.com, selecting the last row showed example.org |
| R7 tabs that were not opened cost no page process | PASS | started with 3 tabs (seeded by the launch environment; real restore comes with P1): 3 rows, 1 page process |
| R8 the lightness budget holds | PASS | one simple tab (example.com), 6 s after load: app judged on the highest of 9 samples 1 s apart: 29.1 MB (max 40); app + 5 helpers judged on the median of 9: 86.7 MB (max 110), highest 87.1 MB; last 4 samples all over 110 MB: no; idle CPU 0.2 % (max 2); bundle 520 KB (max 1024) |
