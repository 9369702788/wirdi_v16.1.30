import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class _Q {
  final String ar; final String en; final List<String> arOptions; final List<String> enOptions; final int correctIndex;
  const _Q({required this.ar, required this.en, required this.arOptions, required this.enOptions, required this.correctIndex});
}

const List<_Q> _bank = [
  _Q(ar: 'في أي سنة هجرية كانت غزوة بدر؟', en: 'In which Hijri year was the Battle of Badr?', arOptions: ['السنة الأولى', 'السنة الثانية', 'السنة الثالثة', 'السنة الخامسة'], enOptions: ['Year 1 AH', 'Year 2 AH', 'Year 3 AH', 'Year 5 AH'], correctIndex: 1),
  _Q(ar: 'متى كانت الهجرة النبوية من مكة إلى المدينة؟', en: 'When did the Hijrah take place?', arOptions: ['622 ميلادية', '610 ميلادية', '632 ميلادية', '570 ميلادية'], enOptions: ['622 CE', '610 CE', '632 CE', '570 CE'], correctIndex: 0),
  _Q(ar: 'ما هي أول غزوة كبرى خاضها المسلمون؟', en: 'What was the first major battle fought by the Muslims?', arOptions: ['غزوة أحد', 'غزوة بدر', 'غزوة الخندق', 'غزوة حنين'], enOptions: ['Battle of Uhud', 'Battle of Badr', 'Battle of the Trench', 'Battle of Hunayn'], correctIndex: 1),
  _Q(ar: 'في أي عام هجري كان فتح مكة؟', en: 'In which Hijri year was the conquest of Makkah?', arOptions: ['السنة الثامنة', 'السنة الأولى', 'السنة العاشرة', 'السنة الخامسة'], enOptions: ['8 AH', '1 AH', '10 AH', '5 AH'], correctIndex: 0),
  _Q(ar: 'من هو أول الخلفاء الراشدين؟', en: 'Who was the first of the Rightly Guided Caliphs?', arOptions: ['عمر بن الخطاب', 'أبو بكر الصديق رضي الله عنه', 'عثمان بن عفان', 'علي بن أبي طالب'], enOptions: ['Umar ibn al-Khattab', 'Abu Bakr al-Siddiq', 'Uthman ibn Affan', 'Ali ibn Abi Talib'], correctIndex: 1),
  _Q(ar: 'كم استمرت مرحلة الدعوة السرية في مكة تقريبًا؟', en: 'About how long was the secret phase of the call to Islam in Makkah?', arOptions: ['ثلاث سنوات', 'سنة واحدة', 'عشر سنوات', 'ستة أشهر'], enOptions: ['About three years', 'One year', 'Ten years', 'Six months'], correctIndex: 0),
  _Q(ar: 'في أي سنة هجرية وقعت غزوة أحد؟', en: 'In which Hijri year was the Battle of Uhud?', arOptions: ['السنة الثالثة', 'السنة الثانية', 'السنة الخامسة', 'السنة الثامنة'], enOptions: ['Year 3 AH', 'Year 2 AH', 'Year 5 AH', 'Year 8 AH'], correctIndex: 0),
  _Q(ar: 'في أي سنة هجرية وقعت غزوة الخندق (الأحزاب)؟', en: 'In which Hijri year was the Battle of the Trench?', arOptions: ['السنة الخامسة', 'السنة الثانية', 'السنة السابعة', 'السنة العاشرة'], enOptions: ['Year 5 AH', 'Year 2 AH', 'Year 7 AH', 'Year 10 AH'], correctIndex: 0),
  _Q(ar: 'في أي سنة هجرية وقع صلح الحديبية؟', en: 'In which Hijri year was the Treaty of Hudaybiyyah?', arOptions: ['السنة السادسة', 'السنة الثالثة', 'السنة الثامنة', 'السنة الأولى'], enOptions: ['Year 6 AH', 'Year 3 AH', 'Year 8 AH', 'Year 1 AH'], correctIndex: 0),
  _Q(ar: 'في أي سنة هجرية وقعت غزوة خيبر؟', en: 'In which Hijri year was the Battle of Khaybar?', arOptions: ['السنة السابعة', 'السنة الرابعة', 'السنة التاسعة', 'السنة الثانية'], enOptions: ['Year 7 AH', 'Year 4 AH', 'Year 9 AH', 'Year 2 AH'], correctIndex: 0),
  _Q(ar: 'في أي سنة هجرية وقعت غزوة حنين؟', en: 'In which Hijri year was the Battle of Hunayn?', arOptions: ['السنة الثامنة', 'السنة الخامسة', 'السنة الحادية عشرة', 'السنة الثالثة'], enOptions: ['Year 8 AH', 'Year 5 AH', 'Year 11 AH', 'Year 3 AH'], correctIndex: 0),
  _Q(ar: 'متى كانت وفاة النبي صلى الله عليه وسلم؟', en: 'When did the Prophet pass away?', arOptions: ['السنة الحادية عشرة للهجرة', 'السنة العاشرة للهجرة', 'السنة الثامنة للهجرة', 'السنة الثالثة عشرة للهجرة'], enOptions: ['Year 11 AH', 'Year 10 AH', 'Year 8 AH', 'Year 13 AH'], correctIndex: 0),
  _Q(ar: 'ما هي أول هجرة في الإسلام؟', en: 'What was the first migration in Islamic history?', arOptions: ['الهجرة إلى الحبشة', 'الهجرة إلى المدينة', 'الهجرة إلى الطائف', 'الهجرة إلى اليمن'], enOptions: ['The migration to Abyssinia', 'The migration to Madinah', 'The migration to Ta\'if', 'The migration to Yemen'], correctIndex: 0),
  _Q(ar: 'إلى أين تحوّلت القبلة بعد أن كانت إلى بيت المقدس؟', en: 'Where was the Qibla changed to, after previously facing Jerusalem?', arOptions: ['المسجد الحرام بمكة', 'المسجد النبوي بالمدينة', 'مسجد قباء', 'لا تحديد'], enOptions: ['The Sacred Mosque in Makkah', 'The Prophet\'s Mosque in Madinah', 'Quba Mosque', 'No specific location'], correctIndex: 0),
  _Q(ar: 'في أي سنة هجرية وقعت معركة اليرموك ضد الروم؟', en: 'In which Hijri year was the Battle of Yarmouk against the Byzantines?', arOptions: ['السنة الخامسة عشرة', 'السنة الحادية عشرة', 'السنة العشرون', 'السنة الثلاثون'], enOptions: ['Year 15 AH', 'Year 11 AH', 'Year 20 AH', 'Year 30 AH'], correctIndex: 0),
  _Q(ar: 'في أي سنة هجرية وقعت معركة القادسية ضد الفرس؟', en: 'In which Hijri year was the Battle of Al-Qadisiyyah against the Persians?', arOptions: ['السنة الخامسة عشرة تقريبًا', 'السنة الثانية', 'السنة الأربعون', 'السنة الستون'], enOptions: ['Approximately year 15 AH', 'Year 2 AH', 'Year 40 AH', 'Year 60 AH'], correctIndex: 0),
  _Q(ar: 'من هو الخليفة الذي تم في عهده توحيد المصاحف على قراءة واحدة؟', en: 'During which caliph\'s era were Quranic copies standardized?', arOptions: ['عثمان بن عفان', 'أبو بكر الصديق', 'عمر بن الخطاب', 'علي بن أبي طالب'], enOptions: ['Uthman ibn Affan', 'Abu Bakr al-Siddiq', 'Umar ibn al-Khattab', 'Ali ibn Abi Talib'], correctIndex: 0),
  _Q(ar: 'من هو الخليفة الذي فُتحت في عهده بلاد فارس والشام بشكل كبير؟', en: 'During which caliph\'s era were Persia and the Levant extensively conquered?', arOptions: ['عمر بن الخطاب', 'أبو بكر الصديق', 'عثمان بن عفان', 'علي بن أبي طالب'], enOptions: ['Umar ibn al-Khattab', 'Abu Bakr al-Siddiq', 'Uthman ibn Affan', 'Ali ibn Abi Talib'], correctIndex: 0),
  _Q(ar: 'ما اسم أول معركة داخلية كبرى بين المسلمين بعد الفتنة؟', en: 'What is the name of the first major internal conflict among Muslims after the strife?', arOptions: ['موقعة الجمل', 'غزوة بدر', 'غزوة أحد', 'معركة اليرموك'], enOptions: ['The Battle of the Camel', 'Battle of Badr', 'Battle of Uhud', 'Battle of Yarmouk'], correctIndex: 0),
  _Q(ar: 'من هو مؤسس الدولة الأموية؟', en: 'Who founded the Umayyad state?', arOptions: ['معاوية بن أبي سفيان', 'عبد الملك بن مروان', 'يزيد بن معاوية', 'الوليد بن عبد الملك'], enOptions: ['Muawiyah ibn Abi Sufyan', 'Abdul-Malik ibn Marwan', 'Yazid ibn Muawiyah', 'Al-Walid ibn Abdul-Malik'], correctIndex: 0),
];

class IslamicHistoryQuizScreen extends StatefulWidget {
  const IslamicHistoryQuizScreen({super.key});
  @override
  State<IslamicHistoryQuizScreen> createState() => _IslamicHistoryQuizScreenState();
}

class _IslamicHistoryQuizScreenState extends State<IslamicHistoryQuizScreen> {
  final _random = Random();
  int _score = 0;
  int _attempts = 0;
  late _Q _current;
  int? _selected;

  @override
  void initState() { super.initState(); _current = _bank[_random.nextInt(_bank.length)]; }

  void _choose(int index) { setState(() { _selected = index; _attempts += 1; if (index == _current.correctIndex) _score += 1; }); }

  void _next() {
    setState(() {
      if (_bank.length > 1) {
        _Q next;
        do { next = _bank[_random.nextInt(_bank.length)]; } while (identical(next, _current));
        _current = next;
      } else {
        _current = _bank[_random.nextInt(_bank.length)];
      }
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final options = isAr ? _current.arOptions : _current.enOptions;
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'اختبار التاريخ الإسلامي' : 'Islamic History Quiz'), centerTitle: true, actions: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Center(child: Text("$_score / $_attempts", style: const TextStyle(fontWeight: FontWeight.bold)))),
      ]),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.goldAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3))),
            child: Text(isAr ? _current.ar : _current.en, textAlign: TextAlign.center, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          ...List.generate(options.length, (i) {
            final isCorrect = i == _current.correctIndex;
            final isPicked = i == _selected;
            Color? bg;
            if (_selected != null) {
              if (isCorrect) {
                bg = AppColors.primaryEmerald.withValues(alpha: 0.15);
              } else if (isPicked) {
                bg = Colors.red.withValues(alpha: 0.1);
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(backgroundColor: bg),
                onPressed: _selected == null ? () => _choose(i) : null,
                child: Text(options[i], textDirection: isAr ? TextDirection.rtl : TextDirection.ltr),
              ),
            );
          }),
          if (_selected != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: _next, child: Text(isAr ? 'التالي' : 'Next')),
          ],
        ]),
      )),
    );
  }
}
