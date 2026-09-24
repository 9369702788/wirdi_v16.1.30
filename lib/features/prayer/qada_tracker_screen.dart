import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class QadaTrackerScreen extends StatefulWidget {
  const QadaTrackerScreen({super.key});

  @override
  State<QadaTrackerScreen> createState() => _QadaTrackerScreenState();
}

class _QadaTrackerScreenState extends State<QadaTrackerScreen> {
  static const _prefsKey = 'qada_counts_v1';
  static const _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final decoded = raw != null ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : <String, dynamic>{};
    if (!mounted) return;
    setState(() {
      _counts = {for (final name in _prayerNames) name: (decoded[name] as int?) ?? 0};
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_counts));
  }

  void _adjust(String name, int delta) {
    setState(() {
      final next = (_counts[name] ?? 0) + delta;
      _counts[name] = next < 0 ? 0 : next;
    });
    _save();
  }

  String _arabicName(String name, bool isAr) {
    if (!isAr) return name;
    switch (name) {
      case 'Fajr':
        return 'الفجر';
      case 'Dhuhr':
        return 'الظهر';
      case 'Asr':
        return 'العصر';
      case 'Maghrib':
        return 'المغرب';
      case 'Isha':
        return 'العشاء';
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final total = _counts.values.fold<int>(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'قضاء الصلوات الفائتة' : 'Missed Prayers (Qada)'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('$total', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                        Text(isAr ? 'إجمالي الصلوات المتبقية' : 'Total prayers still owed', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._prayerNames.map((name) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(_arabicName(name, isAr), textDirection: isAr ? TextDirection.rtl : TextDirection.ltr),
                        subtitle: Text('${_counts[name] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _adjust(name, -1)),
                            IconButton(icon: Icon(Icons.add_circle_outline, color: AppColors.primaryEmerald), onPressed: () => _adjust(name, 1)),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'استخدم زر (+) كل ما تتذكر صلاة فائتة، واستخدم (-) كل ما تقضيها.'
                      : 'Use (+) whenever you remember a missed prayer, and (-) each time you make one up.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
              ],
            )),
    );
  }
}
