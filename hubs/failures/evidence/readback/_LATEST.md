# Readback — latest run

date: 2026-11-17 13:19 +07:00
app: ~/Applications/nhetrinh.app, version 0.1.0, built from commit c751b08
verdict: FAIL (49 passed, 2 failed, 0 not read back)

Each step acts on the app as a user would and says what it saw. R1, R3-R7, R9-R43, R46-R50 act through the app's readback probe (`NHT_READBACK=1`, D23), along the user's own paths;
R2 reads the Dock through the Accessibility API; R8 measures a normal launch, without the probe.
NOT READ BACK means the step could not run. It is never counted as passed.
focus: R26a, R26b may take the focus (--allow-focus, D25); each says so on its line

| Step | Verdict | What the readback did and saw |
|---|---|---|
| R1 the window opens with the sidebar and the address bar | PASS | window "www.google.com"; sidebar 220 pt wide with 1 row(s); address bar shown |
| R2 the Dock icon has no tile | FAIL | the Dock item does not show the bare icon: silhouette agreement 90 %, icon at 94 % of the Dock item |
| R3 an address loads its page | PASS | typed example.com and confirmed; title "Example Domain", address bar "https://example.com/" |
| R4 words in the address bar become one search | PASS | typed `rock & roll` and confirmed; the address bar held "https://www.google.com/search?q=rock%20%26%20roll" |
| R5 New Tab and Close Tab change the sidebar | PASS | File > New Tab (⌘T): rows 1 to 2; File > Close Tab (⌘W): back to 1 |
| R6 selecting another row shows that tab | PASS | two tabs; selecting the row above showed example.com, selecting the last row showed example.org |
| R7 tabs that were not opened cost no page process | PASS | started with 3 tabs (seeded by the launch environment; a restored session is R9): 3 rows, 1 page process |
| R8 the lightness budget holds | PASS | one simple tab (example.com), 6 s after load: app judged on the highest of 9 samples 1 s apart: 32.0 MB (max 40); app + 5 helpers judged on the median of 9: 89.7 MB (max 110), highest 90.0 MB; last 4 samples all over 110 MB: no; idle CPU 0.2 % (max 2); bundle 896 KB (max 1024) |
| R9 Quit and launch give back the same tabs | PASS | 3 tabs, row 2 selected, nhetrinh > Quit nhetrinh, launch: the same 3 rows, row 2 selected, only it loaded, 1 page process |
| R10 a kill gives back the last save | PASS | 4 tabs, row 1 selected, 4 s later signal 9, launch: the same 4 rows, row 1 selected |
| R11 a playing background tab is never unloaded | PASS | idle limit 5 s: the silent background tab was unloaded; the playing one stayed loaded and playing 10 s past that |
| R12 an unloaded tab comes back with its history | PASS | row 1 (test page 1, then 2) was unloaded after 5 s idle; selecting it loaded test page 2; Tabs > Back went to test page 1 |
| R13 a row's menu and a middle click close that row | PASS | 3 rows; row 1's menu > Close Tab: ["nhetrinh test 2", "nhetrinh test 3"]; a middle click on row 1: ["nhetrinh test 3"]; the selected tab kept |
| R14 Move Tab Up moves the row, and it stays after a relaunch | PASS | row 3, Tabs > Move Tab Up twice: it is row 1 and selected; after Quit and a launch: ["nhetrinh test 3", "nhetrinh test 1", "nhetrinh test 2"] |
| R15 Reopen Closed Tab brings a middle row back in its place | PASS | row 2 of 3 selected, File > Close Tab, File > Reopen Closed Tab: rows ["nhetrinh test 1", "nhetrinh test 2", "nhetrinh test 3"], row 2 selected at http://127.0.0.1:49795/page/2 |
| R16 a site with an icon shows it in its row | PASS | row 1 shows the icon of <link rel="icon">, the globe when that icon answers 404, and /favicon.ico for a page with no link |
| R17 Open Link in New Tab opens a background tab | PASS | the link's menu ["Open Link", "Open Link in New Tab", "Download Linked File", "Copy Link", "Share…"] > Open Link in New Tab: 2 rows ["link test", "127.0.0.1"], row 1 still selected at http://127.0.0.1:49795/links; Cmd-click: unit test only |
| R18 Stop ends the loading and the button is Reload again | PASS | a page that answers after 30 s: loading, the button read Stop, the progress line shown; Stop pressed: loading ended, it reads Reload, the line is gone |
| R19 alert shows its text in a sheet; OK closes it | PASS | alert: a sheet "127.0.0.1 says / nhetrinh alert test" ["OK"]; OK closed it, the page went on |
| R20 confirm: Cancel gives false, OK gives true | PASS | confirm: a sheet [OK, Cancel]; Cancel: false, OK: true |
| R21 prompt: the typed text reaches the page | PASS | prompt: a sheet with a field; typed "typed by the readback", OK: the page got it |
| R22 a file input opens the open panel; Cancel closes it | PASS | the file input: the open panel shown as a sheet; Cancel: the page heard cancel, nothing chosen; file choice: unit test only |
| R23 a closed port shows the error page; Retry loads the page | PASS | a closed port: the error page "This page could not be loaded" at http://127.0.0.1:49899/page/7; server started, Retry: the page loaded |
| R24 Basic sign-in: a wrong password asks again, the right one loads | PASS | a Basic page: the sheet "Sign in to 127.0.0.1 / This site asks for a user name and a password."; a wrong password: asked again ("Sign in to 127.0.0.1 / The user name or the password was not right. Try again."); the right one: "auth test: signed in" |
| R25 File > Print… opens the print panel; Cancel closes it | PASS | File > Print…: the print panel shown as a sheet; Cancel closed it; nothing printed |
| R26 a mailto: link asks first; Cancel keeps it in the app | PASS | a mailto: link: the sheet "Open this link in Mail? / mailto:nobody@example.invalid" ["Cancel", "Open"]; Cancel: 0 links handed to macOS, the page stays, the mail app not started |
| R26a camera and microphone are asked per site | PASS | took the focus (--allow-focus, D25): the site sheet "Allow 127.0.0.1 to use your camera? / nhetrinh keeps your answer for this site until it quits." ["Don\'t Allow", "Allow"]; Don't Allow: NotAllowedError, the macOS prompt never asked for; asked again: no sheet, the answer kept; nhetrinh was the active app: no |
| R26b a video goes fullscreen and back | PASS | took the focus (--allow-focus, D25): a video's box, fullscreen pressed: the window went fullscreen; leave pressed: the window is back; nhetrinh was the active app: no |
| R27 Find: found, not found, Close hides the bar | PASS | Edit > Find > Find…: the bar; "Example": found, "zzzz": not found; Close: the bar is gone |
| R28 Zoom In twice shows 125 %, kept for the host after a relaunch | PASS | 127.0.0.1, View > Zoom In twice: the badge reads 125 %; after Quit and a launch: 125 % on 127.0.0.1; localhost: no badge (100 %) |
| R29 the search engine of the Settings Hub takes the next search | PASS | Settings Hub: Search engine DuckDuckGo; typed words: the address bar held https://duckduckgo.com/?q=nhetrinh%20readback%20words; after Quit and a launch the next search goes there too |
| R30 Clear Website Data removes a page's cookie | PASS | a page set a cookie (read back: nhetrinh=readback); Settings Hub > Clear Website Data… ["Clear Last Hour", "Clear All", "Cancel"] > Clear All: the page reads no cookie |
| R30a Appearance Dark: window and page dark, kept; System: the system look | PASS | Appearance Dark: window dark, the page read dark; after Quit and a launch: still dark; Light: the window and the page light; System: both follow macOS (dark) |
| R31 a 1 MB attachment: a footer row, the file in ~/Downloads at its size | PASS | the footer row nhetrinh-readback-attachment.txt (done); ~/Downloads/nhetrinh-readback-attachment.txt: 1048576 bytes |
| R32 the same file again is saved as `name (1)` | PASS | nhetrinh-readback-attachment.txt kept; the second is nhetrinh-readback-attachment (1).txt, 1048576 bytes |
| R33 a slow 20 MB download: Cancel leaves no file | PASS | nhetrinh-readback-slow.zip at 1 %, Cancel: the row says cancelled, no file is left |
| R34 a click on a finished row asks Finder to show the file | PASS | row nhetrinh-readback-attachment (2).txt clicked: Finder was asked to show it (revealed ["nhetrinh-readback-attachment (2).txt"]) |
| R35 a link from another app (open -b) opens as a new tab | PASS | open -g -b io.github.jankylewis.nhetrinh http://127.0.0.1:49795/page/35: rows 1 -> 2, the new tab shows http://127.0.0.1:49795/page/35 |
| R36 a memory warning leaves 1 page process; the unloaded tab comes back with its history | PASS | 3 loaded tabs, 3 page processes; a warning at once unloaded none; a warning 63 s later unloaded rows 1 and 2: 1 page process left; row 1 clicked loaded test page 2, Tabs > Back went to test page 1 |
| R37 a playing tab is still loaded after a memory warning | PASS | row 1 playing, row 2 silent, row 3 selected, 63 s idle; a warning unloaded row 2 only; a critical level after it unloaded the fresh silent row 4: row 1 still loaded and playing |
| R38 3 tabs, 2 unloaded, cost the one-tab budget + 15 MB | PASS | 3 example sites, 2 unloaded by a critical level, 6 s later: app judged on the highest of 9 samples 1 s apart: 36.4 MB (max 55); app + 6 helpers judged on the median of 9: 103.8 MB (max 125), highest 110.1 MB; last 4 samples all over 125 MB: no |
| R39 New Group, named work: its row appears | PASS | 3 tabs; row 1's menu > New Group…, typed work, Create: rows ["nhetrinh test 1", "work", "nhetrinh test 2", "nhetrinh test 3"] |
| R40 2 tabs moved in: the group holds 2 | PASS | rows 3 and 4: menu > Move Tab to Group > work: work holds ["nhetrinh test 2", "nhetrinh test 3"]; rows ["nhetrinh test 1", "work", "nhetrinh test 2", "nhetrinh test 3"] (a drag: unit tested only) |
| R41 collapse hides 2 rows; a relaunch keeps group, name, tabs, collapsed | PASS | Collapse Group: rows ["nhetrinh test 1", "work"]; quit and launch: rows ["nhetrinh test 1", "work"], work holds ["nhetrinh test 2", "nhetrinh test 3"], collapsed |
| R42 Ungroup: its 2 tabs are back at the top level | PASS | Ungroup: no group; rows ["nhetrinh test 1", "nhetrinh test 2", "nhetrinh test 3"]: its 2 tabs at the top level, none closed |
| R43 a version 1 session: every tab is back, the file kept once | FAIL | the save at quit is not version 2 |
| R46 Window > Minimize (⌘M) minimizes the window; it comes back | PASS | Window > Minimize (⌘M): the window minimized; restored from its Dock item: shown, not minimized |
| R47 the sidebar, address bar, find bar and Settings Hub are in Menlo | PASS | 3 tabs, a group, the Settings Hub open: sidebar row, group row, New Tab, address bar, find bar, Settings Hub read Menlo |
| R48 sidebar hidden: the toolbar clears the traffic lights; its toggle works | PASS | sidebar hidden: zoom button ends at x 63, Toggle Sidebar at x 71, Back at x 105; the toolbar's toggle showed the sidebar, then hid it; start state put back |
| R49 groups 4 levels deep: made, 5th refused, renamed, moved, ungrouped, closed and reopened, kept by a relaunch | PASS | built Work > FE > PRs > Feedback entry: rows at levels [0, 0, 1, 1, 2, 2, 3, 3, 4], tab counts [4, 3, 2, 1]; Feedback entry > New Group Inside…: refused, "Groups go 4 levels deep at most."; PRs renamed Pull requests; moved to the top level (["Work", "Work > FE", "Pull requests", "Pull requests > Feedback entry"]) and back into Work > FE; FE ungrouped: ["Work", "Work > Pull requests", "Work > Pull requests > Feedback entry"], tab counts [4, 2, 1], all 5 tabs kept; Close Group… asked about 1 tab, closed it; Reopen Closed Tab brought Feedback entry back with it, inside Pull requests (tab counts [4, 2, 1]); quit and launch: the same 3 groups and 8 rows; start state put back (one home tab) |
| R50 the sidebar sits right, then left, never over the web view; the toolbar clears the traffic lights | PASS | Settings Hub > Sidebar position: Right: sidebar x 1062, web view x 0 to 1059, toggle sidebar.right; Left: sidebar x 0, web view x 219 to 1280, toggle sidebar.left; on each side shown, hidden and shown again: no overlap, the toolbar clear of the traffic lights; start state put back |

end: the app quit when asked
