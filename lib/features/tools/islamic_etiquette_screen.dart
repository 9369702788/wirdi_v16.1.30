import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class _EtiquetteTopic {
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  const _EtiquetteTopic({required this.titleAr, required this.titleEn, required this.bodyAr, required this.bodyEn});
}

/// General Islamic etiquette (Adab) across everyday situations,
/// summarized from authentic Prophetic guidance found across the major
/// hadith collections.
class IslamicEtiquetteScreen extends StatelessWidget {
  const IslamicEtiquetteScreen({super.key});

  static const List<_EtiquetteTopic> _topics = [
    _EtiquetteTopic(
      titleAr: 'آداب الطعام',
      titleEn: 'Eating etiquette',
      bodyAr: 'التسمية قبل الأكل، الأكل باليد اليمنى، الأكل مما يلي الآكل، وحمد الله بعد الانتهاء. كذلك يُستحب عدم الأكل متكئاً، وعدم عيب الطعام إن لم يُعجب، والأكل بثلاث أصابع مما تيسّر.',
      bodyEn: 'Say Bismillah before eating, eat with the right hand, eat from what is nearest to you, and praise Allah after finishing. It is also recommended not to eat while reclining, not to criticize food one dislikes, and to eat with three fingers where practical.',
    ),
    _EtiquetteTopic(
      titleAr: 'آداب النوم',
      titleEn: 'Sleeping etiquette',
      bodyAr: 'النوم على الشق الأيمن، قراءة آية الكرسي والمعوذات قبل النوم، نفض الفراش قبل الاضطجاع، والوضوء قبل النوم إن أمكن. ويُستحب الاستيقاظ بذكر الله والدعاء المأثور عند الاستيقاظ.',
      bodyEn: 'Sleep on the right side, recite Ayat al-Kursi and the last three surahs of protection before sleeping, dust off the bed before lying down, and perform wudu before sleep if possible. It is also recommended to wake with the remembrance of Allah and the reported waking supplication.',
    ),
    _EtiquetteTopic(
      titleAr: 'آداب السلام',
      titleEn: 'Etiquette of greeting',
      bodyAr: 'يبدأ الراكب الماشي بالسلام، والماشي الجالس، والصغير الكبير، والقليل الكثير. وإفشاء السلام بين المسلمين من أسباب المحبة، كما جاء في الحديث "لا تدخلون الجنة حتى تؤمنوا، ولا تؤمنوا حتى تحابوا، أولا أدلكم على شيء إذا فعلتموه تحاببتم؟ أفشوا السلام بينكم".',
      bodyEn: 'The rider greets the walker first, the walker greets the one sitting, the young greet the elder, and the smaller group greets the larger group. Spreading the greeting of peace among Muslims fosters love, as in the hadith: "You will not enter Paradise until you believe, and you will not believe until you love one another. Shall I not guide you to something that, if you do it, you will love one another? Spread the greeting of peace among yourselves."',
    ),
    _EtiquetteTopic(
      titleAr: 'آداب العطاس والتثاؤب',
      titleEn: 'Etiquette of sneezing and yawning',
      bodyAr: 'يقول العاطس "الحمد لله"، ويرد عليه من سمعه "يرحمك الله"، فيقول العاطس "يهديكم الله ويصلح بالكم". أما التثاؤب فهو من الشيطان، ويُستحب كظمه ووضع اليد على الفم قدر المستطاع.',
      bodyEn: 'The sneezer says "Alhamdulillah", those who hear reply "Yarhamuk Allah" (may Allah have mercy on you), and the sneezer responds "Yahdikum Allah wa yuslihu balakum". Yawning, by contrast, is attributed to Shaytan, and it is recommended to suppress it and cover the mouth as much as possible.',
    ),
    _EtiquetteTopic(
      titleAr: 'آداب زيارة المريض',
      titleEn: 'Etiquette of visiting the sick',
      bodyAr: 'يُستحب تخفيف الزيارة، والدعاء للمريض بالشفاء (مثل "أسأل الله العظيم رب العرش العظيم أن يشفيك")، وتطييب خاطره، وتذكيره بالصبر والأجر، دون إطالة الجلوس أو التحدث عن أمور مقلقة.',
      bodyEn: 'It is recommended to keep the visit brief, supplicate for the sick person\'s healing (such as "As\'alu Allah al-\'Adheem, Rabbal-\'Arshil-\'Adheem an yashfiyak"), offer words of comfort, and remind them of patience and reward -- without prolonging the visit or discussing distressing matters.',
    ),
    _EtiquetteTopic(
      titleAr: 'آداب دخول المنزل والخروج منه',
      titleEn: 'Etiquette of entering and leaving the home',
      bodyAr: 'يُستحب ذكر الله عند الدخول والسلام على أهل البيت، وقول دعاء الخروج "بسم الله، توكلت على الله، ولا حول ولا قوة إلا بالله" عند مغادرة المنزل، إذ ورد أن الشيطان يتنحى عمن قال ذلك.',
      bodyEn: 'It is recommended to remember Allah upon entering and greet the household with salam, and to say the supplication for leaving: "Bismillah, tawakkaltu \'alallah, wa la hawla wa la quwwata illa billah" -- it is reported that Shaytan withdraws from whoever says this.',
    ),
    _EtiquetteTopic(
      titleAr: 'آداب دخول المسجد والخروج منه',
      titleEn: 'Etiquette of entering and leaving the mosque',
      bodyAr: 'يُستحب الدخول بالرجل اليمنى مع الدعاء "اللهم افتح لي أبواب رحمتك"، والخروج بالرجل اليسرى مع الدعاء "اللهم إني أسألك من فضلك"، مع الحرص على تحية المسجد بركعتين قبل الجلوس.',
      bodyEn: 'It is recommended to enter with the right foot while saying "Allahumma iftah li abwaba rahmatik", and to leave with the left foot saying "Allahumma inni as\'aluka min fadlik", along with observing the two-rakah greeting of the mosque before sitting.',
    ),
    _EtiquetteTopic(
      titleAr: 'آداب الضيافة',
      titleEn: 'Etiquette of hosting and being a guest',
      bodyAr: 'إكرام الضيف من علامات الإيمان كما في الحديث "من كان يؤمن بالله واليوم الآخر فليكرم ضيفه"، وضيافته الواجبة يوم وليلة. وعلى الضيف عدم الإطالة على مضيفه وعدم تكليفه ما يشق عليه.',
      bodyEn: 'Honoring the guest is a sign of faith, as in the hadith: "Whoever believes in Allah and the Last Day, let him honor his guest." The obligatory hospitality is for a day and a night. The guest, in turn, should not overstay or burden the host with difficult requests.',
    ),
    _EtiquetteTopic(
      titleAr: 'آداب المجلس',
      titleEn: 'Etiquette of gatherings',
      bodyAr: 'التوسّع في المجلس للقادم، عدم التفريق بين اثنين في مجلسهما إلا بإذنهما، خفض الصوت وعدم الخوض في الغيبة والنميمة، والاستئذان عند القيام من المجلس.',
      bodyEn: 'Making room for someone joining the gathering, not separating two people from their seats without permission, lowering one\'s voice and avoiding backbiting and gossip, and excusing oneself before leaving the gathering.',
    ),
    _EtiquetteTopic(
      titleAr: 'آداب الكلام',
      titleEn: 'Etiquette of speech',
      bodyAr: 'قول الخير أو الصمت، كما في الحديث "من كان يؤمن بالله واليوم الآخر فليقل خيراً أو ليصمت"، وتجنّب الكذب والسخرية والجدال بغير علم، والإنصات لمن يتكلم دون مقاطعة.',
      bodyEn: 'Speaking good or remaining silent, as in the hadith: "Whoever believes in Allah and the Last Day should speak good or remain silent." Avoiding lying, mockery, and arguing without knowledge, and listening attentively to the speaker without interrupting.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'آداب إسلامية عامة' : 'Islamic Etiquette (Adab)'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final topic in _topics)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? topic.titleAr : topic.titleEn,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryEmerald),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr ? topic.bodyAr : topic.bodyEn,
                      style: const TextStyle(fontSize: 13, height: 1.7),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              isAr
                  ? 'المصادر: الأحاديث الصحيحة الواردة في الكتب الستة ومجموعات الحديث المعتمدة.'
                  : 'Sources: authentic hadiths reported in the six major hadith collections.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
            ),
          ),
        ],
      )),
    );
  }
}
