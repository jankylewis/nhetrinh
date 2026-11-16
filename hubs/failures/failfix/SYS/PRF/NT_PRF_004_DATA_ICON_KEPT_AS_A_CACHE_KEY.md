# NT-PRF-004 — Data icon kept as a cache key — fix

id: NT-PRF-004
family: PRF
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/NhetrinhCore/Tabs/FaviconURL.swift (`largestDataHref`, P2-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

`resolve` takes a `data:` href of 4 KB at most; a longer one gives no icon. 400 keys of 4 KB
is 1.6 MB at the very worst.

## Wrong fix

Raising only the icon byte cap in `Favicons`: the key is the href, not the fetched body.

## Proof

Red first on cc8affe; green with the fix: 4096 bytes kept, 4097, 64 KB and 500 KB refused
(P2-FIX-1, test.sh). Red again under a mutation that drops the limit. Not read back.
