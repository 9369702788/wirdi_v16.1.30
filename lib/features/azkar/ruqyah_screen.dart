import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class _RuqyahItem {
  final String titleAr; final String titleEn; final String arabic; final String sourceAr; final String sourceEn;
  const _RuqyahItem({required this.titleAr, required this.titleEn, required this.arabic, required this.sourceAr, required this.sourceEn});
}

final List<_RuqyahItem> _ruqyahItems = [
  _RuqyahItem(titleAr: 'آية الكرسي', titleEn: 'Ayat al-Kursi', arabic: 'اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ', sourceAr: 'القرآن الكريم، سورة البقرة: 255', sourceEn: 'The Quran, Surah Al-Baqarah: 255'),
  _RuqyahItem(titleAr: 'آخر آيتين من سورة البقرة', titleEn: 'Last two verses of Al-Baqarah', arabic: 'آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ', sourceAr: 'القرآن الكريم، سورة البقرة: 285-286', sourceEn: 'The Quran, Surah Al-Baqarah: 285-286'),
  _RuqyahItem(titleAr: 'سورة الفلق', titleEn: 'Surah Al-Falaq', arabic: 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ مِن شَرِّ مَا خَلَقَ', sourceAr: 'القرآن الكريم، سورة الفلق', sourceEn: 'The Quran, Surah Al-Falaq'),
  _RuqyahItem(titleAr: 'سورة الناس', titleEn: 'Surah An-Nas', arabic: 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ مَلِكِ النَّاسِ إِلَـٰهِ النَّاسِ', sourceAr: 'القرآن الكريم، سورة الناس', sourceEn: 'The Quran, Surah An-Nas'),
  _RuqyahItem(titleAr: 'سورة الإخلاص', titleEn: 'Surah Al-Ikhlas', arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ اللَّهُ الصَّمَدُ', sourceAr: 'القرآن الكريم، سورة الإخلاص', sourceEn: 'The Quran, Surah Al-Ikhlas'),
  _RuqyahItem(titleAr: 'دعاء الشفاء بالمسح باليد', titleEn: 'Dua for healing while wiping with the hand', arabic: 'أَذْهِبِ الْبَأْسَ رَبَّ النَّاسِ، اشْفِ أَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ', sourceAr: 'رواه البخاري ومسلم', sourceEn: 'Narrated by Bukhari and Muslim'),
  _RuqyahItem(titleAr: 'رقية جبريل للنبي صلى الله عليه وسلم', titleEn: "Jibril's ruqyah for the Prophet", arabic: 'بِسْمِ اللَّهِ أَرْقِيكَ مِنْ كُلِّ شَيْءٍ يُؤْذِيكَ، اللَّهُ يَشْفِيكَ', sourceAr: 'رواه مسلم', sourceEn: 'Narrated by Muslim'),
];

class RuqyahScreen extends StatelessWidget {
  const RuqyahScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'الرقية الشرعية' : 'Ruqyah (Spiritual Healing)'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ruqyahItems.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text(
                isAr
                    ? 'مجموعة من الآيات والأدعية الثابتة في الرقية الشرعية من القرآن والسنة.'
                    : 'A collection of verses and supplications authentically established for spiritual healing (Ruqyah).',
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
            );
          }
          final item = _ruqyahItems[index - 1];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isAr ? item.titleAr : item.titleEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Text(item.arabic, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, height: 1.8)),
                const SizedBox(height: 8),
                Text(isAr ? item.sourceAr : item.sourceEn, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              ]),
            ),
          );
        },
      )),
    );
  }
}
