import 'package:flutter/material.dart';

import '../../core/models/quran_models.dart';
import '../../core/services/hifz_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';
import 'hifz_screen.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  List<SurahModel> _surahs = [];
  SurahModel? _selected;
  int _days = 7;
  int _repsPerAyah = 5;
  bool _loading = true;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final surahs = await QuranRepository.load();
    if (!mounted) return;
    setState(() {
      _surahs = surahs;
      _selected = surahs.isNotEmpty ? surahs[0] : null;
      _loading = false;
    });
  }

  Future<void> _generatePlan(bool isAr) async {
    final surah = _selected;
    if (surah == null || _days <= 0) return;
    final totalAyahs = surah.ayahs.length;
    final perDay = (totalAyahs / _days).ceil().clamp(1, totalAyahs);
    final endAyah = perDay > totalAyahs ? totalAyahs : perDay;
    await HifzService.addPlan(HifzPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      surahNumber: surah.number,
      startAyah: 1,
      endAyah: endAyah,
      targetReps: _repsPerAyah,
    ));
    if (!mounted) return;
    setState(() {
      _resultMessage = isAr
          ? 'تمت إضافة خطة جديدة: ${surah.name}، ستحفظ تقريبًا $perDay آية يوميًا لمدة $_days يوم (بمعدل $_repsPerAyah تكرارات لكل آية). يمكنك إضافة أكثر من خطة في نفس الوقت. اضغط الزر تحت لفتح وضع الحفظ والبدء فعليًا -- المراجعة لاحقًا (بعد يوم واحد على الأقل) هتظهر تلقائيًا هناك.'
          : "New plan added: ${surah.englishName}, roughly $perDay verse(s) per day over $_days day(s), $_repsPerAyah repeats per verse. You can add more than one plan at the same time. Tap the button below to open Hifz Mode and actually start -- revision (from at least a day later) will appear there automatically.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'خطة الحفظ' : 'Study Plan'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(isAr ? 'اختر السورة' : 'Choose a surah', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selected?.number,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: _surahs
                      .map((s) => DropdownMenuItem(value: s.number, child: Text('${s.number}. ${s.name} (${s.ayahs.length})', textDirection: TextDirection.rtl)))
                      .toList(),
                  onChanged: (value) => setState(() => _selected = _surahs.firstWhere((s) => s.number == value)),
                ),
                const SizedBox(height: 20),
                Text(isAr ? 'عدد الأيام: $_days' : 'Number of days: $_days', style: const TextStyle(fontWeight: FontWeight.w600)),
                Slider(
                  value: _days.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  label: '$_days',
                  onChanged: (v) => setState(() => _days = v.round()),
                ),
                const SizedBox(height: 12),
                Text(isAr ? 'عدد التكرارات لكل آية: $_repsPerAyah' : 'Repeats per verse: $_repsPerAyah', style: const TextStyle(fontWeight: FontWeight.w600)),
                Slider(
                  value: _repsPerAyah.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  label: '$_repsPerAyah',
                  onChanged: (v) => setState(() => _repsPerAyah = v.round()),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _generatePlan(isAr),
                  icon: const Icon(Icons.event_available),
                  label: Text(isAr ? 'إنشاء الخطة' : 'Generate Plan'),
                ),
                if (_resultMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_resultMessage!, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr, style: const TextStyle(fontSize: 13, height: 1.6)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HifzScreen())),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(isAr ? 'فتح وضع الحفظ الآن' : 'Open Hifz Mode now'),
                  ),
                ],
              ],
            )),
    );
  }
}
