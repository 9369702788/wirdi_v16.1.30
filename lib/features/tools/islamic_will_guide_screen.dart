import 'package:flutter/material.dart';


class IslamicWillGuideScreen extends StatelessWidget {
  const IslamicWillGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'دليل كتابة الوصية الإسلامية' : 'Islamic Will (Wasiyyah) Guide'), centerTitle: true),
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
                  Text(isAr ? 'لماذا الوصية؟' : 'Why write a will?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'حث النبي صلى الله عليه وسلم على أن يكون للمسلم وصية مكتوبة، خاصة إن كان له مال أو حقوق يخشى ضياعها.' : 'The Prophet encouraged Muslims to have a written will, especially if they have wealth or rights that might otherwise be lost or disputed.',
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
                  Text(isAr ? 'حدود الوصية الشرعية' : 'The legal limit of a will', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'لا تجوز الوصية بأكثر من ثلث المال، ولا وصية لوارث إلا بموافقة بقية الورثة، لأن الله فصّل المواريث في كتابه.' : 'A will may not exceed one third of the estate, and no bequest is valid to an existing heir unless the other heirs agree, since Allah has already detailed inheritance shares in the Quran.',
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
                  Text(isAr ? 'ما يُستحب ذكره في الوصية' : 'What is recommended to include', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'تحديد الديون التي عليك أو لك، توصية بحسن تربية الأولاد الصغار، تسمية مسؤول عن تنفيذ الوصية، والوصية بتقوى الله لأهلك.' : 'Listing debts owed to or by you, guidance on raising young children well, naming someone to execute the will, and advising your family to remain mindful of Allah.',
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
                  Text(isAr ? 'تنبيه مهم' : 'Important note', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'هذا دليل إرشادي عام وليس بديلاً عن استشارة عالم شرعي أو مختص قانوني لصياغة وصية معتمدة رسميًا في بلدك.' : 'This is a general guide only, not a substitute for consulting a qualified scholar or legal professional to draft a formally valid will in your country.',
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
