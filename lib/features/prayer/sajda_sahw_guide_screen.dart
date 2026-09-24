import 'package:flutter/material.dart';


class SajdaSahwGuideScreen extends StatelessWidget {
  const SajdaSahwGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'دليل سجود السهو' : 'Sujud al-Sahw Guide'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'حالة الزيادة' : 'Case of addition', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'إذا زاد المصلي ركوعًا أو سجودًا أو ركعة سهوًا، فإنه يسجد سجدتي السهو بعد السلام.' : "If a worshipper unintentionally adds an extra bowing, prostration, or rak'ah, they perform two prostrations of forgetfulness after the salam.",
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'حالة النقص' : 'Case of omission', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'إذا نسي المصلي ركنًا كالتشهد الأول أو تسبيح الركوع، فإنه يسجد سجدتي السهو قبل السلام غالبًا.' : 'If the worshipper forgets an obligatory part, such as the first tashahhud, they generally perform the two prostrations before the salam.',
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'حالة الشك' : 'Case of doubt', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'إذا شكّ المصلي في عدد الركعات ولم يترجّح عنده شيء، يبني على اليقين (الأقل)، ويكمل صلاته، ثم يسجد سجدتي السهو قبل السلام.' : "If the worshipper doubts the number of rak'ahs prayed with no clear preponderance, they build on certainty (the lesser number), complete the prayer, then prostrate twice before the salam.",
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'كيفية سجود السهو' : 'How to perform it', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'يُكبّر ثم يسجد سجدتين كسجود الصلاة العادي، يفصل بينهما بجلسة خفيفة، ثم يُسلّم (أو يكمل الصلاة إن كان قبل السلام).' : "Say 'Allahu Akbar' then prostrate twice as in normal prayer, sitting briefly between them, then give the salam (or continue the prayer if performed before the salam).",
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }
}
