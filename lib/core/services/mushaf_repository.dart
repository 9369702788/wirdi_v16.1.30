import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/mushaf_models.dart';
import 'app_logger.dart';

/// Repository for the real 604-page Madani Mushaf ayah-to-page mapping, used to
/// render a genuine page-by-page reading view (as opposed to the continuous
/// per-surah list view).
///
/// v1.54: the dataset (hamzakat/madani-muhsaf-json, MIT licence) is BUNDLED in
/// assets/data/mushaf_pages.json instead of being downloaded from a personal
/// GitHub repository's unpinned `main` branch at runtime. The Quran text shown
/// is therefore exactly what shipped in the reviewed release, and the page view
/// works offline from the first launch.
class MushafRepository {
  MushafRepository._();

  static const String _bundledAsset = 'assets/data/mushaf_pages.json';
  static List<MushafPage>? _memoryCache;

  /// [forceRefresh] is kept for source compatibility with existing callers.
  static Future<List<MushafPage>> load({bool forceRefresh = false}) async {
    if (_memoryCache != null && !forceRefresh) return _memoryCache!;
    try {
      final raw = await rootBundle.loadString(_bundledAsset);
      _memoryCache = await compute(_parse, raw);
      return _memoryCache!;
    } catch (e, st) {
      AppLogger.error('Bundled Mushaf pages could not be read', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// The source file is a 605-length array; index 0 is empty/unused and
  /// indices 1-604 hold each page, keyed by chapter number, e.g.:
  /// `{"2": {"chapterNumber": "2", "text": [{"verseNumber": "1", "text": "..."}]}, "juzNumber": "1"}`
  static List<MushafPage> _parse(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    final pages = <MushafPage>[];

    for (var pageNumber = 1; pageNumber < decoded.length; pageNumber++) {
      final pageData = decoded[pageNumber];
      if (pageData is! Map<String, dynamic>) continue;

      final ayahs = <MushafAyahRef>[];
      int juzNumber = 0;

      for (final entry in pageData.entries) {
        if (entry.key == 'juzNumber') {
          juzNumber = int.tryParse(entry.value.toString()) ?? 0;
          continue;
        }
        final chapterData = entry.value;
        if (chapterData is! Map<String, dynamic>) continue;

        final surahNumber = int.tryParse(entry.key) ?? 0;
        final versesRaw = chapterData['text'] as List<dynamic>? ?? [];

        for (final verse in versesRaw) {
          final verseMap = verse as Map<String, dynamic>;
          final ayahNumber = int.tryParse(verseMap['verseNumber']?.toString() ?? '') ?? 0;
          final text = verseMap['text']?.toString() ?? '';
          if (ayahNumber > 0 && text.isNotEmpty) {
            ayahs.add(MushafAyahRef(surahNumber: surahNumber, ayahNumber: ayahNumber, text: text));
          }
        }
      }

      pages.add(MushafPage(pageNumber: pageNumber, juzNumber: juzNumber, ayahs: ayahs));
    }

    return pages;
  }

  /// The first mushaf page containing the given surah — used to deep-link
  /// from the Surah reader into the Mushaf page view at the right spot.
  static int? firstPageForSurah(List<MushafPage> pages, int surahNumber) {
    for (final page in pages) {
      if (page.ayahs.any((a) => a.surahNumber == surahNumber)) {
        return page.pageNumber;
      }
    }
    return null;
  }
}
