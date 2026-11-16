# NT-TG-005 — Readback page is hidden

id: NT-TG-005
family: GAT
status: OPEN
date: 2026-11-16
signature: Cannot request fullscreen in a hidden document
signature: the camera was asked in a page WebKit counts as hidden
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/Pages/Basics/MediaSteps.swift (R26a, R26b)
source: readback runs of P3-BUILD-1, 2026-11-16 22:5x (`--steps R26a,R26b`), build 93f693e+
observed: R26b, a debug title: `fullscreen: TypeError Cannot request fullscreen in a hidden document. focus=false`
observed: R26a: the page's title stayed `media: asking`; no site sheet came in 10 s
links: fix=no lesson=no evidence=yes toolgap=NT-TG-005

## Gap

The readback starts the app without taking the focus (D18), so its window may be under other
windows. WebKit then counts the page as hidden (`document.hidden`, `document.hasFocus()` false):
- fullscreen is refused at once with WebKit's words above (R26b);
- a camera or microphone request gets no answer and the app's site sheet never comes (R26a).
  Not proven: whether WebKit holds the request because the page is hidden, or for another reason;
  the page reports `media: asking (hidden)` since this entry.
So R26a and R26b are NOT READ BACK, with the reason in the report; never PASS.

Also not driven: picking a file in the open panel (R22). The panel runs outside the app; the probe
sees it shown and presses Cancel through `NSOpenPanel.cancel`.

The macOS camera / microphone prompt (TCC) was never reached, so risk R-2 (grants lost after a
rebuild) was not checked in P3: not proven either way.

## Workaround

Read back by hand: the headmate opens the local pages (`/media`, `/fullscreen` of the readback's
test server) in a focused nhetrinh. A ruling is needed to let the probe bring the window to the
front (`orderFrontRegardless`, no activation): it would cover the headmate's windows.
