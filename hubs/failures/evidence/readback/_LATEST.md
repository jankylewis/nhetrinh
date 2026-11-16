# Readback — latest run

date: 2026-11-16 17:31 +07:00
app: ~/Applications/nhetrinh.app, version 0.1.0, built from commit c259116+
verdict: FAIL (0 passed, 1 failed, 7 not read back)

A step acts on the app through the Accessibility API, as a user would, and says what it saw.
NOT READ BACK means the step could not run. It is never counted as passed.

| Step | Verdict | What the readback did and saw |
|---|---|---|
| R1 the window opens with the sidebar and the address bar | NOT READ BACK | the terminal app has no Accessibility permission (System Settings) |
| R2 the Dock icon has no tile | NOT READ BACK | the terminal app has no Accessibility permission (System Settings) |
| R3 an address loads its page | NOT READ BACK | the terminal app has no Accessibility permission (System Settings) |
| R4 words in the address bar become one search | NOT READ BACK | the terminal app has no Accessibility permission (System Settings) |
| R5 New Tab and Close Tab change the sidebar | NOT READ BACK | the terminal app has no Accessibility permission (System Settings) |
| R6 selecting another row shows that tab | NOT READ BACK | the terminal app has no Accessibility permission (System Settings) |
| R7 tabs that were not opened cost no page process | NOT READ BACK | the terminal app has no Accessibility permission (System Settings) |
| R8 the lightness budget holds | FAIL | one simple tab (example.com): app 60.0 MB (max 40); app + 6 helpers 140.2 MB (max 110); idle CPU 0.2 % (max 2); bundle 540 KB (max 1024) |
