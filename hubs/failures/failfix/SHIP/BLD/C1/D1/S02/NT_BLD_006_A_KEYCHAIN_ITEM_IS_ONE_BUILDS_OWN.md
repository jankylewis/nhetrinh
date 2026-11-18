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
signature is not the one chosen. One item per profile (account `signins`): a new build signed by the same
identity is the same app to the Keychain. Every call runs with user interaction off (put back after): a call
that would ask fails at once with its status. A write updates the item in place (allowed whatever signature
made it), adding only a missing one; a delete this signature may not make empties the item in place (read as
none kept): one item, nothing piles up. Cost: an ad-hoc build may not read what a signed build kept.

## Wrong fix

`LAContext.interactionNotAllowed` alone (the first diff): it does not cover the login Keychain's access list.
One item per build (round 1): no prompt, but nothing survives a reinstall, and one emptied item per build stays.

## Proof

`KeychainSecretsTests` on a fake of the Security calls (interaction off on every call and put back, the one
account, update-in-place, the refused delete) and `anEmptiedItemIsNoneKept` red on stubs, green (test.sh);
mutations caught (P9-REMEMBER round 2). `_build.sh` built signed by the local identity (`codesign -dvv`
Authority). Not proven: the real Keychain across two signed builds (no run, R51 not read back).
