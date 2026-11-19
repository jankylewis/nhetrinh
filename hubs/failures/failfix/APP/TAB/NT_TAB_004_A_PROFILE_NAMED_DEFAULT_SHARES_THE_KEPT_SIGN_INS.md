# NT-TAB-004 — A profile named default shares the kept sign-ins — fix

id: NT-TAB-004
family: TAB
status: OBSERVED
date: 2026-11-18
source: _app/_Sources/NhetrinhCore/Shell/Profile/_ProfileLayout.swift (`refusal`, `init?`)
source: _app/_Sources/_Nhetrinh/_Browser/Lifecycle/ProfileKeeping.swift (`prepareProfile`: a refused name keeps nothing)
source: _app/Tests/NhetrinhTests/SignIns/ProfileWiringTests.swift (`aRefusedNameKeepsNoFolder`, `theStoreFollowsTheProfile`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P10-PROFILE, not on master)

`ProfileLayout.refusal` refuses `default` in any case (and `profiles`, P9's root file names, `/ : \`,
a leading dot, edge spaces, control characters, over 64 characters). A refused name gets no layout: no
folder, no Keychain keeper, a non-persistent data store; it is logged at launch. The default profile's
service is unchanged.

## Wrong fixes

Renaming the default profile's service: the item the installed app wrote would no longer be read (D29).

## Proof

Red first: not run (the refusal is new code). Mutation: without the case-insensitive check
`aNameThatCollidesOrEscapesIsRefused` fails (P10-PROFILE gate). `test.sh` exit 0. Not read back.
