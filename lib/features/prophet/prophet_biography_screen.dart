import 'package:flutter/material.dart';

import '../../core/services/prophet_biography.dart';
import '../../core/theme/app_theme.dart';

class ProphetBiographyScreen extends StatelessWidget {
  const ProphetBiographyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? "سيرة النبي صلى الله عليه وسلم" : "The Prophet's Biography"), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final milestone in ProphetBiography.milestones)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.1),
                          child: Text('${milestone.year}', style: TextStyle(fontSize: 11, color: AppColors.primaryEmerald)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? milestone.titleAr : milestone.titleEn,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (milestone.hijriNote.isNotEmpty)
                                Text(milestone.hijriNote, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isAr ? milestone.bodyAr : milestone.bodyEn,
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
                  ? 'المصادر: السيرة النبوية لابن هشام، والرحيق المختوم للمباركفوري.'
                  : "Sources: Ibn Hisham's As-Seerah an-Nabawiyyah and Al-Mubarakpuri's Ar-Raheeq al-Makhtum (The Sealed Nectar).",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
            ),
          ),
        ],
      )),
    );
  }
}
