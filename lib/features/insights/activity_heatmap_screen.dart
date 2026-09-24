import 'package:flutter/material.dart';

import '../../core/models/progress_models.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';

class ActivityHeatmapScreen extends StatefulWidget {
  const ActivityHeatmapScreen({super.key});
  @override
  State<ActivityHeatmapScreen> createState() => _ActivityHeatmapScreenState();
}

class _ActivityHeatmapScreenState extends State<ActivityHeatmapScreen> {
  static const int _weeksToShow = 5;
  List<List<DailyActivitySummary>> _weeks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final weeks = <List<DailyActivitySummary>>[];
    for (var w = _weeksToShow - 1; w >= 0; w--) {
      weeks.add(await UserProgressService.weekSummary(weeksAgo: w));
    }
    if (!mounted) return;
    setState(() {
      _weeks = weeks;
      _loading = false;
    });
  }

  double _score(DailyActivitySummary d) {
    if (!d.hasAnyActivity) return 0.0;
    final quran = (d.wirdPages / 5).clamp(0.0, 1.0);
    final azkar = (d.azkarCompleted / 20).clamp(0.0, 1.0);
    final tasbeeh = (d.tasbeehTotal / 100).clamp(0.0, 1.0);
    final prayer = (d.prayersDone / 5).clamp(0.0, 1.0);
    final avg = (quran + azkar + tasbeeh + prayer) / 4;
    return avg.clamp(0.15, 1.0);
  }

  Color _colorFor(double score, bool isFuture) {
    if (isFuture) return AppColors.mutedText.withValues(alpha: 0.06);
    if (score == 0) return AppColors.mutedText.withValues(alpha: 0.08);
    return AppColors.primaryEmerald.withValues(alpha: 0.2 + (score * 0.8));
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  static const List<String> _dayAbbrevAr = ['سبت', 'أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
  static const List<String> _dayAbbrevEn = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const List<String> _monthNamesAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  static const List<String> _monthNamesEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  String _monthYearLabel(DateTime date, bool isAr) {
    final names = isAr ? _monthNamesAr : _monthNamesEn;
    return '${names[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dayAbbrev = isAr ? _dayAbbrevAr : _dayAbbrevEn;

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'خريطة النشاط' : 'Activity Heatmap'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isAr ? 'آخر $_weeksToShow أسابيع' : 'Last $_weeksToShow weeks',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 56),
                      for (final label in dayAbbrev)
                        Expanded(
                          child: Center(
                            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mutedText)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (var w = 0; w < _weeks.length; w++) ...[
                    if (_weeks[w].isNotEmpty && (w == 0 || _weeks[w].first.date.month != _weeks[w - 1].first.date.month))
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          _monthYearLabel(_weeks[w].first.date, isAr),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryEmerald),
                        ),
                      ),
                    Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            _weeks[w].isEmpty ? '' : '${_weeks[w].first.date.day}-${_weeks[w].last.date.day}',
                            style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                          ),
                        ),
                        for (final d in _weeks[w])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Tooltip(
                                message: '${d.date.year}-${d.date.month}-${d.date.day}',
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _colorFor(_score(d), d.date.isAfter(todayOnly)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _LegendSwatch(color: AppColors.mutedText.withValues(alpha: 0.06), label: isAr ? 'مستقبلي' : 'Future'),
                      _LegendSwatch(color: AppColors.mutedText.withValues(alpha: 0.08), label: isAr ? 'بلا نشاط' : 'No activity'),
                      _LegendSwatch(color: AppColors.primaryEmerald.withValues(alpha: 0.4), label: isAr ? 'نشاط متوسط' : 'Some activity'),
                      _LegendSwatch(color: AppColors.primaryEmerald.withValues(alpha: 1.0), label: isAr ? 'نشاط كامل' : 'Full activity'),
                    ],
                  ),
                ],
              ),
            )),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendSwatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
      ],
    );
  }
}
