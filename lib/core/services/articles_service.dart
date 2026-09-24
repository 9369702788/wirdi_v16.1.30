
class IslamicArticle {
  final String id;
  final String title;
  final String titleAr;
  final String content;
  final String contentAr;
  final String author;
  final String category;
  final String publishDate;

  const IslamicArticle({
    required this.id, required this.title, required this.titleAr,
    required this.content, required this.contentAr,
    required this.author, required this.category, required this.publishDate,
  });
}

class ArticlesService {
  static const List<IslamicArticle> articles = [
    IslamicArticle(
      id: '1',
      title: 'Understanding Tawheed',
      titleAr: 'فهم التوحيد',
      content: 'Tawheed -- the oneness of Allah -- is the foundation of Islamic belief. It means affirming that Allah alone is the Creator, the Sustainer, and the only one deserving of worship, without any partner or equal. Tawheed is traditionally divided into three parts: Tawheed al-Rububiyyah (belief that Allah alone creates, owns, and controls all affairs), Tawheed al-Uluhiyyah (directing all acts of worship -- prayer, supplication, reliance -- to Allah alone), and Tawheed al-Asma was-Sifat (affirming Allah\'s names and attributes as He described Himself, without distortion or resemblance to creation). Every other principle of Islamic belief rests on this foundation.',
      contentAr: 'التوحيد هو أساس العقيدة الإسلامية، ويعني إفراد الله عز وجل بالخلق والملك والتدبير، وإفراده وحده بالعبادة دون شريك. وينقسم التوحيد عند أهل العلم إلى ثلاثة أقسام: توحيد الربوبية (الإيمان بأن الله وحده هو الخالق المالك المدبر لكل شيء)، وتوحيد الألوهية (إفراد الله وحده بجميع أنواع العبادة كالصلاة والدعاء والتوكل)، وتوحيد الأسماء والصفات (إثبات ما وصف الله به نفسه من أسماء وصفات من غير تحريف ولا تمثيل). وعلى هذا الأساس تُبنى سائر أصول الاعتقاد.',
      author: 'Wirdi editorial team', category: 'Aqeedah', publishDate: '',
    ),
    IslamicArticle(
      id: '2',
      title: 'The Importance of Salah',
      titleAr: 'أهمية الصلاة',
      content: 'Prayer (Salah) is the second pillar of Islam and the first matter for which a person will be held accountable on the Day of Judgment. It is a direct link between the servant and their Lord, performed five times daily, and serves as a constant reminder of Allah throughout a Muslim\'s day. The Prophet (peace be upon him) described it as the pillar of the religion, saying that whoever establishes it has established the religion, and whoever abandons it has destroyed the religion. Beyond its spiritual reward, Salah instills discipline, humility, and mindfulness in daily life.',
      contentAr: 'الصلاة هي الركن الثاني من أركان الإسلام، وهي أول ما يُحاسب عليه العبد يوم القيامة. وهي صلة مباشرة بين العبد وربه، تؤدى خمس مرات في اليوم والليلة، وتُذكّر المسلم بربه في كل وقت من يومه. وقد وصفها النبي صلى الله عليه وسلم بأنها عماد الدين، فقال: من أقامها فقد أقام الدين، ومن هدمها فقد هدم الدين. وفوق أجرها العظيم، فإن الصلاة تغرس في المسلم الانضباط والخشوع واستحضار مراقبة الله في حياته اليومية.',
      author: 'Wirdi editorial team', category: 'Ibadah', publishDate: '',
    ),
    IslamicArticle(
      id: '3',
      title: 'Good Character (Akhlaq) in Islam',
      titleAr: 'الأخلاق في الإسلام',
      content: 'Islam places immense weight on good character, considering it a core purpose of the Prophet\'s mission. The Prophet (peace be upon him) said: "I was only sent to perfect good character." Honesty, kindness, patience, humility, and fulfilling trusts are not secondary matters in Islam -- they are integral to faith itself, so much so that the Prophet described the believer with the most complete faith as the one with the best character. Good character extends to how a Muslim treats family, neighbors, strangers, and even animals.',
      contentAr: 'يولي الإسلام اهتمامًا عظيمًا بحسن الخلق، ويعتبره من صميم مقاصد الرسالة النبوية، حيث قال النبي صلى الله عليه وسلم: إنما بُعثت لأتمم مكارم الأخلاق. فالصدق والرفق والصبر والتواضع وأداء الأمانة ليست أمورًا هامشية في الإسلام، بل هي جزء أصيل من الإيمان نفسه، حتى قال النبي صلى الله عليه وسلم: أكمل المؤمنين إيمانًا أحسنهم خلقًا. ويمتد حسن الخلق ليشمل معاملة المسلم لأهله وجيرانه وحتى الحيوان.',
      author: 'Wirdi editorial team', category: 'Akhlaq', publishDate: '',
    ),
    IslamicArticle(
      id: '4',
      title: 'The Etiquette of Seeking Knowledge',
      titleAr: 'آداب طلب العلم',
      content: 'Seeking beneficial knowledge is emphasized throughout the Quran and Sunnah, beginning with the first revealed word: "Read." Scholars stressed that knowledge should be paired with sincere intention, humility toward teachers, patience, and -- crucially -- acting upon what is learned.',
      contentAr: 'طلب العلم النافع فضيلة عظيمة، وبدأ الوحي بكلمة اقرأ. شدد العلماء على أن يقترن طلب العلم بالإخلاص والتواضع للمعلمين والصبر، والأهم العمل بما يُتعلَّم.',
      author: 'Wirdi editorial team', category: 'Knowledge', publishDate: '',
    ),
    IslamicArticle(
      id: '5',
      title: 'The Balance Between Worship and Worldly Life',
      titleAr: 'التوازن بين العبادة والحياة الدنيا',
      content: 'Islam does not call for abandoning worldly life for isolated worship. The Prophet (peace be upon him) taught a companion that his body, family, and guests each have a right over him -- reflecting Islam\'s comprehensive balance.',
      contentAr: 'لا يدعو الإسلام لترك الدنيا للانقطاع للعبادة. علّم النبي صلى الله عليه وسلم صحابيًا بأن لجسده وأهله وزائريه حقًا عليه، وهذا يعكس توازن الإسلام كمنهج حياة.',
      author: 'Wirdi editorial team', category: 'Lifestyle', publishDate: '',
    ),
    IslamicArticle(
      id: '6',
      title: 'Patience (Sabr) in the Quran',
      titleAr: 'الصبر في القرآن الكريم',
      content: 'The Quran mentions patience in over ninety places: "Indeed, the patient will be given their reward without account" (Az-Zumar 39:10). Scholars categorize it into patience in obedience, in avoiding sin, and in accepting Allah\'s decree.',
      contentAr: 'ذكر القرآن الصبر في أكثر من تسعين موضعًا: إنما يوفى الصابرون أجرهم بغير حساب (الزمر: 10). وقسّمه العلماء إلى صبر على الطاعة وعن المعصية وعلى الأقدار.',
      author: 'Wirdi editorial team', category: 'Spirituality', publishDate: '',
    ),
  ];

  static Future<List<IslamicArticle>> getArticlesByCategory(String category) async {
    return articles.where((a) => a.category == category).toList();
  }
}
