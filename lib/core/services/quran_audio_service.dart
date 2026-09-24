import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/app_sources.dart';
import '../models/quran_models.dart';
import 'app_logger.dart';
import 'audio_download_service.dart';
import 'playback_coordinator.dart';
import 'settings_service.dart';
import 'surah_progress_model.dart';

/// App-wide Quran audio playback, deliberately NOT owned by any single
/// screen's State  a screen-owned player is destroyed the moment the
/// user navigates away (e.g. switching bottom-nav tabs), which used to
/// stop playback. Living here means playback survives navigation, and
/// both the Surah reader and the Mushaf page view can control/observe
/// the exact same playback session.
///
/// Uses two alternating players for near-gapless "play whole surah": while
/// one ayah plays, the next is silently preloaded into the other, so
/// advancing doesn't need to wait for a fresh network fetch.
///
/// v1.55 playback fixes (see also SurahProgressModel):
///  * REMOVED the "advance a few ms before the end" shortcut. It compared the
///    playing position with a `duration` that was still the PREVIOUS ayah's
///    after a preloaded hand-off, so a longer ayah following a shorter one was
///    cut off after a few seconds and playback jumped ahead. An ayah now only
///    ends when its player reports completion.
///  * A stream that reports "completed" long before its known duration is
///    retried from where it stopped instead of skipping to the next ayah.
///  * Preloads carry a generation token, so a late/stale preload can never mark
///    the wrong ayah as ready.
///  * The playback speed is applied to the preloaded player at hand-off.
///  * Progress is exposed at SURAH level ([surahProgress], [surahElapsed],
///    [surahEstimatedTotal], [seekToSurahProgress]).
class QuranAudioService extends ChangeNotifier {
  QuranAudioService._();
  static final QuranAudioService instance = QuranAudioService._();

  final AudioPlayer _playerA = AudioPlayer();
  final AudioPlayer _playerB = AudioPlayer();
  late AudioPlayer _active;
  late AudioPlayer _standby;
  bool _initialized = false;

  int? _surahNumber;
  String? _surahName;
  int _surahAyahOffset = 0;
  int _totalAyahsInSurah = 0;
  int? _rangeStartAyah;
  int? _rangeEndAyah;

  int? playingAyah;
  bool playingWholeSurah = false;
  bool repeatCurrent = false;
  int? repeatCreditsRemaining;
  bool isBuffering = false;
  bool isPaused = false;
  double playbackRate = 1.0;
  bool repeatSurah = false;

  /// Position inside the CURRENT ayah.
  Duration position = Duration.zero;

  /// Length of the CURRENT ayah.
  Duration duration = Duration.zero;

  /// Which ayah number (if any) has been successfully preloaded into
  /// [_standby]. [_advanceSequential] only resumes [_standby] when this matches
  /// the ayah it is advancing to; otherwise it falls back to a fresh fetch.
  int? _preloadedAyah;
  int _preloadGeneration = 0;
  bool _advanceInProgress = false;

  /// Incremented by every fresh play so a superseded call can't clobber state.
  int _playToken = 0;

  /// Which ayah each physical player currently holds / its reported length.
  final Map<AudioPlayer, int> _loadedAyah = {};
  final Map<AudioPlayer, Duration> _playerDuration = {};

  int _prematureRetries = 0;
  int _stallRetries = 0;
  Timer? _stallTimer;

  final SurahProgressModel _progress = SurahProgressModel();
  int? _durationsSurah;
  String? _durationsReciter;

  /// The surah currently loaded for playback, or null if nothing is
  /// playing. Exposed for UI (e.g. a global mini-player) that needs to
  /// display what's playing without already knowing the surah number.
  int? get currentSurahNumber => _surahNumber;
  String? get currentSurahName => _surahName;
  int get totalAyahsInSurah => _totalAyahsInSurah;

  bool isPlayingFor(int surahNumber, int ayahNumber) =>
      _surahNumber == surahNumber && playingAyah == ayahNumber;

  bool isSurahActive(int surahNumber) => _surahNumber == surahNumber;

  // ---------------------------------------------------------------------------
  // Surah-level progress
  // ---------------------------------------------------------------------------

  /// First / last ayah of the span the progress bar covers (the played range,
  /// or the whole surah).
  int get scopeStartAyah => _progress.scopeStart;
  int get scopeEndAyah => _progress.scopeEnd;

  /// 0.0 - 1.0 progress through the surah (or the played range).
  double get surahProgress {
    final ayah = playingAyah;
    if (ayah == null || _progress.isEmpty) return 0.0;
    return _progress.progress(ayah: ayah, position: position, duration: duration);
  }

  /// Time played so far in the surah (exact for ayahs that were measured).
  Duration get surahElapsed {
    final ayah = playingAyah;
    if (ayah == null || _progress.isEmpty) return Duration.zero;
    return _progress.elapsed(ayah: ayah, position: position, duration: duration);
  }

  /// Total length of the surah; an estimate until every ayah has been measured
  /// (see [isSurahTotalExact]).
  Duration get surahEstimatedTotal => _progress.isEmpty ? Duration.zero : _progress.estimatedTotal;
  bool get isSurahTotalExact => !_progress.isEmpty && _progress.isTotalExact;

  /// Which ayah a surah-level slider [fraction] points at (for a live label
  /// while dragging).
  int ayahAtSurahProgress(double fraction) => _progress.isEmpty ? (playingAyah ?? 1) : _progress.locate(fraction).ayah;

  /// Seeks using a surah-level [fraction]. Inside the current ayah it seeks
  /// within it; to another ayah it jumps to the start of that ayah, keeping the
  /// current mode (single ayah / whole surah / range).
  Future<void> seekToSurahProgress(double fraction) async {
    final current = playingAyah;
    if (current == null || _progress.isEmpty) return;
    final target = _progress.locate(fraction);

    if (target.ayah == current) {
      if (duration > Duration.zero) {
        await seek(Duration(milliseconds: (duration.inMilliseconds * target.within).round()));
      }
      return;
    }

    isPaused = false;
    final wasWhole = playingWholeSurah;
    await _playAyahAudio(target.ayah);
    if (wasWhole) unawaited(_preloadNext(target.ayah + 1));
  }

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  void _ensureInit() {
    if (_initialized) return;
    _active = _playerA;
    _standby = _playerB;

    // Each listener is bound to the concrete player object (not to the mutable
    // _active/_standby fields, which get swapped during playback).
    for (final player in [_playerA, _playerB]) {
      player.onPlayerComplete.listen((_) => _handleComplete(player));
      player.onPositionChanged.listen((p) {
        if (identical(player, _active)) {
          position = p;
          notifyListeners();
        }
      });
      player.onDurationChanged.listen((d) => _onPlayerDuration(player, d));
    }

    _initialized = true;
  }

  void _onPlayerDuration(AudioPlayer player, Duration d) {
    if (d <= Duration.zero) return;
    _playerDuration[player] = d;
    final ayah = _loadedAyah[player];
    if (ayah != null) _progress.setKnownDuration(ayah, d);
    if (identical(player, _active)) duration = d;
    notifyListeners();
  }

  void _loadSurahContext(SurahModel surah, List<SurahModel> allSurahs) {
    _surahNumber = surah.number;
    _surahName = surah.name;
    _totalAyahsInSurah = surah.ayahs.length;
    _surahAyahOffset = allSurahs
        .where((s) => s.number < surah.number)
        .fold(0, (sum, s) => sum + s.ayahs.length);

    final reciter = appSettings.reciterId;
    if (_durationsSurah != surah.number || _durationsReciter != reciter || _progress.ayahCount != surah.ayahs.length) {
      _progress.reset(surah.ayahs.map((a) => SurahProgressModel.weightOfText(a.text)).toList());
      _durationsSurah = surah.number;
      _durationsReciter = reciter;
    }
    _progress.setScope(start: _rangeStartAyah, end: _rangeEndAyah);
  }

  // ---------------------------------------------------------------------------
  // Public playback API
  // ---------------------------------------------------------------------------

  Future<void> playAyah(SurahModel surah, List<SurahModel> allSurahs, int ayahNumber, {bool keepRepeat = false}) async {
    await PlaybackCoordinator.stopRadioForQuran();
    _ensureInit();
    _rangeStartAyah = null;
    _rangeEndAyah = null;
    _loadSurahContext(surah, allSurahs);
    playingWholeSurah = false;
    isPaused = false;
    position = Duration.zero;
    duration = Duration.zero;
    if (!keepRepeat) repeatCurrent = false;
    notifyListeners();
    await _playAyahAudio(ayahNumber);
  }

  Future<void> playWholeSurah(SurahModel surah, List<SurahModel> allSurahs) async {
    await PlaybackCoordinator.stopRadioForQuran();
    _ensureInit();
    _rangeStartAyah = null;
    _rangeEndAyah = null;
    _loadSurahContext(surah, allSurahs);
    playingWholeSurah = true;
    repeatCurrent = false;
    isPaused = false;
    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();
    await _playAyahAudio(1);
    unawaited(_preloadNext(2));
  }

  /// Plays ayahs [startAyah] through [endAyah] (inclusive) of [surah],
  /// then stops (or repeats the range if [repeatSurah] is enabled).
  /// Reuses the same sequential/preloading engine as [playWholeSurah],
  /// just bounded to the given range instead of the whole surah.
  Future<void> playRange(SurahModel surah, List<SurahModel> allSurahs, int startAyah, int endAyah) async {
    await PlaybackCoordinator.stopRadioForQuran();
    _ensureInit();
    _rangeStartAyah = startAyah;
    _rangeEndAyah = endAyah;
    _loadSurahContext(surah, allSurahs);
    playingWholeSurah = true;
    repeatCurrent = false;
    isPaused = false;
    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();
    await _playAyahAudio(startAyah);
    unawaited(_preloadNext(startAyah + 1));
  }

  /// Pauses playback in place (resumable), for the system media
  /// notification's Pause button. Distinct from [stop], which fully
  /// clears the "now playing" ayah.
  Future<void> pause() async {
    try {
      await _active.pause();
      isPaused = true;
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('Failed to pause ayah playback', error: e, stackTrace: st);
    }
  }

  /// Resumes playback after [pause], for the system media notification's
  /// Play button.
  Future<void> resume() async {
    try {
      await _active.resume();
      isPaused = false;
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('Failed to resume ayah playback', error: e, stackTrace: st);
    }
  }

  Future<void> seek(Duration target) async {
    try {
      await _active.seek(target);
      position = target;
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('Failed to seek Quran audio', error: e, stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // Engine
  // ---------------------------------------------------------------------------

  /// Starts [ayahNumber] on the active player with a fresh source.
  /// [isRetry] keeps the per-ayah retry counters (used by the recovery paths).
  Future<void> _playAyahAudio(int ayahNumber, {bool isRetry = false}) async {
    final token = ++_playToken;
    final globalNumber = _surahAyahOffset + ayahNumber;
    _stallTimer?.cancel();
    playingAyah = ayahNumber;
    if (!isRetry) {
      _prematureRetries = 0;
      _stallRetries = 0;
    }
    position = Duration.zero;
    duration = Duration.zero;
    isBuffering = true;
    notifyListeners();

    final player = _active;
    try {
      await player.stop();
    } catch (_) {
      // Nothing loaded yet  expected on first play, safe to ignore.
    }
    _loadedAyah[player] = ayahNumber;
    _playerDuration.remove(player);

    try {
      final localPath = await AudioDownloadService.localPathFor(appSettings.reciterId, globalNumber);
      if (token != _playToken) return; // superseded by a newer play/stop
      if (localPath != null) {
        await player.play(DeviceFileSource(localPath));
      } else {
        await player.play(UrlSource(AppSources.ayahAudioUrl(globalNumber, reciter: appSettings.reciterId)));
      }
      if (token != _playToken) return;
      await player.setPlaybackRate(playbackRate);
      _armStallWatchdog(ayahNumber, token);
    } catch (e, st) {
      if (token == _playToken) {
        AppLogger.error('Ayah audio playback failed', error: e, stackTrace: st);
        playingAyah = null;
        playingWholeSurah = false;
      }
    } finally {
      if (token == _playToken) {
        isBuffering = false;
        notifyListeners();
      }
    }
  }

  /// If an ayah shows no progress at all after starting (a silent stall), retry
  /// it once with a fresh fetch instead of leaving the user in silence.
  void _armStallWatchdog(int ayahNumber, int token) {
    _stallTimer?.cancel();
    _stallTimer = Timer(const Duration(seconds: 12), () {
      if (token != _playToken || playingAyah != ayahNumber) return;
      if (isPaused || position > Duration.zero) return;
      if (_stallRetries >= 1) return;
      _stallRetries++;
      AppLogger.error('Ayah $ayahNumber showed no progress after 12s; retrying once');
      unawaited(_playAyahAudio(ayahNumber, isRetry: true));
    });
  }

  Future<void> _preloadNext(int ayahNumber) async {
    final generation = ++_preloadGeneration;
    _preloadedAyah = null;
    if (!playingWholeSurah) return;
    if (ayahNumber > (_rangeEndAyah ?? _totalAyahsInSurah)) return;
    final globalNumber = _surahAyahOffset + ayahNumber;

    final localPath = await AudioDownloadService.localPathFor(appSettings.reciterId, globalNumber);
    if (generation != _preloadGeneration) return;
    if (localPath != null) return; // local files start instantly; _advanceSequential fresh-fetches them

    final standby = _standby;
    _loadedAyah[standby] = ayahNumber;
    _playerDuration.remove(standby);
    try {
      await standby.setSourceUrl(AppSources.ayahAudioUrl(globalNumber, reciter: appSettings.reciterId));
      // Only trust this preload if nothing newer started while it was loading.
      if (generation == _preloadGeneration && identical(standby, _standby)) {
        _preloadedAyah = ayahNumber;
      }
    } catch (e, st) {
      if (generation == _preloadGeneration) _preloadedAyah = null;
      AppLogger.error('Preload failed for ayah $ayahNumber -- will fetch fresh when reached instead of risking a silent stall', error: e, stackTrace: st);
    }
  }

  Future<void> _advanceSequential(int nextAyah) async {
    if (_preloadedAyah != nextAyah) {
      // Nothing confirmed ready in the standby player -- a normal fresh fetch
      // always either plays or reports a real error.
      await _playAyahAudio(nextAyah);
      unawaited(_preloadNext(nextAyah + 1));
      return;
    }

    final previousActive = _active;
    _active = _standby;
    _standby = previousActive;
    _preloadedAyah = null;
    _preloadGeneration++;
    _playToken++; // invalidate any in-flight fresh play
    _stallTimer?.cancel();

    playingAyah = nextAyah;
    _prematureRetries = 0;
    _stallRetries = 0;
    position = Duration.zero;
    // The preloaded player already reported its own length while it was standby.
    duration = _playerDuration[_active] ?? Duration.zero;
    isBuffering = false;
    notifyListeners();

    try {
      await _active.setPlaybackRate(playbackRate);
      await _active.resume();
      _armStallWatchdog(nextAyah, _playToken);
    } catch (e, st) {
      AppLogger.error('Resuming preloaded ayah failed, falling back to fresh fetch', error: e, stackTrace: st);
      await _playAyahAudio(nextAyah);
      unawaited(_preloadNext(nextAyah + 1));
      return;
    }

    // The finished player has already stopped by itself; reset it for reuse.
    try {
      await previousActive.stop();
    } catch (_) {}

    unawaited(_preloadNext(nextAyah + 1));
  }

  /// True when the player reported "completed" well before the ayah's known
  /// length: a truncated stream (network hiccup), not a real end.
  bool _endedPrematurely(AudioPlayer source) {
    if (_prematureRetries >= 1) return false;
    final expected = _playerDuration[source] ?? duration;
    if (expected <= Duration.zero || position <= Duration.zero) return false;
    final remaining = expected - position;
    final eightPercent = (expected.inMilliseconds * 0.08).round();
    final tolerance = Duration(milliseconds: eightPercent > 1500 ? eightPercent : 1500);
    return remaining > tolerance;
  }

  Future<void> _recoverPrematureEnd(int ayah) async {
    _prematureRetries++;
    final resumeAt = position;
    AppLogger.error('Ayah $ayah ended at ${resumeAt.inMilliseconds}ms of ${duration.inMilliseconds}ms; retrying from there instead of skipping');
    _advanceInProgress = true;
    try {
      await _playAyahAudio(ayah, isRetry: true);
      if (playingAyah == ayah && resumeAt > Duration.zero) {
        await _active.seek(resumeAt);
        position = resumeAt;
        notifyListeners();
      }
    } catch (e, st) {
      AppLogger.error('Premature-end recovery failed', error: e, stackTrace: st);
    } finally {
      _advanceInProgress = false;
    }
  }

  void _handleComplete(AudioPlayer source) {
    if (!identical(source, _active)) return; // stray event from the preloading standby player
    if (_advanceInProgress) return;
    final ayah = playingAyah;
    if (ayah == null) return;

    if (_endedPrematurely(source)) {
      unawaited(_recoverPrematureEnd(ayah));
      return;
    }

    if (repeatCurrent) {
      if (_consumeRepeatCredit()) {
        unawaited(_playAyahAudio(ayah));
        return;
      }
      repeatCurrent = false;
    }

    if (playingWholeSurah) {
      final nextAyah = ayah + 1;
      final effectiveEnd = _rangeEndAyah ?? _totalAyahsInSurah;
      if (nextAyah <= effectiveEnd) {
        _advanceInProgress = true;
        unawaited(_advanceSequential(nextAyah).whenComplete(() => _advanceInProgress = false));
        return;
      }
      if (repeatSurah) {
        final restartAt = _rangeStartAyah ?? 1;
        _advanceInProgress = true;
        unawaited(_restartFrom(restartAt).whenComplete(() => _advanceInProgress = false));
        return;
      }
    }

    _stallTimer?.cancel();
    playingAyah = null;
    playingWholeSurah = false;
    notifyListeners();
  }

  Future<void> _restartFrom(int ayah) async {
    await _playAyahAudio(ayah);
    unawaited(_preloadNext(ayah + 1));
  }

  /// Changes the reciter without throwing away the current reading position.
  /// If Quran playback is active, the same ayah is restarted with the new
  /// reciter and seeks back to the exact position; whole-surah mode, the played
  /// range and pause state are restored as well.
  Future<void> changeReciter(
    String reciterId, {
    required SurahModel surah,
    required List<SurahModel> allSurahs,
  }) async {
    if (reciterId == appSettings.reciterId) return;

    final wasPlaying = playingAyah != null;
    final savedAyah = playingAyah;
    final savedPosition = position;
    final savedWhole = playingWholeSurah;
    final savedPaused = isPaused;
    final savedRepeatCurrent = repeatCurrent;
    final savedRepeatSurah = repeatSurah;
    final savedRepeatCredits = repeatCreditsRemaining;
    final savedRangeStart = _rangeStartAyah;
    final savedRangeEnd = _rangeEndAyah;

    await stop();
    await appSettings.setReciterId(reciterId);

    if (!wasPlaying || savedAyah == null) return;

    _ensureInit();
    _rangeStartAyah = savedRangeStart;
    _rangeEndAyah = savedRangeEnd;
    _loadSurahContext(surah, allSurahs);
    playingWholeSurah = savedWhole;
    repeatCurrent = savedRepeatCurrent;
    repeatSurah = savedRepeatSurah;
    repeatCreditsRemaining = savedRepeatCredits;
    isPaused = false;
    await _playAyahAudio(savedAyah);

    if (savedPosition > Duration.zero) {
      await _awaitDuration(const Duration(seconds: 3));
      if (duration > Duration.zero) {
        final safePosition = savedPosition <= duration ? savedPosition : duration;
        try {
          await _active.seek(safePosition);
          position = safePosition;
        } catch (e, st) {
          AppLogger.error('Could not restore position after reciter change', error: e, stackTrace: st);
        }
      }
    }
    if (savedWhole) {
      unawaited(_preloadNext(savedAyah + 1));
    }
    if (savedPaused) {
      await _active.pause();
      isPaused = true;
    }
    notifyListeners();
  }

  /// Waits (up to [timeout]) for the current ayah's length to be reported.
  Future<void> _awaitDuration(Duration timeout) async {
    final end = DateTime.now().add(timeout);
    while (duration <= Duration.zero && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> stop() async {
    _stallTimer?.cancel();
    _playToken++;
    _preloadGeneration++;
    try {
      await _active.stop();
    } catch (_) {
      // Already stopped/nothing loaded  fine.
    }
    try {
      await _standby.stop();
    } catch (_) {
      // Nothing preloaded  fine.
    }
    playingAyah = null;
    playingWholeSurah = false;
    isPaused = false;
    isBuffering = false;
    _rangeStartAyah = null;
    _rangeEndAyah = null;
    _progress.setScope();
    _preloadedAyah = null;
    _advanceInProgress = false;
    _loadedAyah.clear();
    _playerDuration.clear();
    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();
  }

  void toggleRepeat() {
    repeatCurrent = !repeatCurrent;
    notifyListeners();
  }

  /// Sets playback speed (e.g. 0.5-2.0) for the current and future ayahs
  /// this session. Applied immediately to the playing ayah and to the
  /// preloaded next one.
  Future<void> setSpeed(double rate) async {
    playbackRate = rate;
    try {
      await _active.setPlaybackRate(rate);
    } catch (_) {
      // Nothing playing yet -- fine, applies on next play.
    }
    try {
      await _standby.setPlaybackRate(rate);
    } catch (_) {}
    notifyListeners();
  }

  void toggleRepeatSurah() {
    repeatSurah = !repeatSurah;
    notifyListeners();
  }

  void setRepeatCount(int? count) {
    repeatCreditsRemaining = count;
    notifyListeners();
  }

  bool _consumeRepeatCredit() {
    if (repeatCreditsRemaining == null) return true;
    if (repeatCreditsRemaining! <= 0) return false;
    repeatCreditsRemaining = repeatCreditsRemaining! - 1;
    return true;
  }
}

/// Single app-wide instance  playback survives navigation between
/// screens because it isn't tied to any one screen's lifecycle.
final QuranAudioService quranAudio = QuranAudioService.instance;
