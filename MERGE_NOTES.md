# Merge notes: Quran Engine + Advanced Compass + Audio/Search/Bookmarks/Mini-player + Notification diagnostic (v22)

This build is your wirdi_v16.1.10 codebase, plus:

## Diagnosing: background notification never appears (not even in foreground)
User confirmed: OS-level notification permission for the app IS enabled, and the
"Wirdi Playback" notification never appears at all, even while the app is open and
audio is actively playing. That rules out the permission and points at either (a) a
stale, disabled notification channel left over from earlier test builds (Android
permanently remembers a per-channel notification setting across app
reinstalls/updates, keyed by channel ID), or (b) AudioService.init() silently failing
(it was only ever logged to debugPrint, invisible in a normal running build).

Two changes to actually find out which it is and fix (a) outright:
1. Rotated the notification channel ID from 'com.wirdi.wirdi.audio' to
   'com.wirdi.wirdi.audio.v2' in lib/main.dart -- guarantees a fresh, default-enabled
   channel, bypassing any old disabled channel from earlier testing in this session.
2. Added `audioServiceInitError` (lib/core/services/wirdi_audio_handler.dart) --
   if AudioService.init() throws, the error is now shown as an AlertDialog on app
   startup (lib/shared/widgets/root_shell.dart initState) instead of only being
   debugPrint'd. If it's still broken after this build, whatever this dialog says is
   the next real clue.

## Background playback + notification controls: already existed
Wirdi already had this fully built (WirdiAudioHandler + audio_service package). The
above changes are about diagnosing/fixing why the notification wasn't appearing, not
rebuilding this from scratch.

## New in v21/v22: global floating mini-player for Quran playback
lib/features/quran/widgets/quran_mini_player.dart - a new QuranMiniPlayer widget, wired
into lib/shared/widgets/root_shell.dart right alongside the existing RadioMiniPlayer, so
it's visible app-wide (any tab/screen) whenever Quran recitation is playing, not just
inside the Quran Reader screen. Shows the current surah/ayah number, play/pause, and stop;
tapping it opens the Quran Reader. Added a small `currentSurahNumber` getter to
QuranAudioService (exposes already-existing private state, no behavior change) so the
mini-player can display what's playing.

## New in v22: verse-range playback
QuranAudioService gained `playRange(surah, allSurahs, startAyah, endAyah)`, reusing the
same sequential/preloading engine as playWholeSurah, just bounded to a range (and
"repeat whole surah" now correctly restarts the range instead of the whole surah when a
range is active). Wired into the Quran Reader's app bar as a new icon that opens a
from/to slider dialog.

## Fix: Radio/Quran audio stopping by itself after a while
Added a global AudioContext (lib/main.dart, right after Firebase init) that requests
proper Android audio focus (AndroidAudioFocus.gain) and a wake lock (stayAwake: true)
for every AudioPlayer instance app-wide. Without this, audioplayers has no dedicated
audio-focus request or wake lock on Android, which is a well-documented cause of
playback silently stopping after the screen locks or the app backgrounds for a while.
This is additive and applies globally -- no changes to RadioService or
QuranAudioService's own playback logic were needed.
Note: on some phones with aggressive battery managers (Xiaomi/MIUI, Huawei, some
Samsung configurations), you may also need to manually disable battery optimization /
enable "autostart" for Wirdi at the OS level -- that part isn't fixable in code.

## Local packages (packages/)
- packages/qcf_quran/ - qcf_quran engine from Al-Furkan (data layer only in this build).
- packages/flutter_compass_v2/ - patched compass plugin (native TSAGeoMag true-north model).

## Build fixes carried over from earlier rounds
1. Removed old `flutter_compass` dependency (namespace collision with flutter_compass_v2);
   qibla_screen.dart now imports flutter_compass_v2 instead (same Dart API).
2. Added 6 missing fields to packages/qcf_quran/lib/src/qcf_theme_data.dart that two of its
   own widget files referenced but didn't exist (pre-existing bug in the vendored package).
3. Added a placeholder packages/qcf_quran/assets/fonts/qcf4.zip so Flutter's asset bundler
   doesn't fail at build time (the real 604-font QCF bundle isn't in Al-Furkan's public repo).

## New in v19: Quran Reader is now wired into Wirdi's own existing audio system
lib/features/quran/mushaf_reader_screen.dart was rewritten to use Wirdi's own
QuranRepository (same text source as the existing quran_screen.dart) and Wirdi's own
QuranAudioService (the same app-wide, already-tested audio engine used elsewhere) instead
of qcf_quran's bundled text -- this means real playback, background/notification controls,
and offline downloads all work using code that was already proven, not a second new stack.

New features in the Quran Reader:
- Per-ayah and whole-surah audio playback (play/pause/resume)
- Playback speed control (0.5x-2x) -- new `setSpeed()` method added to QuranAudioService
- Repeat current ayah (existing feature, now exposed in the UI)
- Repeat whole surah (new) -- new `repeatSurah` field + `toggleRepeatSurah()` added to
  QuranAudioService
- Sleep timer (5/10/15/30 minutes)
- Download surah for offline listening (uses the existing AudioDownloadService, with a
  progress dialog)
- Bookmark any ayah (uses the existing BookmarkService)
- Full verse-text search across the whole Quran (toggle next to the surah search box),
  in addition to the existing surah-name search
- Night reading mode (amber-on-dark toggle)

## Advanced Qibla (Pro) screen
lib/features/qibla/advanced_qibla_screen.dart - a second Qibla compass screen using
flutter_compass_v2 directly. Original qibla_screen.dart also now benefits from the same
more-accurate compass plugin (see fix #1 above), kept as a separate screen for clarity.

## Deliberately NOT included in this pass (and why)
- Tajweed color-coding via qcf_quran's TajweedVerse widget: it's built around the same
  QCF per-page glyph font system that qcf4.zip would enable, and is not compatible with
  plain Unicode Quran text. Shipping it would show garbled/wrong glyphs, so it's left out
  until the real qcf4.zip is available.
- Alternative Quran fonts (6 mentioned from Al-Furkan): several of them are also
  glyph-substitution style fonts whose compatibility with plain Unicode text wasn't
  verified. Left out to avoid shipping broken-looking text.
- Custom playlists, a full 3-tab offline-audio manager UI, verse-range playback, and a
  floating mini-player: all real, reasonable next steps, just scoped out of this pass to
  keep this batch reviewable and low-risk. Happy to build any of these next.

## Before your first build
Nothing manual needed - flutter pub get runs automatically as part of your existing
GitHub Actions workflow (.github/workflows/build_apk.yml).
