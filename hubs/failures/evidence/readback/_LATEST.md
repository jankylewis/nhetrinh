# Readback — latest run

date: 2026-11-17 00:41 +07:00
app: ~/Applications/nhetrinh.app, version 0.1.0, built from commit 41df104
verdict: INCOMPLETE (38 passed, 0 failed, 3 not read back)

Each step acts on the app as a user would and says what it saw. R1, R3-R7 and R9-R38 act through the app's readback probe (`NHT_READBACK=1`, D23), along the user's own paths;
R2 reads the Dock through the Accessibility API; R8 measures a normal launch, without the probe.
NOT READ BACK means the step could not run. It is never counted as passed.
focus: never taken (D18); R26a, R26b need --allow-focus (D25)

| Step | Verdict | What the readback did and saw |
|---|---|---|
| R1 the window opens with the sidebar and the address bar | PASS | window "www.google.com"; sidebar 220 pt wide with 1 row(s); address bar shown |
| R2 the Dock icon has no tile | NOT READ BACK | the terminal app has no Accessibility permission (System Settings, Privacy & Security) |
| R3 an address loads its page | PASS | typed example.com and confirmed; title "Example Domain", address bar "https://example.com/" |
| R4 words in the address bar become one search | PASS | typed `rock & roll` and confirmed; the address bar held "https://www.google.com/search?q=rock%20%26%20roll" |
| R5 New Tab and Close Tab change the sidebar | PASS | File > New Tab (⌘T): rows 1 to 2; File > Close Tab (⌘W): back to 1 |
| R6 selecting another row shows that tab | PASS | two tabs; selecting the row above showed example.com, selecting the last row showed example.org |
| R7 tabs that were not opened cost no page process | PASS | started with 3 tabs (seeded by the launch environment; a restored session is R9): 3 rows, 1 page process |
| R8 the lightness budget holds | PASS | one simple tab (example.com), 6 s after load: app judged on the highest of 9 samples 1 s apart: 32.2 MB (max 40); app + 5 helpers judged on the median of 9: 89.9 MB (max 110), highest 90.3 MB; last 4 samples all over 110 MB: no; idle CPU 0.1 % (max 2); bundle 672 KB (max 1024) |
| R9 Quit and launch give back the same tabs | PASS | 3 tabs, row 2 selected, nhetrinh > Quit nhetrinh, launch: the same 3 rows, row 2 selected, only it loaded, 1 page process |
| R10 a kill gives back the last save | PASS | 4 tabs, row 1 selected, 4 s later signal 9, launch: the same 4 rows, row 1 selected |
| R11 a playing background tab is never unloaded | PASS | idle limit 5 s: the silent background tab was unloaded; the playing one stayed loaded and playing 10 s past that |
| R12 an unloaded tab comes back with its history | PASS | row 1 (test page 1, then 2) was unloaded after 5 s idle; selecting it loaded test page 2; Tabs > Back went to test page 1 |
| R13 a row's menu and a middle click close that row | PASS | 3 rows; row 1's menu > Close Tab: ["nhetrinh test 2", "nhetrinh test 3"]; a middle click on row 1: ["nhetrinh test 3"]; the selected tab kept |
| R14 Move Tab Up moves the row, and it stays after a relaunch | PASS | row 3, Tabs > Move Tab Up twice: it is row 1 and selected; after Quit and a launch: ["nhetrinh test 3", "nhetrinh test 1", "nhetrinh test 2"] |
| R15 Reopen Closed Tab brings a middle row back in its place | PASS | row 2 of 3 selected, File > Close Tab, File > Reopen Closed Tab: rows ["nhetrinh test 1", "nhetrinh test 2", "nhetrinh test 3"], row 2 selected at http://127.0.0.1:58454/page/2 |
| R16 a site with an icon shows it in its row | PASS | row 1 shows the icon of <link rel="icon">, the globe when that icon answers 404, and /favicon.ico for a page with no link |
| R17 Open Link in New Tab opens a background tab | PASS | the link's menu ["Open Link", "Open Link in New Tab", "Download Linked File", "Copy Link", "Share…"] > Open Link in New Tab: 2 rows ["link test", "127.0.0.1"], row 1 still selected at http://127.0.0.1:58454/links; Cmd-click: unit test only |
| R18 Stop ends the loading and the button is Reload again | PASS | a page that answers after 30 s: loading, the button read Stop, the progress line shown; Stop pressed: loading ended, it reads Reload, the line is gone |
| R19 alert shows its text in a sheet; OK closes it | PASS | alert: a sheet "127.0.0.1 says / nhetrinh alert test" ["OK"]; OK closed it, the page went on |
| R20 confirm: Cancel gives false, OK gives true | PASS | confirm: a sheet [OK, Cancel]; Cancel: false, OK: true |
| R21 prompt: the typed text reaches the page | PASS | prompt: a sheet with a field; typed "typed by the readback", OK: the page got it |
| R22 a file input opens the open panel; Cancel closes it | PASS | the file input: the open panel shown as a sheet; Cancel: the page heard cancel, nothing chosen; file choice: unit test only |
| R23 a closed port shows the error page; Retry loads the page | PASS | a closed port: the error page "This page could not be loaded" at http://127.0.0.1:58683/page/7; server started, Retry: the page loaded |
| R24 Basic sign-in: a wrong password asks again, the right one loads | PASS | a Basic page: the sheet "Sign in to 127.0.0.1 / This site asks for a user name and a password."; a wrong password: asked again ("Sign in to 127.0.0.1 / The user name or the password was not right. Try again."); the right one: "auth test: signed in" |
| R25 File > Print… opens the print panel; Cancel closes it | PASS | File > Print…: the print panel shown as a sheet; Cancel closed it; nothing printed |
| R26 a mailto: link asks first; Cancel keeps it in the app | PASS | a mailto: link: the sheet "Open this link in Mail? / mailto:nobody@example.invalid" ["Cancel", "Open"]; Cancel: 0 links handed to macOS, the page stays, the mail app not started |
| R26a camera and microphone are asked per site | NOT READ BACK | the camera was asked in a page WebKit counts as hidden: no site sheet in 15 s; the screen is locked and the display is asleep: macOS hides every window (read back with the screen on); the readback starts nhetrinh without the focus (D18): run with --allow-focus to let this step take it (D25): not read back |
| R26b a video goes fullscreen and back | NOT READ BACK | WebKit refused: "fullscreen: Cannot request fullscreen in a hidden document."; the screen is locked and the display is asleep: macOS hides every window (read back with the screen on); the readback starts nhetrinh without the focus (D18): run with --allow-focus to let this step take it (D25): not read back |
| R27 Find: found, not found, Close hides the bar | PASS | Edit > Find > Find…: the bar; "Example": found, "zzzz": not found; Close: the bar is gone |
| R28 Zoom In twice shows 125 %, kept for the host after a relaunch | PASS | 127.0.0.1, View > Zoom In twice: the badge reads 125 %; after Quit and a launch: 125 % on 127.0.0.1; localhost: no badge (100 %) |
| R29 the search engine of the Settings Hub takes the next search | PASS | Settings Hub: Search engine DuckDuckGo; typed words: the address bar held https://duckduckgo.com/?q=nhetrinh%20readback%20words; after Quit and a launch the next search goes there too |
| R30 Clear Website Data removes a page's cookie | PASS | a page set a cookie (read back: nhetrinh=readback); Settings Hub > Clear Website Data… ["Clear Last Hour", "Clear All", "Cancel"] > Clear All: the page reads no cookie |
| R30a Appearance Dark: window and page dark, kept; System: the system look | PASS | Appearance Dark: window dark, the page read dark; after Quit and a launch: still dark; Light: the window and the page light; System: both follow macOS (dark) |
| R31 a 1 MB attachment: a footer row, the file in ~/Downloads at its size | PASS | the footer row nhetrinh-readback-attachment.txt (done); ~/Downloads/nhetrinh-readback-attachment.txt: 1048576 bytes |
| R32 the same file again is saved as `name (1)` | PASS | nhetrinh-readback-attachment.txt kept; the second is nhetrinh-readback-attachment (1).txt, 1048576 bytes |
| R33 a slow 20 MB download: Cancel leaves no file | PASS | nhetrinh-readback-slow.zip at 1 %, Cancel: the row says cancelled, no file is left |
| R34 a click on a finished row asks Finder to show the file | PASS | row nhetrinh-readback-attachment (2).txt clicked: Finder was asked to show it (revealed ["nhetrinh-readback-attachment (2).txt"]) |
| R35 a link from another app (open -b) opens as a new tab | PASS | open -g -b io.github.jankylewis.nhetrinh http://127.0.0.1:58454/page/35: rows 1 -> 2, the new tab shows http://127.0.0.1:58454/page/35 |
| R36 a memory warning leaves 1 page process; the unloaded tab comes back with its history | PASS | 3 loaded tabs, 3 page processes; a warning at once unloaded none; a warning 63 s later unloaded rows 1 and 2: 1 page process left; row 1 clicked loaded test page 2, Tabs > Back went to test page 1 |
| R37 a playing tab is still loaded after a memory warning | PASS | row 1 playing, row 2 silent, row 3 selected, 63 s idle; a warning unloaded row 2 only; a critical level after it unloaded the fresh silent row 4: row 1 still loaded and playing |
| R38 3 tabs, 2 unloaded, cost the one-tab budget + 15 MB | PASS | 3 example sites, 2 unloaded by a critical level, 6 s later: app judged on the highest of 9 samples 1 s apart: 34.6 MB (max 55); app + 6 helpers judged on the median of 9: 102.8 MB (max 125), highest 103.7 MB; last 4 samples all over 125 MB: no |

end: the app quit when asked
