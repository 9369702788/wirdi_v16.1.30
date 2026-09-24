class IslamicHistoryEvent {
  final int year;
  final String yearAH;
  final String event;
  final String eventAr;
  final String description;
  final String descriptionAr;

  const IslamicHistoryEvent({
    required this.year, required this.yearAH, required this.event, required this.eventAr,
    required this.description, required this.descriptionAr,
  });
}

/// A curated timeline of major early-Islamic events, summarized mainly
/// from Ibn Hisham's seerah, At-Tabari's history, and Ibn Kathir's
/// Al-Bidaya wa'l-Nihaya -- widely accepted classical references.
class IslamicHistoryService {
  static const List<IslamicHistoryEvent> timeline = [
    IslamicHistoryEvent(
      year: 610, yearAH: 'Before Hijra',
      event: 'Beginning of Revelation', eventAr: 'بداية الوحي',
      description:
          'At the age of forty, while in retreat in the Cave of Hira, Prophet Muhammad received the first revelation through the angel Jibreel, opening with the command "Read in the name of your Lord who created." This marked the start of twenty-three years of revelation that would become the Quran, and the beginning of his mission calling people to the worship of Allah alone.',
      descriptionAr:
          'وهو في الأربعين من عمره، وبينما هو متعبّد في غار حراء، نزل عليه الوحي لأول مرة على يد الملَك جبريل عليه السلام بقوله "اقرأ باسم ربك الذي خلق". كانت هذه بداية ثلاث وعشرين سنة من نزول القرآن الكريم، وبداية مهمته في دعوة الناس إلى توحيد الله.',
    ),
    IslamicHistoryEvent(
      year: 613, yearAH: 'Before Hijra',
      event: 'Public Call to Islam', eventAr: 'الجهر بالدعوة',
      description:
          'After three years of quiet, private invitation among close family and friends, the Prophet was commanded to publicly proclaim his message on Mount Safa. This open call provoked fierce opposition from Quraysh, who saw it as a threat to their social order and the profitable pilgrimage trade tied to their idols, beginning years of persecution against the early Muslims.',
      descriptionAr:
          'بعد ثلاث سنوات من الدعوة السرية بين المقربين، أُمر النبي صلى الله عليه وسلم بالجهر بدعوته على جبل الصفا. أثار هذا الإعلان العلني معارضة شديدة من قريش التي رأت في الدعوة تهديداً لنظامها الاجتماعي وتجارة الحج المرتبطة بأصنامها، فبدأت سنوات من اضطهاد المسلمين الأوائل.',
    ),
    IslamicHistoryEvent(
      year: 622, yearAH: '1 AH',
      event: 'The Hijra', eventAr: 'الهجرة النبوية',
      description:
          "Facing an assassination plot and unrelenting persecution, the Prophet and his companion Abu Bakr migrated from Mecca to Medina, whose people had pledged support. This migration established the first organized Islamic community and state, and later became the starting point of the Islamic (Hijri) calendar under Caliph Umar ibn al-Khattab.",
      descriptionAr:
          'أمام مؤامرة اغتيال واضطهاد مستمر، هاجر النبي صلى الله عليه وسلم وصاحبه أبو بكر من مكة إلى المدينة التي بايعه أهلها على النصرة. أسّست هذه الهجرة أول مجتمع ودولة إسلامية منظمة، وصارت لاحقاً بداية التقويم الهجري في عهد الخليفة عمر بن الخطاب رضي الله عنه.',
    ),
    IslamicHistoryEvent(
      year: 624, yearAH: '2 AH',
      event: 'Battle of Badr', eventAr: 'غزوة بدر',
      description:
          "The first major military engagement between the roughly 300 Muslims of Medina and the far larger Quraysh army of Mecca. Despite being heavily outnumbered, the Muslims won a decisive victory, which strengthened the fledgling Islamic state's standing and is remembered as a defining moment of faith and divine support.",
      descriptionAr:
          'أول معركة كبرى بين نحو ثلاثمائة مسلم من المدينة وجيش قريش الأكبر عدداً من مكة. رغم قلة العدد، حقق المسلمون نصراً حاسماً عزّز مكانة الدولة الإسلامية الوليدة، وتُذكر هذه الغزوة كلحظة فارقة في الإيمان والتأييد الإلهي.',
    ),
    IslamicHistoryEvent(
      year: 625, yearAH: '3 AH',
      event: 'Battle of Uhud', eventAr: 'غزوة أُحد',
      description:
          "Quraysh returned seeking revenge for Badr. A tactical error by archers who left their post led to a reversal of Muslim fortunes and the martyrdom of seventy companions, including the Prophet's uncle Hamza. The battle taught enduring lessons about discipline, obedience to leadership, and steadfastness after setbacks.",
      descriptionAr:
          'عادت قريش للثأر من هزيمة بدر. أدى خطأ تكتيكي من الرماة الذين تركوا موقعهم إلى انقلاب موازين المعركة واستشهاد سبعين من الصحابة، منهم عم النبي حمزة رضي الله عنه. علّمت الغزوة دروساً خالدة في الانضباط وطاعة القيادة والثبات بعد النكسات.',
    ),
    IslamicHistoryEvent(
      year: 627, yearAH: '5 AH',
      event: 'Battle of the Trench', eventAr: 'غزوة الخندق',
      description:
          "A coalition of Quraysh and allied tribes besieged Medina, but the Muslims -- on the suggestion of Salman al-Farisi -- dug a defensive trench, a tactic unknown to the Arabs at the time. The siege failed after a harsh storm scattered the confederate army, marking a lasting shift in the balance of power toward the Muslims.",
      descriptionAr:
          'حاصر تحالف من قريش وقبائل حليفة المدينة، لكن المسلمين -- باقتراح من سلمان الفارسي -- حفروا خندقاً دفاعياً، وهي تقنية لم تعرفها العرب من قبل. فشل الحصار بعد أن فرّقت عاصفة شديدة جيش الأحزاب، مما أحدث تحوّلاً دائماً في ميزان القوى لصالح المسلمين.',
    ),
    IslamicHistoryEvent(
      year: 628, yearAH: '6 AH',
      event: 'Treaty of Hudaybiyyah', eventAr: 'صلح الحديبية',
      description:
          "A ten-year peace treaty between the Muslims and Quraysh that appeared unfavorable on its surface, yet the Quran described it as a clear victory. The resulting calm allowed Islam to spread peacefully, and more people accepted it in the following two years than in all the years before combined.",
      descriptionAr:
          'صلح مدته عشر سنوات بين المسلمين وقريش بدا في ظاهره مجحفاً، لكن القرآن وصفه بـ"الفتح المبين". أتاح الهدوء الناتج انتشار الإسلام سلماً، ودخل فيه خلال السنتين التاليتين أكثر ممن دخلوا في كل السنوات السابقة مجتمعة.',
    ),
    IslamicHistoryEvent(
      year: 630, yearAH: '8 AH',
      event: 'Conquest of Mecca', eventAr: 'فتح مكة',
      description:
          "After Quraysh broke the Hudaybiyyah treaty, the Prophet marched on Mecca with a large army and entered it almost without bloodshed, granting a general amnesty to those who had persecuted the Muslims for two decades. He then removed the idols surrounding the Kaaba, restoring it to the monotheistic worship established by Ibrahim.",
      descriptionAr:
          'بعد نقض قريش لصلح الحديبية، سار النبي صلى الله عليه وسلم إلى مكة بجيش كبير ودخلها بلا قتال يُذكر، وعفا عفواً عاماً عمّن اضطهد المسلمين عشرين عاماً. ثم أزال الأصنام المحيطة بالكعبة، مُعيداً إياها إلى التوحيد الذي أسّسه إبراهيم عليه السلام.',
    ),
    IslamicHistoryEvent(
      year: 632, yearAH: '10 AH',
      event: 'The Farewell Pilgrimage', eventAr: 'حجة الوداع',
      description:
          "The Prophet's only pilgrimage after the Hijra, attended by over a hundred thousand Muslims, where he delivered his Farewell Sermon establishing timeless principles of justice, equality, and the sanctity of life and property, and confirmed that the message of Islam had been completed.",
      descriptionAr:
          'حجة النبي صلى الله عليه وسلم الوحيدة بعد الهجرة، حضرها أكثر من مائة ألف مسلم، وألقى فيها خطبة الوداع التي أرست مبادئ خالدة في العدل والمساواة وحرمة الدماء والأموال، وأكّدت اكتمال رسالة الإسلام.',
    ),
    IslamicHistoryEvent(
      year: 632, yearAH: '11 AH',
      event: "The Prophet's Passing and Abu Bakr's Caliphate", eventAr: 'وفاة النبي وخلافة أبي بكر',
      description:
          "The Prophet passed away in Medina a few months after the Farewell Pilgrimage. The Muslim community chose Abu Bakr as-Siddiq as the first caliph, who firmly held the nation together through the Ridda wars (the apostasy wars) against tribes that refused to pay zakat or claimed false prophethood after the Prophet's death.",
      descriptionAr:
          'توفي النبي صلى الله عليه وسلم في المدينة بعد أشهر قليلة من حجة الوداع. اختارت الأمة أبا بكر الصديق خليفة أول، فحافظ بحزم على وحدة الأمة خلال حروب الردة ضد قبائل رفضت الزكاة أو ادّعت النبوة زوراً بعد وفاة النبي.',
    ),
    IslamicHistoryEvent(
      year: 633, yearAH: '12 AH',
      event: 'Compilation of the Quran', eventAr: 'جمع القرآن الكريم',
      description:
          "Following the deaths of many companions who had memorized the Quran in the Battle of Yamama, Abu Bakr ordered the Quran compiled into a single written copy under Zayd ibn Thabit's supervision. Decades later, Caliph Uthman ibn Affan had standardized copies distributed to major cities to preserve one unified text and recitation.",
      descriptionAr:
          'بعد استشهاد عدد كبير من حفظة القرآن في معركة اليمامة، أمر أبو بكر الصديق بجمع القرآن في مصحف واحد بإشراف زيد بن ثابت. وبعد عقود، أمر الخليفة عثمان بن عفان بنسخ مصاحف موحّدة ووزّعها على الأمصار الكبرى للحفاظ على نص وقراءة موحّدة.',
    ),
    IslamicHistoryEvent(
      year: 636, yearAH: '15 AH',
      event: 'Battle of Yarmouk', eventAr: 'معركة اليرموك',
      description:
          "A decisive battle in the Levant between the Muslim army led by Khalid ibn al-Walid and the Byzantine Empire. The Muslim victory ended centuries of Byzantine rule over the region and opened the way for the rapid early expansion of the Islamic state under the Rightly-Guided Caliphs.",
      descriptionAr:
          'معركة فاصلة في بلاد الشام بين الجيش الإسلامي بقيادة خالد بن الوليد والإمبراطورية البيزنطية. أنهى النصر الإسلامي قروناً من الحكم البيزنطي للمنطقة، وفتح الطريق أمام التوسع السريع للدولة الإسلامية في عهد الخلفاء الراشدين.',
    ),
    IslamicHistoryEvent(
      year: 636, yearAH: '15 AH',
      event: 'Battle of Qadisiyyah', eventAr: 'معركة القادسية',
      description: 'A decisive battle between the Rashidun army led by Sa\'d ibn Abi Waqqas and the Sasanian Persian Empire in Iraq. The Muslim victory broke the power of the Persian army and opened the way for the later conquest of the Persian heartland.',
      descriptionAr: 'معركة فاصلة بين جيش الخلافة الراشدة بقيادة سعد بن أبي وقاص والإمبراطورية الفارسية الساسانية في العراق. أدى النصر الإسلامي إلى كسر شوكة الجيش الفارسي وفتح الطريق لاحقًا لفتح بلاد فارس.',
    ),
    IslamicHistoryEvent(
      year: 637, yearAH: '16 AH',
      event: 'Conquest of Jerusalem', eventAr: 'فتح بيت المقدس',
      description: 'Caliph Umar ibn al-Khattab personally traveled to receive the surrender of Jerusalem, granting its Christian inhabitants a covenant of safety for their lives, property, and places of worship -- known as the Umariyya Covenant.',
      descriptionAr: 'سافر الخليفة عمر بن الخطاب بنفسه لاستلام مفاتيح بيت المقدس، وأعطى أهلها من النصارى عهدًا بالأمان على أنفسهم وأموالهم وكنائسهم، عُرف بالعهدة العمرية.',
    ),
    IslamicHistoryEvent(
      year: 644, yearAH: '23 AH',
      event: 'Assassination of Umar and Start of Uthman\'s Caliphate', eventAr: 'استشهاد عمر وخلافة عثمان',
      description: 'Caliph Umar ibn al-Khattab was stabbed by a Persian slave, Abu Lu\'lu\'a, while leading the dawn prayer, and died days later. A consultative council (Shura) he had appointed selected Uthman ibn Affan as the third caliph.',
      descriptionAr: 'طُعن الخليفة عمر بن الخطاب من قبل أبي لؤلؤة المجوسي وهو يؤم الناس في صلاة الفجر، وتوفي بعدها بأيام. اختار مجلس الشورى الذي عيّنه عثمان بن عفان خليفةً ثالثًا.',
    ),
    IslamicHistoryEvent(
      year: 653, yearAH: '30 AH',
      event: 'Standardization of the Quranic Text', eventAr: 'توحيد المصحف العثماني',
      description: 'To prevent disputes over recitation as Islam spread among non-Arabic speakers, Caliph Uthman commissioned a committee to produce standardized master copies of the Quran based on the compilation made under Abu Bakr, sending them to the major Muslim cities.',
      descriptionAr: 'لمنع الاختلاف في القراءة مع اتساع رقعة الإسلام بين غير الناطقين بالعربية، كلّف الخليفة عثمان لجنة بنسخ مصاحف موحّدة اعتمادًا على الجمع الذي تم في عهد أبي بكر، وأرسلها إلى الأمصار الإسلامية الكبرى.',
    ),
    IslamicHistoryEvent(
      year: 656, yearAH: '35 AH',
      event: 'Assassination of Uthman and Start of the First Fitna', eventAr: 'استشهاد عثمان وبداية الفتنة الكبرى',
      description: 'Caliph Uthman ibn Affan was killed by rebels in his own home, marking the start of a period of internal conflict among Muslims known as the First Fitna. Ali ibn Abi Talib was chosen as the fourth caliph amid the ensuing turmoil.',
      descriptionAr: 'قُتل الخليفة عثمان بن عفان على يد ثوار داخل بيته، وكان ذلك بداية فترة من الصراع الداخلي بين المسلمين عُرفت بالفتنة الكبرى. بويع علي بن أبي طالب خليفةً رابعًا في خضم هذه الاضطرابات.',
    ),
    IslamicHistoryEvent(
      year: 661, yearAH: '40 AH',
      event: 'Assassination of Ali and Start of the Umayyad Dynasty', eventAr: 'استشهاد علي وقيام الدولة الأموية',
      description: 'Caliph Ali ibn Abi Talib was assassinated by a Kharijite in Kufa, ending the era of the Rightly-Guided Caliphs. Muawiyah ibn Abi Sufyan then established the Umayyad Caliphate, moving the capital to Damascus.',
      descriptionAr: 'استُشهد الخليفة علي بن أبي طالب على يد أحد الخوارج في الكوفة، لتنتهي بذلك مرحلة الخلافة الراشدة. أسّس معاوية بن أبي سفيان بعدها الدولة الأموية، ونقل مركز الخلافة إلى دمشق.',
    ),
    IslamicHistoryEvent(
      year: 750, yearAH: '132 AH',
      event: 'Establishment of the Abbasid Caliphate', eventAr: 'قيام الدولة العباسية',
      description: 'The Abbasid revolution overthrew the Umayyad dynasty and established a new caliphate that would move the capital to the newly-founded city of Baghdad, ushering in what is often called the Islamic Golden Age of science, philosophy, and culture.',
      descriptionAr: 'أطاحت الثورة العباسية بالدولة الأموية وأسّست خلافة جديدة نقلت مركزها لاحقًا إلى مدينة بغداد المُنشأة حديثًا، لتبدأ مرحلة يُطلق عليها كثيرًا "العصر الذهبي" للعلوم والفلسفة والثقافة الإسلامية.',
    ),
    IslamicHistoryEvent(
      year: 832, yearAH: '217 AH',
      event: 'Founding of the House of Wisdom in Baghdad', eventAr: 'تأسيس بيت الحكمة في بغداد',
      description: 'Caliph Al-Ma\'mun formally established Bayt al-Hikma as a major center for the translation of Greek, Persian, and Indian scientific and philosophical works into Arabic, along with original research, becoming one of the most important intellectual institutions of the medieval world.',
      descriptionAr: 'أسّس الخليفة المأمون رسميًا بيت الحكمة كمركز كبير لترجمة الأعمال العلمية والفلسفية اليونانية والفارسية والهندية إلى العربية، إلى جانب البحث العلمي الأصيل، ليصبح من أهم المؤسسات الفكرية في العالم في العصور الوسطى.',
    ),
  ];

  static List<IslamicHistoryEvent> getTimelineEvents() {
    return timeline;
  }
}
