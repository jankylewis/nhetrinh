# NT-BUG-031 — a PDF file cannot be opened with nhetrinh

id: NT-BUG-031
family: BLD
status: OBSERVED
date: 2026-11-27
signature: Finder > Open With on a .pdf lists other browsers, not nhetrinh
source: the headmate's screenshot (2026-11-27): Finder's Open With list for a PDF in Downloads; installed Info.plist
  read 2026-11-27: `CFBundleDocumentTypes` holds only `public.html` and `public.xhtml`
observed: on the installed 36db960, 2026-11-27
found_by: headmate (2026-11-27, "cannot open .pdf files in nhetrinh, like other browsers?")
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

1. In Finder, right-click a .pdf file > Open With.

Expected: nhetrinh is in the list (as Safari, Chrome, Firefox, Edge are); choosing it opens the PDF in a tab.
Observed: nhetrinh is not in the list.

## Cause

The Info.plist claimed web pages only (`public.html`, `public.xhtml`, NT-BUG-026). Nothing claimed `com.adobe.pdf`,
so macOS never offered nhetrinh for a PDF. The app side already worked: `openIncoming` takes any `file:` URL and
WebKit shows the PDF in the tab.

## Fix

- `_build.sh`: a second document type, "PDF document", `com.adobe.pdf`, role Viewer, rank Alternate (offered in
  Open With; never takes the default PDF app's place).
- Tests: `browser_claims` also wants `com.adobe.pdf` (the build stopped on it before the fix: red);
  `aPDFFileOpensAsATabAndShows` (the tab shows `application/pdf`; red when `file:` links are refused: mutation check).

Not read back on the installed app yet (Finder's Open With list). Images and plain text, which other browsers
also claim, are not claimed: not asked.

Status OBSERVED, not FIXED (2026-11-27): the fix is on a branch, not on `master` yet (`hubs/_SCHEMA.md`).
It becomes FIXED at the merge to `master`.
