import 'package:flutter/material.dart';

import '../../core/services/hijri_date.dart';
import '../../core/theme/app_theme.dart';

class SunnahFastingCalendarScreen extends StatelessWidget {
  const SunnahFastingCalendarScreen({super.key});

  List<Map<String, dynamic>> _upcomingDays(bool isAr) {
    final today = DateTime.now();
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < 30; i++) {
      final date = DateTime(today.year, today.month, today.day).add(Duration(days: i));
      final hijri = HijriDate.fromGregorian(date);
      final isMonday = date.weekday == DateTime.monday;
      final isThursday = date.weekday == DateTime.thursday;
      final isWhiteDay = hijri.day == 13 || hijri.day == 14 || hijri.day == 15;
      final isAshura = hijri.month == 1 && hijri.day == 10;
      final isTasua = hijri.month == 1 && hijri.day == 9;
      final isArafah = hijri.month == 12 && hijri.day == 9;
      if (isMonday || isThursday || isWhiteDay || isAshura || isTasua || isArafah) {
        final reasons = <String>[];
        if (isArafah) reasons.add(isAr ? 'يوم عرفة' : 'Day of Arafah');
        if (isAshura) reasons.add(isAr ? 'يوم عاشوراء' : 'Day of Ashura');
        if (isTasua) reasons.add(isAr ? 'يوم تاسوعاء' : "Day of Tasu'a");
        if (isMonday) reasons.add(isAr ? 'الإثنين' : 'Monday');
        if (isThursday) reasons.add(isAr ? 'الخميس' : 'Thursday');
        if (isWhiteDay) reasons.add(isAr ? 'الأيام البيض' : 'White Days');
        results.add({'date': date, 'hijri': hijri, 'reasons': reasons});
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final days = _upcomingDays(isAr);
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'تقويم الصيام المستحب' : 'Sunnah Fasting Calendar'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: days.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text(
                isAr
                    ? 'أيام الصيام المستحبة خلال الـ30 يومًا القادمة: كل إثنين وخميس، أيام 13-14-15 من كل شهر هجري (الأيام البيض)، ويوم عرفة (9 ذو الحجة)، ويوما تاسوعاء وعاشوراء (9-10 محرم).'
                    : "Recommended voluntary fasting days over the next 30 days: every Monday and Thursday, the 13th-15th of each Hijri month (White Days), the Day of Arafah (9 Dhul-Hijjah), and Tasu'a and Ashura (9-10 Muharram).",
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
            );
          }
          final entry = days[index - 1];
          final date = entry['date'] as DateTime;
          final hijri = entry['hijri'] as HijriDate;
          final reasons = entry['reasons'] as List<String>;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(Icons.nightlight_round, color: AppColors.primaryEmerald),
              title: Text('${date.day}/${date.month}/${date.year}'),
              subtitle: Text(
                '${hijri.toStringLocalized(Localizations.localeOf(context).languageCode)} \u2022 ${reasons.join('، ')}',
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          );
        },
      )),
    );
  }
}
