import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAzkarItem {
  final String id;
  final String text;
  final int targetCount;
  final int currentCount;
  const CustomAzkarItem({required this.id, required this.text, required this.targetCount, required this.currentCount});
  CustomAzkarItem copyWith({int? currentCount}) => CustomAzkarItem(id: id, text: text, targetCount: targetCount, currentCount: currentCount ?? this.currentCount);
  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'targetCount': targetCount, 'currentCount': currentCount};
  factory CustomAzkarItem.fromJson(Map<String, dynamic> json) => CustomAzkarItem(
        id: json['id'] as String, text: json['text'] as String, targetCount: json['targetCount'] as int, currentCount: json['currentCount'] as int? ?? 0);
}

class CustomAzkarService {
  CustomAzkarService._();
  static const _key = 'custom_azkar_items_v1';

  static Future<List<CustomAzkarItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => CustomAzkarItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> add(String text, int targetCount) async {
    final items = await getAll();
    items.add(CustomAzkarItem(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, targetCount: targetCount, currentCount: 0));
    await _saveAll(items);
  }

  static Future<void> increment(String id) async {
    final items = await getAll();
    final updated = items.map((item) {
      if (item.id != id) return item;
      final next = item.currentCount >= item.targetCount ? item.currentCount : item.currentCount + 1;
      return item.copyWith(currentCount: next);
    }).toList();
    await _saveAll(updated);
  }

  static Future<void> resetCount(String id) async {
    final items = await getAll();
    final updated = items.map((item) => item.id == id ? item.copyWith(currentCount: 0) : item).toList();
    await _saveAll(updated);
  }

  static Future<void> delete(String id) async {
    final items = await getAll();
    items.removeWhere((item) => item.id == id);
    await _saveAll(items);
  }

  static Future<void> _saveAll(List<CustomAzkarItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
