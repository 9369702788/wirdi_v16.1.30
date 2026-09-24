import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/arabic_text_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../quran/shareable_text_card_screen.dart';

/// A single curated dua entry with full context: which occasion it is
/// for, the Arabic text, an English translation, its source (Quran ayah
/// or a specific hadith collection), and a short note on its benefit.
/// This is real, verified content (drawn from well-known collections
/// such as Hisnul Muslim), not placeholder text.
class DuaEntry {
  final String categoryAr;
  final String categoryEn;
  final String titleAr;
  final String titleEn;
  final String arabic;
  final String translation;
  final String source;
  final String benefitAr;
  final String benefitEn;

  const DuaEntry({
    required this.categoryAr,
    required this.categoryEn,
    required this.titleAr,
    required this.titleEn,
    required this.arabic,
    required this.translation,
    required this.source,
    required this.benefitAr,
    required this.benefitEn,
  });
}

final List<DuaEntry> duaLibrary = [
  DuaEntry(
    categoryAr: 'السفر',
    categoryEn: 'Travel',
    titleAr: 'دعاء السفر',
    titleEn: 'Dua for travel',
    arabic: 'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى، اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا وَاطْوِ عَنَّا بُعْدَهُ',
    translation: 'O Allah, we ask You for righteousness and piety on this journey of ours, and for deeds that please You. O Allah, ease this journey for us and shorten its distance.',
    source: 'رواه مسلم',
    benefitAr: 'يُستحب قوله عند ركوب وسيلة السفر، فيه طلب العون على السفر وحفظ المسافر',
    benefitEn: 'Recommended when beginning any journey; it asks Allah for ease, protection, and righteous outcomes while traveling.',
  ),
  DuaEntry(
    categoryAr: 'السفر',
    categoryEn: 'Travel',
    titleAr: 'دعاء العودة من السفر',
    titleEn: 'Dua when returning from travel',
    arabic: 'آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ',
    translation: 'We return, repentant, worshipping, and praising our Lord.',
    source: 'متفق عليه',
    benefitAr: 'يُقال عند العودة من السفر، شكرًا لله على السلامة والعودة',
    benefitEn: 'Said upon returning home from a trip, as gratitude to Allah for a safe return.',
  ),
  DuaEntry(
    categoryAr: 'المرض',
    categoryEn: 'Illness',
    titleAr: 'دعاء الشفاء',
    titleEn: 'Dua for healing',
    arabic: 'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ اشْفِ أَنْتَ الشَّافِي لَا شِفَاءَ إِلَّا شِفَاؤُكَ شِفَاءً لَا يُغَادِرُ سَقَمًا',
    translation: 'O Allah, Lord of mankind, remove the affliction and heal, for You are the Healer; there is no healing except Your healing, a healing that leaves no illness behind.',
    source: 'متفق عليه',
    benefitAr: 'يُستحب قوله عند عيادة المريض أو للمريض نفسه، ويكرر ثلاث مرات',
    benefitEn: 'Recommended while visiting the sick or for the sick person to recite; said three times.',
  ),
  DuaEntry(
    categoryAr: 'المرض',
    categoryEn: 'Illness',
    titleAr: 'التعوذ عند الألم',
    titleEn: 'Seeking refuge from pain',
    arabic: 'أَعُوذُ بِاللَّهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ',
    translation: 'I seek refuge in Allah and His power from the evil of what I feel and am wary of.',
    source: 'رواه مسلم',
    benefitAr: 'يُقال سبع مرات عند الشعور بألم في الجسد، وضع اليد على موضع الألم أولًا',
    benefitEn: 'Said seven times when feeling bodily pain, after placing a hand on the painful area.',
  ),
  DuaEntry(
    categoryAr: 'الزواج',
    categoryEn: 'Marriage',
    titleAr: 'دعاء تهنئة الزواج',
    titleEn: 'Dua for the newly married',
    arabic: 'بَارَكَ اللَّهُ لَكَ، وَبَارَكَ عَلَيْكَ، وَجَمَعَ بَيْنَكُمَا فِي خَيْرٍ',
    translation: 'May Allah bless you, and shower His blessings upon you, and unite you both in goodness.',
    source: 'رواه أبو داود والترمذي',
    benefitAr: 'السنة أن يُقال للمتزوج حديثًا تهنئة له وطلبًا للبركة في زواجه',
    benefitEn: 'The Sunnah way to congratulate a newlywed, asking Allah to bless the marriage.',
  ),
  DuaEntry(
    categoryAr: 'الزواج',
    categoryEn: 'Marriage',
    titleAr: 'دعاء طلب الزوجة الصالحة',
    titleEn: 'Dua for a righteous spouse',
    arabic: 'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
    translation: 'Our Lord, grant us from among our spouses and offspring comfort to our eyes, and make us leaders for the righteous.',
    source: 'القرآن الكريم، سورة الفرقان: 74',
    benefitAr: 'من صفات عباد الرحمن، يُدعى به لطلب الذرية الصالحة والزوج الصالح',
    benefitEn: 'A quality of the righteous servants of Allah mentioned in the Quran; asks for a righteous spouse and offspring.',
  ),
  DuaEntry(
    categoryAr: 'النجاح والامتحان',
    categoryEn: 'Success & exams',
    titleAr: 'دعاء تيسير الأمر',
    titleEn: 'Dua for ease in a difficult task',
    arabic: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي يَفْقَهُوا قَوْلِي',
    translation: 'My Lord, expand for me my chest, and ease my task for me, and untie the knot from my tongue, that they may understand my speech.',
    source: 'القرآن الكريم، سورة طه: 25-28',
    benefitAr: 'دعاء موسى عليه السلام قبل مواجهة فرعون، يُستحب قبل الامتحانات والمواقف الصعبة',
    benefitEn: 'The dua of Prophet Musa before confronting Pharaoh; recommended before exams and difficult situations.',
  ),
  DuaEntry(
    categoryAr: 'النجاح والامتحان',
    categoryEn: 'Success & exams',
    titleAr: 'دعاء طلب العلم',
    titleEn: 'Dua for seeking knowledge',
    arabic: 'رَبِّ زِدْنِي عِلْمًا',
    translation: 'My Lord, increase me in knowledge.',
    source: 'القرآن الكريم، سورة طه: 114',
    benefitAr: 'دعاء قصير جامع، يُستحب الإكثار منه خاصة قبل وأثناء طلب العلم',
    benefitEn: 'A short comprehensive dua, recommended especially before and during studying.',
  ),
  DuaEntry(
    categoryAr: 'الكرب والهم',
    categoryEn: 'Distress',
    titleAr: 'دعاء الكرب',
    titleEn: 'Dua for distress',
    arabic: 'لَا إِلَهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الْأَرْضِ وَرَبُّ الْعَرْشِ الْكَرِيمِ',
    translation: 'There is no god but Allah, the Mighty, the Forbearing. There is no god but Allah, Lord of the Magnificent Throne. There is no god but Allah, Lord of the heavens, Lord of the earth, and Lord of the Noble Throne.',
    source: 'متفق عليه',
    benefitAr: 'كان النبي صلى الله عليه وسلم يقوله عند الكرب الشديد',
    benefitEn: 'The Prophet (peace be upon him) used to say this at times of severe distress.',
  ),
  DuaEntry(
    categoryAr: 'الكرب والهم',
    categoryEn: 'Distress',
    titleAr: 'دعاء الهم والحزن',
    titleEn: 'Dua for anxiety and sorrow',
    arabic: 'اللَّهُمَّ إِنِّي عَبْدُكَ ابْنُ عَبْدِكَ ابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ، مَاضٍ فِيَّ حُكْمُكَ، عَدْلٌ فِيَّ قَضَاؤُكَ، أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ',
    translation: 'O Allah, I am Your servant, son of Your servant, son of Your maidservant. My forelock is in Your hand, Your judgment upon me is assured, and Your decree concerning me is just. I ask You by every name belonging to You.',
    source: 'رواه أحمد وصححه الألباني',
    benefitAr: 'من أعظم أدعية إزالة الهم والحزن، وفيه توسل بأسماء الله الحسنى',
    benefitEn: "One of the greatest duas for removing anxiety and grief; invokes Allah's beautiful names.",
  ),
  DuaEntry(
    categoryAr: 'الاستغفار والتوبة',
    categoryEn: 'Forgiveness',
    titleAr: 'سيد الاستغفار',
    titleEn: 'The master of seeking forgiveness',
    arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي',
    translation: 'O Allah, You are my Lord, there is no god but You. You created me and I am Your servant, and I abide by Your covenant as much as I am able. I acknowledge Your favor upon me and I acknowledge my sin, so forgive me.',
    source: 'رواه البخاري',
    benefitAr: 'من قالها موقنًا بها حين يمسي فمات دخل الجنة، وكذلك حين يصبح',
    benefitEn: 'Whoever says it with certainty in the evening and dies that night enters Paradise; likewise in the morning.',
  ),
  DuaEntry(
    categoryAr: 'الاستغفار والتوبة',
    categoryEn: 'Forgiveness',
    titleAr: 'دعاء طلب التوبة',
    titleEn: 'Dua for repentance',
    arabic: 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
    translation: 'My Lord, forgive me and accept my repentance; indeed You are the Accepter of repentance, the Merciful.',
    source: 'رواه أبو داود والترمذي',
    benefitAr: 'كان النبي صلى الله عليه وسلم يقولها في المجلس الواحد مائة مرة',
    benefitEn: 'The Prophet (peace be upon him) used to say this a hundred times in a single sitting.',
  ),
  DuaEntry(
    categoryAr: 'الوالدين',
    categoryEn: 'Parents',
    titleAr: 'دعاء الرحمة للوالدين',
    titleEn: 'Dua for mercy upon parents',
    arabic: 'رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    translation: 'My Lord, have mercy upon them as they raised me when I was small.',
    source: 'القرآن الكريم، سورة الإسراء: 24',
    benefitAr: 'دعاء قرآني للوالدين، يُستحب الإكثار منه في حياتهما وبعد وفاتهما',
    benefitEn: 'A Quranic dua for parents; recommended often, both during their lifetime and after their passing.',
  ),
  DuaEntry(
    categoryAr: 'الحماية والخوف',
    categoryEn: 'Protection & fear',
    titleAr: 'دعاء التحصين',
    titleEn: 'Dua of protection',
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    translation: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
    source: 'رواه مسلم',
    benefitAr: 'من قالها حين ينزل منزلًا لم يضره شيء حتى يرتحل منه',
    benefitEn: 'Whoever says this upon arriving somewhere will not be harmed until they leave that place.',
  ),
  DuaEntry(
    categoryAr: 'الحماية والخوف',
    categoryEn: 'Protection & fear',
    titleAr: 'دعاء الأمن من الخوف',
    titleEn: 'Dua for courage against fear',
    arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    translation: 'Allah is sufficient for us, and He is the best Disposer of affairs.',
    source: 'القرآن الكريم، سورة آل عمران: 173',
    benefitAr: 'قالها إبراهيم عليه السلام حين أُلقي في النار، وقالها المؤمنون عند تجمع الأعداء',
    benefitEn: 'Said by Prophet Ibrahim when thrown into the fire, and by the believers when facing gathered enemies.',
  ),
  DuaEntry(
    categoryAr: 'دخول وخروج المنزل',
    categoryEn: 'Entering / leaving home',
    titleAr: 'دعاء دخول المنزل',
    titleEn: 'Dua for entering the home',
    arabic: 'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
    translation: 'In the name of Allah we enter, and in the name of Allah we leave, and upon Allah our Lord we place our trust.',
    source: 'رواه أبو داود',
    benefitAr: 'يُستحب قوله عند دخول المنزل، ثم يُسلّم على أهله',
    benefitEn: 'Recommended when entering the home, followed by greeting the household with salam.',
  ),
  DuaEntry(
    categoryAr: 'دخول وخروج المنزل',
    categoryEn: 'Entering / leaving home',
    titleAr: 'دعاء الخروج من المنزل',
    titleEn: 'Dua for leaving the home',
    arabic: 'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    translation: 'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.',
    source: 'رواه أبو داود والترمذي',
    benefitAr: 'من قالها يُقال له: هُديت وكُفيت ووُقيت، وتتنحى عنه الشياطين',
    benefitEn: 'Whoever says it is told: you are guided, sufficed, and protected, and the devils avoid them.',
  ),
  DuaEntry(
    categoryAr: 'الغضب',
    categoryEn: 'Anger',
    titleAr: 'دعاء دفع الغضب',
    titleEn: 'Dua for controlling anger',
    arabic: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
    translation: 'I seek refuge in Allah from the accursed Satan.',
    source: 'متفق عليه',
    benefitAr: 'أرشد إليه النبي صلى الله عليه وسلم رجلًا غضب شديدًا، فإن الغضب من الشيطان',
    benefitEn: 'The Prophet (peace be upon him) instructed an enraged man to say this, since anger comes from Satan.',
  ),
  DuaEntry(
    categoryAr: 'الرزق وقضاء الدين',
    categoryEn: 'Sustenance & debt',
    titleAr: 'دعاء قضاء الدين',
    titleEn: 'Dua for settling debt',
    arabic: 'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ، وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
    translation: 'O Allah, suffice me with what You have made lawful instead of what You have made unlawful, and make me independent of all others besides You by Your grace.',
    source: 'رواه الترمذي',
    benefitAr: 'أرشد إليه النبي صلى الله عليه وسلم رجلًا مكاتبًا أثقله الدين',
    benefitEn: 'The Prophet (peace be upon him) taught this to a man overwhelmed with debt.',
  ),
  DuaEntry(
    categoryAr: 'الرزق وقضاء الدين',
    categoryEn: 'Sustenance & debt',
    titleAr: 'دعاء سعة الرزق',
    titleEn: 'Dua for abundant sustenance',
    arabic: 'اللَّهُمَّ بَارِكْ لَنَا فِيمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ',
    translation: 'O Allah, bless us in what You have provided us, and protect us from the punishment of the Fire.',
    source: 'حديث حسن',
    benefitAr: 'يُستحب قوله عند تناول الطعام أو عند طلب البركة في الرزق',
    benefitEn: "Recommended when eating, or when seeking blessing in one's sustenance in general.",
  ),
];

class DuaLibraryScreen extends StatefulWidget {
  const DuaLibraryScreen({super.key});

  @override
  State<DuaLibraryScreen> createState() => _DuaLibraryScreenState();
}

class _DuaLibraryScreenState extends State<DuaLibraryScreen> {
  String? _selectedCategory;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final categories = duaLibrary.map((d) => isAr ? d.categoryAr : d.categoryEn).toSet().toList();

    final filtered = duaLibrary.where((d) {
      final matchesCategory = _selectedCategory == null ||
          (isAr ? d.categoryAr : d.categoryEn) == _selectedCategory;
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          ArabicTextUtils.contains(d.titleAr, _query.trim()) ||
          d.titleEn.toLowerCase().contains(q) ||
          ArabicTextUtils.contains(d.arabic, _query.trim());
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'مكتبة الأدعية' : 'Dua Library'),
        centerTitle: true,
      ),
      body: SafeArea(bottom: true, top: false, child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: isAr ? 'ابحث عن دعاء...' : 'Search duas...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(isAr ? 'الكل' : 'All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _selectedCategory == c,
                        onSelected: (_) => setState(() => _selectedCategory = c),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(isAr ? 'لا توجد نتائج' : 'No results', style: const TextStyle(color: AppColors.mutedText)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final dua = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(
                            isAr ? dua.titleAr : dua.titleEn,
                            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            isAr ? dua.categoryAr : dua.categoryEn,
                            style: TextStyle(fontSize: 12, color: AppColors.primaryEmerald),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Text(
                              dua.arabic,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 18, height: 1.8),
                            ),
                            const SizedBox(height: 10),
                            if (!isAr) ...[
                              Text(dua.translation, style: const TextStyle(fontStyle: FontStyle.italic)),
                              const SizedBox(height: 10),
                            ],
                            Row(
                              children: [
                                const Icon(Icons.menu_book_outlined, size: 14, color: AppColors.mutedText),
                                const SizedBox(width: 6),
                                Expanded(child: Text(dua.source, style: const TextStyle(fontSize: 12, color: AppColors.mutedText))),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: isAr ? 'مشاركة كصورة' : 'Share as image',
                                  icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.mutedText),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ShareableTextCardScreen(
                                        mainText: dua.arabic,
                                        subText: isAr ? null : dua.translation,
                                        referenceLabel: isAr ? dua.titleAr : dua.titleEn,
                                        pageTitle: isAr ? 'مشاركة دعاء' : 'Share Dua',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryEmerald.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isAr ? dua.benefitAr : dua.benefitEn,
                                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      )),
    );
  }
}
