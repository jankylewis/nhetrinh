# NT-TG-007 — a page helper crash cannot be driven in the unit tests

id: NT-TG-007
family: GAT
status: OPEN
date: 2026-11-21
found_by: development (NT-BUG-027 family sweep, while the headmate slept)
signature: test process hangs at 0 % CPU after `_killWebContentProcess`
source: a test tried in `_app/Tests/NhetrinhTests/Page/Outside/LocalPageTests.swift` (not kept)
links: fix=no lesson=no evidence=no toolgap=NT-TG-007

## Gap

The question: after a local page's helper crashes, does `webView.reload()` (`webViewWebContentProcessDidTerminate`)
bring back its `../` files? A test called WebKit's private hook `_killWebContentProcess` to crash the helper.
The test process then hung with no output and 0 % CPU, twice (more than 6 minutes each). Swift Testing's
`.timeLimit(.minutes(1))` did not stop it. The process had to be stopped by hand.

## Workaround

None yet. The crash path for local pages is not proven. A readback could crash the helper of the installed app
(Activity Monitor or `kill` on its WebContent process), with the headmate's OK.
