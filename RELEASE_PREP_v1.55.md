# Wirdi v1.55.0 (build 21) -- fixes from the comprehensive review

Builds on RELEASE_PREP_v1.54.md. Nothing here was compiled or run (no Flutter SDK
available in this environment): run `flutter analyze` and `flutter test`, then test
the release APK on a real device, before uploading. Every change below was verified
by static syntax/reference checking, not by running the app.

## Audio (priority 1 -- reported bug)
- **Ayahs cutting off early during whole-surah playback.** The old code advanced to
  the next ayah a fixed ~220ms before what it believed was the end, using a
  `duration` value that, right after a preloaded hand-off, was still the *previous*
  ayah's. Any ayah longer than the one before it got cut short and the reciter
  jumped ahead -- reproduced arithmetically on real ayah lengths (Al-Baqarah: ~49% of
  ayahs cut short). Fixed: an ayah now only ends on the player's own completion
  event; a stream that completes far short of its known length is resumed from
  where it stopped (once) instead of being skipped.
  See `lib/core/services/quran_audio_service.dart`.
- **Progress display is now at surah level, not per-ayah**, as requested: a new
  `SurahProgressModel` (`lib/core/services/surah_progress_model.dart`, unit-tested in
  `test/surah_progress_model_test.dart`) turns "which ayah + how far into it" into one
  0.0-1.0 value and a clock (elapsed / ~total) for the whole surah or played range.
  Wired into the playback bar (draggable, seeks on release), the mini-player (thin
  progress line), and the system media notification (surah title, ayah x/N, surah
  duration).
- Other reliability fixes in the same file: a stall watchdog (retries once if an
  ayah shows zero progress after 12s), a generation token so a late preload can't
  mark the wrong ayah ready, and the playback speed is now applied to the preloaded
  player at hand-off (it used to reset to 1.0x on every advance).

## Prayer times -- P0 findings from the review report
- **Notifications now scheduled 14 days ahead** (was 2), via `PrayerService.fetchUpcomingPrayers`
  (one AlAdhan calendar request per month touched). If the fetch fails offline,
  already-scheduled future notifications are kept instead of being wiped.
- **Manual calibration offsets are applied once**, inside `PrayerService._buildPrayersForDate`,
  so the times list, the countdown, notifications and the home-screen widget can no
  longer disagree (previously the offset only changed the displayed text).
- **Time zone handled correctly**: AlAdhan's `meta.timezone` is read and used (via the
  `timezone` package) to convert each clock time to the correct absolute instant --
  fixes a manually chosen city (or travel) in a different zone showing a wrong
  countdown/notification time.
- **Default calculation method is now region-based** (`defaultCalcMethodForRegion`,
  keyed off the device locale's country), instead of Egyptian General Authority for
  every user regardless of location. 8 more AlAdhan methods were added to the picker
  (Diyanet, Dubai, Kuwait, Qatar, JAKIM, KEMENAG, Morocco, UOIF France).
- **Recurring daily reminders (Fajr azkar, Friday, etc.) are rescheduled automatically**
  when the device's UTC offset changes (DST or travel), via
  `DailyReminderScheduler.rescheduleIfTimeZoneChanged`, called on app start and
  whenever the prayer times are refreshed.

## Qibla
- **Magnetic declination correction added.** The compass previously reported a
  magnetic heading directly against a true-north bearing (error up to ~13-15 in
  parts of North America/Australia) while the UI claimed a "true-north model". A
  `wirdi/declination` method channel (backed by Android's `GeomagneticField`, added
  to the local `flutter_compass_v2` plugin) now supplies the local declination,
  applied in all three Qibla screens (`qibla_screen`, `advanced_qibla_screen`,
  `qibla_camera_screen`) via `MagneticDeclinationService`.

## Account deletion / sync (P0 privacy finding)
- **Account deletion now removes every synced document.** `custom_azkar`, `sadaqah`,
  `qada`, `muhasabah` and `recitation_mistakes` were missing from the delete list and
  survived deletion (`allSyncedDocumentNames` in `sync_service.dart` is now the single
  source of truth shared by upload/download/delete).
- **Sync no longer overwrites wholesale.** Downloading cloud data used to replace
  local values field by field. Counters and totals now keep the larger value, lists
  (favorites, bookmarks, completed items) are unioned, and the wird streak keeps
  whichever side has the more recent day.

## Content and privacy
- Removed the third Overpass mirror (`maps.mail.ru`); unified the OpenStreetMap
  User-Agent (`AppSources.httpUserAgent`) across nearby-places and prayer-time
  reverse geocoding.
- **Fatwa content corrected**: 4 rulings that were labelled "General consensus" but
  are actually contested between schools were re-worded to say so (combining/shortening
  prayers while traveling, what breaks wudu, eating while fasting by mistake); the
  interest-loan-under-necessity entry (a high-stakes, genuinely disputed ruling) was
  removed; the duplicate "forgetting while fasting" entry was merged; the in-app
  disclaimer now says these are educational summaries, not fatwas. **This still needs
  review by a qualified scholar** -- it was corrected against what the review could
  verify from the wording itself, not authoritatively re-derived.
- Article author attribution changed from the fabricated "Islamic Scholar" to "Wirdi
  editorial team"; fabricated publish dates removed.
- Islamic-occasion reminders (Ramadan, Eid, etc.) now say "expected tomorrow" instead
  of asserting the date, are translated (7 languages, was Arabic/English-only), and a
  new Settings control lets the user shift the calculated Hijri date by -2..+2 days to
  match local moon-sighting/official announcements (`HijriDate.dayOffset`).

## Removed
- The "background ambiance" picker (rain/ocean/birds...) in the Quran reader did
  nothing but save a name -- no audio ever played. Removed rather than left
  half-working.
- The tajweed-coloring legend (`showTajweedLegend`) was written but never opened from
  anywhere; it's now reachable from Settings next to the tajweed-coloring toggle.
- Dead code: `boot_receiver.dart` (an unused stub -- the real post-reboot
  rescheduling is `flutter_local_notifications`' own `ScheduledNotificationBootReceiver`,
  registered in the manifest and unaffected by this), a duplicate unused
  `HijriConverter` class inside `khatma_calendar_screen.dart`, `abjad_calculator.dart`
  (unreferenced), `wirdi_scenic_background.dart` (unreferenced), and the
  `sign_in_with_apple` dependency (never imported -- Apple sign-in goes through
  Firebase directly).

## Performance / quality
- `QuranRepository.load()` now keeps an in-memory cache and parses off the UI thread
  (`compute`), instead of re-parsing the 1.4 MB / ~6,000-ayah JSON synchronously on
  every one of its ~15 call sites.
- The home screen's and prayer screen's 1-second countdown timers now only rebuild a
  small `ValueListenableBuilder` text, not the whole ~1,000-line screen (both screens
  stay alive the whole time inside `RootShell`'s `IndexedStack`).
- Fixed two real leaks: the onboarding `PageController` had no `dispose()`; a
  `StreamSubscription` in the settings screen's adhan-preview player was created
  without ever being cancelled.
- Battery-optimisation guidance card added to the notification diagnostics screen
  (Samsung/Xiaomi/Oppo background restrictions are the most common reason the adhan
  is late or silent) with a direct link to the app's system settings.
- The two largest bundled images were re-encoded PNG -> WebP with no visible quality
  loss at their in-app display size: `wirdi_mosaic` 2.0 MB -> 144 KB, `mosque_sunrise`
  1.9 MB -> 114 KB (~3.7 MB saved). The unused `assets/images/ui/` folder (6 images,
  not declared in pubspec, not referenced anywhere) was deleted.

## Still not done (from the comprehensive review report)
Not attempted in this pass -- still open:
- F3: adhan-choice-has-no-effect-on-Android-8+ (needs per-adhan notification
  channels or a UI change; a real design decision, not a small fix).
- F13: ~24 screens still have Arabic/English-only inline text instead of full ARB
  translation (largest: the 62-entry tools hub).
- F21: unbounded daily SharedPreferences keys / Firestore documents that grow
  indefinitely with usage.
- F22: the persistent "next prayer" notification's text doesn't refresh itself after
  the prayer passes until the app is reopened.
- F23: 7 bottom-nav tabs, flat 62-entry tools list, thin accessibility coverage.
- Crash reporting, in-app review prompt, family-sharing feature: not added (each
  needs a product decision, and Crashlytics needs a privacy-policy/Data-Safety update
  first).

## What was NOT verified
No Flutter SDK was available to run `flutter analyze`, `flutter test`, or a build.
Every changed file was checked with a Dart syntax parser (tree-sitter) and
cross-referenced against the rest of the codebase for dangling symbols; none were
found. But logic correctness (especially the audio hand-off and the timezone
math) needs `flutter test`, `flutter analyze`, and real-device testing -- in
particular: play a long surah start-to-finish and confirm no ayah cuts short; drag
the surah progress slider; change reciter and speed mid-playback; set a manual city
in a different time zone and compare the countdown to a clock; change the device's
date across a DST boundary and confirm the daily reminders stay at the right local
hour; compare the Qibla direction against a known-accurate compass in a
high-declination city.
