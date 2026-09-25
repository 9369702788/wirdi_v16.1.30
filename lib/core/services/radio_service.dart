import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';
import '../data/radio_stations.dart';
import 'playback_coordinator.dart';

enum RadioState { stopped, loading, playing, error }
enum RadioSource { embedded, mp3quran, radioBrowser, dataRosy, uthumany, combined, fallback }

class RadioService extends ChangeNotifier {
  RadioService._();
  static final RadioService instance = RadioService._();

  final AudioPlayer _player = AudioPlayer();
  RadioState _state = RadioState.stopped;
  RadioStation? _currentStation;
  String? _errorMessage;
  Timer? _sleepTimer;
  Timer? _sleepCountdown;
  int? _sleepMinutesRemaining;
  Set<String> _favoriteIds = {};
  bool _initialized = false;

  List<RadioStation> _liveStations = kFallbackStations;
  bool _loadingLive = false;
  RadioSource _activeSource = RadioSource.embedded;
  String _sourceLabel = '18 curated Islamic stations';

  static const _favsKey = 'radio_favorites';

  RadioState get state => _state;
  RadioStation? get currentStation => _currentStation;
  String? get errorMessage => _errorMessage;
  bool get isPlaying => _state == RadioState.playing;
  bool get isLoading => _state == RadioState.loading;
  int? get sleepMinutesRemaining => _sleepMinutesRemaining;
  bool get hasSleepTimer => _sleepTimer != null;
  bool get loadingLive => _loadingLive;
  bool get loadingStations => _loadingLive;
  RadioSource get activeSource => _activeSource;
  String get sourceLabel => _sourceLabel;
  bool isFavorite(String id) => _favoriteIds.contains(id);

  List<RadioStation> get stations => _liveStations;
  List<RadioStation> get allStations => _liveStations;
  List<RadioStation> get favoriteStations => _liveStations.where((s) => _favoriteIds.contains(s.id)).toList();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadFavorites();
    _player.onPlayerStateChanged.listen((ps) {
      if (ps == PlayerState.playing) {
        _state = RadioState.playing;
      } else if (ps == PlayerState.stopped || ps == PlayerState.completed || ps == PlayerState.paused) {
        if (_state != RadioState.error) _state = RadioState.stopped;
      }
      notifyListeners();
    });
    _refreshFromApiInBackground();
  }

  void _refreshFromApiInBackground() { Future.microtask(_doRefresh); }
  Future<void> refreshStations() => _doRefresh();

  Future<void> _doRefresh() async {
    _loadingLive = true;
    notifyListeners();
    final combined = <String, RadioStation>{};
    final succeededSources = <String>[];
    Future<void> mergeFrom(Future<List<RadioStation>> Function() fetch, String label) async {
      try {
        final list = await fetch();
        if (list.isEmpty) return;
        succeededSources.add(label);
        for (final s in list) { if (RadioStation.isSecureUrl(s.streamUrl)) combined[s.streamUrl] = s; }
      } catch (e) { debugPrint('[Radio] $label error: $e'); }
    }
    await mergeFrom(_fetchMp3Quran, 'mp3quran.net');
    await mergeFrom(_fetchRadioBrowser, 'Radio-Browser');
    await mergeFrom(() => searchGlobal('Quran'), 'Quran Search');
    await mergeFrom(() => searchGlobal('Islam'), 'Islamic Search');
    if (combined.isNotEmpty) {
      _liveStations = combined.values.toList();
      _liveStations.sort((a, b) => (b.clickCount ?? 0).compareTo(a.clickCount ?? 0));
      _activeSource = RadioSource.combined;
      _sourceLabel = _liveStations.length.toString() + ' stations from ' + succeededSources.join(' + ');
    }
    _loadingLive = false;
    notifyListeners();
  }

  Future<List<RadioStation>> _fetchMp3Quran() async {
    try {
      final resp = await http.get(Uri.parse('https://mp3quran.net/api/v3/radios?language=ar')).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return const [];
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final radios = decoded['radios'] as List<dynamic>? ?? const [];
      return radios.whereType<Map<String, dynamic>>().map(RadioStation.fromMp3Quran).where((s) => s.streamUrl.isNotEmpty).toList();
    } catch (_) { return []; }
  }

  static const _radioBrowserTags = ['quran', 'coran', 'tilawah', 'radio quran', 'islam', 'islamic', 'sunnah', 'hadith', 'nasheed', 'dawah', 'قرآن', 'تلاوة', 'إذاعة'];

  Future<List<RadioStation>> _fetchRadioBrowser() async {
    final merged = <String, RadioStation>{};
    for (final tag in _radioBrowserTags) {
      try {
        final resp = await http.get(Uri.parse('https://de1.api.radio-browser.info/json/stations/bytag/${Uri.encodeComponent(tag)}?limit=500&hidebroken=true'), headers: {'User-Agent': 'WirdiApp/1.52'}).timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) continue;
        final List<dynamic> data = jsonDecode(resp.body);
        for (final j in data.whereType<Map<String, dynamic>>()) {
          final station = RadioStation.fromRadioBrowser(j);
          if (station.streamUrl.isEmpty) continue;
          merged[station.stationUuid ?? station.streamUrl] = station;
        }
      } catch (_) {}
    }
    return merged.values.toList();
  }

  Future<List<RadioStation>> searchGlobal(String query) async {
    if (query.isEmpty) return [];
    try {
      final url = 'https://de1.api.radio-browser.info/json/stations/search?name=${Uri.encodeComponent(query)}&limit=100&hidebroken=true&order=clickcount&reverse=true';
      final resp = await http.get(Uri.parse(url), headers: {'User-Agent': 'WirdiApp/1.52'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(resp.body);
      return data.map((j) => RadioStation.fromRadioBrowser(j as Map<String, dynamic>)).where((s) => RadioStation.isSecureUrl(s.streamUrl)).toList();
    } catch (_) { return []; }
  }

  Future<void> play(RadioStation station) async {
    try {
      if (_currentStation?.id == station.id && isPlaying) return;
      await PlaybackCoordinator.stopQuranForRadio();
      _state = RadioState.loading;
      _currentStation = station;
      _errorMessage = null;
      notifyListeners();
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(UrlSource(station.streamUrl));
    } catch (e) {
      _state = RadioState.error;
      _errorMessage = 'Could not connect to this station.';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try { await _player.stop(); } catch (_) {}
    _state = RadioState.stopped;
    _currentStation = null;
    cancelSleepTimer();
    notifyListeners();
  }

  Future<void> pause() async {
    try { await _player.stop(); } catch (_) {}
    if (_state != RadioState.error) _state = RadioState.stopped;
    notifyListeners();
  }

  Future<void> togglePlay(RadioStation station) async {
    if (_currentStation?.id == station.id && isPlaying) { await pause(); } else { await play(station); }
  }

  Future<void> playNext() async {
    if (_currentStation == null || _liveStations.length < 2) return;
    final idx = _liveStations.indexWhere((s) => s.id == _currentStation!.id);
    if (idx == -1) return;
    await play(_liveStations[(idx + 1) % _liveStations.length]);
  }

  Future<void> playPrevious() async {
    if (_currentStation == null || _liveStations.length < 2) return;
    final idx = _liveStations.indexWhere((s) => s.id == _currentStation!.id);
    if (idx == -1) return;
    await play(_liveStations[(idx - 1 + _liveStations.length) % _liveStations.length]);
  }

  void setSleepTimer(int minutes) {
    cancelSleepTimer();
    _sleepMinutesRemaining = minutes;
    _sleepTimer = Timer(Duration(minutes: minutes), () async { await stop(); _sleepMinutesRemaining = null; notifyListeners(); });
    _sleepCountdown = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_sleepMinutesRemaining != null && _sleepMinutesRemaining! > 0) { _sleepMinutesRemaining = _sleepMinutesRemaining! - 1; notifyListeners(); }
    });
    notifyListeners();
  }

  void cancelSleepTimer() { _sleepTimer?.cancel(); _sleepCountdown?.cancel(); _sleepTimer = null; _sleepCountdown = null; _sleepMinutesRemaining = null; }

  Future<void> toggleFavorite(String stationId) async {
    if (_favoriteIds.contains(stationId)) { _favoriteIds.remove(stationId); } else { _favoriteIds.add(stationId); }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    final p = await SharedPreferences.getInstance();
    _favoriteIds = (p.getStringList(_favsKey) ?? []).toSet();
  }

  Future<void> _saveFavorites() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_favsKey, _favoriteIds.toList());
  }
}
