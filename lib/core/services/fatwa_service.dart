
class FatwaRuling {
  final String question;
  final String questionAr;
  final String answer;
  final String answerAr;
  final String scholar;
  final String source;
  final String category;
  final String categoryAr;
  const FatwaRuling({required this.question, required this.questionAr, required this.answer, required this.answerAr, required this.scholar, required this.source, required this.category, required this.categoryAr});
}

class FatwaService {
  static const List<FatwaRuling> _rulings = [
    FatwaRuling(category: 'Prayer', categoryAr: 'الصلاة', question: 'Can a traveler shorten (Qasr) their prayers?', questionAr: 'هل يجوز للمسافر أن يقصر صلاته؟', answer: 'Yes. A traveler on a journey of a recognized distance may shorten the 4-rak\'ah prayers to 2 rak\'ahs, as the Prophet (peace be upon him) did. The Hanafi school holds that shortening is obligatory.', answerAr: 'نعم، يقصر المسافر مسافة سفر معتبرة شرعًا الصلاة الرباعية فيجعلها ركعتين كما فعل النبي صلى الله عليه وسلم. والحنفية يرون القصر واجبًا.', scholar: 'Majority view', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Prayer', categoryAr: 'الصلاة', question: 'Can a traveler combine two prayers (Jam)?', questionAr: 'هل يجوز للمسافر أن يجمع بين صلاتين؟', answer: 'Yes, according to the majority of scholars (Maliki, Shafi\'i, Hanbali): combining Dhuhr with Asr, and Maghrib with Isha, is permitted while traveling. The Hanafi school does not allow it while traveling, except at Arafah and Muzdalifah during Hajj.', answerAr: 'نعم عند جمهور العلماء (المالكية والشافعية والحنابلة) يجوز للمسافر جمع الظهر مع العصر، والمغرب مع العشاء. أما الحنفية فلا يجيزون الجمع في السفر إلا في عرفة ومزدلفة في الحج.', scholar: 'Majority view (Hanafi school differs)', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Prayer', categoryAr: 'الصلاة', question: 'I woke up after a prayer time had passed. What should I do?', questionAr: 'استيقظت بعد خروج وقت الصلاة، فماذا أفعل؟', answer: 'Pray it as soon as you wake up or remember -- there is no sin for an unintentional delay caused by sleep or forgetfulness.', answerAr: 'صلّها فور استيقاظك أو تذكّرك، فلا إثم عليك في تأخير غير مقصود بسبب النوم أو النسيان.', scholar: 'General consensus', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Fasting', categoryAr: 'الصيام', question: 'I ate or drank by mistake while fasting -- is my fast broken?', questionAr: 'أكلت أو شربت ناسيًا وأنا صائم، فهل يفسد صيامي؟', answer: 'No, according to the majority (Hanafi, Shafi\'i, Hanbali). If you genuinely forgot, your fast remains valid; stop as soon as you remember. The Maliki school requires making up the day.', answerAr: 'لا يفسد صيامك عند جمهور العلماء (الحنفية والشافعية والحنابلة)، فمن أكل أو شرب ناسيًا فليتم صومه، فإنما أطعمه الله وسقاه. والمالكية يوجبون قضاء ذلك اليوم.', scholar: 'Majority view', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Zakat', categoryAr: 'الزكاة', question: 'Is Zakat due on wealth that has not reached the Nisab threshold?', questionAr: 'هل تجب الزكاة في مال لم يبلغ النصاب؟', answer: 'No. Zakat only becomes obligatory once your zakatable wealth reaches the Nisab AND remains so for a full lunar year (Hawl).', answerAr: 'لا تجب الزكاة إلا إذا بلغ المال النصاب المقرر شرعًا، وحال عليه الحول الهجري كاملًا.', scholar: 'General consensus', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Purification', categoryAr: 'الطهارة', question: 'What breaks Wudu? (main points, with differences noted)', questionAr: 'ما نواقض الوضوء؟ (مع بيان مواضع الخلاف)', answer: 'Using the toilet (urine or stool), passing wind, and losing consciousness (deep sleep, fainting) are agreed upon. Other matters differ between the schools; for example, the flow of blood breaks wudu for the Hanafis and Hanbalis but not for the Shafi\'is and Malikis.', answerAr: 'قضاء الحاجة (البول والغائط)، وخروج الريح، وزوال العقل (كالنوم المستغرق والإغماء) مما اتُّفق على كونه ناقضًا. وتختلف المذاهب في أمور أخرى؛ فخروج الدم مثلًا ينقض الوضوء عند الحنفية والحنابلة ولا ينقضه عند الشافعية والمالكية.', scholar: 'Summary of the four schools', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Zakat', categoryAr: 'الزكاة', question: 'Is Zakat due on jewelry a woman wears regularly?', questionAr: 'هل تجب الزكاة في الذهب الذي تلبسه المرأة باستمرار؟', answer: 'A matter of scholarly difference: some hold no zakat is due on jewelry for personal use, others hold it is due if it reaches nisab. Consult a trusted scholar.', answerAr: 'من مسائل الخلاف الفقهي؛ ذهب كثير من العلماء لعدم وجوب الزكاة في الحلي للاستعمال الشخصي، وأوجبها آخرون إذا بلغ النصاب.', scholar: 'Scholarly difference', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Fasting', categoryAr: 'الصيام', question: 'Can a sick or traveling person break their fast?', questionAr: 'هل يجوز للمريض أو المسافر الفطر في رمضان؟', answer: 'Yes, with the missed days made up later.', answerAr: 'نعم، رخّص القرآن في ذلك صراحة، مع وجوب القضاء بعد زوال العذر.', scholar: 'General consensus', source: 'Quran, Al-Baqarah 2:184-185'),
    FatwaRuling(category: 'Purification', categoryAr: 'الطهارة', question: 'Does touching a woman break wudu?', questionAr: 'هل لمس المرأة ينقض الوضوء؟', answer: 'A matter of scholarly difference between the Fiqh schools.', answerAr: 'من مسائل الخلاف المعتبر بين المذاهب الفقهية؛ فبعضهم يرى عدم النقض وبعضهم يرى النقض بشروط.', scholar: 'Scholarly difference', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Marriage', categoryAr: 'الزواج والأسرة', question: 'Is a marriage valid without a dowry specified?', questionAr: 'هل يصح عقد الزواج بدون تحديد مهر؟', answer: 'Yes, though specifying it is recommended; the wife is then entitled to Mahr al-Mithl.', answerAr: 'يصح العقد ولو لم يُحدَّد المهر، وللزوجة حينها مهر المثل.', scholar: 'General consensus', source: 'Mainstream Fiqh reference'),
    FatwaRuling(category: 'Hajj', categoryAr: 'الحج', question: 'Is Hajj obligatory on someone who cannot afford it?', questionAr: 'هل يجب الحج على من لا يستطيع تكاليفه؟', answer: 'No, only on those with financial and physical capability.', answerAr: 'لا يجب الحج إلا على المستطيع ماليًا وبدنيًا.', scholar: 'General consensus', source: 'Quran, Aal-E-Imran 3:97'),
    FatwaRuling(category: 'Prayer', categoryAr: 'الصلاة', question: 'Can a woman pray in the mosque congregation?', questionAr: 'هل يجوز للمرأة أن تصلي في جماعة المسجد؟', answer: 'Yes, permissible and practiced at the time of the Prophet, peace be upon him.', answerAr: 'نعم يجوز، وقد كان معروفًا في عهد النبي صلى الله عليه وسلم.', scholar: 'General consensus', source: 'Hadith, Sahih Muslim'),
  ];

  static Future<List<FatwaRuling>> getFatwaByCategory(String category) async {
    if (category.isEmpty || category == 'All') return _rulings;
    return _rulings.where((r) => r.category == category).toList();
  }

  static Future<List<FatwaRuling>> getAll() async => _rulings;
  static List<String> get categories => _rulings.map((r) => r.category).toSet().toList()..sort();
}
