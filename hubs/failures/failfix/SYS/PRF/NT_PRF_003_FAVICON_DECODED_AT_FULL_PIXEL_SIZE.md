# NT-PRF-003 — Favicon decoded at full pixel size — fix

id: NT-PRF-003
family: PRF
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/_Browser/Handling/Favicons.swift (`fits`, `largestSide`, P2-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

`Favicons.fits` reads each image's pixel size from its header (`CGImageSourceCopyPropertiesAtIndex`,
every image of an .ico) before anything is decoded. Over 2048 px on a side, or a bitmap whose
size cannot be read: no icon. Data ImageIO does not know (SVG) is still drawn as a vector.

## Wrong fix

A smaller byte cap: a few KB of PNG still holds thousands of pixels a side.

## Proof

Red first on cc8affe (4000 px); green with the fix for 4000 and 2049 px refused, 2048 and 64 px
kept (P2-FIX-1, test.sh). Red again under a mutation where `fits` returns true. Not read back;
the app's footprint with such an icon not measured.
