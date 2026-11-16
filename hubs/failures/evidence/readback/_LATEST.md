# Readback — latest run

date: 2026-11-16 22:13 +07:00
app: ~/Applications/nhetrinh.app, version 0.1.0, built from commit cb22afe+
verdict: INCOMPLETE (11 passed, 0 failed, 1 not read back)

Each step acts on the app as a user would and says what it saw. R1, R3-R7 act through the app's readback probe (`NHT_READBACK=1`, D23), along the user's own paths;
R2 reads the Dock through the Accessibility API; R8 measures a normal launch, without the probe.
NOT READ BACK means the step could not run. It is never counted as passed.

| Step | Verdict | What the readback did and saw |
|---|---|---|
| R1 the window opens with the sidebar and the address bar | PASS | window "www.google.com"; sidebar 220 pt wide with 1 row(s); address bar shown |
| R2 the Dock icon has no tile | NOT READ BACK | the terminal app has no Accessibility permission (System Settings, Privacy & Security) |
| R3 an address loads its page | PASS | typed example.com and confirmed; title "Example Domain", address bar "https://example.com/" |
| R4 words in the address bar become one search | PASS | typed `rock & roll` and confirmed; the address bar held "https://www.google.com/search?q=rock%20%26%20roll" |
| R5 New Tab and Close Tab change the sidebar | PASS | File > New Tab (⌘T): rows 1 to 2; File > Close Tab (⌘W): back to 1 |
| R6 selecting another row shows that tab | PASS | two tabs; selecting the row above showed example.com, selecting the last row showed example.org |
| R7 tabs that were not opened cost no page process | PASS | started with 3 tabs (seeded by the launch environment; a restored session is R9): 3 rows, 1 page process |
| R8 the lightness budget holds | PASS | one simple tab (example.com), 6 s after load: app judged on the highest of 9 samples 1 s apart: 29.9 MB (max 40); app + 5 helpers judged on the median of 9: 93.4 MB (max 110), highest 93.8 MB; last 4 samples all over 110 MB: no; idle CPU 0.1 % (max 2); bundle 656 KB (max 1024) |
| R9 Quit and launch give back the same tabs | PASS | 3 tabs, row 2 selected, nhetrinh > Quit nhetrinh, launch: the same 3 rows, row 2 selected, only it loaded, 1 page process |
| R10 a kill gives back the last save | PASS | 4 tabs, row 1 selected, 4 s later signal 9, launch: the same 4 rows, row 1 selected |
| R11 a playing background tab is never unloaded | PASS | idle limit 5 s: the silent background tab was unloaded; the playing one stayed loaded and playing 10 s past that |
| R12 an unloaded tab comes back with its history | PASS | row 1 (test page 1, then 2) was unloaded after 5 s idle; selecting it loaded test page 2; Tabs > Back went to test page 1 |
