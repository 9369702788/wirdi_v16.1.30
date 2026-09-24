class IslamicHistoricalEvent {
  final String name;
  final String nameAr;
  final String hijriDate;
  final String description;
  final String descriptionAr;

  const IslamicHistoricalEvent({
    required this.name,
    required this.nameAr,
    required this.hijriDate,
    required this.description,
    required this.descriptionAr,
  });
}

/// Recurring Islamic occasions throughout the Hijri year, with their
/// historical origin, virtues, and commonly recommended practices.
class IslamicEventsService {
  static const List<IslamicHistoricalEvent> events = [
    IslamicHistoricalEvent(
      name: 'Islamic New Year',
      nameAr: 'رأس السنة الهجرية',
      hijriDate: '1 Muharram',
      description:
          "Marks the start of the Hijri calendar, which begins not with the Prophet's birth or the first revelation, but with the Hijra -- his migration from Mecca to Medina in 622 CE. Caliph Umar ibn al-Khattab chose this event as the calendar's starting point because it marked the establishment of the first independent Muslim community, making it a fitting occasion for quiet reflection rather than celebration.",
      descriptionAr:
          'بداية التقويم الهجري، الذي لم يُختر ليبدأ بمولد النبي صلى الله عليه وسلم أو ببعثته، بل بالهجرة النبوية من مكة إلى المدينة عام 622م. اختار الخليفة عمر بن الخطاب رضي الله عنه هذا الحدث بداية للتقويم لأنه مثّل تأسيس أول مجتمع إسلامي مستقل، فهي مناسبة للتأمل الهادئ أكثر منها للاحتفال.',
    ),
    IslamicHistoricalEvent(
      name: 'Day of Ashura',
      nameAr: 'يوم عاشوراء',
      hijriDate: '10 Muharram',
      description:
          "A day of great historical significance -- the day Allah saved Prophet Musa and the Children of Israel from Pharaoh by parting the sea. The Prophet found the Jews of Medina fasting it in gratitude and said, \"We have more right to Musa than you,\" and fasted it himself, encouraging Muslims to fast this day (ideally alongside the 9th) as an expiation for the sins of the past year.",
      descriptionAr:
          'يوم عظيم في التاريخ -- هو اليوم الذي نجّى الله فيه موسى عليه السلام وبني إسرائيل من فرعون بشقّ البحر. وجد النبي صلى الله عليه وسلم يهود المدينة يصومونه شكراً لله فقال "نحن أحق بموسى منكم"، وصامه بنفسه، وحثّ المسلمين على صيامه (ويُستحب معه صيام التاسع) تكفيراً لذنوب السنة الماضية.',
    ),
    IslamicHistoricalEvent(
      name: 'Isra and Miraj',
      nameAr: 'الإسراء والمعراج',
      hijriDate: '27 Rajab',
      description:
          "Commemorates the miraculous night journey in which the Prophet was taken from Mecca to Jerusalem (Al-Isra), then ascended through the heavens (Al-Mi'raj), meeting earlier prophets and ultimately receiving the command for the five daily prayers directly from Allah. It stands as a profound reminder of the significance of prayer and of Al-Aqsa Mosque's place in Islamic history.",
      descriptionAr:
          'إحياء لذكرى الرحلة الليلية المعجزة التي انتُقل فيها بالنبي صلى الله عليه وسلم من مكة إلى بيت المقدس (الإسراء)، ثم عُرج به إلى السماوات (المعراج) حيث التقى بالأنبياء السابقين، وفُرضت عليه الصلوات الخمس مباشرة من الله. تبقى تذكيراً عميقاً بمكانة الصلاة ومكانة المسجد الأقصى في التاريخ الإسلامي.',
    ),
    IslamicHistoricalEvent(
      name: 'Start of Ramadan',
      nameAr: 'بداية شهر رمضان',
      hijriDate: '1 Ramadan',
      description:
          'The beginning of the month in which the Quran was first revealed, and in which fasting from dawn to sunset was made obligatory upon every capable adult Muslim. The Prophet described it as a month in which the gates of Paradise are opened, the gates of Hellfire are closed, and the devils are chained, making it a time of heightened worship, charity, and Quran recitation.',
      descriptionAr:
          'بداية الشهر الذي بدأ فيه نزول القرآن الكريم، وفُرض فيه الصيام من الفجر إلى غروب الشمس على كل مسلم بالغ قادر. وصفه النبي صلى الله عليه وسلم بأنه شهر تُفتح فيه أبواب الجنة وتُغلق أبواب النار وتُصفّد فيه الشياطين، فهو موسم مضاعف للعبادة والصدقة وتلاوة القرآن.',
    ),
    IslamicHistoricalEvent(
      name: 'The Last Ten Nights of Ramadan',
      nameAr: 'العشر الأواخر من رمضان',
      hijriDate: '21 Ramadan',
      description:
          "The most virtuous nights of the year, containing Laylat al-Qadr (the Night of Decree), described in the Quran as better than a thousand months. The Prophet used to intensify his worship during this period more than at any other time, staying up in prayer, and would perform i'tikaf (spiritual retreat in the mosque), encouraging Muslims to seek this night especially on the odd-numbered nights.",
      descriptionAr:
          'أفضل ليالي السنة، وتحتوي على ليلة القدر التي وصفها القرآن بأنها خير من ألف شهر. كان النبي صلى الله عليه وسلم يجتهد في هذه الفترة أكثر من أي وقت آخر، فيحيي الليل بالصلاة، ويعتكف في المسجد، وحثّ المسلمين على تحرّي هذه الليلة في الليالي الوتر خاصة.',
    ),
    IslamicHistoricalEvent(
      name: 'Eid al-Fitr',
      nameAr: 'عيد الفطر',
      hijriDate: '1 Shawwal',
      description:
          "The celebration marking the end of Ramadan's fasting month, beginning with a special congregational prayer. Before this prayer, Muslims are obligated to pay Zakat al-Fitr, a small charity ensuring that those in need can also celebrate the day, reflecting Islam's balance between individual spiritual achievement and communal responsibility.",
      descriptionAr:
          'الاحتفال بانتهاء شهر رمضان المبارك، ويبدأ بصلاة عيد جماعية. قبل هذه الصلاة، يجب على كل مسلم إخراج زكاة الفطر، وهي صدقة بسيطة تضمن أن يشارك المحتاجون أيضاً في فرحة العيد، فتعكس توازن الإسلام بين الإنجاز الروحي الفردي والمسؤولية المجتمعية.',
    ),
    IslamicHistoricalEvent(
      name: 'Day of Arafah',
      nameAr: 'يوم عرفة',
      hijriDate: '9 Dhul-Hijjah',
      description:
          "The pinnacle day of Hajj, when pilgrims stand in supplication on the plain of Arafah -- the Prophet said, \"Hajj is Arafah.\" For Muslims not performing Hajj, fasting this day is highly recommended, as the Prophet said it expiates the sins of the past year and the year to come, making it one of the most rewarding voluntary fasts in the Islamic calendar.",
      descriptionAr:
          'ذروة أيام الحج، حيث يقف الحجاج بالدعاء في صعيد عرفات -- قال النبي صلى الله عليه وسلم "الحج عرفة". أما من لم يحج، فيُستحب له صيام هذا اليوم، إذ قال النبي إنه يكفّر ذنوب السنة الماضية والسنة القادمة، فهو من أفضل أيام الصيام التطوعي في التقويم الإسلامي.',
    ),
    IslamicHistoricalEvent(
      name: 'Eid al-Adha',
      nameAr: 'عيد الأضحى',
      hijriDate: '10 Dhul-Hijjah',
      description:
          "The 'Festival of Sacrifice,' commemorating Prophet Ibrahim's willingness to sacrifice his son Ismail in obedience to Allah, before Allah ransomed him with a sacrificial animal. Muslims worldwide -- whether performing Hajj or not -- slaughter a sacrificial animal and distribute much of the meat to the poor, marking it as the greater of the two Eids and the culmination of the Hajj rites.",
      descriptionAr:
          'عيد التضحية، إحياءً لاستعداد النبي إبراهيم عليه السلام لذبح ابنه إسماعيل طاعةً لله، قبل أن يفديه الله بذبح عظيم. يذبح المسلمون في أنحاء العالم -- سواء كانوا حجاجاً أم لا -- أضحية ويوزّعون أغلب لحمها على الفقراء، وهو أكبر العيدين وخاتمة مناسك الحج.',
    ),
  ];
}
