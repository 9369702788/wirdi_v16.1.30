import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'quranic_arabic_lessons_data.dart';

class QuranicArabicLessonsScreen extends StatelessWidget {
  const QuranicArabicLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'دروس عربية القرآن' : 'Quranic Arabic Lessons'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quranicArabicLessons.length,
        itemBuilder: (context, lessonIndex) {
          final lesson = quranicArabicLessons[lessonIndex];
          final words = lesson['words'] as List<QuranicWord>;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                isAr ? lesson['titleAr'] as String : lesson['titleEn'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(isAr ? '${words.length} كلمة' : '${words.length} words'),
              children: words
                  .map((w) => ListTile(
                        title: Text(w.arabic, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.transliteration, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                            Text(isAr ? w.meaningAr : w.meaningEn, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr),
                            const SizedBox(height: 4),
                            Text(
                              isAr ? w.noteAr : w.noteEn,
                              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ))
                  .toList(),
            ),
          );
        },
      )),
    );
  }
}
