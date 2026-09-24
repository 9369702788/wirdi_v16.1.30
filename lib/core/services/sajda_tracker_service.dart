import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const List<({int surah, int verse, String type})> _sajdaVerses = [
  (surah: 7, verse: 206, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 13, verse: 15, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 16, verse: 50, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 17, verse: 109, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 19, verse: 58, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 22, verse: 18, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 22, verse: 77, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 25, verse: 60, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 27, verse: 26, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 32, verse: 15, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 38, verse: 24, type: '\u0645\u0633\u062a\u062d\u0628\u0629'),
  (surah: 41, verse: 38, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 53, verse: 62, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 84, verse: 21, type: '\u0648\u0627\u062c\u0628\u0629'),
  (surah: 96, verse: 19, type: '\u0648\u0627\u062c\u0628\u0629'),
];

class SajdaTrackerService {
  SajdaTrackerService._();
  static const _key = 'sajda_tilawah_log_v1';

  static bool isSajdaVerse(int surah, int verse) => _sajdaVerses.any((s) => s.surah == surah && s.verse == verse);

  static String? sajdaTypeFor(int surah, int verse) {
    for (final s in _sajdaVerses) {
      if (s.surah == surah && s.verse == verse) return s.type;
    }
    return null;
  }

  static Future<void> logSajda(int surah, int verse) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode({'surah': surah, 'verse': verse, 'at': DateTime.now().toIso8601String()}));
    await prefs.setStringList(_key, raw);
  }

  static Future<int> totalCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).length;
  }
}
