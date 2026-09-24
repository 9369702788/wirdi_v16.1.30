import 'package:flutter/material.dart';

import '../../core/models/progress_models.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// Visual month-style reading calendar built from the same real,
/// date-keyed daily activity log already used for the Home Dashboard's
/// week summary (UserProgressService.weekSummary) -- not a separate or
/// simulated data source. Shows the last 4 calendar weeks (Saturday to
/// Friday, matching the app's existing week-start convention) so the
/// user can see at a glance which days met their daily wird target.
class KhatmaCalendarScreen extends StatefulWidget {
  const KhatmaCalendarScreen({super.key});

  @override
  State<KhatmaCalendarScreen> createState() => _KhatmaCalendarScreenState();
}

class _KhatmaCalendarScreenState extends State<KhatmaCalendarScreen> {
  static const int _weeksToShow = 4;
  List<List<DailyActivitySummary>> _weeks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final weeks = <List<DailyActivitySummary>>[];
    for (var i = _weeksToShow - 1; i >= 0; i--) {
      weeks.add(await UserProgressService.weekSummary(weeksAgo: i));
    }
    if (!mounted) return;
    setState(() {
      _weeks = weeks;
      _loading = false;
    });
  }

  static const List<String> _monthNamesAr = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
  static const List<String> _monthNamesEn = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  String _monthYearLabel(DateTime date, bool isAr) {
    final names = isAr ? _monthNamesAr : _monthNamesEn;
    return '${names[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.khatmaCalendarTitle), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                children: [
                  for (var i = 0; i < _weeks.length; i++) ...[
                    if (_weeks[i].isNotEmpty && (i == 0 || _weeks[i].first.date.month != _weeks[i - 1].first.date.month))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_monthYearLabel(_weeks[i].first.date, isAr), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    _WeekRow(week: _weeks[i], today: todayKey),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _LegendDot(color: AppColors.primaryEmerald, label: l10n.khatmaCalendarLegendMet),
                      _LegendDot(color: Colors.orange, label: l10n.khatmaCalendarLegendMissed),
                      _LegendDot(color: AppColors.mutedText.withValues(alpha: 0.3), label: l10n.khatmaCalendarLegendFuture),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<DailyActivitySummary> week;
  final DateTime today;
  const _WeekRow({required this.week, required this.today});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in week)
          Expanded(child: _DayCell(day: day, isFuture: day.date.isAfter(today))),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DailyActivitySummary day;
  final bool isFuture;
  const _DayCell({required this.day, required this.isFuture});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (isFuture) {
      color = AppColors.mutedText.withValues(alpha: 0.12);
    } else if (day.wirdTargetMet) {
      color = AppColors.primaryEmerald.withValues(alpha: 0.85);
    } else if (day.wirdPages > 0) {
      color = Colors.orange.withValues(alpha: 0.55);
    } else {
      color = Colors.orange.withValues(alpha: 0.85);
    }
    return Padding(
      padding: const EdgeInsets.all(3),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(
            '${day.date.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isFuture ? AppColors.mutedText : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
      ],
    );
  }
}
