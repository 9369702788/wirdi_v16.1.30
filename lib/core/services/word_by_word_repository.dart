import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'local_cache_service.dart';

class WbwWord {
  final String arabic;
  final String meaning;
  const WbwWord({required this.arabic, required this.meaning});
}

class WordByWordRepository {
  WordByWordRepository._();

  static final Map<String, List<WbwWord>> _memoryCache = {};

  static Future<List<WbwWord>> wordsFor(int surah, int ayah) async {
    final key = '${surah}_$ayah';
    if (_memoryCache.containsKey(key)) return _memoryCache[key]!;

    final cacheKey = 'cache_wbw_${surah}_$ayah';
    final cached = await LocalCacheService.getString(cacheKey);
    if (cached != null) {
      final words = await compute(_parse, cached);
      _memoryCache[key] = words;
      return words;
    }

    final raw = await _fetchRaw(surah, ayah);
    await LocalCacheService.setString(cacheKey, raw);
    final words = await compute(_parse, raw);
    _memoryCache[key] = words;
    return words;
  }

  static Future<String> _fetchRaw(int surah, int ayah) async {
    final response = await http.get(
      Uri.parse('https://ummahapi.com/api/quran/words/$surah/$ayah'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load word-by-word data (HTTP ${response.statusCode})');
    }
    return utf8.decode(response.bodyBytes);
  }

  static List<WbwWord> _parse(String raw) {
    final decoded = jsonDecode(raw);
    List<dynamic>? list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      for (final key in ['words', 'data', 'result', 'results']) {
        final candidate = decoded[key];
        if (candidate is List) {
          list = candidate;
          break;
        }
      }
    }
    if (list == null) {
      throw Exception(
        'Word-by-word parse error: could not find a words list in the response. '
        'Top-level shape: ${decoded is Map ? decoded.keys.toList() : decoded.runtimeType}',
      );
    }

    final words = <WbwWord>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      final arabic = (entry['arabic'] ?? entry['text'] ?? entry['ar'] ?? entry['word'])?.toString();
      final meaning = (entry['translation'] ?? entry['meaning'] ?? entry['en'] ?? entry['english'])?.toString();
      if (arabic != null && arabic.isNotEmpty) {
        words.add(WbwWord(arabic: arabic, meaning: meaning ?? ''));
      }
    }
    if (words.isEmpty) {
      throw Exception(
        'Word-by-word parse error: parsed 0 words from a non-empty list. '
        'First entry keys: ${list.isNotEmpty && list.first is Map ? (list.first as Map).keys.toList() : 'n/a'}',
      );
    }
    return words;
  }
}
