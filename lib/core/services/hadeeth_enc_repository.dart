import 'dart:convert';

import '../models/hadeeth_enc_models.dart';
import 'app_logger.dart';
import 'hadeeth_enc_api_service.dart';
import 'local_cache_service.dart';

/// Offline-first repository for the HadeethEnc.com hadith library.
class HadeethEncRepository {
  HadeethEncRepository._();

  static String _categoriesKey(String lang) => 'hadeethenc_categories_$lang';
  static String _categoryHadeethsKey(String categoryId, String lang) => 'hadeethenc_cat_${categoryId}_$lang';
  static String _detailKey(String id, String lang) => 'hadeethenc_detail_${id}_$lang';

  static Future<List<HadeethCategoryModel>> getCategories({
    required String languageCode,
    bool forceRefresh = false,
  }) async {
    final key = _categoriesKey(languageCode);
    if (!forceRefresh) {
      final cached = await LocalCacheService.getString(key);
      if (cached != null) {
        try {
          final list = (jsonDecode(cached) as List)
              .map((e) => HadeethCategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          return list;
        } catch (_) {}
      }
    }
    final fetched = await HadeethEncApiService.fetchRootCategories(languageCode: languageCode);
    await LocalCacheService.setString(key, jsonEncode(fetched.map((e) => e.toJson()).toList()));
    return fetched;
  }

  static Future<List<HadeethSummaryModel>> getHadeethsForCategory({
    required String categoryId,
    required String languageCode,
    bool forceRefresh = false,
  }) async {
    final key = _categoryHadeethsKey(categoryId, languageCode);
    if (!forceRefresh) {
      final cached = await LocalCacheService.getString(key);
      if (cached != null) {
        try {
          final list = (jsonDecode(cached) as List)
              .map((e) => HadeethSummaryModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          return list;
        } catch (_) {}
      }
    }

    final all = <HadeethSummaryModel>[];
    for (var page = 1; page <= 20; page++) {
      final batch = await HadeethEncApiService.fetchHadeethsForCategory(
        categoryId: categoryId,
        languageCode: languageCode,
        page: page,
      );
      if (batch.isEmpty) break;
      all.addAll(batch);
      if (batch.length < 100) break;
    }
    await LocalCacheService.setString(key, jsonEncode(all.map((e) => e.toJson()).toList()));
    return all;
  }

  static Future<HadeethDetailModel> getHadeethDetail({
    required String id,
    required String languageCode,
    bool forceRefresh = false,
  }) async {
    final key = _detailKey(id, languageCode);
    if (!forceRefresh) {
      final cached = await LocalCacheService.getString(key);
      if (cached != null) {
        try {
          return HadeethDetailModel.fromJson(Map<String, dynamic>.from(jsonDecode(cached) as Map));
        } catch (_) {}
      }
    }
    final detail = await HadeethEncApiService.fetchHadeethDetail(id: id, languageCode: languageCode);
    await LocalCacheService.setString(key, jsonEncode(detail.toJson()));
    return detail;
  }

  static Future<List<HadeethSummaryModel>> search({
    required String query,
    required String languageCode,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final results = <String, HadeethSummaryModel>{};

    try {
      final apiResults = await HadeethEncApiService.search(query: trimmed, languageCode: languageCode);
      for (final r in apiResults) {
        results[r.id] = r;
      }
    } catch (e, st) {
      AppLogger.error('HadeethEnc: live search failed, falling back to local cache only', error: e, stackTrace: st);
    }

    final localMatches = await _searchLocalCache(trimmed, languageCode);
    for (final r in localMatches) {
      results.putIfAbsent(r.id, () => r);
    }

    return results.values.toList();
  }

  static Future<List<HadeethSummaryModel>> _searchLocalCache(String query, String languageCode) async {
    final categories = await getCategories(languageCode: languageCode);
    final lowerQuery = query.toLowerCase();
    final matches = <HadeethSummaryModel>[];
    for (final category in categories) {
      final cached = await LocalCacheService.getString(_categoryHadeethsKey(category.id, languageCode));
      if (cached == null) continue;
      try {
        final list = (jsonDecode(cached) as List)
            .map((e) => HadeethSummaryModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        matches.addAll(list.where((h) => h.title.toLowerCase().contains(lowerQuery)));
      } catch (_) {
        continue;
      }
    }
    return matches;
  }

  static Future<DateTime?> lastSyncDate({required String languageCode}) {
    return LocalCacheService.getCachedAt(_categoriesKey(languageCode));
  }
}
