import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/app_sources.dart';
import 'app_logger.dart';
import 'local_cache_service.dart';

/// Offline-first repository for Tafsir Al-Muyassar. Keyed by
/// "surah_ayah" for O(1) lookup once loaded. Same cache-first /
/// background-refresh strategy as [QuranRepository] / [AzkarRepository].
///
/// This file is ~2.7MB, larger than Quran/Azkar — so unlike those two,
/// parsing happens in a background isolate via [compute] rather than on
/// the UI thread, and the network timeout is longer to tolerate slower
/// mobile connections.
class TafsirRepository {
  TafsirRepository._();

  static const String _cacheKey = 'cache_tafsir_json_v1';
  static Map<String, String>? _memoryCache;

  static Future<Map<String, String>> load({bool forceRefresh = false}) async {
    if (_memoryCache != null && !forceRefresh) return _memoryCache!;

    if (!forceRefresh) {
      final cached = await LocalCacheService.getString(_cacheKey);
      if (cached != null) {
        // ignore: unawaited_futures
        _refreshInBackground();
        _memoryCache = await compute(_parse, cached);
        return _memoryCache!;
      }
    }

    try {
      final raw = await _fetchRaw();
      await LocalCacheService.setString(_cacheKey, raw);
      _memoryCache = await compute(_parse, raw);
      return _memoryCache!;
    } catch (e, st) {
      final cached = await LocalCacheService.getString(_cacheKey);
      if (cached != null) {
        AppLogger.error('Tafsir fetch failed, falling back to cache', error: e, stackTrace: st);
        _memoryCache = await compute(_parse, cached);
        return _memoryCache!;
      }
      AppLogger.error('Tafsir fetch failed with no cache available', error: e, stackTrace: st);
      rethrow;
    }
  }

  static Future<void> _refreshInBackground() async {
    try {
      final raw = await _fetchRaw();
      await LocalCacheService.setString(_cacheKey, raw);
      _memoryCache = await compute(_parse, raw);
    } catch (e, st) {
      AppLogger.error('Tafsir background refresh failed, serving cached copy', error: e, stackTrace: st);
    }
  }

  static Future<String> _fetchRaw() async {
    final response = await http.get(
      Uri.parse(AppSources.tafsirJsonUrl),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('Failed to load Tafsir (HTTP ${response.statusCode})');
    }
    // Explicitly decode as UTF-8 — response.body defaults to
    // Latin-1 when a server doesn't declare charset=utf-8, which
    // mangles Arabic text into unreadable symbols.
    return utf8.decode(response.bodyBytes);
  }

  // Top-level-callable (static) so it can run in a background isolate
  // via compute() — must not touch any instance/static mutable state
  // beyond its own arguments and return value.
  //
  // Al Quran Cloud's GET /v1/quran/{edition} response shape:
  // { "code": 200, "status": "OK",
  //   "data": { "surahs": [
  //     { "number": 1, "ayahs": [
  //         { "number": <global 1-6236>, "text": "...",
  //           "numberInSurah": <1-based within surah>, "juz": .. },
  //         ... ] },
  //     ... ] } }
  // We key by "surah_numberInSurah" (matches tafsirFor's lookup), not
  // the global 1-6236 "number" field.
  //
  // NOTE: this exact top-level "data.surahs[].ayahs[]" shape is the
  // documented Al Quran Cloud pattern for whole-Quran-by-edition
  // fetches, but wasn't independently re-verified against a live
  // response in this session (tool access was limited to the
  // /v1/edition listing endpoint, which WAS verified and returned
  // ar.muyassar correctly). Confirm this parses cleanly on the first
  // real test run; if the shape differs, the error below will name
  // exactly which key was missing rather than failing silently.
  static Map<String, String> _parse(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Tafsir parse error: no "data" object in response. '
          'Raw keys: ${decoded.keys.toList()}');
    }
    final surahs = data['surahs'];
    if (surahs is! List) {
      throw Exception('Tafsir parse error: no "data.surahs" array. '
          'data keys: ${data.keys.toList()}');
    }

    final map = <String, String>{};
    for (final surahEntry in surahs) {
      final surahMap = surahEntry as Map<String, dynamic>;
      final surahNumber = surahMap['number']?.toString();
      final ayahs = surahMap['ayahs'];
      if (surahNumber == null || ayahs is! List) continue;
      for (final ayahEntry in ayahs) {
        final ayahMap = ayahEntry as Map<String, dynamic>;
        final ayahInSurah = ayahMap['numberInSurah']?.toString();
        final text = ayahMap['text']?.toString();
        if (ayahInSurah != null && text != null && text.isNotEmpty) {
          map['${surahNumber}_$ayahInSurah'] = text;
        }
      }
    }

    if (map.isEmpty) {
      throw Exception('Tafsir parse error: parsed 0 entries from a '
          'well-formed response — check field names against a live '
          'sample of https://api.alquran.cloud/v1/quran/ar.muyassar');
    }
    return map;
  }

  static String? tafsirFor(Map<String, String> data, int surah, int ayah) =>
      data['${surah}_$ayah'];
}
