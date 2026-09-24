import 'package:flutter/material.dart';


class JanazahGuideScreen extends StatelessWidget {
  const JanazahGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'دليل صلاة الجنازة' : 'Janazah Prayer Guide'), centerTitle: true),
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
                  Text(isAr ? 'التكبيرة الأولى' : 'First Takbir', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'يُكبّر تكبيرة الإحرام ثم يقرأ الفاتحة (بدون دعاء الاستفتاح أو الاستعاذة عند جمهور العلماء).' : 'Say the opening Takbir, then recite Surah Al-Fatiha (without the opening supplication, according to most scholars).',
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
                  Text(isAr ? 'التكبيرة الثانية' : 'Second Takbir', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'يُكبّر ثم يُصلّي على النبي صلى الله عليه وسلم كما في التشهد.' : 'Say Takbir, then send blessings upon the Prophet as in the tashahhud.',
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
                  Text(isAr ? 'التكبيرة الثالثة' : 'Third Takbir', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'يُكبّر ثم يدعو للميت بالمغفرة والرحمة.' : 'Say Takbir, then supplicate for the deceased with forgiveness and mercy.',
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
                  Text(isAr ? 'التكبيرة الرابعة والتسليم' : 'Fourth Takbir and Salam', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'يُكبّر تكبيرة رابعة، ثم يقف قليلًا أو يدعو دعاءً مختصرًا، ثم يُسلّم تسليمة واحدة أو تسليمتين.' : 'Say a fourth Takbir, pause briefly or make a short supplication, then give one or two salams to conclude.',
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
