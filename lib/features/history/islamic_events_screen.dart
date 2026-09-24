import 'package:flutter/material.dart';

import '../../core/services/islamic_events_service.dart';
import '../../core/theme/app_theme.dart';

class IslamicEventsScreen extends StatelessWidget {
  const IslamicEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final events = IslamicEventsService.events;
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'المناسبات الإسلامية' : 'Islamic Events'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final e in events)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_outlined, color: AppColors.primaryEmerald, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr ? e.nameAr : e.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(e.hijriDate, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? e.descriptionAr : e.description,
                      style: const TextStyle(fontSize: 14, height: 1.8),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              isAr
                  ? 'المصادر: القرآن الكريم والسنة النبوية الصحيحة، ومراجع تاريخية إسلامية معتمدة.'
                  : 'Sources: the Quran, authentic Prophetic tradition, and established Islamic historical references.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
            ),
          ),
        ],
      )),
    );
  }
}
