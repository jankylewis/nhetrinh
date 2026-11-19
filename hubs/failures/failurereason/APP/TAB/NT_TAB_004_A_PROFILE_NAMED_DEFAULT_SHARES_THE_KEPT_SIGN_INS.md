# NT-TAB-004 — A profile named default shares the kept sign-ins

id: NT-TAB-004
family: TAB
status: OBSERVED
date: 2026-11-18
found_by: development (P10-PROFILE, reading `SignIns.service` while laying out one folder per profile)
signature: aNameThatCollidesOrEscapesIsRefused
source: _app/_Sources/NhetrinhCore/Prefs/SignIns/_SignIns.swift (`service(profile:)`: nil or empty gives `default`)
source: _app/_Sources/NhetrinhCore/Shell/Profile/_ProfileLayout.swift (`refusal`)
source: _app/Tests/_NhetrinhCoreTests/Shell/Profile/_ProfileLayoutTests.swift (`aNameThatCollidesOrEscapesIsRefused`)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

P9 names the Keychain item of a profile `...signins.<name>`, and of the default profile `...signins.default`.
`NHT_PROFILE=default` gives the same service as no profile at all: such a launch would set the default
profile's kept sign-ins into its own data store and then delete the item (used once), so the default
profile's next launch finds none. With P10's folders, `Default` and `default` are also one folder on a disk
that ignores case. No launch with that name is known: not proven that it ever happened.

## Confirm

`SignIns.service(profile: "default") == SignIns.service(profile: nil)` is true on P9 (`77ee8f5`).
