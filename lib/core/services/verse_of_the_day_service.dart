class VerseOfTheDay {
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final String translation;
  const VerseOfTheDay({
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    required this.translation,
  });
}

class VerseOfTheDayService {
  static const List<VerseOfTheDay> _verses = [
    VerseOfTheDay(surahName: 'البقرة', surahNumber: 2, ayahNumber: 286, arabicText: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا', translation: 'Allah does not burden a soul beyond what it can bear.'),
    VerseOfTheDay(surahName: 'الشرح', surahNumber: 94, ayahNumber: 6, arabicText: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا', translation: 'Indeed, with hardship comes ease.'),
    VerseOfTheDay(surahName: 'الطلاق', surahNumber: 65, ayahNumber: 3, arabicText: 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ', translation: 'Whoever relies upon Allah, He is sufficient for him.'),
    VerseOfTheDay(surahName: 'البقرة', surahNumber: 2, ayahNumber: 152, arabicText: 'فَاذْكُرُونِي أَذْكُرْكُمْ', translation: 'So remember Me; I will remember you.'),
    VerseOfTheDay(surahName: 'آل عمران', surahNumber: 3, ayahNumber: 159, arabicText: 'فَبِمَا رَحْمَةٍ مِّنَ اللَّهِ لِنتَ لَهُمْ', translation: 'It is by mercy from Allah that you were gentle with them.'),
    VerseOfTheDay(surahName: 'الرعد', surahNumber: 13, ayahNumber: 28, arabicText: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', translation: 'Verily, in the remembrance of Allah do hearts find rest.'),
    VerseOfTheDay(surahName: 'الزمر', surahNumber: 39, ayahNumber: 53, arabicText: 'لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ', translation: 'Do not despair of the mercy of Allah.'),
    VerseOfTheDay(surahName: 'البقرة', surahNumber: 2, ayahNumber: 216, arabicText: 'وَعَسَىٰ أَن تَكْرَهُوا شَيْئًا وَهُوَ خَيْرٌ لَّكُمْ', translation: 'You may dislike something which is good for you.'),
    VerseOfTheDay(surahName: 'الضحى', surahNumber: 93, ayahNumber: 5, arabicText: 'وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ', translation: 'And your Lord is going to give you, and you will be satisfied.'),
    VerseOfTheDay(surahName: 'الفرقان', surahNumber: 25, ayahNumber: 70, arabicText: 'إِلَّا مَن تَابَ وَآمَنَ وَعَمِلَ عَمَلًا صَالِحًا', translation: 'Except for those who repent, believe, and do righteous work.'),
    VerseOfTheDay(surahName: 'البقرة', surahNumber: 2, ayahNumber: 186, arabicText: 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ', translation: 'And when My servants ask you concerning Me, indeed I am near.'),
    VerseOfTheDay(surahName: 'يوسف', surahNumber: 12, ayahNumber: 87, arabicText: 'إِنَّهُ لَا يَيْأَسُ مِن رَّوْحِ اللَّهِ إِلَّا الْقَوْمُ الْكَافِرُونَ', translation: 'No one despairs of relief from Allah except the disbelieving people.'),
    VerseOfTheDay(surahName: 'التوبة', surahNumber: 9, ayahNumber: 40, arabicText: 'لَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا', translation: 'Do not grieve; indeed Allah is with us.'),
    VerseOfTheDay(surahName: 'النحل', surahNumber: 16, ayahNumber: 128, arabicText: 'إِنَّ اللَّهَ مَعَ الَّذِينَ اتَّقَوا وَّالَّذِينَ هُم مُّحْسِنُونَ', translation: 'Indeed, Allah is with those who fear Him and those who do good.'),
    VerseOfTheDay(surahName: 'الحجر', surahNumber: 15, ayahNumber: 56, arabicText: 'وَمَن يَقْنَطُ مِن رَّحْمَةِ رَبِّهِ إِلَّا الضَّالُّونَ', translation: 'Who despairs of the mercy of his Lord except those astray?'),
    VerseOfTheDay(surahName: 'العنكبوت', surahNumber: 29, ayahNumber: 69, arabicText: 'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا', translation: 'Those who strive for Us, We will surely guide them to Our ways.'),
    VerseOfTheDay(surahName: 'إبراهيم', surahNumber: 14, ayahNumber: 7, arabicText: 'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ', translation: 'If you are grateful, I will surely increase you.'),
    VerseOfTheDay(surahName: 'البقرة', surahNumber: 2, ayahNumber: 153, arabicText: 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ', translation: 'Indeed, Allah is with the patient.'),
    VerseOfTheDay(surahName: 'آل عمران', surahNumber: 3, ayahNumber: 173, arabicText: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ', translation: 'Sufficient for us is Allah, and He is the best Disposer of affairs.'),
    VerseOfTheDay(surahName: 'الأنعام', surahNumber: 6, ayahNumber: 59, arabicText: 'وَعِندَهُ مَفَاتِحُ الْغَيْبِ لَا يَعْلَمُهَا إِلَّا هُوَ', translation: 'With Him are the keys of the unseen; none knows them except Him.'),
  ];

  static VerseOfTheDay forToday() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _verses[dayOfYear % _verses.length];
  }
}
