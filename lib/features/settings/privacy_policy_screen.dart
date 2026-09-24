import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/app_sources.dart';
import '../../l10n/generated/app_localizations.dart';

/// Privacy policy text describing what this codebase actually does (v1.54):
/// bundled Quran/Azkar data, optional account + cloud sync, location used for
/// prayer times / weather / Qibla / nearby places, camera only for the Qibla
/// camera mode, no ads and no analytics. Keep it in sync with docs/privacy-policy.html
/// and with the real data flows if any are added.
/// (French, Spanish and Indonesian fall back to English.)
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Map<String, List<(String, String)>> _sectionsByLocale = {
    'ar': [
      ('البيانات التي يجمعها التطبيق',
       'يمكنك استخدام التطبيق بدون حساب، وفي هذه الحالة لا يُجمع اسمك ولا بريدك الإلكتروني. إذا أنشأت حسابًا (بالبريد الإلكتروني أو جوجل أو آبل) لمزامنة بياناتك بين أجهزتك، فإننا نجمع بريدك الإلكتروني واسم العرض وصورة الملف الشخصي (إن وُجدت) من مزوّد تسجيل الدخول الذي اخترته. يُستخدم موقعك الجغرافي (خط الطول والعرض) فقط في الميزات التي تحتاجه: مواقيت الصلاة والطقس في الشاشة الرئيسية، وشاشات مواقيت الصلاة، والقبلة، وأقرب المساجد والمطاعم الحلال. ويُرسَل إلى الخدمات الخارجية المذكورة أدناه للحصول على المواقيت والطقس وأسماء الأماكن والأماكن القريبة. لا نخزّنه على خوادمنا ولا نربطه بحسابك.'),
      ('أين تُخزَّن بياناتك',
       'بدون تسجيل الدخول: كل بيانات الاستخدام (المفضلة، عدادات الأذكار، إحصاءات التسبيح، آخر موضع قراءة، إعدادات الوضع الليلي وحجم الخط) تُخزَّن محليًا على جهازك فقط باستخدام SharedPreferences ولا تُرسَل إلى أي خادم. حذف التطبيق أو استخدام "حذف البيانات المحلية" في الإعدادات يمسحها نهائيًا.\nبعد تسجيل الدخول: تُخزَّن البيانات نفسها أيضًا في قاعدة بيانات Cloud Firestore التابعة لـ Firebase من جوجل، مرتبطة بحسابك فقط، لتتم مزامنتها بين أجهزتك.'),
      ('الحساب والمزامنة السحابية',
       'إنشاء الحساب اختياري تمامًا. عند تسجيل الدخول بالبريد الإلكتروني أو جوجل أو آبل تُدير خدمة Firebase Authentication (التابعة لجوجل) تسجيل الدخول، وتحفظ خدمة Cloud Firestore (التابعة لجوجل أيضًا) نسخة سحابية من بياناتك لمزامنتها بين الأجهزة المسجَّلة بنفس الحساب. لا تُشارَك هذه البيانات مع أي طرف ثالث خارج بنية Firebase/Google التي تدعم هذه الميزة.'),
      ('خدمات خارجية يتصل بها التطبيق',
       '• نص القرآن الكريم والأذكار: مضمَّنان داخل التطبيق (Quran JSON المبني على بيانات Tanzil، وIslamic Pro Azkar API)، وقراءتهما لا تُنشئ أي طلب شبكة.\n• مواقيت الصلاة: AlAdhan Prayer Times API (إحداثياتك أو المدينة التي تختارها).\n• الطقس في الشاشة الرئيسية: Open-Meteo (إحداثياتك التقريبية).\n• أسماء الأماكن وأقرب المساجد والمطاعم الحلال: OpenStreetMap Nominatim وOverpass API (إحداثياتك أو المكان الذي تكتبه).\n• ترجمات القرآن والتفسير والأحاديث: QuranEnc.com وAl Quran Cloud وHadeethEnc.com وjsDelivr (لا تُرسَل بيانات شخصية سوى عنوان IP).\n• معاني الكلمات: ummahapi.com.\n• التلاوة الصوتية: Islamic Network CDN.\n• الراديو: mp3quran.net وRadio-Browser لقائمة المحطات؛ وخادم البث للمحطة التي تشغّلها يرى عنوان IP الخاص بك.\n• تسجيل الدخول والمزامنة (فقط إذا أنشأت حسابًا): Firebase Authentication وCloud Firestore من جوجل.\nتذهب هذه الطلبات مباشرة من جهازك إلى تلك الخدمات؛ يُرجى مراجعة سياسات الخصوصية الخاصة بها.'),
      ('الإعلانات والتحليلات',
       'لا يحتوي التطبيق على إعلانات، ولا يستخدم أي أداة تحليلات أو تتبع لسلوك المستخدم في هذا الإصدار.'),
      ('أذونات الجهاز',
       'الموقع: لمواقيت صلاة دقيقة والطقس والقبلة والأماكن القريبة (اختياري). الإشعارات والمنبّهات الدقيقة: لتنبيهات الصلاة والتذكيرات وأزرار التحكم في التشغيل الصوتي (اختياري). الكاميرا: فقط في وضع القبلة بالكاميرا لعرض الصورة الحيّة؛ تُعالَج الصورة على جهازك ولا تُحفظ ولا تُرفع. يمكنك رفض أي إذن أو سحبه من إعدادات النظام، وتبقى بقية الميزات تعمل.'),
      ('حذف بياناتك',
       'البيانات المحلية: استخدم "حذف البيانات المحلية" من الإعدادات، أو احذف التطبيق. الحساب والبيانات السحابية: افتح الإعدادات، ثم اضغط على حسابك في الأعلى، ثم اختر "حذف الحساب". يؤدي ذلك إلى حذف حسابك وكل ما زامنته إلى السحابة نهائيًا.'),
    ],
    'en': [
      ('Data the app collects',
       'You can use the app without an account; in that case your name and email are never collected. If you create an account (email, Google or Apple) to sync between your devices, we collect the email address, display name and profile photo (if any) from the sign-in provider you choose. Your device location (latitude and longitude) is used only by features that need it: prayer times and weather on the Home screen, the Prayer Times screens, Qibla, and Nearby Mosques & Halal Restaurants. It is sent to the third-party services listed below to obtain prayer times, weather, place names and nearby places. We do not store it on our servers and do not link it to your account.'),
      ('Where your data is stored',
       'Without signing in: all usage data (favorites, azkar counters, tasbeeh stats, last reading position, dark-mode and font-size settings) is stored locally on your device only, using SharedPreferences, and is never sent to any server. Deleting the app, or using "Delete local data" in Settings, erases it permanently.\nAfter signing in: the same data is also stored in Google Firebase\'s Cloud Firestore database, tied only to your own account, so it can sync across your devices.'),
      ('Account & cloud sync',
       'Creating an account is entirely optional. When you sign in via email, Google or Apple, Firebase Authentication (a Google service) manages sign-in, and Cloud Firestore (also a Google service) stores a cloud copy of your data to sync it across devices signed into the same account. This data is not shared with any third party outside the Firebase/Google infrastructure that powers this feature.'),
      ('External services the app connects to',
       '• Quran text and Azkar: bundled inside the app (Quran JSON, based on Tanzil data; Islamic Pro Azkar API). Reading them makes no network request.\n• Prayer times: AlAdhan Prayer Times API (your coordinates, or the city you choose).\n• Weather on the Home screen: Open-Meteo (your approximate coordinates).\n• Place names, nearby mosques and halal restaurants: OpenStreetMap Nominatim and Overpass API (your coordinates, or the place you type).\n• Quran translations, Tafsir and Hadith: QuranEnc.com, Al Quran Cloud, HadeethEnc.com and jsDelivr (no personal data beyond your IP address).\n• Word-by-word meanings: ummahapi.com.\n• Recitation audio: Islamic Network CDN.\n• Radio: mp3quran.net and Radio-Browser provide the station list; the stream server of a station you play can see your IP address.\n• Sign-in and sync (only if you create an account): Firebase Authentication and Cloud Firestore (Google).\nThese requests go directly from your device to those services; please review their own privacy policies.'),
      ('Ads and analytics',
       'The app contains no ads and uses no analytics or user-tracking tools in this version.'),
      ('Device permissions',
       'Location: accurate prayer times, weather, Qibla and nearby places (optional). Notifications and exact alarms: prayer-time and reminder alerts, and audio playback controls (optional). Camera: only in the Qibla camera mode, to show the live camera image; the image is processed on your device and is never saved or uploaded. You can deny or revoke any permission in your system settings; the rest of the app keeps working.'),
      ('Deleting your data',
       'Local data: use "Delete local data" in Settings, or uninstall the app. Account and cloud data: open Settings, tap your account at the top, then choose Delete Account. This permanently deletes your account and all data synced to the cloud.'),
    ],
    'de': [
      ('Welche Daten die App sammelt',
       'Du kannst die App ohne Konto nutzen; dann werden dein Name und deine E-Mail-Adresse nie erfasst. Wenn du ein Konto erstellst (E-Mail, Google oder Apple), um zwischen deinen Geräten zu synchronisieren, erfassen wir E-Mail-Adresse, Anzeigenamen und ggf. das Profilbild des gewählten Anmeldeanbieters. Dein Gerätestandort (Breiten- und Längengrad) wird nur von Funktionen genutzt, die ihn brauchen: Gebetszeiten und Wetter auf dem Startbildschirm, die Gebetszeiten-Bildschirme, Qibla sowie Moscheen und Halal-Restaurants in der Nähe. Er wird an die unten genannten Drittdienste gesendet, um Gebetszeiten, Wetter, Ortsnamen und Orte in der Nähe zu erhalten. Wir speichern ihn nicht auf unseren Servern und verknüpfen ihn nicht mit deinem Konto.'),
      ('Wo deine Daten gespeichert werden',
       'Ohne Anmeldung: Alle Nutzungsdaten (Favoriten, Adhkar-Zähler, Tasbih-Statistiken, letzte Leseposition, Dunkelmodus- und Schriftgrößeneinstellungen) werden ausschließlich lokal auf deinem Gerät über SharedPreferences gespeichert und nie an einen Server gesendet. Das Löschen der App oder „Lokale Daten löschen” in den Einstellungen entfernt sie dauerhaft.\nNach der Anmeldung: Dieselben Daten werden zusätzlich in der Cloud-Firestore-Datenbank von Google Firebase gespeichert, nur mit deinem eigenen Konto verknüpft, damit sie zwischen deinen Geräten synchronisiert werden.'),
      ('Konto und Cloud-Synchronisierung',
       'Ein Konto ist vollständig optional. Bei der Anmeldung per E-Mail, Google oder Apple verwaltet Firebase Authentication (ein Google-Dienst) die Anmeldung, und Cloud Firestore (ebenfalls ein Google-Dienst) speichert eine Cloud-Kopie deiner Daten, um sie zwischen Geräten mit demselben Konto zu synchronisieren. Diese Daten werden nicht an Dritte außerhalb der Firebase/Google-Infrastruktur weitergegeben.'),
      ('Externe Dienste, mit denen sich die App verbindet',
       '• Korantext und Adhkar: in der App enthalten (Quran JSON auf Basis der Tanzil-Daten; Islamic Pro Azkar API). Das Lesen erzeugt keine Netzwerkanfrage.\n• Gebetszeiten: AlAdhan Prayer Times API (deine Koordinaten oder die gewählte Stadt).\n• Wetter auf dem Startbildschirm: Open-Meteo (deine ungefähren Koordinaten).\n• Ortsnamen, Moscheen und Halal-Restaurants in der Nähe: OpenStreetMap Nominatim und Overpass API (deine Koordinaten oder der eingegebene Ort).\n• Koranübersetzungen, Tafsir und Hadith: QuranEnc.com, Al Quran Cloud, HadeethEnc.com und jsDelivr (keine personenbezogenen Daten außer deiner IP-Adresse).\n• Wort-für-Wort-Bedeutungen: ummahapi.com.\n• Rezitationsaudio: Islamic Network CDN.\n• Radio: mp3quran.net und Radio-Browser liefern die Senderliste; der Stream-Server eines abgespielten Senders sieht deine IP-Adresse.\n• Anmeldung und Synchronisierung (nur mit Konto): Firebase Authentication und Cloud Firestore (Google).\nDiese Anfragen gehen direkt von deinem Gerät an die Dienste; bitte lies deren eigene Datenschutzerklärungen.'),
      ('Werbung und Analyse',
       'Die App enthält in dieser Version keine Werbung und nutzt keine Analyse- oder Tracking-Tools.'),
      ('Geräteberechtigungen',
       'Standort: genaue Gebetszeiten, Wetter, Qibla und Orte in der Nähe (optional). Benachrichtigungen und exakte Alarme: Gebets- und Erinnerungsmeldungen sowie Steuerung der Audiowiedergabe (optional). Kamera: nur im Qibla-Kameramodus, um das Live-Bild anzuzeigen; das Bild wird auf deinem Gerät verarbeitet und weder gespeichert noch hochgeladen. Du kannst jede Berechtigung in den Systemeinstellungen verweigern oder widerrufen; der Rest der App funktioniert weiter.'),
      ('Löschen deiner Daten',
       'Lokale Daten: „Lokale Daten löschen” in den Einstellungen oder die App deinstallieren. Konto und Cloud-Daten: Einstellungen öffnen, oben dein Konto antippen und „Konto löschen” wählen. Dadurch werden dein Konto und alle in die Cloud synchronisierten Daten dauerhaft gelöscht.'),
    ],
    'tr': [
      ('Uygulamanın topladığı veriler',
       'Uygulamayı hesap olmadan kullanabilirsiniz; bu durumda adınız ve e-postanız asla toplanmaz. Cihazlarınız arasında senkronizasyon için hesap oluşturursanız (e-posta, Google veya Apple), seçtiğiniz oturum açma sağlayıcısından e-posta adresinizi, görünen adınızı ve varsa profil fotoğrafınızı toplarız. Cihaz konumunuz (enlem ve boylam) yalnızca ona ihtiyaç duyan özelliklerde kullanılır: ana ekrandaki namaz vakitleri ve hava durumu, Namaz Vakitleri ekranları, Kıble ve Yakındaki Camiler ile Helal Restoranlar. Namaz vakitlerini, hava durumunu, yer adlarını ve yakındaki yerleri almak için aşağıda listelenen üçüncü taraf hizmetlere gönderilir. Sunucularımızda saklamaz ve hesabınızla ilişkilendirmeyiz.'),
      ('Verileriniz nerede saklanır',
       'Oturum açmadan: tüm kullanım verileri (favoriler, zikir sayaçları, tesbih istatistikleri, son okuma konumu, karanlık mod ve yazı boyutu ayarları) yalnızca SharedPreferences ile cihazınızda yerel olarak saklanır ve hiçbir sunucuya gönderilmez. Uygulamayı silmek veya Ayarlar\'daki "Yerel verileri sil" bunları kalıcı olarak siler.\nOturum açtıktan sonra: aynı veriler, cihazlarınız arasında senkronize edilmek üzere yalnızca kendi hesabınıza bağlı olarak Google Firebase\'in Cloud Firestore veritabanında da saklanır.'),
      ('Hesap ve bulut senkronizasyonu',
       'Hesap oluşturmak tamamen isteğe bağlıdır. E-posta, Google veya Apple ile oturum açtığınızda Firebase Authentication (bir Google hizmeti) oturumu yönetir; Cloud Firestore (yine bir Google hizmeti) verilerinizin bulut kopyasını aynı hesapla oturum açmış cihazlar arasında senkronize etmek için saklar. Bu veriler, bu özelliği destekleyen Firebase/Google altyapısı dışındaki hiçbir üçüncü tarafla paylaşılmaz.'),
      ('Uygulamanın bağlandığı harici hizmetler',
       '• Kur\'an metni ve Zikirler: uygulamanın içinde gömülüdür (Tanzil verilerine dayanan Quran JSON; Islamic Pro Azkar API). Okunmaları ağ isteği oluşturmaz.\n• Namaz vakitleri: AlAdhan Prayer Times API (koordinatlarınız veya seçtiğiniz şehir).\n• Ana ekrandaki hava durumu: Open-Meteo (yaklaşık koordinatlarınız).\n• Yer adları, yakındaki camiler ve helal restoranlar: OpenStreetMap Nominatim ve Overpass API (koordinatlarınız veya yazdığınız yer).\n• Kur\'an mealleri, Tefsir ve Hadis: QuranEnc.com, Al Quran Cloud, HadeethEnc.com ve jsDelivr (IP adresiniz dışında kişisel veri yok).\n• Kelime kelime anlamlar: ummahapi.com.\n• Tilavet sesleri: Islamic Network CDN.\n• Radyo: istasyon listesi mp3quran.net ve Radio-Browser\'dan gelir; dinlediğiniz istasyonun yayın sunucusu IP adresinizi görebilir.\n• Oturum açma ve senkronizasyon (yalnızca hesap oluşturursanız): Firebase Authentication ve Cloud Firestore (Google).\nBu istekler doğrudan cihazınızdan bu hizmetlere gider; lütfen kendi gizlilik politikalarını inceleyin.'),
      ('Reklamlar ve analiz',
       'Uygulama bu sürümde reklam içermez ve hiçbir analiz veya kullanıcı takip aracı kullanmaz.'),
      ('Cihaz izinleri',
       'Konum: doğru namaz vakitleri, hava durumu, Kıble ve yakındaki yerler (isteğe bağlı). Bildirimler ve tam zamanlı alarmlar: namaz vakti ve hatırlatma uyarıları ile ses oynatma kontrolleri (isteğe bağlı). Kamera: yalnızca Kıble kamera modunda canlı görüntüyü göstermek için; görüntü cihazınızda işlenir, asla kaydedilmez veya yüklenmez. Her izni sistem ayarlarından reddedebilir veya geri alabilirsiniz; uygulamanın geri kalanı çalışmaya devam eder.'),
      ('Verilerinizi silme',
       'Yerel veriler: Ayarlar\'daki "Yerel verileri sil" veya uygulamayı kaldırın. Hesap ve bulut verileri: Ayarlar\'ı açın, üstteki hesabınıza dokunun ve Hesabı Sil\'i seçin. Bu işlem hesabınızı ve buluta senkronize edilen tüm verileri kalıcı olarak siler.'),
    ],
  };

  static const Map<String, String> _lastUpdatedByLocale = {
    'ar': 'آخر تحديث: سبتمبر 2026',
    'en': 'Last updated: September 2026',
    'de': 'Zuletzt aktualisiert: September 2026',
    'tr': 'Son güncelleme: Eylül 2026',
  };

  static const Map<String, String> _viewOnlineByLocale = {
    'ar': 'عرض السياسة على الإنترنت',
    'en': 'View online',
    'de': 'Online ansehen',
    'tr': 'Çevrimiçi görüntüle',
  };

  static const Map<String, String> _contactByLocale = {
    'ar': 'للتواصل',
    'en': 'Contact',
    'de': 'Kontakt',
    'tr': 'İletişim',
  };

  Future<void> _openOnline() async {
    final uri = Uri.tryParse(AppSources.privacyPolicyUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final sections = _sectionsByLocale[languageCode] ?? _sectionsByLocale['en']!;
    final lastUpdated = _lastUpdatedByLocale[languageCode] ?? _lastUpdatedByLocale['en']!;
    final viewOnline = _viewOnlineByLocale[languageCode] ?? _viewOnlineByLocale['en']!;
    final contactLabel = _contactByLocale[languageCode] ?? _contactByLocale['en']!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicyTitle), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          Text(
            lastUpdated,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          for (final (title, body) in sections) ...[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(height: 1.7)),
            const SizedBox(height: 20),
          ],
          if (AppSources.privacyContactEmail.isNotEmpty) ...[
            Text('$contactLabel: ${AppSources.privacyContactEmail}', style: const TextStyle(height: 1.7)),
            const SizedBox(height: 12),
          ],
          if (AppSources.privacyPolicyUrl.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: _openOnline,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(viewOnline),
              ),
            ),
        ],
      ),
    );
  }
}
