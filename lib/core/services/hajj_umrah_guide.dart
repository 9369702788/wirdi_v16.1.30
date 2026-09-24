/// Step-by-step Hajj and Umrah guide with the recommended supplications
/// (duas) for each stage, summarized from mainstream, widely-taught
/// rulings. Duas are given in transliteration/English and in Arabic
/// exactly as commonly recited -- not reworded.
class HajjUmrahGuide {
  static const Map<String, dynamic> hajjSteps = {
    'ihram': {
      'type': 'both', 'step': 1, 'nameAr': 'الإحرام',
      'description':
          'Enter the state of Ihram at the designated Miqat boundary with the intention (niyyah) for Hajj or Umrah, wearing the two unstitched white garments (for men) and reciting the Talbiyah repeatedly until reaching the Kaaba.',
      'descriptionAr':
          'الدخول في نية الإحرام من الميقات المحدد قبل دخول حدود الحرم، بارتداء ثوبي الإحرام الأبيضين غير المخيطين (للرجال)، وتكرار التلبية باستمرار حتى الوصول إلى الكعبة.',
      'duas': ["Labbaik Allahumma Labbaik, Labbaik la sharika laka Labbaik, Innal-hamda wan-ni'mata laka wal-mulk, la sharika lak"],
      'duasAr': ['لبيك اللهم لبيك، لبيك لا شريك لك لبيك، إن الحمد والنعمة لك والملك، لا شريك لك'],
    },
    'tawaf': {
      'type': 'both', 'step': 2, 'nameAr': 'الطواف',
      'description':
          'Circumambulate the Kaaba seven times counter-clockwise, starting and ending at the Black Stone corner, ideally in a state of ritual purity (wudu). Men perform Idtiba (exposing the right shoulder) and Raml (brisk walking) in the first three rounds for Umrah or the arrival tawaf of Hajj.',
      'descriptionAr':
          'الطواف حول الكعبة المشرفة سبعة أشواط عكس اتجاه عقارب الساعة، بدءًا وانتهاءً من الحجر الأسود، ويُستحب أن يكون على طهارة. يُستحب للرجال الاضطباع (كشف الكتف الأيمن) والرَّمَل (الإسراع في المشي) في الأشواط الثلاثة الأولى في طواف العمرة أو طواف القدوم للحج.',
      'duas': ["Bismillahi, Allahu Akbar (said when passing the Black Stone each round)", "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar (recited between the Yemeni Corner and the Black Stone)"],
      'duasAr': ['بسم الله، والله أكبر (تُقال عند محاذاة الحجر الأسود في كل شوط)', 'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار (بين الركن اليماني والحجر الأسود)'],
    },
    'sai': {
      'type': 'both', 'step': 3, 'nameAr': 'السعي',
      'description':
          "Walk seven times between the hills of Safa and Marwa, starting at Safa and ending at Marwa, in remembrance of Hajar's search for water for her son Ismail. Men jog briskly between the two green markers.",
      'descriptionAr':
          'السعي بين جبلي الصفا والمروة سبعة أشواط، يبدأ من الصفا وينتهي بالمروة، تذكاراً لسعي هاجر عليها السلام بحثاً عن الماء لابنها إسماعيل. يُستحب للرجال الهرولة بين العلمين الأخضرين.',
      'duas': ["Innas-Safa wal-Marwata min sha'a'irillah (recited on approaching Safa)", "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa 'ala kulli shay'in qadeer (said atop Safa and Marwa, facing the Kaaba)"],
      'duasAr': ['إن الصفا والمروة من شعائر الله (تُقال عند الاقتراب من الصفا)', 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير (تُقال أعلى الصفا والمروة متجهاً للكعبة)'],
    },
    'waiting_mina': {
      'type': 'hajj', 'step': 4, 'nameAr': 'التوجه إلى منى (يوم التروية)',
      'description':
          'On the 8th of Dhul-Hijjah (Yawm at-Tarwiyah), Hajj pilgrims head to Mina and spend the day and night there, performing the five daily prayers shortened (but not combined) in preparation for the standing at Arafah.',
      'descriptionAr':
          'في اليوم الثامن من ذي الحجة (يوم التروية)، يتوجه حجاج الفريضة إلى منى ويمكثون فيها يومهم وليلتهم، ويؤدون الصلوات الخمس مقصورة (دون جمع) استعداداً للوقوف بعرفة.',
      'duas': [],
      'duasAr': [],
    },
    'arafah': {
      'type': 'hajj', 'step': 5, 'nameAr': 'الوقوف بعرفة',
      'description':
          'Stand at Mount Arafah from noon until sunset on the 9th of Dhul-Hijjah -- described by the Prophet as "Hajj is Arafah," and the single most essential pillar of Hajj without which it is not valid. This is the time for the most sincere, extended personal supplication of the year.',
      'descriptionAr':
          'الوقوف بعرفة من زوال الشمس إلى غروبها يوم 9 ذي الحجة -- وهو الركن الأعظم للحج كما قال النبي صلى الله عليه وسلم "الحج عرفة"، ولا يصح الحج بدونه. وهو أفضل وقت في العام للدعاء المطوّل الصادق.',
      'duas': ["La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa 'ala kulli shay'in qadeer (the best supplication of the Day of Arafah, as taught by the Prophet)"],
      'duasAr': ['لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير (خير الدعاء يوم عرفة كما علّم النبي صلى الله عليه وسلم)'],
    },
    'muzdalifah': {
      'type': 'hajj', 'step': 6, 'nameAr': 'المبيت بمزدلفة',
      'description':
          'After sunset, leave Arafah for Muzdalifah, combining Maghrib and Isha prayers there. Spend the night (or at least its latter part) and gather at least 49 pebbles for the stoning ritual over the following days.',
      'descriptionAr':
          'بعد غروب الشمس، الدفع من عرفة إلى مزدلفة، وجمع صلاتي المغرب والعشاء هناك. المبيت بمزدلفة (أو معظم الليل على الأقل) وجمع 49 حصاة على الأقل لرمي الجمرات في الأيام التالية.',
      'duas': ["Allahumma inni as'aluka min khayri ma sa'alaka minhu 'ibaduka as-saliheen (a general supplication for the sacred night)"],
      'duasAr': ['اللهم إني أسألك من خير ما سألك منه عبادك الصالحون (دعاء عام لهذه الليلة المباركة)'],
    },
    'ramy': {
      'type': 'hajj', 'step': 7, 'nameAr': 'رمي جمرة العقبة',
      'description':
          'On the 10th of Dhul-Hijjah (Eid al-Adha), stone the largest pillar (Jamrat al-Aqabah) with seven pebbles, saying "Allahu Akbar" with each throw -- marking the beginning of Tahallul (partial release from Ihram restrictions).',
      'descriptionAr':
          'في يوم النحر (10 ذي الحجة)، رمي جمرة العقبة الكبرى بسبع حصيات، قائلاً "الله أكبر" مع كل حصاة -- وهو بداية التحلل الأصغر من محظورات الإحرام.',
      'duas': ['Allahu Akbar (said with each of the seven pebbles thrown)'],
      'duasAr': ['الله أكبر (تُقال مع كل حصاة من الحصيات السبع)'],
    },
    'hady': {
      'type': 'hajj', 'step': 8, 'nameAr': 'الهدي (الذبح)',
      'description':
          "Slaughter a sacrificial animal (Hady) on the 10th of Dhul-Hijjah, obligatory for those performing Hajj at-Tamattu' or al-Qiran, commemorating Ibrahim's willingness to sacrifice his son. The meat is distributed to the poor.",
      'descriptionAr':
          'ذبح الهدي يوم النحر (10 ذي الحجة)، وهو واجب على من أدى حج التمتع أو القران، إحياءً لذكرى استعداد إبراهيم عليه السلام لذبح ابنه. يُوزَّع اللحم على الفقراء والمساكين.',
      'duas': ['Bismillahi wallahu akbar, Allahumma hadha minka wa laka (said before slaughtering)'],
      'duasAr': ['بسم الله والله أكبر، اللهم هذا منك ولك (تُقال قبل الذبح)'],
    },
    'halq_taqsir': {
      'type': 'both', 'step': 9, 'nameAr': 'الحلق أو التقصير',
      'description':
          'Shave the head completely (Halq, preferred and more rewarded for men) or trim the hair (Taqsir), completing the greater Tahallul when combined with the pillar Tawaf. Women only trim a fingertip-length of hair.',
      'descriptionAr':
          'حلق الرأس بالكامل (الحلق أفضل وأعظم أجراً للرجال) أو تقصير الشعر، ويكتمل به التحلل الأكبر إذا اقترن بطواف الإفاضة. أما النساء فيقصّرن قدر أنملة من شعرهن فقط.',
      'duas': [],
      'duasAr': [],
    },
    'tawaf_ifadah': {
      'type': 'hajj', 'step': 10, 'nameAr': 'طواف الإفاضة',
      'description':
          'Perform the obligatory pillar Tawaf (Tawaf al-Ifadah) around the Kaaba, ideally on the 10th of Dhul-Hijjah or within the following days, followed by Sai if it was not already completed for this Hajj. This tawaf, combined with Halq/Taqsir, completes the full release from Ihram.',
      'descriptionAr':
          'أداء طواف الإفاضة، وهو ركن الحج الذي لا يصح الحج بدونه، ويُستحب يوم النحر أو في الأيام التالية له، ويتبعه السعي إن لم يكن قد أُدي من قبل في هذا الحج. يكتمل به مع الحلق أو التقصير التحلل الكامل من الإحرام.',
      'duas': [],
      'duasAr': [],
    },
    'tashreeq': {
      'type': 'hajj', 'step': 11, 'nameAr': 'أيام التشريق',
      'description':
          'Stay in Mina during the Days of Tashreeq (11th-13th of Dhul-Hijjah), stoning all three pillars (small, medium, and largest) each day after noon with seven pebbles each, saying "Allahu Akbar" with every throw.',
      'descriptionAr':
          'المكوث في منى خلال أيام التشريق (11-13 ذي الحجة)، ورمي الجمرات الثلاث (الصغرى والوسطى والكبرى) كل يوم بعد الزوال بسبع حصيات لكل جمرة، قائلاً "الله أكبر" مع كل حصاة.',
      'duas': ["Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar (recited after stoning the small and medium pillars, facing the Qiblah)"],
      'duasAr': ['ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار (تُقال بعد رمي الجمرتين الصغرى والوسطى، مستقبلاً القبلة)'],
    },
    'tawaf_wada': {
      'type': 'both', 'step': 12, 'nameAr': 'طواف الوداع',
      'description':
          'Perform the Farewell Tawaf (Tawaf al-Wada) around the Kaaba as the very last act before leaving Mecca, obligatory for pilgrims from outside the Haram (not required for women in their menstrual period). This marks the conclusion of the Hajj journey.',
      'descriptionAr':
          'أداء طواف الوداع حول الكعبة كآخر عمل قبل مغادرة مكة، وهو واجب على الحجاج من غير أهل الحرم (ولا يجب على الحائض). وبه تُختتم رحلة الحج.',
      'duas': [],
      'duasAr': [],
    },
  };
}
