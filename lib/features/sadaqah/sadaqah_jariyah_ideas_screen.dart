import 'package:flutter/material.dart';


class SadaqahJariyahIdeasScreen extends StatelessWidget {
  const SadaqahJariyahIdeasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'أفكار صدقة جارية' : 'Sadaqah Jariyah Ideas'), centerTitle: true),
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
                  Text(isAr ? 'حفر بئر أو توفير مياه' : 'Digging a well / providing water', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'من أعظم صور الصدقة الجارية، وفيها اقتداء بفعل عثمان بن عفان رضي الله عنه في بئر رومة.' : 'One of the greatest forms of ongoing charity, following the example of Uthman ibn Affan (may Allah be pleased with him) with the well of Rumah.',
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
                  Text(isAr ? 'المساهمة في بناء مسجد' : 'Contributing to building a mosque', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'من بنى لله مسجدًا بنى الله له بيتًا في الجنة، والمساهمة الجزئية تدخل في هذا الأجر.' : 'Whoever builds a mosque for Allah, Allah builds for them a house in Paradise -- partial contributions share in this reward.',
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
                  Text(isAr ? 'طباعة أو توزيع مصحف' : 'Printing or distributing copies of the Quran', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'كل من قرأ فيه أو انتفع به يكون للمتصدّق به أجر مستمر بإذن الله.' : "Everyone who reads from or benefits from it brings ongoing reward to the one who gave it, by Allah's permission.",
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
                  Text(isAr ? 'كفالة يتيم' : 'Sponsoring an orphan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'كافل اليتيم مع النبي صلى الله عليه وسلم كهاتين في الجنة، مع استمرار أثر الرعاية والتربية.' : 'The sponsor of an orphan will be with the Prophet in Paradise like this and this (two fingers together), with lasting impact of the care given.',
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
                  Text(isAr ? 'غرس شجرة' : 'Planting a tree', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'ما من مسلم يغرس غرسًا فيأكل منه إنسان أو طير إلا كان له به صدقة.' : 'No Muslim plants a tree from which a person or bird eats, except that it is charity for them.',
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
                  Text(isAr ? 'تعليم علم نافع' : 'Teaching beneficial knowledge', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'العلم الذي يُعلَّم وينتفع به يبقى أثره وأجره مستمرًا بعد موت صاحبه.' : "Knowledge that is taught and benefited from continues to bring reward even after the teacher's death.",
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
                  Text(isAr ? 'المساهمة في الرعاية الصحية' : 'Contributing to healthcare', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'دعم مستشفى أو عيادة خيرية صدقة جارية ينتفع بها كل مريض يُعالَج فيها.' : 'Supporting a charitable hospital or clinic is ongoing charity that benefits every patient treated there.',
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
