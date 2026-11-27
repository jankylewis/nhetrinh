# NT-BUG-031 — a PDF file cannot be opened with nhetrinh

id: NT-BUG-031
family: BLD
status: OPEN
date: 2026-11-27
signature: Finder > Open With on a .pdf lists other browsers, not nhetrinh
source: the headmate's screenshot (2026-11-27): Finder's Open With list for a PDF in Downloads; installed Info.plist
  read 2026-11-27: `CFBundleDocumentTypes` holds only `public.html` and `public.xhtml`
observed: on the installed 36db960, 2026-11-27
found_by: headmate (2026-11-27, "cannot open .pdf files in nhetrinh, like other browsers?")
links: fix=no lesson=no evidence=no toolgap=none

## Steps

1. In Finder, right-click a .pdf file > Open With.

Expected: nhetrinh is in the list (as Safari, Chrome, Firefox, Edge are); choosing it opens the PDF in a tab.
Observed: nhetrinh is not in the list.

## Cause

The Info.plist claims web pages only (`public.html`, `public.xhtml`, NT-BUG-026). Nothing claims `com.adobe.pdf`,
so macOS never offers nhetrinh for a PDF. Read from the installed Info.plist; the app side is not proven:
`openIncoming` takes any `file:` URL and WebKit shows PDFs itself (expected, not run).

## To do

1. Test first: `browser_claims` in `_build.sh` also wants `com.adobe.pdf` (red), then add it as a Viewer type.
2. A unit test: a PDF opened with `openIncoming` shows as a tab (WebKit's PDF view).
3. Consider `public.svg-image`, images and `public.plain-text`, which other browsers also claim (ask the headmate).
4. Read back: Finder > Open With lists nhetrinh; the PDF opens. Keep the default PDF app as it is.
