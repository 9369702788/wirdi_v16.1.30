import 'package:flutter/material.dart';


class SajdaTilawahGuideScreen extends StatelessWidget {
  const SajdaTilawahGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'دليل سجود التلاوة' : 'Sujud al-Tilawah Guide'), centerTitle: true),
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
                  Text(isAr ? 'متى تُشرع سجدة التلاوة؟' : 'When is the Sujud al-Tilawah prescribed?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'تُشرع عند قراءة أو سماع إحدى آيات السجدة في القرآن، سواء كان القارئ في صلاة أو خارجها.' : 'It is prescribed upon reciting or hearing one of the sajdah verses in the Quran, whether during prayer or outside of it.',
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
                  Text(isAr ? 'كيفيتها خارج الصلاة' : 'How to perform it outside of prayer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'يُكبّر، ثم يسجد سجدة واحدة كسجود الصلاة، يقول فيها أذكار السجود المعتادة، ثم يرفع بلا تسليم.' : "Say 'Allahu Akbar', then prostrate once as in prayer, saying the usual prostration remembrances, then rise without a salam.",
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
                  Text(isAr ? 'كيفيتها داخل الصلاة' : 'How to perform it during prayer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'إذا مرّ المصلي بآية سجدة وهو يصلي، يُكبّر ويسجد سجدة واحدة ثم يقوم ويكمل صلاته.' : "If a worshipper passes by a sajdah verse while praying, they say 'Allahu Akbar', prostrate once, then stand and continue the prayer.",
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
                  Text(isAr ? 'حكمها' : 'Its ruling', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'سجدة التلاوة سنة مؤكدة عند جمهور العلماء، وليست واجبة، فمن تركها فلا إثم عليه.' : 'Sujud al-Tilawah is a confirmed Sunnah according to most scholars, not obligatory -- there is no sin in omitting it.',
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
