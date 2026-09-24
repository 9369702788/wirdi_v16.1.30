import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class RecitationMistake {
  final String id;
  final String surahAndAyah;
  final String note;
  final DateTime date;

  const RecitationMistake({required this.id, required this.surahAndAyah, required this.note, required this.date});

  Map<String, dynamic> toJson() => {'id': id, 'surahAndAyah': surahAndAyah, 'note': note, 'date': date.toIso8601String()};
  factory RecitationMistake.fromJson(Map<String, dynamic> json) => RecitationMistake(
        id: json['id'] as String,
        surahAndAyah: json['surahAndAyah'] as String,
        note: json['note'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

class RecitationMistakeLogScreen extends StatefulWidget {
  const RecitationMistakeLogScreen({super.key});

  @override
  State<RecitationMistakeLogScreen> createState() => _RecitationMistakeLogScreenState();
}

class _RecitationMistakeLogScreenState extends State<RecitationMistakeLogScreen> {
  static const _prefsKey = 'recitation_mistakes_v1';
  List<RecitationMistake> _mistakes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    if (!mounted) return;
    setState(() {
      _mistakes = raw.map((e) => RecitationMistake.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _mistakes.map((m) => jsonEncode(m.toJson())).toList());
  }

  Future<void> _add() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final refController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAr ? 'إضافة خطأ تلاوة' : 'Add a recitation mistake'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: refController,
                decoration: InputDecoration(labelText: isAr ? 'السورة والآية (مثال: البقرة 255)' : 'Surah and verse (e.g. Al-Baqarah 255)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(labelText: isAr ? 'ملاحظة (ما نوع الخطأ؟)' : 'Note (what kind of mistake?)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(isAr ? 'حفظ' : 'Save')),
        ],
      ),
    );
    if (result != true || refController.text.trim().isEmpty) return;
    setState(() {
      _mistakes.insert(
        0,
        RecitationMistake(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          surahAndAyah: refController.text.trim(),
          note: noteController.text.trim(),
          date: DateTime.now(),
        ),
      );
    });
    await _save();
  }

  Future<void> _delete(String id) async {
    setState(() => _mistakes.removeWhere((m) => m.id == id));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'سجل أخطاء التلاوة' : 'Recitation Mistake Log'), centerTitle: true),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mistakes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isAr
                          ? 'لا توجد أخطاء مسجّلة. اضغط + كل ما تلاحظ خطأ متكررًا في التلاوة لتتذكّر تصحيحه.'
                          : 'No mistakes logged yet. Tap + whenever you notice a recurring recitation mistake, so you remember to work on it.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _mistakes.length,
                  itemBuilder: (context, index) {
                    final m = _mistakes[index];
                    return Dismissible(
                      key: ValueKey(m.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _delete(m.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(Icons.priority_high, color: AppColors.goldAccent),
                          title: Text(m.surahAndAyah, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr),
                          subtitle: m.note.isEmpty ? null : Text(m.note),
                        ),
                      ),
                    );
                  },
                )),
    );
  }
}
