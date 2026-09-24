import 'package:flutter/material.dart';

import '../../core/data/reciters.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// Short, factual, well-known background info for each reciter in
/// [Reciters.all] -- country and recitation style, used so users can
/// pick a reciter based on real distinguishing characteristics rather
/// than name alone.
final Map<String, Map<String, String>> reciterInfo = {
  'ar.alafasy': {
    'ar': 'قارئ كويتي معاصر، إمام وخطيب، صوته من أكثر الأصوات انتشارًا عالميًا خاصة بين الشباب، تلاوته مرتلة واضحة ميسّرة الحفظ.',
    'en': 'Contemporary Kuwaiti reciter and imam; one of the most widely-heard voices worldwide, especially among younger listeners. Clear, measured Murattal style that is easy to follow for memorization.',
  },
  'ar.husary': {
    'ar': 'قارئ مصري راحل، اشتهر بأسلوب "التحقيق" البطيء الدقيق في تطبيق أحكام التجويد، ومصحفه المرتل يُستخدم مرجعًا لتعليم القراءة الصحيحة.',
    'en': 'Legendary Egyptian reciter, known for the slow, precise "Tahqiq" style that carefully applies every tajweed rule -- his Murattal recording is widely used as a teaching reference.',
  },
  'ar.minshawi': {
    'ar': 'قارئ مصري راحل، اشتهر بأسلوب "المجوّد" العاطفي المؤثر ذي المقامات الصوتية المتنوعة، من أكثر التلاوات تأثيرًا في القلوب.',
    'en': 'Renowned Egyptian reciter known for an emotionally powerful "Mujawwad" style with varied vocal maqamat (melodic modes); among the most moving recitations widely cited.',
  },
  'ar.abdulbasitmurattal': {
    'ar': 'قارئ مصري راحل، يُعدّ من أعظم القراء في القرن العشرين، اشتهر بقوة الصوت وطول النَفَس وجمال الأداء في كل من المرتل والمجوّد.',
    'en': "Egyptian reciter widely regarded as one of the greatest of the 20th century, known for a powerful voice, remarkable breath control, and mastery of both Murattal and Mujawwad styles.",
  },
  'ar.abdurrahmaansudais': {
    'ar': 'إمام الحرم المكي الشريف، صوته معروف عالميًا من خلال بث صلوات الحرم، تلاوته مرتلة بخشوع وتؤدة.',
    'en': 'Imam of the Grand Mosque in Makkah; his voice is globally recognized through the broadcast of prayers from the Haram, with a calm, reverent Murattal style.',
  },
  'ar.mahermuaiqly': {
    'ar': 'إمام الحرم المكي الشريف، صوته مألوف للحجاج والمعتمرين عبر بث صلوات الحرم، أداؤه هادئ وواضح.',
    'en': 'Imam of the Grand Mosque in Makkah; familiar to pilgrims through the live broadcast of Haram prayers, with a calm and clear delivery.',
  },
};

class ReciterComparisonScreen extends StatefulWidget {
  const ReciterComparisonScreen({super.key});

  @override
  State<ReciterComparisonScreen> createState() => _ReciterComparisonScreenState();
}

class _ReciterComparisonScreenState extends State<ReciterComparisonScreen> {
  late ReciterOption _a = Reciters.all[0];
  late ReciterOption _b = Reciters.all.length > 1 ? Reciters.all[1] : Reciters.all[0];

  Widget _card(ReciterOption option, bool isAr, String languageCode) {
    final info = reciterInfo[option.id];
    return Expanded(
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: option.id,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            items: Reciters.all
                .map((r) => DropdownMenuItem(value: r.id, child: Text(r.displayNameFor(languageCode), overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (id) => setState(() {
              final selected = Reciters.byId(id!);
              if (option.id == _a.id) {
                _a = selected;
              } else {
                _b = selected;
              }
            }),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(option.displayNameFor(languageCode), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                  const Divider(height: 20),
                  Text(
                    info?[isAr ? 'ar' : 'en'] ?? '',
                    textAlign: TextAlign.start,
                    textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'معلومات عن القراء' : 'Reciter Info'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(_a, isAr, languageCode),
            const SizedBox(width: 12),
            _card(_b, isAr, languageCode),
          ],
        ),
      ),
    );
  }
}
