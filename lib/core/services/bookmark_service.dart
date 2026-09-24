import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bookmark_models.dart';

class BookmarkService {
  BookmarkService._();

  /// Search across ayah text, surah name and personal notes -- used by the
  /// bookmark search/filter UI. Case-insensitive substring match.
  static Future<List<BookmarkEntry>> searchBookmarks(String query) async {
    final all = await allBookmarks();
    final q = query.toLowerCase();
    if (q.isEmpty) return all;
    return all.where((b) {
      return b.ayahText.toLowerCase().contains(q) ||
             b.surahName.toLowerCase().contains(q) ||
             b.note.toLowerCase().contains(q);
    }).toList();
  }

  /// Filters saved bookmarks down to the given [categories] (see
  /// [BookmarkService.categories] for the fixed set of valid values).
  static Future<List<BookmarkEntry>> filterByCategories(List<String> categories) async {
    final all = await allBookmarks();
    if (categories.isEmpty) return all;
    return all.where((b) => categories.contains(b.category)).toList();
  }

  static const _prefsKey = 'advanced_bookmarks_v1';
  static const List<String> categories = ['ramadan', 'dua', 'family', 'study', 'personal', 'other'];

  static Future<List<BookmarkEntry>> allBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final list = decoded.map((e) => BookmarkEntry.fromJson(e as Map<String, dynamic>)).toList();
    list.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return list;
  }

  static Future<void> addBookmark({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    required String ayahText,
    required String note,
    required String category,
  }) async {
    final bookmarks = await allBookmarks();
    bookmarks.add(BookmarkEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: ayahNumber,
      ayahText: ayahText,
      note: note,
      category: category,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    ));
    await _save(bookmarks);
  }

  static Future<void> deleteBookmark(String id) async {
    final bookmarks = await allBookmarks();
    bookmarks.removeWhere((b) => b.id == id);
    await _save(bookmarks);
  }

  static Future<void> _save(List<BookmarkEntry> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(bookmarks.map((b) => b.toJson()).toList()));
  }
}
