# جرد كامل لمشروع وردي (Wirdi) — النسخة v16.1.27-play-prep (1.54.0+20)

> **كيف عُمل هذا الجرد:** استُخرج آليًا من الكود نفسه (سكريبتات تحلّل كل ملفات `lib/` و`android/` و`pubspec.yaml` و`.github/`) ثم قُرئت الأجزاء الحساسة يدويًا. الأرقام حقيقية وليست تقديرات. **لم يُشغَّل التطبيق** ولا `flutter analyze`؛ لذلك ما يخص السلوك الفعلي على الجهاز (مثل عمل الإشعارات) لم يُختبر هنا.

## 1. الملخص التنفيذي

| البند | القيمة |
|---|---|
| ملفات Dart في `lib/` (بدون المولَّد) | **184** ملفًا، حوالي **33,900** سطر |
| شاشات (`*_screen.dart`) | **94** شاشة — كلها متصلة بمسار تنقّل، لا توجد شاشة يتيمة |
| خدمات (`core/services`) | **58** ملفًا (~7,950 سطر) |
| مدخلات «الأدوات الإسلامية» | **62** مدخلًا في قائمة واحدة مسطحة |
| تبويبات الشريط السفلي | **7** (الرئيسية، القرآن، الأذكار، الصلاة، التسبيح، الراديو، المزيد) |
| مسارات مسمّاة (`routes`) | 4 فقط: `/splash` `/onboarding` `/login` `/home`؛ الباقي `Navigator.push` |
| اللغات | 7: ar, en, de, tr, fr, es, id — **659** مفتاح ARB لكل لغة |
| الاعتماديات | 24 حزمة تشغيل (واحدة محلية `flutter_compass_v2`) |
| الاختبارات | ملفان فقط (سلامة البيانات المضمّنة + فلتر الراديو) |
| حجم `assets/` | ~9.1 MB (منها ~3.9 MB صورتان PNG كبيرتان) |
| مزوّدو الشبكة | 13 مزوّدًا/خدمة خارجية (انظر §9) |

**الخلاصة:** التطبيق أوسع بكثير من «تطبيق قرآن وأذكار»: يضم قرآنًا (نص + مصحف صفحات + صوت + تفسير + ترجمة + كلمات + تجويد)، مواقيت وقبلة (حتى AR)، حفظ بنظام Leitner، ختمات، أذكار، تسبيح، أحاديث، راديو، زكاة، حج، تقويم رمضان، إنجازات، رؤى ونشاط، مزامنة سحابية، widget. المشاكل الفعلية الموجودة ملخّصة في §16.

## 2. الهيكل العام

```text
lib/
  main.dart, firebase_options.dart
  core/  services(58)  data(8)  models(11)  theme(1)
  features/ 35 مجلدًا (انظر §4)
  shared/widgets  root_shell.dart, wirdi_scenic_background.dart
  l10n/  7 ملفات ARB + كود مولَّد
packages/flutter_compass_v2   (حزمة محلية Kotlin/Java، بلا native C++)
android/  Manifest + WirdiWidgetProvider.kt + layouts/xml/raw
android_overrides/res/  keep.xml + ic_stat_wirdi.xml (تُنسخ عند بناء CI)
assets/  data(quran, mushaf, azkar) fonts google_fonts images
docs/  privacy-policy.html, delete-account.html
test/  bundled_data_test.dart, radio_station_test.dart
.github/workflows/build_apk.yml  (31 خطوة)
```

**النمط المعماري:** بلا مكتبة إدارة حالة؛ `StatefulWidget` + خدمات static/singleton، و`appSettings` كـ `ChangeNotifier` عام لإعادة بناء الثيم والخط لحظيًا. التخزين المحلي `SharedPreferences`، والسحابة Firestore اختيارية.

## 3. خريطة التنقل

```text
/splash → (أول مرة) /onboarding → /login (أو «تخطي») → /home (RootShell)
RootShell (IndexedStack + شريط سفلي + مشغّلان مصغّران للراديو والقرآن):
  0 الرئيسية   1 القرآن   2 الأذكار   3 الصلاة   4 التسبيح   5 الراديو   6 المزيد (الإعدادات)
الرئيسية ← بطاقة/زر → IslamicToolsScreen (62 مدخل) ← معظم الشاشات الفرعية
```

ملاحظة: 7 عناصر في `BottomNavigationBar` (نوع fixed) أكثر من الموصى به في Material (3–5)؛ ويعمل حاليًا لكنه مزدحم على الشاشات الصغيرة.

## 4. الشاشات (94) حسب المجال

عمود «لغات»: **كامل (ARB)** = كل النصوص من ملفات الترجمة (7 لغات)؛ **ar+en فقط** = النص مكتوب داخل الكود بالعربية والإنجليزية فقط، وباقي اللغات (de/tr/fr/es/id) ترى الإنجليزية.

### achievements

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Achievements** (`achievements_screen.dart`) | Track your milestones and badges | 250 | islamic_tools_screen | مختلط (2 نص ar/en) |

### articles

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Islamic Articles** (`articles_screen.dart`) | Short educational articles | 37 | islamic_tools_screen | كامل (ARB) |

### asma_ul_husna

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Names of Allah Quiz** (`asma_ul_husna_quiz_screen.dart`) | Test your memorization of the 99 Names and their meanings | 116 | islamic_tools_screen | كامل (ARB) |
| **The 99 Names of Allah** (`asma_ul_husna_screen.dart`) | The 99 Names and their meanings | 83 | islamic_tools_screen | كامل (ARB) |

### auth

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Account** (`account_screen.dart`) | بيانات الحساب، مزامنة يدوية، تسجيل خروج، حذف الحساب (يمسح Firestore ثم الحساب) | 336 | settings_screen | كامل (ARB) |
| **Forgot password** (`forgot_password_screen.dart`) | إرسال رابط استعادة كلمة المرور | 63 | login_screen | كامل (ARB) |
| **Sign in** (`login_screen.dart`) | دخول بالبريد أو Google أو «تخطي»؛ زر Apple معطّل في الواجهة | 177 | account_screen, main | كامل (ARB) |
| **Create account** (`register_screen.dart`) | إنشاء حساب بالبريد | 146 | login_screen | كامل (ARB) |

### azkar

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Azkar** (`azkar_screen.dart`) | أذكار حصن المسلم (132 تصنيفًا) بعدادات يومية وإعادة ضبط تلقائية ومفضلة | 570 | favorites_screen, global_search_screen, home_dashboard_screen +2 | كامل (ARB) |
| **My Custom Azkar** (`custom_azkar_screen.dart`) | Create your own dhikr with a target count | 139 | islamic_tools_screen | كامل (ARB) |
| **Ruqyah (Spiritual Healing)** (`ruqyah_screen.dart`) | Authentic verses and supplications for spiritual healing | 62 | islamic_tools_screen | كامل (ARB) |

### bookmarks

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Bookmarks** (`bookmarks_screen.dart`) | Save ayahs with notes and categories | 300 | islamic_tools_screen | كامل (ARB) |

### duas

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Dua Library** (`dua_library_screen.dart`) | Authentic duas for every occasion, with benefits | 412 | islamic_tools_screen | مختلط (1 نص ar/en) |
| **My Duas** (`my_duas_screen.dart`) | Save your own personal duas | 194 | islamic_tools_screen, my_wirdi_screen | كامل (ARB) |

### fatwa

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **General Rulings** (`fatwa_screen.dart`) | Common, widely-agreed questions | 82 | islamic_tools_screen | كامل (ARB) |

### favorites

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Favorites** (`favorites_screen.dart`) | المفضلة (آيات/أذكار) | 181 | home_dashboard_screen | كامل (ARB) |

### hadeeth_enc

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **HadeethEnc categories** (`hadeeth_category_screen.dart`) | تصنيفات مكتبة الأحاديث (HadeethEnc) | 105 | hadeeth_hub_screen | ar+en فقط |
| **Hadeeth detail** (`hadeeth_detail_screen.dart`) | تفاصيل الحديث (نص/شرح/فوائد) + مفضلة + مشاركة | 149 | hadeeth_category_screen, hadeeth_favorites_screen, hadeeth_search_screen | ar+en فقط |
| **Hadeeth favorites** (`hadeeth_favorites_screen.dart`) | الأحاديث المفضلة | 76 | hadeeth_hub_screen | ar+en فقط |
| **Prophetic Hadith** (`hadeeth_hub_screen.dart`) | The Forty Hadith of an-Nawawi and the Hadith Encyclopedia | 135 | islamic_tools_screen | ar+en فقط |
| **Hadeeth search** (`hadeeth_search_screen.dart`) | بحث في مكتبة الأحاديث | 91 | hadeeth_hub_screen | ar+en فقط |

### hadith

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Forty Hadith** (`hadith_collection_screen.dart`) | الأربعون النووية (بيانات fawazahmed0) | 282 | global_search_screen, hadeeth_hub_screen, home_dashboard_screen | مختلط (3 نص ar/en) |
| **Hadith Memorization** (`hadith_memorization_screen.dart`) | Memorize the 40 Hadith of an-Nawawi with a word-guessing game | 178 | islamic_tools_screen | كامل (ARB) |

### hajj

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Hajj & Umrah Guide** (`hajj_umrah_guide_screen.dart`) | Step-by-step guide with duas | 138 | islamic_tools_screen | كامل (ARB) |

### history

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Islamic Events** (`islamic_events_screen.dart`) | Ashura, Hijra, and more | 66 | islamic_tools_screen | كامل (ARB) |
| **Islamic History Quiz** (`islamic_history_quiz_screen.dart`) | Questions about major events in Islamic history | 111 | islamic_tools_screen | كامل (ARB) |
| **Islamic History** (`islamic_history_screen.dart`) | Timeline of major Islamic events | 34 | islamic_tools_screen | كامل (ARB) |

### home

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Home** (`home_dashboard_screen.dart`) | تحية + سلسلة الأيام، عدّ تنازلي للصلاة القادمة، طقس، حديث اليوم (مع streak)، 4 بطاقات (الورد اليومي/متابعة القراءة/المفضلة/اقتباس اليوم)، ملخص أسبوعي | 1027 | root_shell | مختلط (1 نص ar/en) |

### insights

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Activity Heatmap** (`activity_heatmap_screen.dart`) | See your activity over the weeks | 171 | islamic_tools_screen | كامل (ARB) |
| **Self-Accountability Journal** (`muhasabah_journal_screen.dart`) | A simple daily journal for reflection and self-improvement | 110 | islamic_tools_screen | كامل (ARB) |
| **Wirdi Insights** (`wirdi_insights_screen.dart`) | See your weekly worship stats and trends | 458 | home_dashboard_screen, islamic_tools_screen | كامل (ARB) |

### khatma

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Reading calendar** (`khatma_calendar_screen.dart`) | تقويم الأسابيع الأربعة الأخيرة لتحقيق هدف الورد اليومي | 207 | khatma_tracker_screen | كامل (ARB) |
| **Khatma Tracker** (`khatma_tracker_screen.dart`) | Plan and track finishing the Quran | 459 | home_dashboard_screen, islamic_tools_screen | مختلط (3 نص ar/en) |

### moon

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Moon Phase** (`moon_screen.dart`) | Current moon phase (astronomical estimate) | 269 | islamic_tools_screen | كامل (ARB) |

### mosque_finder

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Nearby Mosques & Halal Food** (`mosque_finder_screen.dart`) | Free search powered by OpenStreetMap data | 228 | islamic_tools_screen | كامل (ARB) |

### mushaf

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Mushaf pages** (`mushaf_view_screen.dart`) | عرض المصحف صفحة بصفحة (604 صفحة، wakelock، تلوين تجويد) | 794 | quran_screen | مختلط (11 نص ar/en) |

### onboarding

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Onboarding** (`onboarding_screen.dart`) | شرائح تعريفية؛ بعدها يُطلب إذن الإشعارات (v1.54) | 206 | main | كامل (ARB) |

### prayer

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Congregation Prayer** (`congregation_tracker_screen.dart`) | Track prayers performed in congregation | 161 | islamic_tools_screen | كامل (ARB) |
| **Iftar & Suhoor Countdown** (`fasting_countdown_screen.dart`) | Live countdown to Iftar time and end of Suhoor | 137 | islamic_tools_screen | كامل (ARB) |
| **Janazah Prayer Guide** (`janazah_guide_screen.dart`) | The four Takbirs and what to say in each | 87 | islamic_tools_screen | كامل (ARB) |
| **Monthly Prayer Times Table** (`monthly_prayer_calendar_screen.dart`) | localeName | 103 | islamic_tools_screen | كامل (ARB) |
| **Prayer Times in Another City** (`other_city_prayer_times_screen.dart`) | Check prayer times in any city without changing your own location | 104 | islamic_tools_screen | كامل (ARB) |
| **Export Prayer Times to Calendar** (`prayer_calendar_export_screen.dart`) | localeName | 110 | islamic_tools_screen | كامل (ARB) |
| **Prayer chart** (`prayer_chart_screen.dart`) | رسم بياني لمواقيت الصلاة | 87 | prayer_times_screen | كامل (ARB) |
| **Prayer times** (`prayer_times_screen.dart`) | مواقيت GPS أو مدينة، طرق حساب، إزاحات، إشعارات، رسم بياني | 717 | home_dashboard_screen, my_wirdi_screen, root_shell | مختلط (3 نص ar/en) |
| **Missed Prayers (Qada)** (`qada_tracker_screen.dart`) | Track and log the prayers you owe | 119 | islamic_tools_screen | كامل (ARB) |
| **Sujud al-Sahw Guide** (`sajda_sahw_guide_screen.dart`) | What to do when you forget something in prayer | 87 | islamic_tools_screen | كامل (ARB) |
| **localeName** (`travel_prayer_guide_screen.dart`) | Rules for shortening and combining prayers while traveling | 70 | islamic_tools_screen | كامل (ARB) |

### prophet

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **localeName** (`prophet_biography_screen.dart`) | Key events of his life | 70 | islamic_tools_screen | كامل (ARB) |
| **Stories of the Prophets** (`prophet_stories_screen.dart`) | Brief stories of several prophets, peace be upon them | 251 | islamic_tools_screen | كامل (ARB) |
| **Sahaba Quiz** (`sahaba_quiz_screen.dart`) | Questions about the lives and virtues of the companions | 111 | islamic_tools_screen | كامل (ARB) |

### qibla

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Precision Qibla (Pro)** (`advanced_qibla_screen.dart`) | Geomagnetic-model true-north compass | 237 | islamic_tools_screen | مختلط (1 نص ar/en) |
| **Qibla camera** (`qibla_camera_screen.dart`) | القبلة بالكاميرا (AR) | 201 | advanced_qibla_screen, qibla_screen | مختلط (1 نص ar/en) |
| **Qibla Direction** (`qibla_screen.dart`) | A compass to find the Qibla direction wherever you are | 419 | home_dashboard_screen, islamic_tools_screen | مختلط (1 نص ar/en) |

### quiz

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Islamic Quiz** (`quiz_screen.dart`) | Test your knowledge of Quran and Seerah | 219 | islamic_tools_screen | كامل (ARB) |

### quran

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Share ayah** (`ayah_share_screen.dart`) | بطاقة مشاركة آية كصورة | 211 | quran_screen | كامل (ARB) |
| **Hifz Revision** (`hifz_revision_screen.dart`) | Revise what you memorized before | 101 | islamic_tools_screen | كامل (ARB) |
| **Hifz Mode** (`hifz_screen.dart`) | Practice memorization by hiding words | 436 | islamic_tools_screen, study_plan_screen | ar+en فقط |
| **Memorization Test** (`memorization_game_screen.dart`) | Guess the missing word from the verse | 208 | islamic_tools_screen | كامل (ARB) |
| **Quran Reader** (`mushaf_reader_screen.dart`) | Read, listen and bookmark all 114 surahs | 1123 | islamic_tools_screen, quran_mini_player | ar+en فقط |
| **Quran** (`quran_screen.dart`) | 4 تبويبات (سور/أجزاء/بحث/مفضلة)؛ قراءة مع ترجمة وتفسير وحروف لاتينية؛ تشغيل صوتي (تكرار/سرعة/تحميل)؛ مشاركة آية | 1565 | bookmarks_screen, favorites_screen, global_search_screen +7 | مختلط (6 نص ar/en) |
| **Quranic Arabic Lessons** (`quranic_arabic_lessons_screen.dart`) | The most common Quranic words and their meanings | 53 | islamic_tools_screen | كامل (ARB) |
| **Recitation Mistake Log** (`recitation_mistake_log_screen.dart`) | Note recurring mistakes so you can focus on them | 159 | islamic_tools_screen | كامل (ARB) |
| **Reciter Info** (`reciter_comparison_screen.dart`) | Learn about each reciter | 114 | islamic_tools_screen | مختلط (1 نص ar/en) |
| **Sujud al-Tilawah Guide** (`sajda_tilawah_guide_screen.dart`) | When and how to perform the recitation prostration | 87 | islamic_tools_screen | كامل (ARB) |
| **Sajdah Verses** (`sajdah_verses_screen.dart`) | A list of the 15 sajdah-verse locations | 105 | islamic_tools_screen | كامل (ARB) |
| **Share card** (`shareable_text_card_screen.dart`) | بطاقة نصية قابلة للمشاركة (أدعية/أحاديث) | 162 | dua_library_screen, hadith_collection_screen | كامل (ARB) |
| **Study Plan** (`study_plan_screen.dart`) | A computed daily pace to memorize any surah | 129 | islamic_tools_screen | كامل (ARB) |
| **Surah Information** (`surah_comparison_screen.dart`) | Compare two surahs by verse count and length | 114 | islamic_tools_screen | مختلط (1 نص ar/en) |

### radio

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Radio player** (`radio_now_playing_screen.dart`) | مشغّل الراديو الكامل (مؤقّت نوم، ...) | 364 | radio_mini_player, radio_screen | كامل (ARB) |
| **Islamic Radio** (`radio_screen.dart`) | Listen to Quran & lectures live | 498 | islamic_tools_screen, root_shell | كامل (ARB) |

### ramadan

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Ramadan Companion** (`ramadan_companion_screen.dart`) | Countdown to suhoor and iftar, and fasting tracker | 296 | home_dashboard_screen, islamic_tools_screen | مختلط (3 نص ar/en) |
| **Sunnah Fasting Calendar** (`sunnah_fasting_calendar_screen.dart`) | Upcoming Mondays, Thursdays, and White Days | 77 | islamic_tools_screen | كامل (ARB) |

### sadaqah

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Sadaqah Jariyah Ideas** (`sadaqah_jariyah_ideas_screen.dart`) | Real suggestions for ongoing charity | 138 | islamic_tools_screen | كامل (ARB) |
| **Sadaqah Tracker** (`sadaqah_screen.dart`) | Log your charity | 229 | islamic_tools_screen | كامل (ARB) |

### search

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Global Search** (`global_search_screen.dart`) | Search everything at once | 277 | islamic_tools_screen | كامل (ARB) |

### settings

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **About** (`about_screen.dart`) | عن التطبيق | 49 | settings_screen | كامل (ARB) |
| **Notification diagnostics** (`notification_diagnostics_screen.dart`) | فحص الإذن والـ exact alarm وإعادة الجدولة وتقرير الحالة | 209 | settings_screen | ar+en فقط |
| **Privacy center** (`privacy_center_screen.dart`) | مركز الخصوصية: تصدير/حذف البيانات المحلية + رابط السياسة | 145 | settings_screen | كامل (ARB) |
| **Privacy policy** (`privacy_policy_screen.dart`) | نص السياسة (ar/en/de/tr؛ الباقي إنجليزي) | 151 | privacy_center_screen | كامل (ARB) |
| **Settings** (`settings_screen.dart`) | الإعدادات (مظهر، لغة، صلاة، تنبيهات، حساب، خصوصية، مصادر) | 1269 | home_dashboard_screen, root_shell | مختلط (33 نص ar/en) |
| **Sources & licenses** (`sources_licenses_screen.dart`) | المصادر والتراخيص | 35 | settings_screen | كامل (ARB) |
| **Theme colors** (`theme_selection_screen.dart`) | اختيار سمة الألوان | 202 | settings_screen | كامل (ARB) |

### splash

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Splash** (`splash_screen.dart`) | شاشة البداية (صورة mosque_sunrise + fade) ثم التوجيه للـ onboarding أو الرئيسية | 191 | main | كامل (ARB) |

### tasbeeh

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Tasbeeh** (`tasbeeh_screen.dart`) | سبحة رقمية بعبارات مخصصة وإحصاءات يومية/إجمالية | 433 | home_dashboard_screen, my_wirdi_screen, root_shell | كامل (ARB) |

### tools

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Hijri Converter** (`hijri_converter_screen.dart`) | Convert between Gregorian and Hijri dates | 78 | islamic_tools_screen | كامل (ARB) |
| **Islamic Etiquette (Adab)** (`islamic_etiquette_screen.dart`) | Etiquette of eating, sleeping, greeting, and sneezing | 125 | islamic_tools_screen | كامل (ARB) |
| **Islamic tools hub** (`islamic_tools_screen.dart`) | شاشة مركزية بها 62 مدخلًا (قائمة مسطحة بلا تجميع) | 471 | home_dashboard_screen | مختلط (96 نص ar/en) |
| **Islamic Will Guide** (`islamic_will_guide_screen.dart`) | General guidance for writing an Islamic will | 87 | islamic_tools_screen | كامل (ARB) |

### wird

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **My Wirdi** (`my_wirdi_screen.dart`) | See how you're doing today across all your worship | 246 | home_dashboard_screen, islamic_tools_screen | كامل (ARB) |

### zakat

| الشاشة | الوصف | سطر | يُفتح من | لغات |
|---|---|---:|---|---|
| **Qurbani & Aqiqah** (`qurbani_calculator_screen.dart`) | Info and share calculator for Qurbani & Aqiqah | 131 | islamic_tools_screen | كامل (ARB) |
| **Zakat Calculator** (`zakat_calculator_screen.dart`) | Calculate your Zakat with ease | 258 | islamic_tools_screen | كامل (ARB) |
| **Zakat al-Fitr Calculator** (`zakat_fitr_calculator_screen.dart`) | Calculate Zakat al-Fitr for your household | 85 | islamic_tools_screen | كامل (ARB) |
| **Zakat on Trade Goods** (`zakat_trade_goods_screen.dart`) | A separate calculator for business owners | 83 | islamic_tools_screen | كامل (ARB) |

**ملفات واجهة مساعدة (ليست شاشات):** `radio_mini_player`، `radio_station_tile`، `sleep_timer_sheet`، `quran_mini_player`، `quran_playback_bar`، `hadeeth_attribution`، `quranic_arabic_lessons_data`، `tajweed_legend` (غير مستخدم — انظر §16)، `wirdi_scenic_background` (غير مستخدم).

## 5. الخدمات (`core/services`)

| الملف | سطر | يُستخدم في | الوظيفة |
|---|---:|---:|---|
| `abjad_calculator` | 61 | 0 | Computes the traditional Abjad (Hisab al-Jummal) numeral value of an Arabic string -- the classical letter-to-number system where each Arabic letter carries a fixed nu... |
| `achievement_service` | 59 | 1 | حساب إحصاءات الإنجازات (أطول سلسلة، صفحات، أذكار، تسبيح، ختمات) لشاشة الإنجازات |
| `adhan_audio_cache` | 65 | 2 | تنزيل وتخزين ملفات الأذان محليًا لاستخدامها كصوت إشعار |
| `ambiance_service` | 23 | 1 | ⚠️ اختيار «صوت خلفية» للقراءة — يخزّن الاسم فقط ولا يشغّل أي صوت (stub) |
| `app_logger` | 18 | 22 | Minimal logging wrapper around dart:developer's log() — zero new dependencies, visible in `flutter run`/adb logcat/DevTools. |
| `arabic_text_utils` | 40 | 6 | Utilities for forgiving Arabic text search: the Quran text is fully vocalized (tashkeel/diacritics) and uses Uthmani-specific marks, but users type plain, undiacritize... |
| `articles_service` | 75 | 1 | 7 مقالات ثابتة داخل الكود |
| `audio_download_service` | 150 | 4 | Downloads ayah audio to local app storage for fully offline playback — no more waiting on a network fetch, even for the first play. |
| `auth_service` | 214 | 6 | Firebase Auth: بريد/Google (+Apple عبر Firebase بلا واجهة)، إعادة مصادقة، حذف |
| `azkar_repository` | 85 | 5 | Repository for the full Hisn Al Muslim azkar collection. |
| `bookmark_service` | 77 | 3 | الإشارات المرجعية المتقدمة |
| `boot_receiver` | 25 | 0 | BroadcastReceiver for BOOT_COMPLETED intent. |
| `custom_azkar_service` | 61 | 1 | أذكار يضيفها المستخدم |
| `daily_reminder_scheduler` | 156 | 3 | تذكيرات يومية: الجمعة، أذكار الصباح/المساء/النوم، الورد |
| `fatwa_service` | 40 | 1 | 15 حكمًا فقهيًا ثابتًا (سؤال/جواب/مصدر) داخل الكود |
| `hadeeth_enc_api_service` | 89 | 1 | Raw HTTP client for the HadeethEnc.com public API (no API key required). |
| `hadeeth_enc_repository` | 138 | 5 | Offline-first repository for the HadeethEnc.com hadith library. |
| `hadith_repository` | 129 | 4 | Offline-first repository for the Forty (42) Hadith of an-Nawawi, sourced from the fawazahmed0/hadith-api dataset (see [AppSources.hadithApiBase]). |
| `hajj_umrah_guide` | 117 | 1 | Step-by-step Hajj and Umrah guide with the recommended supplications (duas) for each stage, summarized from mainstream, widely-taught rulings. |
| `hifz_service` | 268 | 4 | Persists Hifz (memorization) progress: how many times each ayah has been repeated TODAY per plan, the user's active daily plans (each a surah + ayah range + target rep... |
| `hijri_date` | 83 | 5 | تحويل ميلادي→هجري بخوارزمية حسابية (Kuwaiti) — قد تختلف يومًا عن الرؤية |
| `islamic_events_service` | 95 | 1 | Recurring Islamic occasions throughout the Hijri year, with their historical origin, virtues, and commonly recommended practices. |
| `islamic_history_service` | 170 | 1 | A curated timeline of major early-Islamic events, summarized mainly from Ibn Hisham's seerah, At-Tabari's history, and Ibn Kathir's Al-Bidaya wa'l-Nihaya -- widely acc... |
| `islamic_occasions_service` | 53 | 1 | جدولة تذكيرات المناسبات الهجرية |
| `khatma_service` | 73 | 1 | خطط الختمة وتقدمها |
| `local_cache_service` | 36 | 8 | Thin wrapper around SharedPreferences for the offline-first caches (Quran text, Azkar dataset, last-known prayer times). |
| `mathhab_service` | 37 | 2 | المذهب (حنفي/مالكي/شافعي/حنبلي) — يحدّد `school` لوقت العصر |
| `moon_calculator` | 47 | 5 | حسابات طور القمر |
| `moon_phases_service` | 30 | 1 | أطوار القمر |
| `moon_sighting_service` | 47 | 1 | معلومات رؤية الهلال (حسابية) |
| `mushaf_repository` | 89 | 2 | Repository for the real 604-page Madani Mushaf ayah-to-page mapping, used to render a genuine page-by-page reading view (as opposed to the continuous per-surah list vi... |
| `nearby_places_service` | 200 | 1 | Finds nearby mosques and halal restaurants using: 1. |
| `notification_service` | 654 | 10 | A single reminder to schedule, already fully localized by the caller (this service has no BuildContext / AppLocalizations access, by design — same separation as prayer... |
| `playback_coordinator` | 29 | 2 | Wirdi has two independent audio engines -- Islamic Radio and Quran recitation -- that don't know about each other. |
| `prayer_display` | 23 | 3 | أسماء الصلوات بلغة الواجهة |
| `prayer_notification_scheduler` | 108 | 5 | جدولة إشعارات الصلاة والتذكير |
| `prayer_service` | 432 | 13 | Single source of truth for prayer times: real GPS + AlAdhan API, with an offline fallback to the last successful response (clearly marked as cached, never presented as... |
| `prophet_biography` | 119 | 1 | Key milestones of the Prophet Muhammad's (peace be upon him) life, summarized primarily from Ibn Hisham's "As-Seerah an-Nabawiyyah" and Safiur-Rahman al-Mubarakpuri's ... |
| `qibla_service` | 47 | 3 | Computes the compass bearing to the Kaaba from any point on Earth, using the standard great-circle initial-bearing formula (the same approach used by aviation/navigati... |
| `quran_audio_service` | 441 | 7 | App-wide Quran audio playback, deliberately NOT owned by any single screen's State — a screen-owned player is destroyed the moment the user navigates away (e.g. |
| `quran_repository` | 173 | 17 | Offline-first repository for the Quran text. |
| `quran_translation_repository` | 154 | 2 | Offline-first repository for verse-by-verse meaning translations, sourced from QuranEnc.com (see [AppSources.quranEncApiBase]). |
| `radio_service` | 321 | 10 | Which source is currently serving the station list. |
| `sadaqah_service` | 50 | 1 | سجل الصدقات |
| `sajda_tracker_service` | 47 | 2 | تتبع سجدات التلاوة |
| `settings_service` | 537 | 23 | App-wide settings, persisted and reactive via ChangeNotifier so MaterialApp can rebuild its theme/text scale live without adding a state-management package. |
| `sunrise_sunset_calculator` | 53 | 2 | حساب الشروق/الغروب محليًا |
| `sync_service` | 586 | 5 | Thrown by SyncService methods when there is no signed-in user to sync for -- previously uploadAll()/downloadAll() just silently returned in that case, which the UI (ac... |
| `tafsir_repository` | 142 | 3 | Offline-first repository for Tafsir Al-Muyassar. |
| `tajweed_helper` | 110 | 1 | Simplified, rule-based Tajweed color-coding applied directly to plain vocalized (fully-diacritized) Arabic Unicode text -- NOT dependent on the QCF page-image font sys... |
| `tajweed_service` | 148 | 1 | تلوين تجويد مبسّط (7 قواعد) |
| `transliteration_repository` | 94 | 1 | Offline-first repository for English transliteration. |
| `user_progress_service` | 486 | 22 | Persisted user progress/state shared across screens: favorites, per-item azkar counters (with real daily reset), daily wird tracking, and last-read position. |
| `verse_of_the_day_service` | 46 | 1 | آية اليوم |
| `weather_service` | 49 | 2 | طقس Open-Meteo عند موقع المستخدم |
| `widget_service` | 57 | 1 | تحديث widget الشاشة الرئيسية (حديث اليوم) |
| `wirdi_audio_handler` | 166 | 3 | Bridges Wirdi's existing Radio + Quran audio playback into the OS-level media session: lock-screen controls and the persistent notification-shade "now playing" card wi... |
| `word_by_word_repository` | 87 | 1 | معاني الكلمات (ummahapi.com) |

الأكبر: `sync_service` (586)، `notification_service` (654)، `settings_service` (537)، `user_progress_service` (486)، `quran_audio_service` (441)، `prayer_service` (432).

## 6. البيانات والنماذج

**بيانات داخل الكود (`core/data`):** `adhan_option` (6 أذان)، `app_sources` (كل الروابط + نصوص المصادر)، `asma_ul_husna` (99 اسمًا)، `bismillah`، `daily_quotes` (16 اقتباسًا)، `juz_data`، `radio_stations` (10 محطات احتياطية)، `reciters` (6 قرّاء: العفاسي، الحصري، المنشاوي، عبدالباسط، السديس، المعيقلي).

**نماذج (`core/models`):** azkar، bookmark، hadeeth_enc، hadith، khatma، mushaf، nearby_place، prayer، progress، quran، radio_station.

**محتوى مضمّن في `assets/data` (v1.54):** `quran.json` (114 سورة/6236 آية، 1.4MB)، `mushaf_pages.json` (604 صفحة، 1.9MB)، `azkar.json` (132 تصنيفًا / 267 ذكرًا، 163KB) + ملفات تراخيصها. **محتوى ثابت كبير داخل الكود:** الحج والعمرة، سيرة النبي، التاريخ الإسلامي، مناسبات، دروس عربية قرآنية، 15 حكمًا، 7 مقالات.

## 7. الإعدادات (`settings_service`، 27 مفتاحًا)

- **المظهر:** وضع الثيم، وضع AMOLED الأسود، تغيير تلقائي للداكن عند المغرب، سمة الألوان، تباين عالٍ، مقياس الخط، اللغة.
- **القرآن:** خط القرآن (3 خطوط بعد v1.54)، تلوين التجويد، الحروف اللاتينية، القارئ والمفضلون، الأذان المختار.
- **الصلاة:** طريقة الحساب، إزاحات كل صلاة، تذكير قبل/بعد الصلاة (مدة وأسلوب)، صوت مخصص، إشعار «الصلاة القادمة» الدائم، الصلوات المفعّلة.
- **أخرى:** تذكيرات يومية، تذكيرات الأذكار المخصصة، قفل الـ widget.

فحصتُ استهلاك كل إعداد: أغلبها له مستهلك فعلي. **استثناءات:** `prayerOffsets` (إزاحات المواقيت) تُطبَّق على النص المعروض في شاشة المواقيت فقط ولا تصل للعدّ التنازلي ولا الإشعارات ولا الـ widget (انظر التقرير الشامل F4)؛ و`textDirection` getter بلا استخدام.

## 8. التخزين المحلي والمزامنة

**SharedPreferences:** ~97 مفتاحًا حرفيًا (أكثرها في `user_progress_service` و`settings_service`)، منها: `azkar_*`، `tasbeeh_*`، `hifz plans`، `pinned_surahs`، `favorite_mosques`، `zakat_history`، `hadith_streak`، `last_read_position`، `cache_*` (قرآن/حروف لاتينية/مواقيت).

**Firestore** (`users/{uid}/data/{doc}` مع `merge` و`updatedAt` من الخادم): `settings`، `quran_progress`، `tasbeeh`، `profile`، `favorites`، `prayer_log`، `progress_stats`، `bookmarks`، `khatma`، `tasbeeh_custom`، `my_duas`، `custom_azkar`، `sadaqah`، `qada`، `muhasabah`، `recitation_mistakes`. الموقع الجغرافي **لا** يُزامَن.

## 9. الخدمات الخارجية

| الخدمة | تُستخدم لـ | يُرسَل إليها |
|---|---|---|
| AlAdhan (`api.aladhan.com`, `cdn.aladhan.com`) | مواقيت الصلاة + ملفات الأذان | إحداثيات أو اسم المدينة |
| Open-Meteo | طقس الرئيسية | إحداثيات تقريبية |
| Nominatim (OSM) | اسم المدينة/بحث المكان | إحداثيات أو نص |
| Overpass: `overpass-api.de` ثم `overpass.kumi.systems` ثم **`maps.mail.ru`** | أقرب مساجد/مطاعم | إحداثيات |
| `cdn.islamic.network` / `api.alquran.cloud` | صوت التلاوة + تفسير الميسّر | رقم السورة/الآية |
| QuranEnc | ترجمات المعاني | رقم السورة |
| HadeethEnc | مكتبة الأحاديث | تصنيف/بحث |
| jsDelivr | الأربعون النووية، حروف لاتينية (مثبّتة 3.1.2)، تحديث نص القرآن | لا شيء شخصي |
| ummahapi.com | معاني الكلمات | رقم الآية |
| mp3quran.net + Radio-Browser + بث المحطات | الراديو | عنوان IP فقط |
| `i.postimg.cc` | شعارات 10 محطات | IP |
| Firebase Auth + Firestore | حساب ومزامنة (اختياري) | بيانات الحساب |
| Google Sign-In | دخول Google (اختياري) | — |

## 10. الأندرويد

**الأذونات (12):** INTERNET، ACCESS_NETWORK_STATE، ACCESS_FINE/COARSE_LOCATION، POST_NOTIFICATIONS، SCHEDULE_EXACT_ALARM، RECEIVE_BOOT_COMPLETED، VIBRATE، CAMERA، WAKE_LOCK، FOREGROUND_SERVICE، FOREGROUND_SERVICE_MEDIA_PLAYBACK.  **uses-feature اختيارية:** camera, camera.autofocus, location, location.gps, sensor.compass.

**المكوّنات:** `MainActivity`، `AudioService` + `MediaButtonReceiver` (audio_service)، `ScheduledNotificationReceiver` + `ScheduledNotificationBootReceiver` (من flutter_local_notifications — هذا هو **الذي يعيد الجدولة بعد إعادة التشغيل فعليًا**)، `WirdiWidgetProvider` (Kotlin).

**قنوات الإشعارات (6):** `wirdi_prayer_reminder_v2`، `wirdi_prayer_adhan_v2`، `wirdi_prayer_beep_v1`، `wirdi_daily_reminder_v2`، `wirdi_ongoing_next_prayer_v1`، `wirdi_test`.  **معرّفات:** التذكيرات اليومية تبدأ من `900000000` (جمعة، صباح، مساء، ورد، نوم).

**الأمان الشبكي:** `usesCleartextTraffic=false` + `network_security_config`.

## 11. الأصول والخطوط

- **خطوط:** AmiriQuran (OFL)، KFGQPC Uthmanic HAFS وQPC Hafs (© مجمع الملك فهد، توزيع مجاني دون تعديل)، Tajawal ×3 (OFL). **أُزيلت في v1.54:** AlQuran Neo وIndoPak وMe Quran (تراخيص لا تسمح بالتوزيع).
- **صور:** `wirdi_mosaic.png` (2.0MB، يُستخدم كخلفية في 10 أماكن) و`generated/mosque_sunrise.png` (1.9MB) — **تحتاج ضغطًا** (WebP يوفّر ~3MB)؛ 8 صور طور القمر WebP؛ 6 صور في `assets/images/ui/` **غير مستخدمة وغير مضمّنة** (~465KB ملفات ميتة).
- **صوت:** `adhan_sound.mp3` (1.1MB) في `res/raw`.

## 12. الاعتماديات

Firebase (core/auth/firestore)، google_sign_in، home_widget، http، shared_preferences، intl، geolocator، audioplayers، audio_service، url_launcher، path_provider، share_plus، file_picker، flutter_local_notifications، timezone، google_fonts، package_info_plus، wakelock_plus، camera، flutter_compass_v2 (محلية). **غير مستخدمتين:** `sign_in_with_apple` و`cupertino_icons` (لا استيراد لهما في `lib/`). SDK: Dart ≥3.3، Flutter 3.35.5 في CI.

## 13. اللغات والترجمة

- 7 لغات × 659 مفتاحًا: **كاملة** (لا نقص).
- على مستوى الشاشات (94): **70 كاملة** من ARB، **16 مختلطة**، **8 ar+en فقط** (انظر عمود «لغات» في §4).
- لكن **285 موضع نص** مكتوب مباشرة في الكود بالعربية/الإنجليزية فقط، أكثرها في: الأدوات (96 — كل عناوين وأوصاف الـ 62 مدخلًا)، القرآن (75)، الإعدادات (44)، `hadeeth_enc` (37 — بلا أي مفتاح ARB). في de/tr/fr/es/id تظهر هذه بالإنجليزية.
- سياسة الخصوصية: ar/en/de/tr فقط (الباقي إنجليزي).

## 14. البناء والتشغيل (CI)

`build_apk.yml` (31 خطوة، يعمل على push لـ main/master وdispatch): يولّد مجلد android، يرقّع الـ manifest والـ MainActivity والـ gradle، يثبّت Firebase، **بوّابات صارمة** للتوقيع (debug ثم release للـ APK والـ AAB)، `flutter analyze`، `flutter test` (غير مانع حاليًا)، بناء debug APK، وبناء release AAB+APK عند وجود الأسرار.  **سكريبتات الجذر:** `patch_manifest.py`، `patch_gradle.py`، `patch_release_signing.py`، `patch_main_activity.py`، `scripts/verify_google_signin_config.py`، `setup_debug_signing.bat`.  **وثائق (10):** README، FIREBASE_SETUP، FIRESTORE_RULES، LOCAL_DEV_SETUP، RELEASE_SIGNING_SETUP، RELEASE_PREP_v1.54، MERGE_NOTES، UPGRADE_NOTES، UI_FIXES، الـ brief. ⚠️ `VERSION_MANIFEST.txt` و`_DIFF_MANIFEST.json` قديمان.

## 15. جودة الكود (أرقام)

| المقياس | القيمة |
|---|---|
| أكبر الملفات | `quran_screen` 1566، `settings_screen` 1270، `mushaf_reader_screen` 1124، `home_dashboard_screen` 1028، `mushaf_view_screen` 795 |
| أسطر أطول من 200 حرف | 458 |
| `catch (_)` صامتة | 46 |
| `print/debugPrint` | 23 |
| TODO/FIXME | 0 |
| اختبارات | 2 ملف (بيانات مضمّنة + فلتر الراديو) |
| إدارة الحالة | بلا مكتبة (`appSettings` عام + static services) |

## 16. النتائج: ما يحتاج معالجة

### أ) عيوب فعلية ظاهرة للمستخدم

1. **«صوت الخلفية» (Ambiance) وهمي.** في قارئ القرآن يختار المستخدم «Rain Sound / Ocean Waves / …» فيُحفظ الاسم فقط ولا يُشغَّل أي صوت (`ambiance_service.dart` بلا صوت ولا ملفات). إمّا يُخفى الخيار أو يُنفَّذ بأصوات مرخّصة.
2. **مفتاح ألوان التجويد بلا شرح.** `showTajweedLegend()` معرّفة ولا تُستدعى من أي مكان؛ فالمستخدم يفعّل تلوين التجويد دون أن يرى معنى الألوان.
3. **ترجمة ناقصة فعليًا** لـ de/tr/fr/es/id في قائمة الأدوات وأجزاء من القرآن والإعدادات وكل شاشات HadeethEnc (انظر §13).
4. **التاريخ الهجري حسابي بلا ضبط يدوي.** `hijri_date.dart` (Kuwaiti) قد يخالف الرؤية المحلية بيوم؛ وتنبيهات المناسبات (رمضان/العيد) مبنية عليه، وليس في الإعدادات إزاحة يوم.
5. **قائمة الأدوات مسطحة من 62 مدخلًا** بلا أقسام أو تجميع — صعبة الاكتشاف (توجد شاشة «البحث الشامل» كمدخل منفصل).
6. **7 تبويبات** في الشريط السفلي.

### ب) خصوصية وامتثال

1. **مرآة Overpass الثالثة `maps.mail.ru`** (تابعة لشركة Mail.ru/VK): تُرسَل إليها إحداثيات المستخدم إذا فشلت الأولى والثانية. سياسة الخصوصية (بنسختها المحدَّثة في v1.54) تذكر «Overpass API» عمومًا دون هذه الجهة. يُنصح بحذفها والإبقاء على الأوليين أو استضافة أوضح.
2. **User-Agent وبريد التواصل:** `nearby_places_service` يرسل `support@wirdi.app` (إن لم يكن بريدًا فعليًا لك فهو مخالف لسياسة Nominatim)، بينما `prayer_service` (الـ reverse geocoding عبر Nominatim) يرسل UA بلا أي وسيلة تواصل؛ وأرقام الإصدارات داخل الـ UA قديمة (1.52/1.53/1.0).
3. **شعارات 10 محطات** من `i.postimg.cc` (استضافة صور عامة قد تنتهي) — تُنقل إلى assets أو تُترك بأيقونة موحدة.
4. **محتوى ديني ثابت** (15 حكمًا + 7 مقالات + سيرة/تاريخ/حج) مكتوب داخل الكود؛ راجع نسبة المصادر والدقة قبل الترويج له كـ«فتاوى».
5. **Open-Meteo** مجاني للاستخدام غير التجاري فقط.

### ج) كود ميت أو مكرر (لا يضر تشغيلًا، لكنه يربك الصيانة)

| العنصر | الملف | الملاحظة |
|---|---|---|
| `BootReceiver` | `core/services/boot_receiver.dart` | **stub لا يفعل شيئًا** (يطبع log فقط) وغير مستورد؛ إعادة الجدولة تتم عبر مستقبِل الإضافة |
| `HijriConverter` | داخل `khatma_calendar_screen.dart` | تنفيذ ثانٍ للتحويل الهجري غير مستخدم (والتعليق فوقه يخص الشاشة) |
| `AbjadCalculator` | `abjad_calculator.dart` | حاسبة حساب الجمّل غير موصولة بأي شاشة |
| `showTajweedLegend` | `tajweed_legend.dart` | غير مستدعاة |
| `WirdiScenicBackground` | `shared/widgets` | غير مستخدم |
| `textDirection` getter | `settings_service.dart` | بلا استهلاك |
| `sign_in_with_apple` | `pubspec.yaml` | حزمة غير مستوردة (Apple يمر عبر Firebase بلا واجهة) |
| 6 صور `assets/images/ui/*.jpg` | `assets/` | غير مستخدمة |
| `VERSION_MANIFEST.txt`, `_DIFF_MANIFEST.json` | الجذر | ملاحظات قديمة |

### د) نقاط قوة موثّقة

لا شاشات يتيمة؛ إعدادات كلها مستهلكة؛ Leitner فعلي لمراجعة الحفظ؛ مزامنة بـ server timestamps؛ حذف حساب يمسح Firestore أولًا؛ بيانات القرآن/المصحف/الأذكار مضمّنة ومحمية باختبارات؛ بوّابات توقيع صارمة في CI؛ خصوصية: لا إعلانات ولا analytics؛ تشخيص إشعارات مدمج.

## 17. تصحيح لما قلته سابقًا

- قلت إن الترجمات «كاملة»: صحيح لملفات ARB (659×7) لكن **ليس لكل الواجهة** (انظر §13).
- ذكرتُ «`boot_receiver` موجود» عند الحديث عن إعادة الجدولة بعد التشغيل: كلاس Dart المذكور **stub**؛ الآلية الفعلية هي `ScheduledNotificationBootReceiver` من الإضافة (مُعلَن في الـ manifest).
- اقترحتُ سابقًا إضافة إنجازات وتقويم هجري وبحث وتحميل للصوت ومراجعة حفظ بالتكرار المتباعد: **كلها موجودة** (انظر §4).
- **ما لا يزال غير موجود فعلًا:** طلب تقييم Play (in_app_review)، مراقبة الأعطال، مشاركة العائلة، إرشاد استثناء توفير البطارية، تغطية وصولية واسعة (15 `Semantics`، 0 `semanticLabel` على 94 شاشة)، وملخصات لـ111 سورة (لـ3 فقط).

## 18. مرور ثانٍ للبحث عن أخطاء منطقية (أُضيف بعد الجرد)

> بُنيت هذه النتائج على قراءة الكود، **ولم تُختبر على جهاز**. مستوى الثقة مذكور لكل بند.

| # | الخطورة | المشكلة | الدليل | الثقة |
|---|---|---|---|---|
| 1 | عالية | **إشعارات الصلاة تُجدول ليومين فقط (اليوم وغدًا)** ولا تُجدَّد إلا عند فتح التطبيق؛ لا يوجد مهمة خلفية. إذا لم يفتح المستخدم التطبيق 3 أيام يتوقف الأذان والتذكير. | `prayer_notification_scheduler.dart` (`addFor(result.prayers, today)` ثم `fetchTomorrowPrayers()` فقط)؛ الاستدعاءات كلها من شاشات (root_shell/home/prayer/settings) | عالية |
| 2 | عالية | **اختيار الأذان (6 خيارات) غالبًا بلا تأثير على أندرويد 8+**: الصوت يُحدَّد على «قناة الإشعار» لا على الإشعار الفردي، والقناة `wirdi_prayer_adhan_v2` ثابتة بصوت `adhan_sound`؛ كما أن `UriAndroidNotificationSound` يُمرَّر له مسار ملف داخل مساحة التطبيق الخاصة (لا يصل إليه النظام). النتيجة المرجّحة: يُسمع الأذان الافتراضي دائمًا وتُهدر ملفات `AdhanAudioCache`. | `notification_service.dart` أسطر ~419 و~579–611 | متوسطة-عالية — **جرّب: غيّر الأذان وانتظر صلاة** |
| 3 | متوسطة | **التذكيرات اليومية المتكررة** (أذكار الصباح/المساء/النوم، الجمعة، الورد) تُجدول بـ `matchDateTimeComponents` لكن بمنطقة زمنية **UTC** مصطنعة؛ الإضافة تكرر «الساعة» بتوقيت UTC، فتنزاح ساعة عند تغيير التوقيت الصيفي (مصر وألمانيا) ولا تتبع المستخدم إذا سافر. | `notification_service.dart` ~463–504 (`tz.TZDateTime.from(scheduledLocal, tz.UTC)`) | متوسطة — تحتاج تجربة عبر تغيير توقيت |
| 4 | متوسطة | **`QuranRepository.load` بلا كاش في الذاكرة** ويفك JSON بحجم 1.4MB على خيط الواجهة في **كل** استدعاء (15 موضعًا)؛ بينما مستودعات التفسير والمصحف والحروف اللاتينية تستخدم `compute()` وكاش ذاكرة. توقّع تقطيع (jank) عند فتح شاشات القرآن على الأجهزة الضعيفة. (المسار الجديد للنسخة المضمّنة الذي أضفتُه في v1.54 يرث نفس المشكلة — كان يجب أن أستخدم `compute` فيه.) | `quran_repository.dart` (`_parse` متزامن، لا `_memoryCache`) | عالية للبنية، والأثر الفعلي يحتاج قياسًا |
| 5 | منخفضة | تسريبات بسيطة: `TextEditingController` بلا `dispose` في 7 شاشات (account، my_duas، muhasabah، khatma_tracker، recitation_mistake_log، global_search، tasbeeh)، و`PageController` في onboarding، و`stream.listen` بلا `cancel` في settings_screen. | فحص آلي لكل ملف | عالية (تأثير صغير) |
| 6 | منخفضة | القاعدة `use_build_context_synchronously` **معطّلة** في `analysis_options.yaml`، فتُخفى تحذيرات استخدام `context` بعد `await`؛ و`tasbeeh_screen` يستدعي `setState` بعد `await` بلا `mounted` في عدة مواضع. | `analysis_options.yaml` + `tasbeeh_screen.dart` | عالية |
| 7 | معلومة | إشعار «الصلاة القادمة» الدائم نصّه ثابت وقت نشره، ولا يتحدث بعد مرور الصلاة إلا عند إعادة فتح التطبيق. | `showOngoingNextPrayer` + نقطة 1 | متوسطة |

**ما فُحص وتبيّن سليمًا:** كل طلبات `http` لها `timeout`؛ قواعد Firestore تقيّد الوصول بـ `users/{uid}`؛ لا توجد أسرار (مفاتيح API خاصة) مكتوبة في الكود عدا `google-services.json` المعتاد (وقيّده من Google Cloud).

**لم يُفحص بعد (خارج ما استطعت التحقق منه هنا):** صحة حسابات المواقيت والقبلة رياضيًا، تفاصيل منطق المزامنة عند التعارض، دقة المحتوى الديني الثابت، الأداء الفعلي والذاكرة، وأي سلوك يحتاج جهازًا حقيقيًا.
