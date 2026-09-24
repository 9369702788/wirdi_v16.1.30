import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Stories of the Prophets, summarized from the Quran and the classical
/// works of tafsir and seerah (chiefly Ibn Kathir's "Qasas al-Anbiya"
/// and "Al-Bidaya wa'l-Nihaya", and Ibn Hisham's "As-Seerah
/// an-Nabawiyyah"). Kept to the well-established, non-disputed core of
/// each story -- deliberately avoiding Isra'iliyyat (unverified
/// narrations borrowed from earlier scriptures) that classical scholars
/// themselves flagged as unreliable.
class ProphetStoriesScreen extends StatelessWidget {
  const ProphetStoriesScreen({super.key});

  static const List<_ProphetStory> _stories = [
    _ProphetStory(
      nameAr: 'آدم عليه السلام',
      nameEn: 'Adam (peace be upon him)',
      bodyAr:
          'أبو البشر، خلقه الله بيده ونفخ فيه من روحه، وعلّمه الأسماء كلها فضلاً فاق به الملائكة، وأسكنه الجنة مع زوجه حواء. أغواه الشيطان فأكلا من الشجرة التي نُهيا عنها، فأُهبطا إلى الأرض ليكونا أول أب وأم للبشرية، لكن الله تعالى تاب عليه بعد أن تلقّى من ربه كلمات فاعترف بذنبه وأناب، فصار سنّة التوبة والاستغفار لذريته من بعده.',
      bodyEn:
          "The father of humanity. Allah created him with His own hand, breathed into him from His spirit, and taught him the names of all things -- a distinction even the angels did not share. He and his wife Hawwa (Eve) were placed in Paradise, but Shaytan tempted them into eating from the one tree they were forbidden, so they were sent down to earth to become the first parents of mankind. Allah accepted his sincere repentance after Adam turned to Him with words of contrition, establishing repentance as an enduring practice for his descendants.",
    ),
    _ProphetStory(
      nameAr: 'إدريس عليه السلام',
      nameEn: 'Idris / Enoch (peace be upon him)',
      bodyAr:
          'من أوائل الأنبياء بعد آدم، وصفه القرآن بأنه "صدّيق نبي" ورُفع مكاناً علياً. اشتهر بصبره وشكره الدائم لله، وقيل إنه أول من خطّ بالقلم واهتم بالعلم والحكمة بين قومه، فدعاهم إلى توحيد الله وترك المعاصي في زمن كثر فيه الفساد.',
      bodyEn:
          'One of the earliest prophets after Adam, described in the Quran as "truthful and a prophet" who was "raised to a high station." He was known for his constant patience and gratitude to Allah, and is traditionally remembered for valuing knowledge and wisdom among his people, calling them to the worship of Allah alone at a time when corruption had spread widely.',
    ),
    _ProphetStory(
      nameAr: 'نوح عليه السلام',
      nameEn: 'Nuh / Noah (peace be upon him)',
      bodyAr:
          'دعا قومه إلى توحيد الله تسعمائة وخمسين عاماً بالحكمة تارة وبالإنذار تارة أخرى، فما آمن معه إلا قليل. أُمر ببناء السفينة بأمر الله ووحيه، فسخِر منه قومه وهو يصنعها في غير موضع ماء، حتى فار التنور وجاء الطوفان فحمل فيها من آمن معه من كل زوجين اثنين، بينما غرق المكذبون ومنهم ابنه الذي أبى أن يركب معه. فكانت قصته درساً في طول الصبر على الدعوة وعاقبة التكذيب.',
      bodyEn:
          "He called his people to the worship of Allah alone for nine hundred and fifty years, alternating gentle wisdom with clear warning, yet only a few believed. By Allah's command and revelation he built the Ark while his people mocked him for building a ship far from any sea -- until the flood came and the earth burst forth with water. The Ark carried the believers and a pair of every kind of creature, while the disbelievers drowned, including his own son who refused to board. His story remains a lesson in patient, persistent calling to truth and the consequences of persistent denial.",
    ),
    _ProphetStory(
      nameAr: 'هود عليه السلام',
      nameEn: 'Hud (peace be upon him)',
      bodyAr:
          'أُرسل إلى قبيلة عاد، قوم عُرفوا بقوتهم وطول أجسادهم وعظيم بنيانهم، فدعاهم إلى عبادة الله وترك الأصنام فاستكبروا وكذّبوه. أنذرهم بعذاب أليم إن استمروا في طغيانهم، فأرسل الله عليهم ريحاً صرصراً عاتية استمرت أياماً حتى أهلكتهم عن آخرهم، ونجّى الله هوداً ومن آمن معه.',
      bodyEn:
          "Sent to the people of 'Aad, known for their great physical strength and towering architecture, he called them to worship Allah alone and abandon their idols, but they responded with arrogance and denial. He warned them of a painful punishment if they persisted in their transgression, and Allah sent upon them a violently raging wind that lasted for days until it destroyed them entirely, while saving Hud and those who believed with him.",
    ),
    _ProphetStory(
      nameAr: 'صالح عليه السلام',
      nameEn: 'Salih (peace be upon him)',
      bodyAr:
          'أُرسل إلى ثمود الذين نحتوا بيوتهم في الجبال، فطلبوا منه آية فأخرج الله لهم ناقة من صخرة عظيمة، وأمرهم صالح ألا يمسّوها بسوء وأن يتركوا لها شرباً يوماً وللقوم يوماً. عقروا الناقة عناداً واستكباراً، فأخذتهم صيحة عظيمة أهلكتهم، ونجا صالح ومن آمن معه.',
      bodyEn:
          'Sent to the people of Thamud, who carved their homes into mountains, he was asked for a miraculous sign, so Allah brought forth a she-camel from solid rock. Salih commanded them not to harm her and to share the water source between her and the people on alternating days. Out of stubbornness and arrogance they hamstrung the camel, and a tremendous blast seized and destroyed them, while Salih and the believers were saved.',
    ),
    _ProphetStory(
      nameAr: 'إبراهيم عليه السلام',
      nameEn: 'Ibrahim / Abraham (peace be upon him)',
      bodyAr:
          'خليل الله وأبو الأنبياء، كسر أصنام قومه وهو شاب مبيناً بطلان عبادتها، فحاجّ قومه بالحجة البالغة حتى بهت الذين كفروا. أُلقي في النار عقاباً على تحطيمه الأصنام، فجعلها الله عليه برداً وسلاماً فخرج منها سالماً. هاجر بأمر الله وابتُلي بذبح ابنه إسماعيل في المنام ففداه الله بذبح عظيم، ثم بنى مع ابنه إسماعيل قواعد الكعبة المشرفة ودعا الناس إلى حجها، فصار أباً روحياً لليهودية والنصرانية والإسلام جميعاً.',
      bodyEn:
          "The close friend of Allah and father of the prophets. As a young man he broke his people's idols to demonstrate the falseness of their worship, and debated them with decisive proof until the disbelievers were left speechless. He was thrown into a fire as punishment, but Allah made it cool and safe for him, and he emerged unharmed. He later migrated by Allah's command, was tested with a vision commanding him to sacrifice his son Ismail, and Allah ransomed the boy with a great sacrifice instead. Together with Ismail he raised the foundations of the Kaaba and called mankind to pilgrimage there, becoming a spiritual father recognized across Judaism, Christianity, and Islam alike.",
    ),
    _ProphetStory(
      nameAr: 'لوط عليه السلام',
      nameEn: 'Lut / Lot (peace be upon him)',
      bodyAr:
          'ابن أخي إبراهيم عليه السلام، أُرسل إلى أهل سدوم الذين ابتدعوا فاحشة لم يسبقهم بها أحد من العالمين، فدعاهم إلى الطهارة والعفة فسخروا منه وهدّدوه. أرسل الله ملائكة على هيئة رجال لإنذاره وإخراج أهله المؤمنين ليلاً، فنجا هو وابنتاه، وقُلبت قرى قومه فجعل الله عاليها سافلها وأمطرهم حجارة من سجيل.',
      bodyEn:
          "The nephew of Ibrahim, sent to the people of Sodom who invented an immorality unknown to any nation before them. He called them to purity and decency, but they mocked and threatened him. Allah sent angels in human form to warn him and lead his believing family out by night; he and his two daughters were saved, while his people's towns were overturned -- turned upside down -- and struck with a rain of stones of baked clay.",
    ),
    _ProphetStory(
      nameAr: 'إسماعيل عليه السلام',
      nameEn: 'Ismail / Ishmael (peace be upon him)',
      bodyAr:
          'ابن إبراهيم البكر، اتصف بالصبر العظيم حين علم بأمر ذبحه في المنام فقال لأبيه "يا أبتِ افعل ما تؤمر ستجدني إن شاء الله من الصابرين"، ففداه الله. أسكنه أبوه ووالدته هاجر وادي مكة القاحل فتفجّرت لهما بئر زمزم بأمر الله، ثم أعانه في شبابه على رفع قواعد الكعبة مع أبيه، وكان من أوائل من تكلّم بالعربية الفصحى وصار جدّاً لقبائل عربية كثيرة.',
      bodyEn:
          'The firstborn son of Ibrahim, remembered for his remarkable patience: when told of the vision commanding his sacrifice, he replied, "O my father, do as you are commanded; you will find me, if Allah wills, among the patient." Allah spared him. As an infant he and his mother Hajar were settled in the barren valley of Mecca, where the well of Zamzam sprang forth by Allah\'s command. In his youth he helped his father raise the foundations of the Kaaba, and he became an ancestor to many Arab tribes.',
    ),
    _ProphetStory(
      nameAr: 'يوسف عليه السلام',
      nameEn: 'Yusuf / Joseph (peace be upon him)',
      bodyAr:
          'قصته "أحسن القصص" كما وصفها القرآن. حسده إخوته فألقوه في الجب، فالتقطته قافلة وبِيع في مصر، وابتُلي بمراودة امرأة العزيز له عن نفسه فاستعصم، فسُجن ظلماً سنين. أكرمه الله بتأويل الرؤى فأوّل رؤيا الملك فأُخرج من السجن وتولّى خزائن مصر، ثم جمع الله شمله بأبيه يعقوب وإخوته بعد فراق طويل، وكانت خاتمة قصته عفوه الجميل عمّن ظلمه قائلاً "لا تثريب عليكم اليوم".',
      bodyEn:
          'His story is described in the Quran as "the best of narratives." Envied by his brothers, he was thrown into a well, picked up by a caravan, and sold in Egypt. He was tested when the wife of his master tried to seduce him, and he resisted, yet was still unjustly imprisoned for years. Allah blessed him with the interpretation of dreams; after correctly interpreting the king\'s dream he was freed and placed in charge of Egypt\'s stores. Years later he was reunited with his father Ya\'qub and his brothers after a long separation, and famously forgave those who had wronged him, saying, "No blame will there be upon you today."',
    ),
    _ProphetStory(
      nameAr: 'أيوب عليه السلام',
      nameEn: 'Ayyub / Job (peace be upon him)',
      bodyAr:
          'ضُرب به المثل في الصبر. ابتُلي بفقد المال والولد ثم بمرض شديد أقعده سنين طويلة، فصبر واحتسب ولم يفتر عن ذكر الله وشكره، حتى قال "أنّي مسّني الضرّ وأنت أرحم الراحمين" في أرقّ دعاء وأقله شكوى. فاستجاب الله له وكشف عنه الضر وردّ له أهله ومثلهم معهم رحمة من عنده وذكرى للعابدين.',
      bodyEn:
          'The example of patience mentioned throughout Islamic tradition. He was tested with the loss of his wealth and children, then afflicted with severe illness for many long years, yet he remained patient and never stopped remembering and thanking Allah, until he prayed with the gentlest of supplications, "Indeed, adversity has touched me, and You are the Most Merciful of the merciful." Allah answered him, removed his affliction, and restored his family to him and the like of them besides, as a mercy and a reminder for those devoted to Him.',
    ),
    _ProphetStory(
      nameAr: 'شعيب عليه السلام',
      nameEn: 'Shuayb (peace be upon him)',
      bodyAr:
          'أُرسل إلى أهل مدين الذين اشتهروا بالتطفيف في الكيل والميزان، فدعاهم إلى توحيد الله والعدل في المعاملات التجارية، وحذّرهم من إفساد الأرض بعد إصلاحها. كذّبوه واستكبروا فأخذتهم صيحة وزلزلة أصبحوا بها في ديارهم جاثمين، فكان درساً بليغاً في أهمية الأمانة والصدق في البيع والشراء.',
      bodyEn:
          "Sent to the people of Madyan, known for cheating in weights and measures, he called them to worship Allah alone and to deal justly in trade, warning them against corrupting the earth after it had been set right. They rejected him with arrogance, and a mighty blast and earthquake seized them, leaving them motionless in their homes -- a lasting lesson on the importance of honesty and fairness in commerce.",
    ),
    _ProphetStory(
      nameAr: 'موسى عليه السلام',
      nameEn: 'Musa / Moses (peace be upon him)',
      bodyAr:
          'أُلقي في اليمّ طفلاً فرباه الله في قصر فرعون نفسه، وقتل نفساً خطأً ففرّ إلى مدين، ثم كلّمه الله تكليماً عند الطور وأرسله إلى فرعون بمعجزتي العصا واليد البيضاء. جادل فرعون وسحرته فآمن السحرة، لكن فرعون استكبر وطغى، فنجّى الله بني إسرائيل بشقّ البحر لهم وأغرق فرعون وجنوده. أُنزلت عليه التوراة، وابتُلي بعناد قومه وعبادتهم العجل، فصبر عليهم وواصل الدعوة والإصلاح.',
      bodyEn:
          "Cast into the river as an infant, he was raised in Pharaoh's own palace by Allah's decree. After accidentally causing a man's death, he fled to Madyan, where Allah later spoke to him directly at Mount Tur and sent him back to Pharaoh with the miracles of the staff and the radiant hand. He debated Pharaoh's sorcerers, who then believed, but Pharaoh remained arrogant and tyrannical, so Allah saved the Children of Israel by parting the sea for them and drowning Pharaoh and his army. He was given the Torah, and though tested by his own people's stubbornness -- including their worship of a golden calf -- he remained patient and continued guiding them.",
    ),
    _ProphetStory(
      nameAr: 'داود عليه السلام',
      nameEn: 'Dawud / David (peace be upon him)',
      bodyAr:
          'جمع الله له بين النبوة والملك، وآتاه الزبور وألان له الحديد فكان يصنع منه دروع الحرب، وسخّر له الجبال والطير يسبّحن معه. عُرف بشدة العبادة حتى قيل إن صيامه كان يوماً وإفطاره يوماً، وبصوته الحسن في تلاوة الزبور، وبعدله البالغ في الحكم بين الناس.',
      bodyEn:
          'Allah combined for him both prophethood and kingship, gave him the Zabur (Psalms), softened iron in his hands so he could craft armor, and made the mountains and birds glorify Allah alongside him. He was known for the intensity of his worship -- reportedly fasting every other day -- for his beautiful voice in reciting the Zabur, and for his exceptional fairness in judging between people.',
    ),
    _ProphetStory(
      nameAr: 'سليمان عليه السلام',
      nameEn: 'Sulaiman / Solomon (peace be upon him)',
      bodyAr:
          'ورث النبوة والملك عن أبيه داود، وآتاه الله ملكاً عظيماً لا ينبغي لأحد من بعده، فسخّر له الريح والجن وعلّمه منطق الطير. حكم بحكمة بالغة، ومن أشهر قصصه مراسلته لملكة سبأ ودعوتها إلى الإسلام فأسلمت معه، فكان مثالاً للملك الذي يستخدم النعمة في طاعة الله وشكره لا في الكِبر والطغيان.',
      bodyEn:
          'He inherited both prophethood and kingship from his father Dawud, and Allah granted him a dominion unlike any given to another, subjecting the wind and the jinn to him and teaching him the language of birds. He ruled with profound wisdom, and one of his most famous accounts is his correspondence with the Queen of Sheba, inviting her to submit to Allah -- which she ultimately did. He remains an example of a ruler who used immense blessing in gratitude and obedience to Allah rather than arrogance.',
    ),
    _ProphetStory(
      nameAr: 'يونس عليه السلام',
      nameEn: 'Yunus / Jonah (peace be upon him)',
      bodyAr:
          'غادر قومه مغاضباً قبل أن يأذن الله له بذلك، فركب سفينة واقترع أهلها فوقعت عليه القرعة فأُلقي في البحر فابتلعه حوت عظيم. دعا ربه في ظلمات ثلاث -- ظلمة الليل وظلمة البحر وظلمة بطن الحوت -- بكلمات "لا إله إلا أنت سبحانك إني كنت من الظالمين"، فاستجاب الله له ونجّاه، وكان قومه قد آمنوا من بعده فنفعهم إيمانهم ولم يُهلكوا كما أُهلكت الأمم المكذبة قبلهم.',
      bodyEn:
          'He left his people in frustration before Allah had permitted him to do so, boarded a ship, and was cast into the sea after losing a drawn lot among its passengers, where a great fish swallowed him. In the threefold darkness -- of night, of the sea, and of the fish\'s belly -- he called upon his Lord: "There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers." Allah answered and saved him. His people, meanwhile, had come to believe after his departure, and their faith benefited them -- they were spared the fate of the earlier nations who persisted in denial.',
    ),
    _ProphetStory(
      nameAr: 'عيسى عليه السلام',
      nameEn: 'Isa / Jesus (peace be upon him)',
      bodyAr:
          'وُلد بلا أب بمعجزة من الله لمريم العذراء الصدّيقة، وتكلّم في المهد دفاعاً عن براءة أمه. آتاه الله الإنجيل وأيّده بمعجزات عظيمة: إحياء الموتى وإبراء الأكمه والأبرص بإذن الله، وأخذ الطين فينفخ فيه فيكون طيراً بإذن الله. كذّبه قومه وأرادوا قتله فرفعه الله إليه، وسينزل في آخر الزمان كما أخبر النبي محمد صلى الله عليه وسلم ليحكم بالعدل.',
      bodyEn:
          "Born without a father through Allah's miracle to the truthful virgin Maryam, he spoke from the cradle in defense of his mother's honor. Allah gave him the Gospel and supported him with great miracles: reviving the dead, healing the blind and the leper, and shaping clay into a bird that would fly, all by Allah's permission. His people rejected him and sought to kill him, but Allah raised him up to Himself, and Islamic tradition holds -- based on the Prophet Muhammad's own statements -- that he will return in the end times to rule with justice.",
    ),
    _ProphetStory(
      nameAr: 'إسحاق عليه السلام',
      nameEn: 'Ishaq / Isaac (peace be upon him)',
      bodyAr: 'ابن إبراهيم عليه السلام من زوجته سارة، وُلد بشارةً من الله بعد أن تقدّم بهما العمر. تزوّج وأنجب يعقوب عليه السلام، واستمرت من نسله سلسلة الأنبياء إلى بني إسرائيل.',
      bodyEn: "Son of Ibrahim from his wife Sarah, born as a divine glad tiding in their old age. He fathered Ya'qub (Jacob), and through his line the chain of prophethood continued among the Children of Israel.",
    ),
    _ProphetStory(
      nameAr: 'يعقوب عليه السلام',
      nameEn: "Ya'qub / Jacob (peace be upon him)",
      bodyAr: 'ابن إسحاق عليه السلام، ويُلقّب بإسرائيل، وهو أبو الأسباط الاثني عشر. عُرف بصبره الطويل حين فقد ابنه يوسف عليه السلام سنين طويلة، حتى رد الله عليه بصره وجمعه بيوسف من جديد.',
      bodyEn: "Son of Ishaq, also called Israel, and the father of the twelve tribes. Remembered for his extraordinary patience after losing his son Yusuf for many years, until Allah reunited them.",
    ),
    _ProphetStory(
      nameAr: 'هارون عليه السلام',
      nameEn: 'Harun / Aaron (peace be upon him)',
      bodyAr: 'أخو موسى عليه السلام الأكبر، طلب موسى من ربه أن يجعله معينًا له في تبليغ الرسالة، فاستجاب الله وأشركه معه في النبوة. وقف مع موسى أمام فرعون، وكان أمينًا على بني إسرائيل في غيابه.',
      bodyEn: "Musa's elder brother, made a prophet alongside him as a helper in conveying the message. He stood with Musa before Pharaoh, and was left in charge of the Children of Israel in his absence.",
    ),
    _ProphetStory(
      nameAr: 'ذو الكفل عليه السلام',
      nameEn: 'Dhul-Kifl (peace be upon him)',
      bodyAr: 'ذكره القرآن مقترنًا بإسماعيل واليسع عليهما السلام ضمن "الأخيار"، ووصفه بأنه "من الصابرين". كان نبيًا صالحًا ملتزمًا بما تكفّل به من عبادة وعدل بين الناس.',
      bodyEn: 'Mentioned in the Quran alongside Ismail and Al-Yasa among "the outstanding," described as "among the patient." A righteous prophet who steadfastly fulfilled his commitments of worship and just dealings.',
    ),
    _ProphetStory(
      nameAr: 'إلياس عليه السلام',
      nameEn: 'Ilyas / Elijah (peace be upon him)',
      bodyAr: 'أُرسل إلى قومه من بني إسرائيل بعد انتشار عبادة الصنم "بعل" فيهم، فدعاهم إلى توحيد الله. كذّبه أكثر قومه، وأثنى الله عليه في القرآن بأنه من المرسلين.',
      bodyEn: "Sent to his people after the worship of the idol Ba'l spread among them, calling them to Allah's oneness. Most rejected him, but Allah praised him as one of the messengers.",
    ),
    _ProphetStory(
      nameAr: 'اليسع عليه السلام',
      nameEn: 'Al-Yasa / Elisha (peace be upon him)',
      bodyAr: 'ذُكر في القرآن مقترنًا بإسماعيل وذي الكفل ضمن من فضّلهم الله على العالمين. يرى كثير من المفسرين أنه خلَف النبي إلياس عليه السلام في الدعوة من بعده.',
      bodyEn: 'Mentioned in the Quran alongside Ismail and Dhul-Kifl among those Allah favored. Many commentators hold he succeeded the prophet Ilyas in calling his people after him.',
    ),
    _ProphetStory(
      nameAr: 'زكريا عليه السلام',
      nameEn: 'Zakariya / Zechariah (peace be upon him)',
      bodyAr: 'كان كافلًا لمريم عليها السلام في المحراب، ودعا ربه أن يهب له ذرية طيبة رغم كبر سنه، فاستجاب الله له وبشّره بيحيى عليه السلام.',
      bodyEn: "Guardian of Maryam in the sanctuary. He prayed for righteous offspring despite his old age, and Allah answered him with the glad tidings of Yahya.",
    ),
    _ProphetStory(
      nameAr: 'يحيى عليه السلام',
      nameEn: 'Yahya / John (peace be upon him)',
      bodyAr: 'ابن زكريا عليه السلام، آتاه الله الحكم صبيًا، ووصفه القرآن بأنه كان عفيفًا زاهدًا وبرًّا بوالديه، وسلّم الله عليه يوم وُلد ويوم يموت ويوم يُبعث حيًا.',
      bodyEn: "Son of Zakariya. Allah gave him wisdom while still a boy, and the Quran describes him as chaste, devoted, and dutiful to his parents.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'قصص الأنبياء' : 'Stories of the Prophets'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final story in _stories)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? story.nameAr : story.nameEn,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryEmerald),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? story.bodyAr : story.bodyEn,
                      style: const TextStyle(fontSize: 14, height: 1.8),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              isAr
                  ? 'المصادر: القرآن الكريم، وقصص الأنبياء والبداية والنهاية لابن كثير، والسيرة النبوية لابن هشام. تم تجنّب الروايات الإسرائيلية غير الموثقة عمداً.'
                  : "Sources: the Quran, Ibn Kathir's Qasas al-Anbiya and Al-Bidaya wa'l-Nihaya, and Ibn Hisham's As-Seerah an-Nabawiyyah. Unverified Isra'iliyyat narrations were deliberately excluded.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
            ),
          ),
        ],
      )),
    );
  }
}

class _ProphetStory {
  final String nameAr;
  final String nameEn;
  final String bodyAr;
  final String bodyEn;

  const _ProphetStory({
    required this.nameAr,
    required this.nameEn,
    required this.bodyAr,
    required this.bodyEn,
  });
}
