import 'package:flutter/material.dart';

import '../../core/services/islamic_history_service.dart';
import '../../core/theme/app_theme.dart';

class IslamicHistoryScreen extends StatelessWidget {
  const IslamicHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final events = IslamicHistoryService.getTimelineEvents();
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'التاريخ الإسلامي' : 'Islamic History'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final e = events[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.1),
              child: Text('${e.year}', style: TextStyle(fontSize: 10, color: AppColors.primaryEmerald)),
            ),
            title: Text(isAr ? e.eventAr : e.event, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${isAr ? e.descriptionAr : e.description}\n${e.yearAH}', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
            isThreeLine: true,
          );
        },
      )),
    );
  }
}
