# NT-BLD-006 — A Keychain item is one build's own — fix

id: NT-BLD-006
family: BLD
status: OBSERVED
date: 2026-11-18
source: _app/_Sources/_Nhetrinh/Support/Secrets.swift (`KeychainSecrets`)
source: _app/_Sources/NhetrinhCore/Prefs/SignIns/SignInKeeper.swift (`kept`: every launch deletes)
links: fix=yes lesson=yes evidence=no toolgap=none

## Fix that holds

Round 2 (headmate priority: sign-ins survive reinstalling a new build). `_build.sh` signs the app with the local
identity of `install/signing.sh` when it exists, else ad hoc (GitHub CI), prints which, and stops when the
signature is not the one chosen. One item per profile and signing kind (P9-REMEMBER-2: account `signins.signed`
or `signins.adhoc`, from the app's own code-signing flags; unknown counts as ad hoc): a new build signed by the
same identity is the same app to the Keychain, and an ad-hoc build never touches the signed builds' item. A launch
refused the item (-25293, -25243, -25244, -25308) makes that run's quit write nothing, logged as
`the item cannot be read (keychain status <n>), kept 0 of <count>`. Every call runs with user interaction off (put back after): a call
that would ask fails at once with its status. A write updates the item in place (allowed whatever signature
made it), adding only a missing one; a delete this signature may not make empties the item in place (read as
none kept): one item per kind, nothing piles up. The old account `signins` (77ee8f5 and earlier): a signed
build with no item of its own reads it once, then deletes it (and a delete removes it too), so the update to this
build keeps the sign-ins (matemaster review, 2026-11-19: without it the first launch after the install restored
nothing and the headmate signed in again); one it may not read counts as none.

## Wrong fix

`LAContext.interactionNotAllowed` alone (the first diff): it does not cover the login Keychain's access list.
One item per build (round 1): no prompt, but nothing survives a reinstall, and one emptied item per build stays.
One account `signins` for every build (round 2): an item first kept by an ad-hoc build is unreadable by a signed
one forever; launches read -25293 and quits keep writing into it (RECHECK_P9_REMEMBER.md round 2, nhetrinh_1).

## Proof

`KeychainSecretsTests` on a fake of the Security calls (interaction off on every call and put back, the one
account, update-in-place, the refused delete) and `anEmptiedItemIsNoneKept` red on stubs, green (test.sh);
mutations caught (P9-REMEMBER round 2). `_build.sh` built signed by the local identity (`codesign -dvv`
Authority). P9-REMEMBER-2: `everyCallIsTheProfilesOneItemOfItsSigningKind` (`RecordedCalls`) and
`aQuitAfterAnAccessRefusedReadWritesNothing` red on stubs (24 and 9 issues), green; mutations caught: one account
for both kinds, the launch never marking the refusal, the quit ignoring it. The flag read: a scratch ad-hoc
binary reads `adhoc`; the installed app's `codesign -dv` reads `flags=0x0`. The old account: `anUpdateReadsTheOldItemOnce` (written
after the fix; mutation caught: no fallback read fails 2 of its 4 cases). Not proven: the real Keychain
across two signed builds, an ad-hoc build after a signed one (no run, R51 not read back).
