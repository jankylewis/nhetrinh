# Readback — latest run

date: 2026-11-16 22:55 +07:00
app: ~/Applications/nhetrinh.app, version 0.1.0, built from commit 93f693e+
verdict: INCOMPLETE (25 passed, 0 failed, 3 not read back)

Each step acts on the app as a user would and says what it saw. R1, R3-R7 and R9-R26b act through the app's readback probe (`NHT_READBACK=1`, D23), along the user's own paths;
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
| R8 the lightness budget holds | PASS | one simple tab (example.com), 6 s after load: app judged on the highest of 9 samples 1 s apart: 30.9 MB (max 40); app + 5 helpers judged on the median of 9: 88.5 MB (max 110), highest 88.6 MB; last 4 samples all over 110 MB: no; idle CPU 0.1 % (max 2); bundle 804 KB (max 1024) |
| R9 Quit and launch give back the same tabs | PASS | 3 tabs, row 2 selected, nhetrinh > Quit nhetrinh, launch: the same 3 rows, row 2 selected, only it loaded, 1 page process |
| R10 a kill gives back the last save | PASS | 4 tabs, row 1 selected, 4 s later signal 9, launch: the same 4 rows, row 1 selected |
| R11 a playing background tab is never unloaded | PASS | idle limit 5 s: the silent background tab was unloaded; the playing one stayed loaded and playing 10 s past that |
| R12 an unloaded tab comes back with its history | PASS | row 1 (test page 1, then 2) was unloaded after 5 s idle; selecting it loaded test page 2; Tabs > Back went to test page 1 |
| R13 a row's menu closes that row | PASS | 3 rows; row 1's menu > Close Tab: 2 rows ["nhetrinh test 2", "nhetrinh test 3"], the selected tab kept |
| R14 Move Tab Up moves the row, and it stays after a relaunch | PASS | row 3, Tabs > Move Tab Up twice: it is row 1 and selected; after Quit and a launch: ["nhetrinh test 3", "nhetrinh test 1", "nhetrinh test 2"] |
| R15 Reopen Closed Tab brings the row back | PASS | File > Close Tab on row 3, File > Reopen Closed Tab: rows ["nhetrinh test 1", "nhetrinh test 2", "nhetrinh test 3"], address http://127.0.0.1:61002/page/3 |
| R16 a site with an icon shows it in its row | PASS | a test page with <link rel="icon">: row 1 shows its icon |
| R17 Open Link in New Tab opens a background tab | PASS | the link's menu ["Open Link", "Open Link in New Tab", "Download Linked File", "Copy Link", "Share…"] > Open Link in New Tab: 2 rows ["link test", "127.0.0.1"], row 1 still selected at http://127.0.0.1:61002/links |
| R18 Stop ends the loading and the button is Reload again | PASS | a page that answers after 30 s: loading, the button read Stop; Stop pressed: loading ended, it reads Reload |
| R19 alert shows its text in a sheet; OK closes it | PASS | alert: a sheet "127.0.0.1 says / nhetrinh alert test" ["OK"]; OK closed it, the page went on |
| R20 confirm: Cancel gives false, OK gives true | PASS | confirm: a sheet [OK, Cancel]; Cancel: false, OK: true |
| R21 prompt: the typed text reaches the page | PASS | prompt: a sheet with a field; typed "typed by the readback", OK: the page got it |
| R22 a file input opens the open panel; Cancel closes it | PASS | the file input: the open panel shown as a sheet; Cancel closed it (title "file: cancel"); picking a file in the panel: not read back |
| R23 a closed port shows the error page; Retry loads the page | PASS | a closed port: the error page "This page could not be loaded" at http://127.0.0.1:61456/page/7; server started, Retry: the page loaded |
| R24 Basic sign-in: a wrong password asks again, the right one loads | PASS | a Basic page: the sheet "Sign in to 127.0.0.1 / This site asks for a user name and a password."; a wrong password: asked again ("Sign in to 127.0.0.1 / The user name or the password was not right. Try again."); the right one: "auth test: signed in" |
| R25 File > Print… opens the print panel; Cancel closes it | PASS | File > Print…: the print panel shown as a sheet; Cancel closed it; nothing printed |
| R26 a mailto: link asks first; Cancel keeps it in the app | PASS | a mailto: link: the sheet "Open this link in Mail? / mailto:nobody@example.invalid" ["Cancel", "Open"]; Cancel: 0 links handed to macOS, the page stays, the mail app not started |
| R26a camera and microphone are asked per site | NOT READ BACK | the camera was asked in a page WebKit counts as hidden (no focus, D18): no site sheet in 10 s, the macOS prompt not reached: not read back |
| R26b a video goes fullscreen and back | NOT READ BACK | WebKit refused: "fullscreen: Cannot request fullscreen in a hidden document."; the readback starts the app without the focus (D18), so the page counts as hidden: not read back |

end: the app quit when asked
