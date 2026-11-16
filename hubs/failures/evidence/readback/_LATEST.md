# Readback — latest run

date: 2026-11-16 20:07 +07:00
app: ~/Applications/nhetrinh.app, version 0.1.0, built from commit fba7d9e
verdict: INCOMPLETE (1 passed, 0 failed, 7 not read back)

A step acts on the app through the Accessibility API, as a user would, and says what it saw.
NOT READ BACK means the step could not run. It is never counted as passed.

| Step | Verdict | What the readback did and saw |
|---|---|---|
| R1 the window opens with the sidebar and the address bar | NOT READ BACK | no element `nhetrinh.sidebar`: none of the app's identifiers (nhetrinh.*) is in the window, its tree was not read (window "nhetrinh", 2 children, first roles [AXApplication, AXMenuBar], read error 0) |
| R2 the Dock icon has no tile | NOT READ BACK | Accessibility reads are empty: re-grant nhetrinh-readback.app (0 Dock items read) |
| R3 an address loads its page | NOT READ BACK | no element `nhetrinh.address`: none of the app's identifiers (nhetrinh.*) is in the window, its tree was not read (window "nhetrinh", 2 children, first roles [AXApplication, AXMenuBar], read error 0) |
| R4 words in the address bar become one search | NOT READ BACK | no element `nhetrinh.address`: none of the app's identifiers (nhetrinh.*) is in the window, its tree was not read (window "nhetrinh", 2 children, first roles [AXApplication, AXMenuBar], read error 0) |
| R5 New Tab and Close Tab change the sidebar | NOT READ BACK | no element `nhetrinh.sidebar`: none of the app's identifiers (nhetrinh.*) is in the window, its tree was not read (window "nhetrinh", 2 children, first roles [AXApplication, AXMenuBar], read error 0) |
| R6 selecting another row shows that tab | NOT READ BACK | no element `nhetrinh.address`: none of the app's identifiers (nhetrinh.*) is in the window, its tree was not read (window "nhetrinh", 2 children, first roles [AXApplication, AXMenuBar], read error 0) |
| R7 tabs that were not opened cost no page process | NOT READ BACK | no element `nhetrinh.sidebar`: none of the app's identifiers (nhetrinh.*) is in the window, its tree was not read (window "nhetrinh", 2 children, first roles [AXApplication, AXMenuBar], read error 0) |
| R8 the lightness budget holds | PASS | one simple tab (example.com), 6 s after load: app judged on the highest of 9 samples 1 s apart: 29.2 MB (max 40); app + 5 helpers judged on the median of 9: 87.3 MB (max 110), highest 87.6 MB; last 4 samples all over 110 MB: no; idle CPU 0.1 % (max 2); bundle 520 KB (max 1024) |
