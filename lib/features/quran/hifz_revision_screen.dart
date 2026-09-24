import 'package:flutter/material.dart';

import '../../core/services/hifz_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';

class HifzRevisionScreen extends StatefulWidget {
  const HifzRevisionScreen({super.key});
  @override
  State<HifzRevisionScreen> createState() => _HifzRevisionScreenState();
}

class _HifzRevisionScreenState extends State<HifzRevisionScreen> {
  List<Map<String, dynamic>>? _due;
  Map<int, String> _surahNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final due = await HifzService.getPortionsDueForRevision();
    final surahs = await QuranRepository.load();
    if (!mounted) return;
    setState(() {
      _due = due;
      _surahNames = {for (final s in surahs) s.number: s.name};
      _loading = false;
    });
  }

  Future<void> _markRevised(String id) async {
    await HifzService.markPortionRevised(id);
    await _load();
  }

  Future<void> _markForgot(String id) async {
    await HifzService.markPortionForgot(id);
    await _load();
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr;
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'مراجعة الحفظ' : 'Hifz Revision'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_due == null || _due!.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isAr
                          ? 'لا توجد مقاطع محفوظة تحتاج مراجعة حالياً. أكمل خطة حفظ يومية لتظهر هنا لاحقاً للمراجعة.'
                          : 'No portions due for revision yet. Complete a daily memorization plan for it to appear here later for revision.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _due!.length,
                    itemBuilder: (context, index) {
                      final p = _due![index];
                      final surahName = _surahNames[p['surah']] ?? "${p['surah']}";
                      final box = (p['box'] as int?) ?? 1;
                      return Card(
                        child: ListTile(
                          title: Text(surahName, textDirection: TextDirection.rtl),
                          subtitle: Text("${p['start']} - ${p['end']}  \u2022  ${isAr ? 'المستوى' : 'Level'} $box/5"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: isAr ? 'نسيت' : 'Forgot',
                                icon: const Icon(Icons.replay, color: Colors.red),
                                onPressed: () => _markForgot(p['id'] as String),
                              ),
                              FilledButton(
                                onPressed: () => _markRevised(p['id'] as String),
                                child: Text(isAr ? 'تمت المراجعة' : 'Revised'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )),
    );
  }
}
