/// Key milestones of the Prophet Muhammad's (peace be upon him) life,
/// summarized primarily from Ibn Hisham's "As-Seerah an-Nabawiyyah" and
/// Safiur-Rahman al-Mubarakpuri's "Ar-Raheeq al-Makhtum" (The Sealed
/// Nectar) -- two of the most widely referenced seerah works.
class ProphetBiographyMilestone {
  final int year;
  final String hijriNote;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;

  const ProphetBiographyMilestone({
    required this.year,
    required this.hijriNote,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
  });
}

class ProphetBiography {
  ProphetBiography._();

  static const List<ProphetBiographyMilestone> milestones = [
    ProphetBiographyMilestone(
      year: 570,
      hijriNote: 'عام الفيل',
      titleAr: 'المولد والنشأة',
      titleEn: 'Birth and Early Life',
      bodyAr:
          'وُلد النبي محمد صلى الله عليه وسلم في مكة المكرمة عام الفيل، من قبيلة قريش وبيت بني هاشم الشريف. توفي أبوه عبد الله قبل ولادته، وأرضعته حليمة السعدية في بادية بني سعد كعادة أشراف قريش، ثم توفيت أمه آمنة وهو ابن ست سنين فكفله جده عبد المطلب، ثم عمه أبو طالب بعد وفاة جده. نشأ يتيماً معروفاً بين قومه بالصدق والأمانة حتى لُقّب بـ"الصادق الأمين" قبل البعثة بسنين طويلة، وعمل بالتجارة ثم تزوج خديجة بنت خويلد رضي الله عنها.',
      bodyEn:
          "Prophet Muhammad (peace be upon him) was born in Mecca in the Year of the Elephant, into the tribe of Quraysh and the noble house of Banu Hashim. His father Abdullah died before his birth. Following Quraysh custom for noble families, he was nursed in his infancy by Halima as-Sa'diyyah in the desert among Banu Sa'd. His mother Amina died when he was six, so his grandfather Abdul-Muttalib took him in, followed by his uncle Abu Talib after the grandfather's death. He grew up an orphan known among his people for such honesty and trustworthiness that he was called 'The Truthful, The Trustworthy' years before his prophethood, worked in trade, and later married Khadijah bint Khuwaylid.",
    ),
    ProphetBiographyMilestone(
      year: 610,
      hijriNote: 'قبل الهجرة',
      titleAr: 'بدء الوحي',
      titleEn: 'The Beginning of Revelation',
      bodyAr:
          'وهو في الأربعين من عمره، كان صلى الله عليه وسلم يتحنّث ويتعبّد في غار حراء بعيداً عن ضجيج مكة، حتى فاجأه الملَك جبريل عليه السلام فقال له "اقرأ" فأجابه "ما أنا بقارئ" ثلاث مرات، ثم تلا عليه أول آيات القرآن: "اقرأ باسم ربك الذي خلق". عاد مرتجفاً إلى خديجة فطمأنته وذهبت به إلى ابن عمها ورقة بن نوفل الذي بشّره بأنه نبي هذه الأمة. انقطع الوحي فترة (فترة الوحي) قبل أن يتوالى نزول القرآن ويبدأ عهد الدعوة السرية بين المقربين.',
      bodyEn:
          'At the age of forty, while retreating in worship and contemplation in the Cave of Hira away from the noise of Mecca, he was suddenly approached by the angel Jibreel (Gabriel), who commanded him "Read!" He replied "I cannot read" three times, after which Jibreel recited the first verses of the Quran to be revealed: "Read in the name of your Lord who created." He returned home trembling; Khadijah comforted him and took him to her cousin Waraqah ibn Nawfal, who recognized him as the awaited prophet of this nation. Revelation then paused for a period before resuming steadily, marking the start of a quiet, private phase of calling those closest to him to Islam.',
    ),
    ProphetBiographyMilestone(
      year: 622,
      hijriNote: '1 هـ',
      titleAr: 'الهجرة إلى المدينة',
      titleEn: 'The Hijra to Medina',
      bodyAr:
          'بعد ثلاث عشرة سنة من الدعوة في مكة، اشتد أذى قريش للمسلمين حتى قرروا اغتيال النبي صلى الله عليه وسلم، فأذن الله له بالهجرة إلى يثرب (المدينة المنورة) التي بايعه أهلها على نصرته. هاجر مع صاحبه أبي بكر الصديق رضي الله عنه واختبآ في غار ثور ثلاثة أيام قبل أن يتابعا الطريق، بينما نام علي بن أبي طالب في فراش النبي ليخذل الكفار عن تتبعه. بوصوله إلى المدينة أسّس أول دولة إسلامية، وآخى بين المهاجرين والأنصار، وبنى المسجد النبوي، وصار هذا الحدث بداية للتقويم الهجري.',
      bodyEn:
          "After thirteen years of calling people to Islam in Mecca, persecution by Quraysh intensified until they plotted to assassinate him, so Allah permitted him to migrate to Yathrib (later called Medina), whose people had pledged to support and protect him. He migrated with his companion Abu Bakr as-Siddiq, hiding for three days in the Cave of Thawr before continuing the journey, while Ali ibn Abi Talib slept in the Prophet's bed to mislead those hunting him. Upon arriving in Medina, he established the first Islamic state, forged a bond of brotherhood between the Meccan emigrants (Muhajirun) and Medinan helpers (Ansar), built the Prophet's Mosque, and this migration became the starting point of the Islamic (Hijri) calendar.",
    ),
    ProphetBiographyMilestone(
      year: 624,
      hijriNote: '2 هـ',
      titleAr: 'غزوة بدر الكبرى',
      titleEn: 'The Battle of Badr',
      bodyAr:
          'أول معركة كبرى بين المسلمين وقريش، خرج فيها النبي صلى الله عليه وسلم في نحو ثلاثمائة وبضعة عشر رجلاً لاعتراض قافلة تجارية لقريش، فخرجت قريش بجيش يفوقهم عدداً وعتاداً بلغ نحو ألف مقاتل لحماية القافلة والدفاع عن كبريائها. دعا النبي ربه دعاءً بليغاً طلب فيه النصر، فأنزل الله ملائكة تُثبّت المؤمنين، وانتهت المعركة بنصر ساحق للمسلمين رغم قلة عددهم، وقُتل من صناديد قريش من قُتل وأُسر من أُسر. سُمّي هذا اليوم "يوم الفرقان" لأنه فرّق بين الحق والباطل، وكان نقطة تحول رفعت من هيبة الدولة الإسلامية الوليدة.',
      bodyEn:
          'The first major battle between the Muslims and Quraysh. The Prophet set out with roughly three hundred men to intercept a Quraysh trade caravan, but Quraysh instead marched out with an army of around a thousand men to defend their caravan and their pride. He made an earnest, humble supplication for victory, and Allah sent down angels to steady the believers; the battle ended in a decisive Muslim victory despite being vastly outnumbered, with several prominent Quraysh leaders killed or captured. This day became known as "the Day of Criterion," since it distinguished truth from falsehood, and it marked a turning point that established the standing of the young Muslim state.',
    ),
    ProphetBiographyMilestone(
      year: 625,
      hijriNote: '3 هـ',
      titleAr: 'غزوة أُحد',
      titleEn: 'The Battle of Uhud',
      bodyAr:
          'خرجت قريش بجيش كبير لتثأر لهزيمة بدر، فخرج النبي صلى الله عليه وسلم لملاقاتهم عند جبل أحد بعد مشورة أصحابه، ووضع خمسين رامياً على جبل صغير وأمرهم بعدم مغادرة موقعهم مهما حدث. بدأ القتال لصالح المسلمين، لكن حين ظنّ الرماة أن المعركة انتهت غادر أغلبهم موقعهم طلباً للغنيمة، فالتفّ خالد بن الوليد (وكان حينها على الشرك) بفرسانه من خلفهم فانقلبت الدائرة على المسلمين، وأُصيب النبي صلى الله عليه وسلم واستُشهد سبعون من الصحابة منهم عمّه حمزة رضي الله عنه. كانت الغزوة درساً عظيماً في طاعة أوامر القيادة وعدم التعجّل بالغنيمة.',
      bodyEn:
          "Quraysh marched out with a large army seeking revenge for their defeat at Badr. The Prophet went out to meet them near Mount Uhud after consulting his companions, positioning fifty archers on a small hill and commanding them firmly not to leave their post under any circumstance. The battle initially favored the Muslims, but when most of the archers believed victory was secured and left their position to gather spoils, Khalid ibn al-Walid (still a polytheist at the time) led his cavalry around to attack from the rear, turning the tide against the Muslims. The Prophet himself was wounded, and seventy companions were martyred, including his uncle Hamzah. The battle remains a profound lesson in obeying leadership and resisting the temptation of premature gain.",
    ),
    ProphetBiographyMilestone(
      year: 627,
      hijriNote: '5 هـ',
      titleAr: 'غزوة الخندق (الأحزاب)',
      titleEn: 'The Battle of the Trench (Al-Ahzab)',
      bodyAr:
          'تحالفت قريش مع قبائل أخرى وبعض يهود بني النضير المنفيين لتجمع أحزاباً كثيرة قصدت استئصال المسلمين في المدينة، فاقترح سلمان الفارسي رضي الله عنه -- بخبرته الفارسية -- حفر خندق حول المدينة لم تعرفه العرب من قبل، فحفره المسلمون جميعاً بمن فيهم النبي صلى الله عليه وسلم. حاصر الأحزاب المدينة أياماً طويلة عجزوا فيها عن اقتحام الخندق، وأرسل الله عليهم ريحاً شديدة باردة قلبت خيامهم وأطفأت نيرانهم، فتفرقوا منهزمين من غير قتال يُذكر، وقال النبي صلى الله عليه وسلم بعدها "الآن نغزوهم ولا يغزوننا" إيذاناً بتحوّل ميزان القوة لصالح المسلمين.',
      bodyEn:
          "Quraysh allied with other tribes and some exiled members of Banu an-Nadir to form a large confederation aiming to eliminate the Muslims in Medina. The companion Salman al-Farisi, drawing on Persian military knowledge unfamiliar to the Arabs, suggested digging a trench around the city, which the Muslims -- including the Prophet himself -- dug together. The confederate forces besieged Medina for many days but could not cross the trench; Allah then sent a fierce, cold wind that overturned their tents and extinguished their fires, and they dispersed in defeat with almost no direct fighting. Afterward the Prophet remarked, 'Now we will raid them, and they will not raid us,' signaling a decisive shift in the balance of power toward the Muslims.",
    ),
    ProphetBiographyMilestone(
      year: 628,
      hijriNote: '6 هـ',
      titleAr: 'صلح الحديبية',
      titleEn: 'The Treaty of Hudaybiyyah',
      bodyAr:
          'خرج النبي صلى الله عليه وسلم بأصحابه معتمرين محرمين لا يريدون قتالاً، فمنعتهم قريش من دخول مكة، فتفاوض الطرفان عند الحديبية وانتهى الأمر بصلح بدا في ظاهره مجحفاً بحق المسلمين -- كأن يُعاد من أسلم من مكة إلى قريش دون العكس، وأن يرجع المسلمون هذا العام دون أداء العمرة -- حتى غضب بعض الصحابة، لكن النبي صلى الله عليه وسلم صبر وأطاع أمر الله. أنزل الله بعدها سورة الفتح ووصف الصلح بـ"الفتح المبين"، إذ هيّأ عشر سنوات من الهدنة أتاحت للدعوة الإسلامية الانتشار بسلام حتى دخل في تلك المدة في الإسلام أكثر ممن دخلوا في كل السنوات السابقة مجتمعة.',
      bodyEn:
          'The Prophet set out with his companions in the state of pilgrim consecration, intending only to perform Umrah peacefully, but Quraysh barred them from entering Mecca. Negotiations at Hudaybiyyah resulted in a treaty that appeared, on its surface, unfavorable to the Muslims -- such as returning any Meccan who embraced Islam and fled to Medina, while Quraysh had no reciprocal obligation, and the Muslims had to return home that year without completing Umrah. Some companions were troubled by these terms, yet the Prophet remained patient and obeyed Allah\'s command. Allah then revealed Surah Al-Fath, describing the treaty as "a clear victory," since the resulting ten-year truce allowed Islam to spread peacefully -- more people accepted Islam in that period than in all the years before it combined.',
    ),
    ProphetBiographyMilestone(
      year: 630,
      hijriNote: '8 هـ',
      titleAr: 'فتح مكة',
      titleEn: 'The Conquest of Mecca',
      bodyAr:
          'نقضت قريش صلح الحديبية بمساعدة حلفائها ضد حلفاء المسلمين، فخرج النبي صلى الله عليه وسلم بجيش ضخم بلغ نحو عشرة آلاف مقاتل ودخل مكة فاتحاً بلا قتال يُذكر، وأمر جنوده ألا يُقاتلوا إلا من قاتلهم. عفا عفواً عاماً عن أهل مكة الذين آذوه وأصحابه عشرين عاماً قائلاً "اذهبوا فأنتم الطلقاء"، وطاف بالكعبة وحطّم الأصنام المحيطة بها وهو يتلو "جاء الحق وزهق الباطل إن الباطل كان زهوقاً". كان الفتح تتويجاً لسنوات الصبر والدعوة، ودخل الناس بعده في دين الله أفواجاً.',
      bodyEn:
          'Quraysh broke the Treaty of Hudaybiyyah by helping their allies attack the Muslims\' allies, so the Prophet marched on Mecca with a massive army of roughly ten thousand men and entered the city as a conqueror with almost no fighting, instructing his soldiers to fight only those who fought them. He granted a general amnesty to the people of Mecca who had persecuted him and his companions for twenty years, declaring, "Go, for you are free." He then circled the Kaaba, removed the idols surrounding it, reciting, "Truth has come, and falsehood has departed; indeed, falsehood is bound to depart." The conquest crowned years of patience and outreach, and afterward people entered the religion of Allah in large numbers.',
    ),
    ProphetBiographyMilestone(
      year: 632,
      hijriNote: '10 هـ',
      titleAr: 'حجة الوداع ووفاة النبي',
      titleEn: "The Farewell Pilgrimage and the Prophet's Passing",
      bodyAr:
          'حج النبي صلى الله عليه وسلم حجته الوحيدة بعد الهجرة برفقة أكثر من مائة ألف من أصحابه، وألقى فيها خطبته المشهورة بخطبة الوداع التي أرسى فيها مبادئ عظيمة: حرمة الدماء والأموال، والمساواة بين الناس "لا فضل لعربي على عجمي إلا بالتقوى"، وحسن معاملة النساء، والتمسك بكتاب الله وسنته، وسأل أصحابه "ألا هل بلّغت؟" فقالوا نعم فقال "اللهم فاشهد". نزلت بعدها آية "اليوم أكملت لكم دينكم"، ثم توفي صلى الله عليه وسلم بعد أشهر قليلة في المدينة المنورة، تاركاً أمة عظيمة ورسالة خالدة، ودُفن في حجرة عائشة رضي الله عنها المتصلة بالمسجد النبوي.',
      bodyEn:
          'The Prophet performed his only pilgrimage after the Hijra, accompanied by more than a hundred thousand companions, and delivered his famous Farewell Sermon, establishing enduring principles: the sanctity of life and property, human equality -- "no Arab has superiority over a non-Arab except by piety" -- kindness toward women, and holding fast to the Book of Allah and his teachings. He asked his companions, "Have I conveyed the message?" and when they affirmed it, he said, "O Allah, bear witness." Shortly after, the verse "This day I have perfected for you your religion" was revealed. A few months later he passed away in Medina, leaving behind a great nation and an enduring message, and was buried in the room of his wife Aisha, adjoining the Prophet\'s Mosque.',
    ),
  ];
}
