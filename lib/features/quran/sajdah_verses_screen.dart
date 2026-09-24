import 'package:flutter/material.dart';

import '../../core/models/quran_models.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';
import 'quran_screen.dart';

class _SajdahVerse {
  final int surahNumber; final String surahAr; final String surahEn; final int ayah; final String noteAr; final String noteEn;
  const _SajdahVerse({required this.surahNumber, required this.surahAr, required this.surahEn, required this.ayah, required this.noteAr, required this.noteEn});
}

const List<_SajdahVerse> _sajdahVerses = [
  _SajdahVerse(surahNumber: 7, surahAr: 'الأعراف', surahEn: "Al-A'raf", ayah: 206, noteAr: 'استكبار المتكبرين عن العبادة مقابل خضوع الملائكة', noteEn: "Contrasts the arrogance of those who refuse worship with the angels' submission"),
  _SajdahVerse(surahNumber: 13, surahAr: 'الرعد', surahEn: "Ar-Ra'd", ayah: 15, noteAr: 'سجود كل من في السماوات والأرض لله طوعًا أو كرهًا', noteEn: 'All in the heavens and earth prostrate to Allah, willingly or unwillingly'),
  _SajdahVerse(surahNumber: 16, surahAr: 'النحل', surahEn: 'An-Nahl', ayah: 50, noteAr: 'خشية الملائكة لربهم وامتثالهم لأمره', noteEn: "The angels' awe of their Lord and their obedience to His command"),
  _SajdahVerse(surahNumber: 17, surahAr: 'الإسراء', surahEn: 'Al-Isra', ayah: 109, noteAr: 'بكاء أهل الكتاب المؤمنين عند سماع القرآن', noteEn: 'The weeping of believing People of the Book upon hearing the Quran'),
  _SajdahVerse(surahNumber: 19, surahAr: 'مريم', surahEn: 'Maryam', ayah: 58, noteAr: 'سجود من هداهم الله من الأنبياء والصالحين', noteEn: 'The prostration of those Allah guided among the prophets and righteous'),
  _SajdahVerse(surahNumber: 22, surahAr: 'الحج', surahEn: 'Al-Hajj', ayah: 18, noteAr: 'سجود كل المخلوقات في السماوات والأرض لله', noteEn: 'All creation in the heavens and earth prostrating to Allah'),
  _SajdahVerse(surahNumber: 22, surahAr: 'الحج', surahEn: 'Al-Hajj', ayah: 77, noteAr: 'أمر بالركوع والسجود وعبادة الله وفعل الخير', noteEn: 'A command to bow, prostrate, worship Allah, and do good'),
  _SajdahVerse(surahNumber: 25, surahAr: 'الفرقان', surahEn: 'Al-Furqan', ayah: 60, noteAr: 'إعراض المتكبرين عن السجود لله', noteEn: 'The arrogant turning away from prostrating to Allah'),
  _SajdahVerse(surahNumber: 27, surahAr: 'النمل', surahEn: 'An-Naml', ayah: 26, noteAr: 'سجود ملكة سبأ وقومها للشمس بدل الله', noteEn: "The Queen of Sheba's people prostrating to the sun instead of Allah"),
  _SajdahVerse(surahNumber: 32, surahAr: 'السجدة', surahEn: 'As-Sajdah', ayah: 15, noteAr: 'المؤمنون الذين تتجافى جنوبهم عن المضاجع', noteEn: 'The believers whose sides forsake their beds in devotion'),
  _SajdahVerse(surahNumber: 38, surahAr: 'ص', surahEn: 'Sad', ayah: 24, noteAr: 'سجود داود عليه السلام توبة واستغفارًا', noteEn: "Prophet Dawud's prostration in repentance and seeking forgiveness"),
  _SajdahVerse(surahNumber: 41, surahAr: 'فصلت', surahEn: 'Fussilat', ayah: 38, noteAr: 'سجود من عند الله لا يستكبرون عنه', noteEn: 'Those with Allah who do not turn away from His worship in arrogance'),
  _SajdahVerse(surahNumber: 53, surahAr: 'النجم', surahEn: 'An-Najm', ayah: 62, noteAr: 'أمر بالسجود لله وعبادته', noteEn: 'A command to prostrate to Allah and worship Him'),
  _SajdahVerse(surahNumber: 84, surahAr: 'الانشقاق', surahEn: 'Al-Inshiqaq', ayah: 21, noteAr: 'توبيخ من لا يسجد عند سماع القرآن', noteEn: 'A rebuke of those who do not prostrate upon hearing the Quran'),
  _SajdahVerse(surahNumber: 96, surahAr: 'العلق', surahEn: 'Al-Alaq', ayah: 19, noteAr: 'أمر بالسجود والاقتراب من الله', noteEn: 'A command to prostrate and draw near to Allah'),
];

class SajdahVersesScreen extends StatefulWidget {
  const SajdahVersesScreen({super.key});

  @override
  State<SajdahVersesScreen> createState() => _SajdahVersesScreenState();
}

class _SajdahVersesScreenState extends State<SajdahVersesScreen> {
  List<SurahModel>? _allSurahs;

  @override
  void initState() {
    super.initState();
    QuranRepository.load().then((surahs) {
      if (mounted) setState(() => _allSurahs = surahs);
    });
  }

  Future<void> _openVerse(_SajdahVerse v) async {
    final surahs = _allSurahs;
    if (surahs == null) return;
    SurahModel? surah;
    for (final s in surahs) {
      if (s.number == v.surahNumber) {
        surah = s;
        break;
      }
    }
    if (surah == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(surah: surah!, allSurahs: surahs, scrollToAyah: v.ayah),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'آيات السجدة' : 'Sajdah Verses'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sajdahVerses.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text(
                isAr
                    ? 'القائمة الشائعة المتّبعة في أغلب طبعات المصحف لمواضع آيات السجدة الخمس عشرة.'
                    : 'The commonly followed list of the 15 sajdah-verse locations as marked in most mushaf editions.',
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
            );
          }
          final v = _sajdahVerses[index - 1];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(radius: 16, backgroundColor: AppColors.goldAccent.withValues(alpha: 0.15), child: Text('$index', style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold))),
              title: Text(isAr ? '${v.surahAr} - آية ${v.ayah}' : '${v.surahEn} - Verse ${v.ayah}', textDirection: isAr ? TextDirection.rtl : TextDirection.ltr),
              subtitle: Text(isAr ? v.noteAr : v.noteEn, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openVerse(v),
            ),
          );
        },
      )),
    );
  }
}
