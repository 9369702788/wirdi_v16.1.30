# Wirdi v1.54.0 (build 20) -- Google Play preparation

Everything below was done in code/CI. Nothing here was compiled or run by the author of
this change set (no Flutter SDK available): run the CI, then test the **release APK** on a
real device before uploading the AAB.

## Fixed in this version
| # | Problem | Fix |
|---|---------|-----|
| 1 | Release AAB was signed with the DEBUG key (Flutter template + patch ordering) | `patch_release_signing.py` + workflow step; HARD GATE #3 now also checks the AAB |
| 2 | R8 resource shrinker would delete `adhan_sound` (referenced only by name) from release builds | `android_overrides/res/raw/keep.xml`, copied by CI |
| 3 | Notification small icon was the coloured launcher icon (grey square) | monochrome `ic_stat_wirdi` drawable (notifications + audio_service) |
| 4 | Quran text needed internet on first launch, no fallback | `assets/data/quran.json` (quran-json 3.1.2, CC BY 4.0) used as seed/fallback |
| 5 | Azkar + Mushaf page data fetched at runtime from personal GitHub repos (unpinned) | bundled: `azkar.json` (MIT), `mushaf_pages.json` (MIT); transliteration pinned to the same npm release |
| 6 | Radio: unverified personal sources (data-rosy.vercel.app, uthumany) + generic tags; `http://` streams could never play (cleartext disabled) | sources removed, generic tags removed, https-only filter (streams and favicons) |
| 7 | `qcf_quran` package unused (7 MB, placeholder `qcf4.zip`) | removed |
| 8 | Fonts with redistribution-restricting licences: `me_quran` (non-commercial), AlQuran Neo / IndoPak (QuranWBW: "not for distribution") | removed; saved preference falls back to default font |
| 9 | `patch_manifest.py` silently added nothing (permissions never inserted) | regex fix, fails loudly, adds optional-hardware `uses-feature` (camera/location/compass) |
| 10 | Privacy policy incomplete/inaccurate (camera, external services, location used on Home too) | rewritten (ar/en/de/tr) + hosted pages in `docs/` |
| 11 | Sources & Licenses screen missing font / data / OSM / Open-Meteo credits | added |
| 12 | Notification permission requested the instant the app opens | first-run users are asked right after onboarding |
| 13 | Tajawal downloaded from Google Fonts at runtime | bundled in `assets/google_fonts/`, runtime fetching disabled |
| 14 | Cancelling Google sign-in showed "Exception: cancelled" | silent |
| 15 | No tests / lock file | `test/` (data integrity + radio filter), CI uploads `pubspec.lock` |
| 16 | Stale SHA-1 in RELEASE_SIGNING_SETUP.md | corrected |

## STILL MANUAL (cannot be done from code)
1. **Register SHA-1 keys in Firebase** (project wirdi-cb813): upload key + (after first upload) Play App Signing key from Play Console -> App integrity. Download the new `google-services.json`, commit it. Set the OAuth consent screen to **In production**.
2. **Host the policy pages**: enable GitHub Pages on `/docs`, replace `CONTACT_EMAIL_HERE` in `docs/*.html`, then set `AppSources.privacyPolicyUrl` and `AppSources.privacyContactEmail` in `lib/core/data/app_sources.dart`.
3. **Contact e-mail in User-Agent**: `nearby_places_service.dart` sends `support@wirdi.app`. Nominatim's policy needs a real, reachable contact -- change it to yours.
4. **Play Console declarations**: Data safety (email, name, photo, precise+approximate location, user content via Firebase; data encrypted in transit; deletion supported + URL of `docs/delete-account.html`); foreground service `mediaPlayback` (audio playback of Quran/radio, needs a short demo video); exact alarms (prayer reminders); camera (Qibla camera mode); content rating; target audience (13+/all, not designed for children).
5. **Restrict the Firebase API key** (Google Cloud Console -> Credentials): Android apps only, package `com.wirdi.wirdi` + your SHA-1s.
6. **Licences to keep an eye on**: Open-Meteo's free API is for non-commercial use (fine for a free app without ads/IAP; get a plan if you monetise). QuranEnc/Al Quran Cloud/HadeethEnc terms are credited on the Sources screen.
7. Commit `pubspec.lock` (download it from the CI artifact) for reproducible builds, then make the "Unit tests" step blocking (remove `continue-on-error`).
8. New personal Play developer accounts usually must run a closed test (12 testers, 14 days) before production access.
