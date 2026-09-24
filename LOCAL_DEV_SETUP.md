# Local Development: Google/Apple Sign-In Setup

Google/Apple Sign-In validate the app's SIGNING CERTIFICATE. If you run
this app locally via `flutter run` using your machine's own
auto-generated debug keystore, its SHA-1 will differ from the one
committed to this repo and registered in Firebase -- Sign-In will fail
with `ApiException: 10` even though everything else is correct.

## Fix: use the project's shared debug.keystore

**macOS/Linux:**
```bash
mkdir -p ~/.android
cp debug.keystore ~/.android/debug.keystore
```

**Windows:** run `setup_debug_signing.bat` from the repo root.

## Verifying it worked

```bash
keytool -list -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey | grep SHA1
```
Must print: `SHA1: 2A:7B:78:30:20:FD:3B:27:D4:4D:35:AA:37:21:32:B7:F3:04:B9:13`

## Why debug.keystore is committed (unusual, but intentional)

1. It's a DEBUG-only key (storepass/keypass = Android's well-known default
   `android` -- never used for the real Play Store release build).
2. Sign-In needs a STABLE SHA-1; every machine generating its own random
   debug keystore makes that impossible.
3. `.gitignore` has an explicit `!debug.keystore` exception so this file
   is never silently dropped again (this exact mistake previously broke
   Google Sign-In on every CI run without anyone noticing -- confirmed
   root cause as of v83).

The RELEASE keystore is never committed -- see `RELEASE_SIGNING_SETUP.md`.


## Debug vs Release vs Google Play App Signing -- THREE different certificates

Google Sign-In (and the HARD GATE CI check) only ever validates ONE
certificate at a time. Depending on which build you are testing, a
DIFFERENT SHA-1 must be registered in Firebase:

| Build you are testing              | Certificate that signs it          | Where its SHA-1 is registered |
|-------------------------------------|-------------------------------------|--------------------------------|
| CI debug APK / `flutter run` local  | `debug.keystore` (this repo's, shared)  | Firebase Console -> this Android app -> SHA-1 #1 |
| Release APK/AAB built by CI          | `release.keystore` (GitHub Secret, never committed) | Firebase Console -> this Android app -> SHA-1 #2 |
| App installed from Google Play (after upload) | Google Play App Signing certificate (Google generates/holds this, NOT your upload key) | Firebase Console -> this Android app -> SHA-1 #3, copied from Play Console -> Setup -> App Signing |

**All three SHA-1s can be registered on the SAME Firebase Android app
entry at the same time** -- Firebase allows multiple SHA-1 fingerprints
per app. If you only ever tested Sign-In on a debug APK before publishing
to Play, you have NOT yet proven Sign-In works for real users installing
from the Play Store, because that build is signed with the Play App
Signing certificate, not your debug or even your release upload key.

The CI's HARD GATE step currently validates the DEBUG certificate only
(labeled `[DEBUG]` in its output). A PASS there is not evidence about the
release or Play Store certificates -- those require their own,
separate verification once a release build / Play Store upload exists.
