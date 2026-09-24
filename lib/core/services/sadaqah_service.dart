import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SadaqahEntry {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String note;
  const SadaqahEntry({required this.id, required this.type, required this.amount, required this.date, required this.note});
  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'amount': amount, 'date': date.toIso8601String(), 'note': note};
  factory SadaqahEntry.fromJson(Map<String, dynamic> json) => SadaqahEntry(
        id: json['id'] as String, type: json['type'] as String, amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String), note: json['note'] as String? ?? '');
}

class SadaqahService {
  SadaqahService._();
  static const _key = 'sadaqah_entries_v1';

  static Future<List<SadaqahEntry>> getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    final entries = list.map((e) => SadaqahEntry.fromJson(e as Map<String, dynamic>)).toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> addEntry(SadaqahEntry entry) async {
    final entries = await getAllEntries();
    entries.add(entry);
    await _saveAll(entries);
  }

  static Future<void> deleteEntry(String id) async {
    final entries = await getAllEntries();
    entries.removeWhere((e) => e.id == id);
    await _saveAll(entries);
  }

  static Future<void> _saveAll(List<SadaqahEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  static double totalAmount(List<SadaqahEntry> entries) => entries.fold(0.0, (sum, e) => sum + e.amount);
}
