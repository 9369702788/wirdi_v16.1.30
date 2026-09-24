import 'package:flutter/material.dart';


class TravelPrayerGuideScreen extends StatelessWidget {
  const TravelPrayerGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'دليل الجمع والقصر للمسافر' : "Travel Prayer Guide (Jam' & Qasr)"), centerTitle: true),
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
                  Text(isAr ? 'القصر' : 'Shortening (Qasr)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'يجوز للمسافر سفرًا تُقصر فيه الصلاة أن يقصر الصلاة الرباعية (الظهر والعصر والعشاء) إلى ركعتين، أما الفجر والمغرب فلا تُقصران.' : "A traveler on a journey of a distance recognized for shortening prayer may shorten the four-rak'ah prayers (Dhuhr, Asr, Isha) to two rak'ahs each. Fajr and Maghrib are not shortened.",
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
                  Text(isAr ? 'الجمع' : 'Combining (Jam)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'يجوز للمسافر أن يجمع بين الظهر والعصر، وبين المغرب والعشاء، إما جمع تقديم (في وقت الأولى) أو جمع تأخير (في وقت الثانية).' : 'A traveler may combine Dhuhr with Asr, and Maghrib with Isha, either by combining them earlier (in the time of the first) or later (in the time of the second).',
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
                  Text(isAr ? 'رخصة لا عزيمة' : 'A concession, not an obligation', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'الجمع والقصر رخصتان من الله للمسافر تخفيفًا عليه، وليستا واجبتين، فمن أراد الإتمام والفصل جاز له ذلك.' : 'Combining and shortening are concessions from Allah to ease travel, not obligations -- a traveler may choose to pray in full and separately if they wish.',
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
