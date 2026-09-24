# Wirdi — Islamic Companion App

**Version:** 1.56.0 (Build 22) | **Code Version:** v16.1.29 (Visual-identity + tools-reorg)  
**Status:** Release-prep + comprehensive-review + visual-identity fixes applied -- see RELEASE_PREP_v1.54.md, RELEASE_PREP_v1.55.md and RELEASE_PREP_v1.56.md for what changed and the manual steps still required

## What is Wirdi?

Wirdi is a comprehensive Islamic companion app for Muslims, featuring:
- **Quran Reader** with offline reading, bookmarks, search, and playback
- **Prayer Times** with GPS, city lookup, and accurate calculation methods
- **Islamic Content**: Prophet stories, Hadith, Fiqh rulings, Islamic history, articles
- **Personal Tools**: Khatma (Quran completion tracking), Tasbeeh counter, Azkar, Sadaqah tracker, Hifz (memorization) tracking
- **Radio** with curated Islamic stations
- **Qibla Compass** with AR precision mode
- **Cloud Sync** via Firebase (Email, Google, Apple sign-in)
- **Multilingual** (Arabic, English, Urdu, Malay, Indonesian, Turkish, French)

## Features Implemented (v1.53.0)

### Core
- ✅ Quran Reader (full text, audio per-ayah/surah, offline download, bookmarks, search)
- ✅ Prayer Times (GPS, city search via Nominatim, AlAdhan API, 8 calculation methods, 4 madhabs)
- ✅ Islamic Content Library (24 prophets, 14 fiqh rulings, 20 historical events, 6 articles, 10 Arabic lessons, Hajj/Umrah guides)
- ✅ Personal Progress Tracking (Khatma, Tasbeeh, Hifz, Sadaqah, prayer logs)
- ✅ Cloud Sync (Firebase Firestore with per-user security rules)
- ✅ Offline Support (cached Quran, prayer times cache, local storage)
- ✅ Radio (4 curated Islamic station APIs with fallback)
- ✅ Notifications (prayer alarms, daily reminders, Adhan audio)
- ✅ Multi-language (7 languages supported)
- ⚠️ Boot Alarm Rescheduling — NOT implemented (requires native Android BroadcastReceiver, deferred to v1.54)
- ⚠️ Timezone Change Handling — NOT automatic (invalidatePrayerCache() exists but has no trigger wired yet, deferred to v1.54)

### Known Limitations (v1.53.0)
- ⚠️ Quran text cached in SharedPreferences (should use SQLite — deferred to v1.54)
- ⚠️ Quran summaries only available for 3 surahs (others show "not available yet" — deferred to v1.54)
- ⚠️ No offline Hadith starter dataset (requires internet on first launch — deferred to v1.54)

## Installation

### From Source
```bash
git clone https://github.com/wirdi/wirdi.git
cd wirdi
flutter pub get
flutter run
```

### From APK
Download latest APK from Releases or Google Play Store.

## Firebase Setup

See FIREBASE_SETUP.md for detailed setup instructions.

**Current Project:** wirdi-cb813

## Security & Privacy

- All user data stored in Firestore is encrypted in transit (HTTPS only)
- Per-user security rules enforce user-only access to their own data
- No cleartext traffic allowed
- Prayer alarms do NOT currently reschedule after device reboot (known limitation, needs native Android work)
- Prayer times cache does NOT currently auto-invalidate on timezone/time changes (known limitation)

## What's New in v1.53.0

### Security Fixes (v229)
- Fixed critical Firebase project mismatch (wirdi-cd6c0 → wirdi-cb813)
- Fixed user-facing error message escaping
- Removed exposed keystore passwords from documentation
- Added CI hard gate for Firebase consistency

### CI & Build (v230)
- Pinned Flutter version (3.35.5) for deterministic builds
- Preserved pubspec.lock (no longer deleted on every run)

### Notifications & Reliability (v232)
- Attempted BOOT_COMPLETED/TIMEZONE_CHANGED handlers in v232-v236, but they only declared native Android receiver
  classes in AndroidManifest.xml without ever creating the matching Kotlin/Java classes -- non-functional.
  Reverted in v239: removed the misleading manifest declarations and dead Dart stub code. This remains an
  open item for a future release (needs real native BroadcastReceiver + a way to run Dart in the background,
  e.g. via the workmanager plugin).

## License

MIT License

---

**Last Updated:** 2026-09-06  
**Version:** v1.53.0+19 (Build 19)  
**Code Status:** Ready for device testing
