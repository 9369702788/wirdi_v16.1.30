import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class MuhasabahEntry {
  final String id; final DateTime date; final String good; final String improve;
  const MuhasabahEntry({required this.id, required this.date, required this.good, required this.improve});
  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'good': good, 'improve': improve};
  factory MuhasabahEntry.fromJson(Map<String, dynamic> json) => MuhasabahEntry(id: json['id'] as String, date: DateTime.parse(json['date'] as String), good: json['good'] as String, improve: json['improve'] as String);
}

class MuhasabahJournalScreen extends StatefulWidget {
  const MuhasabahJournalScreen({super.key});
  @override
  State<MuhasabahJournalScreen> createState() => _MuhasabahJournalScreenState();
}

class _MuhasabahJournalScreenState extends State<MuhasabahJournalScreen> {
  static const _prefsKey = 'muhasabah_entries_v1';
  List<MuhasabahEntry> _entries = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    if (!mounted) return;
    setState(() {
      _entries = raw.map((e) => MuhasabahEntry.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList()..sort((a, b) => b.date.compareTo(a.date));
      _loading = false;
    });
  }
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _entries.map((e) => jsonEncode(e.toJson())).toList());
  }
  Future<void> _add() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final goodController = TextEditingController();
    final improveController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAr ? 'محاسبة اليوم' : "Today's reflection"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: goodController, maxLines: 3, decoration: InputDecoration(labelText: isAr ? 'ما الذي أحسنت فيه اليوم؟' : 'What did you do well today?')),
            const SizedBox(height: 12),
            TextField(controller: improveController, maxLines: 3, decoration: InputDecoration(labelText: isAr ? 'ما الذي تريد تحسينه غدًا؟' : 'What do you want to improve tomorrow?')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(isAr ? 'حفظ' : 'Save')),
        ],
      ),
    );
    if (result != true) return;
    if (goodController.text.trim().isEmpty && improveController.text.trim().isEmpty) return;
    setState(() {
      _entries.insert(0, MuhasabahEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), date: DateTime.now(), good: goodController.text.trim(), improve: improveController.text.trim()));
    });
    await _save();
  }
  Future<void> _delete(String id) async { setState(() => _entries.removeWhere((e) => e.id == id)); await _save(); }
  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'محاسبة النفس' : 'Self-Accountability Journal'), centerTitle: true),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(isAr ? 'ابدأ عادة محاسبة النفس يوميًا.' : 'Start a daily habit of self-reflection.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final e = _entries[index];
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _delete(e.id),
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                            const SizedBox(height: 8),
                            if (e.good.isNotEmpty) ...[
                              Row(children: [Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryEmerald), const SizedBox(width: 6), Expanded(child: Text(e.good))]),
                              const SizedBox(height: 6),
                            ],
                            if (e.improve.isNotEmpty)
                              Row(children: [Icon(Icons.trending_up, size: 16, color: AppColors.goldAccent), const SizedBox(width: 6), Expanded(child: Text(e.improve))]),
                          ]),
                        ),
                      ),
                    );
                  },
                )),
    );
  }
}
