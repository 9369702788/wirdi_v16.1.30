# One-time setup: permanent RELEASE signing via GitHub Secrets

Release builds are signed from GitHub Secrets, never auto-generated in CI.
Do this ONCE:

1. Get a release.keystore file. If you already downloaded one from a
   previous Actions run artifact ("release-keystore-COMMIT-THIS-TO-REPO-ROOT-AND-KEEP-SAFE"),
   use that exact file so any prior release build stays consistent.
   SECURITY NOTICE: this document used to print this keystore's real
   storePassword/keyAlias/keyPassword in plain text -- those values
   must be treated as COMPROMISED. Generate a brand new release
   keystore with a fresh password, store credentials ONLY as GitHub
   Secrets (step 3), and never commit release.keystore or
   key.properties to git.

2. Base64-encode the keystore file:
   - Windows (PowerShell): [Convert]::ToBase64String([IO.File]::ReadAllBytes("release.keystore")) | Out-File release.keystore.b64
   - macOS/Linux: base64 -i release.keystore -o release.keystore.b64

3. In your GitHub repo: Settings > Secrets and variables > Actions > New repository secret.
   Create these 4 secrets (use YOUR newly-generated, never-shared values):
     RELEASE_KEYSTORE_BASE64   = (paste the full contents of release.keystore.b64)
     RELEASE_KEYSTORE_PASSWORD = <your new store password -- never write it in any file>
     RELEASE_KEY_ALIAS         = <your new key alias>
     RELEASE_KEY_PASSWORD      = <your new key password -- never write it in any file>

4. Keep the original release.keystore file backed up somewhere safe OUTSIDE
   GitHub too (e.g. a password manager or encrypted drive). If you ever
   lose it AND the GitHub secret, you can never publish updates to the
   same Play Store listing again.

5. Do NOT commit release.keystore or key.properties to the repository.
   They are intentionally excluded now -- the workflow builds them at
   runtime from the secrets above and discards them after the job ends.

---

# The THREE distinct signing certificates -- do not confuse them

Wirdi has (or will have) THREE separate signing certificates in play at
different stages. Each one needs its OWN SHA-1/SHA-256 registered as a
separate OAuth Android client in Firebase/Google Cloud Console for
Google Sign-In to keep working at that stage. Registering only one and
assuming it covers the others is the single most common cause of
"Google Sign-In worked in testing but broke after publishing".

## 1. Debug keystore
- Used for: CI-built debug APKs (the "wirdi-debug-apk" artifact), and
  anyone building `flutter run` / `flutter build apk --debug` locally
  with the SAME committed `debug.keystore` file.
- Where it lives: `debug.keystore` committed at the repo root (see
  LOCAL_DEV_SETUP.md for how it was generated and why a committed file
  is used instead of each machine's own auto-generated debug keystore).
- Verified automatically every CI run by HARD GATE #1/#2 in
  `build_apk.yml` (reads the actual built APK's certificate, not just
  the keystore file).
- SHA-1 currently registered in Firebase (wirdi-cb813) for this
  certificate: `2A:7B:78:30:20:FD:3B:27:D4:4D:35:AA:37:21:32:B7:F3:04:B9:13`
  (v1.54: corrected -- an older revision of this file listed a different, stale
  fingerprint. This value is what `keytool` prints for the committed debug.keystore
  and what google-services.json contains.)
  (working -- do not change unless this exact keystore file changes).

## 2. Upload key (release.keystore)
- Used for: the RELEASE .aab/.apk this CI workflow builds and uploads
  as an artifact -- this is the file you actually upload to Google Play
  Console when publishing/updating the app.
- Where it lives: NEVER committed to the repo. Built at CI runtime from
  the `RELEASE_KEYSTORE_BASE64` GitHub Secret (see setup steps above),
  and discarded when the job ends.
- Verified automatically by HARD GATE #3 in `build_apk.yml` (reads the
  actual built release APK's certificate and compares against
  release.keystore's own fingerprint -- fails the build on any
  mismatch).
- Its SHA-1/SHA-256 MUST be registered in Firebase (wirdi-cb813) as a
  SECOND Android OAuth client (same package name `com.wirdi.wirdi`,
  different SHA-1) -- otherwise Google Sign-In will work in CI-built
  debug testing but fail for anyone using an app built from this
  upload key, e.g. during Closed Testing before Play App Signing takes
  over. Get the fingerprint via:
  `keytool -list -v -keystore release.keystore -storepass <pwd> -alias <alias>`

## 3. Google Play App Signing key
- Used for: the ACTUAL certificate every real user downloads from the
  Play Store is signed with. Once "Google Play App Signing" is enabled
  for this app (Play Console prompts for this the first time you
  upload a release, and it is effectively mandatory for new apps now),
  Google RE-SIGNS your uploaded .aab with its OWN managed key before
  distributing it -- the upload key above only proves to Google that
  the upload came from you, it is NOT what ships to users.
- Where it lives: entirely inside Google's infrastructure -- you never
  see the private key. You only see its PUBLIC certificate fingerprint,
  shown in Play Console under
  **Setup -> App integrity -> App signing -> App signing key certificate**.
- CANNOT be verified by this CI pipeline at all (it does not exist
  until Google generates it during your first Play Console upload) --
  this one is GOOGLE PLAY VERIFIED only, never CODE VERIFIED or DEVICE
  TESTED.
- Its SHA-1/SHA-256 MUST be copied from Play Console and registered in
  Firebase (wirdi-cb813) as a THIRD Android OAuth client. **Do this
  immediately after your first successful upload/release, BEFORE
  announcing the app publicly** -- until this is done, Google Sign-In
  will fail for every user who installs the app FROM the Play Store
  (it will still work fine for anyone testing your own upload-key-signed
  APK directly, which is why this gap is easy to miss during testing).

### Summary table

| Certificate         | Where it signs             | Verified by                          | Registered in Firebase? |
|----------------------|-----------------------------|----------------------------------------|--------------------------|
| Debug keystore        | CI debug APK, local dev     | HARD GATE #1/#2 (automatic, every run) | Yes -- already done      |
| Upload key             | CI release .aab/.apk       | HARD GATE #3 (automatic, every run)    | Do this before Closed Testing |
| Play App Signing key   | What real users receive     | Cannot be automated -- read from Play Console manually | Do this immediately after first Play Console upload |


## v1.54 -- how the RELEASE build is actually signed (IMPORTANT)
Flutter 3.35's generated `build.gradle.kts` signs the `release` build type with the
DEBUG key. `patch_gradle.py` runs before `key.properties` exists, so it could never
change that. Since v1.54 the workflow runs `patch_release_signing.py` right after the
release secrets are written and before `flutter build appbundle --release`, and
HARD GATE #3 now verifies BOTH the release APK and the release AAB against
`release.keystore`. If you ever see "release AAB is NOT signed with release.keystore",
that patch step did not run or its self-check failed.
