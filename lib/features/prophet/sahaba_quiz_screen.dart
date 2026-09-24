import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class _Q {
  final String ar; final String en; final List<String> arOptions; final List<String> enOptions; final int correctIndex;
  const _Q({required this.ar, required this.en, required this.arOptions, required this.enOptions, required this.correctIndex});
}

const List<_Q> _bank = [
  _Q(ar: 'من هو الصحابي الملقب بالصديق؟', en: 'Which companion is known as "Al-Siddiq" (The Truthful)?', arOptions: ['أبو بكر رضي الله عنه', 'عمر بن الخطاب', 'عثمان بن عفان', 'علي بن أبي طالب'], enOptions: ['Abu Bakr', 'Umar ibn al-Khattab', 'Uthman ibn Affan', 'Ali ibn Abi Talib'], correctIndex: 0),
  _Q(ar: 'من هو الصحابي الملقب بالفاروق؟', en: 'Which companion is known as "Al-Farooq"?', arOptions: ['أبو بكر رضي الله عنه', 'عمر بن الخطاب رضي الله عنه', 'خالد بن الوليد', 'أبو عبيدة بن الجراح'], enOptions: ['Abu Bakr', 'Umar ibn al-Khattab', 'Khalid ibn al-Walid', 'Abu Ubaidah ibn al-Jarrah'], correctIndex: 1),
  _Q(ar: 'من هو الصحابي الملقب بسيف الله المسلول؟', en: 'Which companion is called "The Drawn Sword of Allah"?', arOptions: ['سعد بن أبي وقاص', 'خالد بن الوليد رضي الله عنه', 'الزبير بن العوام', 'طلحة بن عبيد الله'], enOptions: ['Saad ibn Abi Waqqas', 'Khalid ibn al-Walid', 'Al-Zubayr ibn al-Awwam', 'Talha ibn Ubaydillah'], correctIndex: 1),
  _Q(ar: 'من هي أول امرأة أسلمت؟', en: 'Who was the first woman to accept Islam?', arOptions: ['عائشة رضي الله عنها', 'فاطمة بنت محمد', 'خديجة بنت خويلد رضي الله عنها', 'أم سلمة'], enOptions: ['Aisha', 'Fatimah bint Muhammad', 'Khadijah bint Khuwaylid', 'Umm Salamah'], correctIndex: 2),
  _Q(ar: 'من هو مؤذن النبي صلى الله عليه وسلم؟', en: "Who was the Prophet's muezzin?", arOptions: ['بلال بن رباح رضي الله عنه', 'عبد الله بن مسعود', 'أبو هريرة', 'معاذ بن جبل'], enOptions: ['Bilal ibn Rabah', 'Abdullah ibn Masud', 'Abu Hurayrah', "Mu'adh ibn Jabal"], correctIndex: 0),
  _Q(ar: 'في عهد أي خليفة جُمع القرآن أول مرة في مصحف واحد؟', en: "During which caliph's era was the Quran first compiled into one copy?", arOptions: ['أبو بكر الصديق رضي الله عنه', 'عمر بن الخطاب', 'عثمان بن عفان', 'علي بن أبي طالب'], enOptions: ['Abu Bakr al-Siddiq', 'Umar ibn al-Khattab', 'Uthman ibn Affan', 'Ali ibn Abi Talib'], correctIndex: 0),
  _Q(ar: 'من هو الصحابي الملقب بـ"أمين الأمة"؟', en: 'Which companion is known as "The Trustee of this Nation"?', arOptions: ['أبو عبيدة بن الجراح', 'سعد بن أبي وقاص', 'الزبير بن العوام', 'طلحة بن عبيد الله'], enOptions: ['Abu Ubaidah ibn al-Jarrah', 'Saad ibn Abi Waqqas', 'Al-Zubayr ibn al-Awwam', 'Talha ibn Ubaydillah'], correctIndex: 0),
  _Q(ar: 'من هو أول من أسلم من الفرس؟', en: 'Who was the first Persian to accept Islam?', arOptions: ['سلمان الفارسي', 'صهيب الرومي', 'بلال بن رباح', 'زيد بن حارثة'], enOptions: ['Salman al-Farisi', 'Suhayb al-Rumi', 'Bilal ibn Rabah', 'Zayd ibn Harithah'], correctIndex: 0),
  _Q(ar: 'من هو الصحابي الملقب بـ"ذي النورين"؟', en: 'Which companion is known as "Dhun-Nurayn" (Possessor of the Two Lights)?', arOptions: ['عمر بن الخطاب', 'عثمان بن عفان', 'علي بن أبي طالب', 'أبو بكر الصديق'], enOptions: ['Umar ibn al-Khattab', 'Uthman ibn Affan', 'Ali ibn Abi Talib', 'Abu Bakr al-Siddiq'], correctIndex: 1),
  _Q(ar: 'من هو الصحابي الملقب بـ"أسد الله" وسيد الشهداء؟', en: 'Which companion is known as "The Lion of Allah" and Master of the Martyrs?', arOptions: ['حمزة بن عبد المطلب', 'جعفر بن أبي طالب', 'خالد بن الوليد', 'الزبير بن العوام'], enOptions: ['Hamza ibn Abdul-Muttalib', 'Jafar ibn Abi Talib', 'Khalid ibn al-Walid', 'Al-Zubayr ibn al-Awwam'], correctIndex: 0),
  _Q(ar: 'من هو الصحابي الذي كلّفه أبو بكر رضي الله عنه بجمع القرآن في مصحف واحد؟', en: 'Whom did Abu Bakr task with compiling the Quran into a single mushaf?', arOptions: ['زيد بن ثابت', 'أبيّ بن كعب', 'عبد الله بن مسعود', 'معاذ بن جبل'], enOptions: ['Zayd ibn Thabit', 'Ubayy ibn Kaab', 'Abdullah ibn Masud', 'Muadh ibn Jabal'], correctIndex: 0),
  _Q(ar: 'من هي أول زوجات النبي صلى الله عليه وسلم وأول من آمن به؟', en: 'Who was the Prophet\'s first wife and the first person to believe in him?', arOptions: ['عائشة رضي الله عنها', 'خديجة بنت خويلد رضي الله عنها', 'حفصة بنت عمر', 'أم سلمة'], enOptions: ['Aisha', 'Khadijah bint Khuwaylid', 'Hafsah bint Umar', 'Umm Salamah'], correctIndex: 1),
  _Q(ar: 'من هو الصحابي الذي يُلقّب بـ"ترجمان القرآن"؟', en: 'Which companion is known as "The Interpreter of the Quran"?', arOptions: ['عبد الله بن عباس', 'عبد الله بن عمر', 'أنس بن مالك', 'أبو هريرة'], enOptions: ['Abdullah ibn Abbas', 'Abdullah ibn Umar', 'Anas ibn Malik', 'Abu Hurayrah'], correctIndex: 0),
  _Q(ar: 'كم عدد الصحابة المبشرين بالجنة الذين ذكرهم النبي صلى الله عليه وسلم بأسمائهم؟', en: 'How many companions did the Prophet name as given the glad tidings of Paradise?', arOptions: ['عشرة', 'سبعة', 'اثنا عشر', 'خمسة'], enOptions: ['Ten', 'Seven', 'Twelve', 'Five'], correctIndex: 0),
  _Q(ar: 'من هو الصحابي الملقب بـ"غسيل الملائكة"؟', en: 'Which companion is known as "The One Washed by the Angels"?', arOptions: ['حنظلة بن أبي عامر', 'سعد بن معاذ', 'أبو أيوب الأنصاري', 'عمار بن ياسر'], enOptions: ['Hanzalah ibn Abi Aamir', 'Saad ibn Muadh', 'Abu Ayyub al-Ansari', 'Ammar ibn Yasir'], correctIndex: 0),
  _Q(ar: 'من هو الصحابي الملقب بـ"جعفر الطيار"؟', en: 'Which companion is known as "Jafar the Flyer"?', arOptions: ['جعفر بن أبي طالب', 'زيد بن حارثة', 'عبد الله بن رواحة', 'حمزة بن عبد المطلب'], enOptions: ['Jafar ibn Abi Talib', 'Zayd ibn Harithah', 'Abdullah ibn Rawahah', 'Hamza ibn Abdul-Muttalib'], correctIndex: 0),
  _Q(ar: 'كم سنة خدم أنس بن مالك رضي الله عنه النبي صلى الله عليه وسلم؟', en: 'For how many years did Anas ibn Malik serve the Prophet?', arOptions: ['عشر سنوات', 'خمس سنوات', 'عشرين سنة', 'سنتان'], enOptions: ['Ten years', 'Five years', 'Twenty years', 'Two years'], correctIndex: 0),
  _Q(ar: 'من هو الصحابي الذي عُرف بكثرة الإنفاق في سبيل الله من أصحاب الأموال؟', en: 'Which wealthy companion was renowned for his extensive charitable spending?', arOptions: ['عبد الرحمن بن عوف', 'عثمان بن عفان', 'سعد بن أبي وقاص', 'معاذ بن جبل'], enOptions: ['Abdur-Rahman ibn Awf', 'Uthman ibn Affan', 'Saad ibn Abi Waqqas', 'Muadh ibn Jabal'], correctIndex: 0),
  _Q(ar: 'من هو الصحابي الذي أرسله النبي صلى الله عليه وسلم معلمًا إلى أهل اليمن؟', en: 'Whom did the Prophet send to Yemen to teach the Quran and jurisprudence?', arOptions: ['معاذ بن جبل', 'أبو موسى الأشعري', 'عمرو بن العاص', 'خالد بن الوليد'], enOptions: ['Muadh ibn Jabal', 'Abu Musa al-Ashari', 'Amr ibn al-As', 'Khalid ibn al-Walid'], correctIndex: 0),
  _Q(ar: 'من هي الصحابية التي اشتهرت بروايتها الكثيرة للحديث النبوي؟', en: 'Which female companion is renowned for narrating a great number of hadiths?', arOptions: ['عائشة رضي الله عنها', 'فاطمة بنت النبي', 'أم عمارة', 'صفية بنت عبد المطلب'], enOptions: ['Aisha', 'Fatimah bint Muhammad', 'Umm Umarah', 'Safiyyah bint Abdul-Muttalib'], correctIndex: 0),
];

class SahabaQuizScreen extends StatefulWidget {
  const SahabaQuizScreen({super.key});
  @override
  State<SahabaQuizScreen> createState() => _SahabaQuizScreenState();
}

class _SahabaQuizScreenState extends State<SahabaQuizScreen> {
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
      appBar: AppBar(title: Text(isAr ? 'اختبار عن الصحابة' : 'Sahaba (Companions) Quiz'), centerTitle: true, actions: [
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
