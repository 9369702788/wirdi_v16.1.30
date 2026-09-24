import 'adhan_option.dart';

class AppSources {
  AppSources._();

  /// Public URL of the hosted privacy policy (see docs/privacy-policy.html;
  /// GitHub Pages works). Google Play requires this same URL in the store
  /// listing. While empty, the in-app policy simply hides the "View online" button.
  static const String privacyPolicyUrl = 'https://wirdi-app.web.app/privacy-policy.html';

  /// Real, monitored contact e-mail shown in the in-app privacy policy.
  /// While empty, no contact line is shown.
  static const String privacyContactEmail = 'wirdi.info@gmail.com';

  /// User-Agent for OpenStreetMap services (Nominatim/Overpass require an
  /// identifying agent with a way to contact the operator).
  static String get httpUserAgent => privacyContactEmail.isEmpty
      ? 'WirdiApp/1.55 (Islamic companion app for Android)'
      : 'WirdiApp/1.55 (Islamic companion app for Android; contact: $privacyContactEmail)';

  static const String quranJsonUrl =
      'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran.json';

  // azkarJsonUrl / mushafPagesJsonUrl were removed in v1.54: both datasets are now bundled in assets/data/.

  /// Tafsir Al-Muyassar (ar.muyassar), served by Al Quran Cloud
  /// (Islamic Network) — a long-running, widely used public Quran API
  /// with no key required. This edition is attributed by the API
  /// itself to its publisher, King Fahad Quran Complex:
  /// https://api.alquran.cloud/v1/edition?format=text&type=tafsir&language=ar
  /// Replaces a prior unverified personal GitHub mirror that had no
  /// stated license for this text.
  static const String tafsirJsonUrl =
      'https://api.alquran.cloud/v1/quran/ar.muyassar';

  /// English transliteration, same underlying project (risan/quran-json)
  /// and Tanzil.net sourcing as the main Quran text, same surah/ayah
  /// numbering — verified structure and completeness (6236 verses)
  /// before wiring in.
  static const String transliterationJsonUrl =
      'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran_transliteration.json';

  /// QuranEnc.com (Encyclopedia of the Noble Quran / King Fahd Complex
  /// affiliated project) — per-language meaning translations, fetched
  /// per-surah. Free to use and redistribute per their terms, provided
  /// the source is credited (see Sources & Licenses) and the text isn't
  /// altered. https://quranenc.com/en/home/api
  static const String quranEncApiBase = 'https://quranenc.com/api/v1/translation';

  /// Maps this app's UI language to a specific QuranEnc.com translation
  /// edition. Arabic has no entry: for the 'ar' locale the app shows the
  /// Quran's own Arabic text directly, there's no separate "translation"
  /// to fetch. Picking a specific edition per language (rather than just
  /// "the English one") matters because QuranEnc hosts several editions
  /// per language from different translators — these are the widely-used
  /// default editions for each.
  static const Map<String, String> quranEncTranslationKeyByLocale = {
    'en': 'english_saheeh', // Saheeh International
    'de': 'german_bubenheim', // Frank Bubenheim & Nadeem Elyas
    'tr': 'turkish_shahin', // Dr. Ali Özek and others (Diyanet-affiliated team)
    'fr': 'french_noor', // Noor International Center
    'es': 'spanish_garcia', // Muhammad Isa García
    'id': 'indonesian_affairs', // Indonesian Ministry of Religious Affairs
  };

  static String? quranEncTranslationKeyFor(String languageCode) =>
      quranEncTranslationKeyByLocale[languageCode];

  /// fawazahmed0/hadith-api — free, no API key, served via the jsDelivr
  /// GitHub CDN (same trust model as [quranJsonUrl], which already uses
  /// a jsDelivr-hosted GitHub project). Verified structure and content
  /// before wiring in: https://github.com/fawazahmed0/hadith-api
  static const String hadithApiBase = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  /// Collection slugs available from the API that this app exposes.
  /// Starting with the 40 (really 42) Hadith of an-Nawawi: a compact,
  /// foundational, universally-taught collection — the natural starting
  /// point before adding the much larger Bukhari/Muslim collections in
  /// a future update.
  static const String hadithCollectionNawawi = 'nawawi';

  /// Verified real edition names for the Nawawi collection (see
  /// hadithApiBase/../editions.json). Arabic is always shown as the
  /// source text (same principle as Quran/azkar text elsewhere in this
  /// app); translation editions are layered on top per UI language.
  /// No German edition exists in this dataset for any collection, so
  /// German falls back to English — same fallback pattern already used
  /// by [DailyQuote.translationFor].
  static const String hadithArabicEdition = 'ara-nawawi';
  static const Map<String, String> hadithTranslationEditionByLocale = {
    'ar': 'ara-nawawi',
    'en': 'eng-nawawi',
    'tr': 'tur-nawawi',
  };

  static String hadithTranslationEditionFor(String languageCode) =>
      hadithTranslationEditionByLocale[languageCode] ?? hadithTranslationEditionByLocale['en']!;

  static const String hadeethEncApiBase = 'https://hadeethenc.com/api/v1';

  /// Adhan audio recordings, officially hosted by AlAdhan (the same
  /// provider already used for prayer times), listed at
  /// https://aladhan.com/download-adhans
  static const List<AdhanOption> adhanOptions = [
    AdhanOption('a9', 'مشاري راشد العفاسي', 'Mishari Rashid Alafasy', 'https://cdn.aladhan.com/audio/adhans/a9.mp3'),
    AdhanOption('a4', 'أذان دبي (مشاري العفاسي)', 'Dubai Adhan (Mishari Alafasy)', 'https://cdn.aladhan.com/audio/adhans/a4.mp3'),
    AdhanOption('a7', 'مشاري راشد العفاسي (نسخة أخرى)', 'Mishari Rashid Alafasy (alternate)', 'https://cdn.aladhan.com/audio/adhans/a7.mp3'),
    AdhanOption('a1', 'أحمد النفيس', 'Ahmad Al-Nafees', 'https://cdn.aladhan.com/audio/adhans/a1.mp3'),
    AdhanOption('a11', 'منصور الزهراني', 'Mansour Al-Zahrani', 'https://cdn.aladhan.com/audio/adhans/a11-mansour-al-zahrani.mp3'),
    AdhanOption('a2', 'حافظ مصطفى أوزجان (تركيا)', 'Hafız Mustafa Özcan (Turkey)', 'https://cdn.aladhan.com/audio/adhans/a2.mp3'),
  ];

  static String prayerTimesUrl({
    required double latitude,
    required double longitude,
    DateTime? date,
    int method = 5,
    int school = 0,
  }) {
    final datePath = date == null ? '' : '/${_ddmmyyyy(date)}';
    return 'https://api.aladhan.com/v1/timings$datePath?latitude=$latitude&longitude=$longitude&method=$method&school=$school';
  }

  /// Documented AlAdhan endpoint that geocodes the address server-side,
  /// so no separate geocoding call is needed for manual city entry.
  static String prayerTimesByAddressUrl(String address, {DateTime? date, int method = 5, int school = 0}) {
    final encoded = Uri.encodeComponent(address);
    final datePath = date == null ? '' : '/${_ddmmyyyy(date)}';
    return 'https://api.aladhan.com/v1/timingsByAddress$datePath?address=$encoded&method=$method&school=$school';
  }

  static const List<(int, String, String)> prayerCalculationMethods = [
    (5, '\u0627\u0644\u0647\u064a\u0626\u0629 \u0627\u0644\u0645\u0635\u0631\u064a\u0629 \u0627\u0644\u0639\u0627\u0645\u0629 \u0644\u0644\u0645\u0633\u0627\u062d\u0629', 'Egyptian General Authority'),
    (4, '\u0623\u0645 \u0627\u0644\u0642\u0631\u0649 (\u0645\u0643\u0629 \u0627\u0644\u0645\u0643\u0631\u0645\u0629)', 'Umm Al-Qura, Makkah'),
    (3, '\u0631\u0627\u0628\u0637\u0629 \u0627\u0644\u0639\u0627\u0644\u0645 \u0627\u0644\u0625\u0633\u0644\u0627\u0645\u064a', 'Muslim World League'),
    (2, '\u0627\u0644\u062c\u0645\u0639\u064a\u0629 \u0627\u0644\u0625\u0633\u0644\u0627\u0645\u064a\u0629 \u0644\u0623\u0645\u0631\u064a\u0643\u0627 \u0627\u0644\u0634\u0645\u0627\u0644\u064a\u0629 (ISNA)', 'ISNA (North America)'),
    (1, '\u062c\u0627\u0645\u0639\u0629 \u0627\u0644\u0639\u0644\u0648\u0645 \u0627\u0644\u0625\u0633\u0644\u0627\u0645\u064a\u0629\u060c \u0643\u0631\u0627\u062a\u0634\u064a', 'University of Islamic Sciences, Karachi'),
    (0, '\u0634\u0631\u0643\u0629 \u0645\u0648\u0627\u0642\u064a\u062a \u0627\u0644\u0635\u0644\u0627\u0629 \u062c\u064a\u0627\u0641', 'Shia Ithna-Ashari (Jafari)'),
    (13, 'رئاسة الشؤون الدينية التركية (ديانت)', 'Diyanet, Turkey'),
    (16, 'هيئة الشؤون الإسلامية والأوقاف بدبي', 'Dubai'),
    (9, 'الكويت', 'Kuwait'),
    (10, 'قطر', 'Qatar'),
    (17, 'ماليزيا (جاكيم)', 'JAKIM, Malaysia'),
    (20, 'إندونيسيا (وزارة الشؤون الدينية)', 'KEMENAG, Indonesia'),
    (21, 'وزارة الأوقاف المغربية', 'Morocco'),
    (12, 'اتحاد المنظمات الإسلامية في فرنسا', 'France (UOIF)'),
  ];

  static String prayerCalendarUrl({
    required double latitude,
    required double longitude,
    required int month,
    required int year,
    int method = 5,
    int school = 0,
  }) {
    return 'https://api.aladhan.com/v1/calendar?latitude=$latitude&longitude=$longitude&method=$method&school=$school&month=$month&year=$year';
  }

  static String _ddmmyyyy(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year}';
  }

  // Recitation. Verified reciter identifiers from the islamic.network CDN
  // docs (https://alquran.cloud/cdn). Default kept as Alafasy for
  // backward compatibility with existing cached audio behavior.
  static const String _audioBitrate = '128';

  static String surahAudioUrl(int surahNumber, {String reciter = 'ar.alafasy', String bitrate = '128'}) =>
      'https://cdn.islamic.network/quran/audio-surah/$bitrate/$reciter/$surahNumber.mp3';

  /// [globalAyahNumber] is the ayah's position across the whole Quran
  /// (1-6236), not its position within its surah.
  static String ayahAudioUrl(int globalAyahNumber, {String reciter = 'ar.alafasy'}) =>
      'https://cdn.islamic.network/quran/audio/$_audioBitrate/$reciter/$globalAyahNumber.mp3';

  static String sourcesAndLicensesFor(String languageCode) {
    final main = _sourcesAndLicensesByLocale[languageCode] ?? _sourcesAndLicensesByLocale['en']!;
    final extra = _extraCreditsByLocale[languageCode] ?? _extraCreditsByLocale['en']!;
    return '${main.trim()}\n\n${extra.trim()}';
  }

  /// v1.54: credits for the data that is now bundled, the fonts that ship with the
  /// app, and the third-party services it calls. Kept separate from the long
  /// per-locale text above so it can be edited in one place.
  static const Map<String, String> _extraCreditsByLocale = {
    'ar': '''
بيانات وخطوط وخدمات إضافية:
• نص القرآن: quran-json 3.1.2 (risan/quran-json) برخصة CC BY 4.0 ومبني على Tanzil.net — مضمَّن داخل التطبيق.
• ترقيم صفحات المصحف: madani-muhsaf-json (hamzakat) برخصة MIT — مضمَّن.
• الأذكار: Islamic Pro Azkar API برخصة MIT — مضمَّنة.
• خطوط القرآن: Amiri Quran (رخصة SIL OFL 1.1)، وخطا KFGQPC Uthmanic Script HAFS وQPC Hafs © مجمع الملك فهد لطباعة المصحف الشريف (مسموح باستخدامهما وتوزيعهما مجانًا دون تعديل).
• خط الواجهة: Tajawal (Boutros International) برخصة SIL OFL 1.1.
• بيانات الأماكن: © مساهمو OpenStreetMap (ODbL) عبر Nominatim وOverpass. الطقس: Open-Meteo.com (CC BY 4.0). المواقيت: AlAdhan. قوائم الراديو: mp3quran.net وRadio-Browser. معاني الكلمات: ummahapi.com. التلاوة: Islamic Network.
''',
    'en': '''
Additional data, fonts and services:
• Quran text: quran-json 3.1.2 (risan/quran-json), CC BY 4.0, based on Tanzil.net — bundled in the app.
• Mushaf page layout: madani-muhsaf-json (hamzakat), MIT licence — bundled.
• Azkar: Islamic Pro Azkar API contributors, MIT licence — bundled.
• Quran fonts: Amiri Quran (SIL OFL 1.1); KFGQPC Uthmanic Script HAFS and QPC Hafs © King Fahd Glorious Quran Printing Complex (free to use and distribute, unmodified).
• UI font: Tajawal (Boutros International), SIL OFL 1.1.
• Place data: © OpenStreetMap contributors (ODbL) via Nominatim and Overpass. Weather: Open-Meteo.com (CC BY 4.0). Prayer times: AlAdhan. Radio lists: mp3quran.net and Radio-Browser. Word-by-word meanings: ummahapi.com. Recitation audio: Islamic Network.
''',
    'de': '''
Weitere Daten, Schriften und Dienste:
• Korantext: quran-json 3.1.2 (risan/quran-json), CC BY 4.0, basierend auf Tanzil.net — in der App enthalten.
• Mushaf-Seitenaufteilung: madani-muhsaf-json (hamzakat), MIT-Lizenz — enthalten.
• Adhkar: Islamic Pro Azkar API, MIT-Lizenz — enthalten.
• Koranschriften: Amiri Quran (SIL OFL 1.1); KFGQPC Uthmanic Script HAFS und QPC Hafs © King Fahd Glorious Quran Printing Complex (kostenlos nutzbar und unverändert weitergebbar).
• Oberflächenschrift: Tajawal (Boutros International), SIL OFL 1.1.
• Ortsdaten: © OpenStreetMap-Mitwirkende (ODbL) über Nominatim und Overpass. Wetter: Open-Meteo.com (CC BY 4.0). Gebetszeiten: AlAdhan. Radiolisten: mp3quran.net und Radio-Browser. Wort-für-Wort: ummahapi.com. Rezitation: Islamic Network.
''',
    'tr': '''
Ek veriler, yazı tipleri ve hizmetler:
• Kur'an metni: quran-json 3.1.2 (risan/quran-json), CC BY 4.0, Tanzil.net tabanlı — uygulamaya gömülüdür.
• Mushaf sayfa düzeni: madani-muhsaf-json (hamzakat), MIT lisansı — gömülüdür.
• Zikirler: Islamic Pro Azkar API, MIT lisansı — gömülüdür.
• Kur'an yazı tipleri: Amiri Quran (SIL OFL 1.1); KFGQPC Uthmanic Script HAFS ve QPC Hafs © Kral Fahd Kur'an Basım Kompleksi (ücretsiz kullanılabilir, değiştirilmeden dağıtılabilir).
• Arayüz yazı tipi: Tajawal (Boutros International), SIL OFL 1.1.
• Yer verileri: © OpenStreetMap katkıda bulunanlar (ODbL), Nominatim ve Overpass üzerinden. Hava durumu: Open-Meteo.com (CC BY 4.0). Namaz vakitleri: AlAdhan. Radyo listeleri: mp3quran.net ve Radio-Browser. Kelime kelime anlamlar: ummahapi.com. Tilavet: Islamic Network.
''',
  };

  /// Kept for call sites not yet migrated to [sourcesAndLicensesFor];
  /// prefer the localized version in new code.
  static String get sourcesAndLicenses => _sourcesAndLicensesByLocale['ar']!;

  static const Map<String, String> _sourcesAndLicensesByLocale = {
    'ar': '''
المصادر والتراخيص

نص القرآن الكريم:
Quran JSON
https://github.com/risan/quran-json

مصدر نص القرآن:
Tanzil Project
https://tanzil.net

الأذكار:
Hisn Al-Muslim / Islamic Pro Azkar API
https://github.com/YousefAsalya/Islamic-Pro-azkar-API

مواقيت الصلاة:
AlAdhan Prayer Times API
https://aladhan.com/prayer-times-api

تلاوة القرآن الكريم:
عدة قراء (راجع قائمة القراء داخل شاشة القراءة)
عبر شبكة Islamic Network CDN
https://alquran.cloud/cdn

ترجمات معاني القرآن الكريم:
عدة لغات (الإنجليزية، الألمانية، التركية)
عبر Encyclopedia of the Noble Quran
https://quranenc.com

الأحاديث النبوية (الأربعون النووية):
مصدر بيانات JSON مفتوح على GitHub (بالعربية والإنجليزية والتركية)
https://github.com/fawazahmed0/hadith-api

التفسير الميسر:
مجمع الملك فهد لطباعة المصحف الشريف (الناشر الرسمي)
عبر واجهة Al Quran Cloud (شبكة Islamic Network)
https://alquran.cloud/cdn

ترقيم صفحات المصحف (604 صفحة):
مصدر بيانات JSON مفتوح على GitHub
https://github.com/hamzakat/madani-muhsaf-json

أصوات الأذان:
AlAdhan (Islamic Network)
https://aladhan.com/download-adhans

خط عرض القرآن الكريم:
Amiri Quran — Khaled Hosny / The Amiri Project
مرخص بموجب SIL Open Font License 1.1
https://github.com/aliftype/amiri

بيانات المساجد والمطاعم الحلال القريبة:
© مساهمو OpenStreetMap، عبر Overpass API
مرخصة بموجب Open Database License (ODbL)
https://www.openstreetmap.org/copyright

موسوعة الأحاديث النبوية:
HadeethEnc.com
https://hadeethenc.com
يُعاد نشر الترجمات وفق شروط HadeethEnc.com بدون أي تعديل أو حذف.

ملاحظات مهمة:
- يجب عدم تعديل نص القرآن الكريم.
- يجب ذكر مصدر Tanzil داخل صفحة المصادر والتراخيص.
- مواقيت الصلاة قد تختلف عن توقيت المسجد المحلي إذا كانت هناك تعديلات محلية.
''',
    'en': '''
Sources & Licenses

Quran text:
Quran JSON
https://github.com/risan/quran-json

Quran text source:
Tanzil Project
https://tanzil.net

Azkar (remembrances):
Hisn Al-Muslim / Islamic Pro Azkar API
https://github.com/YousefAsalya/Islamic-Pro-azkar-API

Prayer times:
AlAdhan Prayer Times API
https://aladhan.com/prayer-times-api

Quran recitation:
Multiple reciters (see the reciter list inside the reading screen)
Served via the Islamic Network CDN
https://alquran.cloud/cdn

Quran meaning translations:
Multiple languages (English, German, Turkish)
Via the Encyclopedia of the Noble Quran
https://quranenc.com

Hadith collection (Forty Hadith of an-Nawawi):
Open JSON dataset on GitHub (Arabic, English, and Turkish)
https://github.com/fawazahmed0/hadith-api

Simplified Tafsir (Al-Muyassar):
King Fahd Quran Complex (official publisher)
Served via Al Quran Cloud (Islamic Network)
https://alquran.cloud/cdn

Mushaf page numbering (604 pages):
Open JSON dataset on GitHub
https://github.com/hamzakat/madani-muhsaf-json

Adhan audio:
AlAdhan (Islamic Network)
https://aladhan.com/download-adhans

Quran display font:
Amiri Quran — Khaled Hosny / The Amiri Project
Licensed under the SIL Open Font License 1.1
https://github.com/aliftype/amiri

Nearby mosque & halal restaurant data:
© OpenStreetMap contributors, via the Overpass API
Licensed under the Open Database License (ODbL)
https://www.openstreetmap.org/copyright

Hadith Encyclopedia:
HadeethEnc.com
https://hadeethenc.com
Translations are republished per HadeethEnc.com's terms without modification.

Important notes:
- The Quran text must not be modified.
- The Tanzil source must be credited on the Sources & Licenses page.
- Prayer times may differ from your local mosque's schedule where local adjustments apply.
''',
    'de': '''
Quellen & Lizenzen

Korantext:
Quran JSON
https://github.com/risan/quran-json

Quelle des Korantextes:
Tanzil Project
https://tanzil.net

Adhkar (Gedenkformeln):
Hisn Al-Muslim / Islamic Pro Azkar API
https://github.com/YousefAsalya/Islamic-Pro-azkar-API

Gebetszeiten:
AlAdhan Prayer Times API
https://aladhan.com/prayer-times-api

Koran-Rezitation:
Mehrere Rezitatoren (siehe Rezitatorenliste im Leseansicht)
Bereitgestellt über das Islamic Network CDN
https://alquran.cloud/cdn

Koran-Bedeutungsübersetzungen:
Mehrere Sprachen (Englisch, Deutsch, Türkisch)
Über die Encyclopedia of the Noble Quran
https://quranenc.com

Hadith-Sammlung (Vierzig Hadithe von an-Nawawi):
Offener JSON-Datensatz auf GitHub (Arabisch, Englisch und Türkisch)
https://github.com/fawazahmed0/hadith-api

Vereinfachter Tafsir (Al-Muyassar):
King Fahd Quran Complex (offizieller Herausgeber)
Bereitgestellt über Al Quran Cloud (Islamic Network)
https://alquran.cloud/cdn

Mushaf-Seitennummerierung (604 Seiten):
Offener JSON-Datensatz auf GitHub
https://github.com/hamzakat/madani-muhsaf-json

Adhan-Audio:
AlAdhan (Islamic Network)
https://aladhan.com/download-adhans

Koran-Anzeigeschrift:
Amiri Quran — Khaled Hosny / The Amiri Project
Lizenziert unter der SIL Open Font License 1.1
https://github.com/aliftype/amiri

Daten zu Moscheen & Halal-Restaurants in der Nähe:
© OpenStreetMap-Mitwirkende, über die Overpass API
Lizenziert unter der Open Database License (ODbL)
https://www.openstreetmap.org/copyright

Hadith-Enzyklopädie:
HadeethEnc.com
https://hadeethenc.com
Übersetzungen werden unverändert gemäß HadeethEnc.com weiterveröffentlicht.

Wichtige Hinweise:
- Der Korantext darf nicht verändert werden.
- Die Quelle Tanzil muss auf der Seite „Quellen & Lizenzen" genannt werden.
- Gebetszeiten können bei lokalen Anpassungen von der Moscheenzeit vor Ort abweichen.
''',
    'tr': '''
Kaynaklar ve Lisanslar

Kur'an metni:
Quran JSON
https://github.com/risan/quran-json

Kur'an metni kaynağı:
Tanzil Project
https://tanzil.net

Zikirler:
Hisn Al-Muslim / Islamic Pro Azkar API
https://github.com/YousefAsalya/Islamic-Pro-azkar-API

Namaz vakitleri:
AlAdhan Prayer Times API
https://aladhan.com/prayer-times-api

Kur'an tilaveti:
Birden fazla kâri (kâri listesi okuma ekranında)
Islamic Network CDN üzerinden sunulur
https://alquran.cloud/cdn

Kur'an meal çevirileri:
Birden fazla dil (İngilizce, Almanca, Türkçe)
Encyclopedia of the Noble Quran üzerinden
https://quranenc.com

Hadis derlemesi (Kırk Hadis - Nevevî):
GitHub üzerinde açık JSON veri seti (Arapça, İngilizce ve Türkçe)
https://github.com/fawazahmed0/hadith-api

Muyesser Tefsir:
Kral Fahd Kur'an Basım Kompleksi (resmi yayıncı)
Al Quran Cloud (Islamic Network) üzerinden sunulur
https://alquran.cloud/cdn

Mushaf sayfa numaralandırması (604 sayfa):
GitHub üzerinde açık JSON veri seti
https://github.com/hamzakat/madani-muhsaf-json

Ezan sesleri:
AlAdhan (Islamic Network)
https://aladhan.com/download-adhans

Kur'an gösterim yazı tipi:
Amiri Quran — Khaled Hosny / The Amiri Project
SIL Open Font License 1.1 ile lisanslanmıştır
https://github.com/aliftype/amiri

Yakındaki cami ve helal restoran verileri:
© OpenStreetMap katkıda bulunanları, Overpass API aracılığıyla
Open Database License (ODbL) ile lisanslanmıştır
https://www.openstreetmap.org/copyright

Hadis Ansiklopedisi:
HadeethEnc.com
https://hadeethenc.com
Çeviriler HadeethEnc.com şartlarına uygun olarak değiştirilmeden yayınlanır.

Önemli notlar:
- Kur'an metni değiştirilemez.
- Tanzil kaynağı, Kaynaklar ve Lisanslar sayfasında belirtilmelidir.
- Namaz vakitleri, yerel düzenlemeler olduğunda yerel cami vaktinden farklı olabilir.
''',
  };
}
