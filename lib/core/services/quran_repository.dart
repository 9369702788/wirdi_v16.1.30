import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_sources.dart';
import '../models/quran_models.dart';
import 'app_logger.dart';
import 'local_cache_service.dart';

/// Offline-first repository for the Quran text.
///
/// Strategy: if a cached copy exists, return it immediately (fast, works
/// with no connection) and refresh from network in the background so the
/// next launch has fresh data. If there is no cache yet (first launch), the
/// bundled copy (assets/data/quran.json) is served immediately and the cache
/// is filled from the network in the background. A forced refresh that fails
/// falls back to the cache, then to the bundled copy; the error is rethrown
/// only if every source is unavailable.
class QuranRepository {
  static Future<Map<String, dynamic>?> getSurahSummary(int surahNumber) async {
    final summaries = {
      1: {'name': 'Al-Fatiha', 'verses': 7, 'type': 'Meccan', 'theme': 'Opening chapter'},
      2: {'name': 'Al-Baqarah', 'verses': 286, 'type': 'Medinan', 'theme': 'The Cow'},
      3: {'name': 'Aal-i-Imran', 'verses': 200, 'type': 'Medinan', 'theme': 'Family of Imran'},
    };
    return summaries[surahNumber];
  }
  static Future<Map<String, dynamic>?> getLastReadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('last_read_position');
    return raw != null ? jsonDecode(raw) as Map<String, dynamic> : null;
  }
  
  static Future<void> saveLastReadPosition(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final position = {
      'surah': surah,
      'ayah': ayah,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('last_read_position', jsonEncode(position));
  }
  QuranRepository._();

  static const String _cacheKey = 'cache_quran_json_v1';

  /// Bundled copy of the SAME pinned dataset [AppSources.quranJsonUrl] points
  /// at (quran-json 3.1.2, CC-BY-4.0, Tanzil-based). It makes the very first
  /// launch work with no connection and removes the hard dependency on the CDN.
  static const String _bundledAsset = 'assets/data/quran.json';

  static Future<String?> _loadBundled() async {
    try {
      return await rootBundle.loadString(_bundledAsset);
    } catch (e, st) {
      AppLogger.error('Bundled Quran asset could not be read', error: e, stackTrace: st);
      return null;
    }
  }

  /// Parsed surahs kept in memory. Before v1.55 every caller (15 screens/widgets)
  /// re-read the 1.4 MB JSON and parsed it on the UI thread on each call.
  static List<SurahModel>? _memoryCache;

  static Future<List<SurahModel>> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryCache != null) return _memoryCache!;
    final surahs = await _loadUncached(forceRefresh: forceRefresh);
    _memoryCache = surahs;
    return surahs;
  }

  /// Parses off the UI thread (about 6,000 ayahs).
  static Future<List<SurahModel>> _parseAsync(String raw) => compute(_parse, raw);

  static Future<List<SurahModel>> _loadUncached({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await LocalCacheService.getString(_cacheKey);
      if (cached != null) {
        // Return cached data immediately, refresh silently in background.
        // ignore: unawaited_futures
        _refreshInBackground();
        return _parseAsync(cached);
      }
      // No cache yet (first launch): serve the bundled copy immediately and
      // fill the cache from the network in the background.
      final bundled = await _loadBundled();
      if (bundled != null) {
        // ignore: unawaited_futures
        _refreshInBackground();
        return _parseAsync(bundled);
      }
    }

    try {
      final raw = await _fetchRaw();
      await LocalCacheService.setString(_cacheKey, raw);
      return _parseAsync(raw);
    } catch (e, st) {
      final cached = await LocalCacheService.getString(_cacheKey);
      if (cached != null) {
        AppLogger.error('Quran fetch failed, falling back to cache', error: e, stackTrace: st);
        return _parseAsync(cached);
      }
      final bundled = await _loadBundled();
      if (bundled != null) {
        AppLogger.error('Quran fetch failed, falling back to bundled copy', error: e, stackTrace: st);
        return _parseAsync(bundled);
      }
      AppLogger.error('Quran fetch failed with no cache available', error: e, stackTrace: st);
      rethrow;
    }
  }

  static Future<void> _refreshInBackground() async {
    try {
      final raw = await _fetchRaw();
      await LocalCacheService.setString(_cacheKey, raw);
    } catch (e, st) {
      AppLogger.error('Quran background refresh failed, serving cached copy', error: e, stackTrace: st);
    }
  }

  static Future<String> _fetchRaw() async {
    final response = await http
        .get(Uri.parse(AppSources.quranJsonUrl))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load Quran (HTTP ${response.statusCode})');
    }

    // Explicitly decode as UTF-8 — response.body defaults to
    // Latin-1 when a server doesn't declare charset=utf-8, which
    // mangles Arabic text into unreadable symbols.
    return utf8.decode(response.bodyBytes);
  }

  static Future<DateTime?> cachedAt() => LocalCacheService.getCachedAt(_cacheKey);

  static List<SurahModel> _parse(String raw) {
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw Exception('Unexpected Quran JSON format');
    }

    return decoded.map<SurahModel>((item) {
      final map = item as Map<String, dynamic>;
      final versesRaw = (map['verses'] as List<dynamic>? ?? []);

      final ayahs = versesRaw.map<AyahModel>((verse) {
        final verseMap = verse as Map<String, dynamic>;
        return AyahModel(
          number: _readInt(verseMap, ['id', 'number']),
          text: _readString(verseMap, ['text']),
        );
      }).toList();

      return SurahModel(
        number: _readInt(map, ['id', 'number']),
        name: _readString(map, ['name']),
        englishName: _readString(map, ['transliteration']),
        ayahs: ayahs,
      );
    }).toList();
  }

  static int _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) return value.toString();
    }
    return '';
  }
}
