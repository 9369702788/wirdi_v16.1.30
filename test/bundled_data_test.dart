import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the datasets that ship inside the app (assets/data/). They replaced
/// runtime downloads from third-party hosts, so a corrupted or truncated file
/// must fail CI instead of shipping.
void main() {
  dynamic readJson(String path) => jsonDecode(File(path).readAsStringSync());

  test('quran.json has 114 surahs and 6236 ayahs', () {
    final surahs = readJson('assets/data/quran.json') as List<dynamic>;
    expect(surahs.length, 114);
    var verses = 0;
    for (final s in surahs) {
      final list = (s as Map<String, dynamic>)['verses'] as List<dynamic>;
      expect(list.length, s['total_verses']);
      verses += list.length;
    }
    expect(verses, 6236);
  });

  test('azkar.json has categories with non-empty items', () {
    final cats = readJson('assets/data/azkar.json') as List<dynamic>;
    expect(cats.length, greaterThan(100));
    for (final c in cats) {
      final map = c as Map<String, dynamic>;
      expect((map['category'] as String).trim(), isNotEmpty);
      expect(map['array'] as List<dynamic>, isNotEmpty);
    }
  });

  test('mushaf_pages.json has 604 pages after the unused index 0', () {
    final pages = readJson('assets/data/mushaf_pages.json') as List<dynamic>;
    expect(pages.length, 605);
    for (var i = 1; i < pages.length; i++) {
      expect(pages[i], isA<Map<String, dynamic>>(), reason: 'page $i');
      expect((pages[i] as Map<String, dynamic>).isNotEmpty, isTrue, reason: 'page $i');
    }
  });

  test('licence files for bundled data are present', () {
    for (final f in ['quran-json-LICENSE.txt', 'azkar-LICENSE.txt', 'mushaf-LICENSE.txt']) {
      expect(File('assets/data/$f').existsSync(), isTrue, reason: f);
    }
  });
}
