import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/azkar_models.dart';
import 'app_logger.dart';

/// Repository for the full Hisn Al Muslim azkar collection.
///
/// The dataset (Islamic Pro Azkar API, MIT licence) is BUNDLED with the app
/// (assets/data/azkar.json). Religious text is deliberately not fetched from a
/// third-party GitHub repository at runtime: the content shown to users is
/// exactly what shipped in the reviewed release, and it works fully offline.
class AzkarRepository {
  AzkarRepository._();

  static const String _bundledAsset = 'assets/data/azkar.json';

  /// [forceRefresh] is accepted for source compatibility with existing callers
  /// (retry / "refresh data" buttons); the data is local so it just re-reads it.
  static Future<List<AzkarCategoryModel>> load({bool forceRefresh = false}) async {
    try {
      final raw = await rootBundle.loadString(_bundledAsset);
      return _parse(raw);
    } catch (e, st) {
      AppLogger.error('Bundled Azkar dataset could not be read', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Data is bundled, so there is no download timestamp.
  static Future<DateTime?> cachedAt() async => null;

  static List<AzkarCategoryModel> _parse(String raw) {
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw Exception('Unexpected Azkar JSON format');
    }

    return decoded.map<AzkarCategoryModel>((item) {
      final map = item as Map<String, dynamic>;
      final categoryId = _readInt(map, ['id']);
      final arrayRaw = (map['array'] as List<dynamic>? ?? []);

      final items = arrayRaw.map<AzkarItemModel>((entry) {
        final entryMap = entry as Map<String, dynamic>;
        final itemId = _readInt(entryMap, ['id']);

        return AzkarItemModel(
          uid: '${categoryId}_$itemId',
          id: itemId,
          text: _readString(entryMap, ['text']),
          targetCount: _readInt(entryMap, ['count']) == 0
              ? 1
              : _readInt(entryMap, ['count']),
        );
      }).where((item) => item.text.trim().isNotEmpty).toList();

      return AzkarCategoryModel(
        id: categoryId,
        category: _readString(map, ['category']),
        items: items,
      );
    }).where((cat) => cat.items.isNotEmpty).toList();
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
