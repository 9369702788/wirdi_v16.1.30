import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/app_sources.dart';
import '../models/hadeeth_enc_models.dart';
import 'app_logger.dart';

/// Raw HTTP client for the HadeethEnc.com public API (no API key
/// required). Field names are parsed defensively (see
/// HadeethDetailModel.fromJson) since this couldn't be tested against a
/// live response from this environment.
class HadeethEncApiService {
  HadeethEncApiService._();

  static Uri _uri(String path, Map<String, String> params) =>
      Uri.parse('${AppSources.hadeethEncApiBase}$path').replace(queryParameters: params);

  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('HadeethEnc request failed (HTTP ${response.statusCode}) for $uri');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    if (decoded is List) return {'data': decoded};
    throw Exception('Unexpected HadeethEnc response shape for $uri');
  }

  static Future<List<HadeethCategoryModel>> fetchRootCategories({required String languageCode}) async {
    final json = await _getJson(_uri('/categories/roots/', {'language': languageCode}));
    final list = (json['data'] ?? json['categories'] ?? []) as List;
    return list
        .whereType<Map>()
        .map((e) => HadeethCategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<HadeethSummaryModel>> fetchHadeethsForCategory({
    required String categoryId,
    required String languageCode,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final json = await _getJson(_uri('/hadeeths/list/', {
        'language': languageCode,
        'category_id': categoryId,
        'page': page.toString(),
        'per_page': perPage.toString(),
      }));
      final list = (json['data'] ?? []) as List;
      return list
          .whereType<Map>()
          .map((e) => HadeethSummaryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e, st) {
      AppLogger.error('HadeethEnc: failed to fetch category $categoryId page $page', error: e, stackTrace: st);
      rethrow;
    }
  }

  static Future<HadeethDetailModel> fetchHadeethDetail({
    required String id,
    required String languageCode,
  }) async {
    final json = await _getJson(_uri('/hadeeths/one/', {'language': languageCode, 'id': id}));
    dynamic raw = json['data'] ?? json;
    if (raw is List) {
      if (raw.isEmpty) throw Exception('HadeethEnc: hadith $id not found');
      raw = raw.first;
    }
    if (raw is! Map) throw Exception('HadeethEnc: unexpected detail shape for hadith $id');
    return HadeethDetailModel.fromJson(Map<String, dynamic>.from(raw));
  }

  static Future<List<HadeethSummaryModel>> search({
    required String query,
    required String languageCode,
  }) async {
    final json = await _getJson(_uri('/hadeeths/search/', {'language': languageCode, 'word': query}));
    final list = (json['data'] ?? []) as List;
    return list
        .whereType<Map>()
        .map((e) => HadeethSummaryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
