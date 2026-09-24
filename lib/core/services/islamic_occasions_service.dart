import 'notification_service.dart';
import 'hijri_date.dart';
import 'settings_service.dart';

class _Occasion {
  final int hijriMonth;
  final int hijriDay;
  final int idOffset; // also the index into _occasionNames
  const _Occasion(this.hijriMonth, this.hijriDay, this.idOffset);
}

const List<_Occasion> _occasions = [
  _Occasion(1, 1, 0),
  _Occasion(1, 10, 1),
  _Occasion(7, 27, 2),
  _Occasion(9, 1, 3),
  _Occasion(9, 21, 4),
  _Occasion(10, 1, 5),
  _Occasion(12, 9, 6),
  _Occasion(12, 10, 7),
];

/// Occasion names per language, indexed by [_Occasion.idOffset].
const List<Map<String, String>> _occasionNames = [
  {'ar': 'رأس السنة الهجرية', 'en': 'Islamic New Year', 'de': 'Islamisches Neujahr', 'tr': 'Hicri Yılbaşı', 'fr': 'Nouvel An hégirien', 'es': 'Año Nuevo islámico', 'id': 'Tahun Baru Islam'},
  {'ar': 'يوم عاشوراء', 'en': 'Day of Ashura', 'de': 'Aschura-Tag', 'tr': 'Aşure Günü', 'fr': 'Jour d\'Achoura', 'es': 'Día de Áshura', 'id': 'Hari Asyura'},
  {'ar': 'الإسراء والمعراج', 'en': 'Isra and Miraj', 'de': 'Isra und Miradsch', 'tr': 'İsra ve Mirac', 'fr': 'Isra et Miraj', 'es': 'Isra y Miraj', 'id': 'Isra Mikraj'},
  {'ar': 'بداية شهر رمضان', 'en': 'Start of Ramadan', 'de': 'Beginn des Ramadan', 'tr': 'Ramazan başlangıcı', 'fr': 'Début du Ramadan', 'es': 'Inicio del Ramadán', 'id': 'Awal Ramadan'},
  {'ar': 'بداية العشر الأواخر من رمضان', 'en': 'Start of the last ten nights of Ramadan', 'de': 'Beginn der letzten zehn Nächte des Ramadan', 'tr': 'Ramazan\'ın son on gecesinin başlangıcı', 'fr': 'Début des dix dernières nuits du Ramadan', 'es': 'Inicio de las últimas diez noches del Ramadán', 'id': 'Awal sepuluh malam terakhir Ramadan'},
  {'ar': 'عيد الفطر', 'en': 'Eid al-Fitr', 'de': 'Fest des Fastenbrechens (Eid al-Fitr)', 'tr': 'Ramazan Bayramı', 'fr': 'Aïd el-Fitr', 'es': 'Eid al-Fitr', 'id': 'Idulfitri'},
  {'ar': 'يوم عرفة', 'en': 'Day of Arafah', 'de': 'Tag von Arafat', 'tr': 'Arefe Günü', 'fr': 'Jour d\'Arafat', 'es': 'Día de Arafat', 'id': 'Hari Arafah'},
  {'ar': 'عيد الأضحى', 'en': 'Eid al-Adha', 'de': 'Opferfest (Eid al-Adha)', 'tr': 'Kurban Bayramı', 'fr': 'Aïd el-Adha', 'es': 'Eid al-Adha', 'id': 'Iduladha'},
];

/// "{n} is expected tomorrow" wording. The date comes from a CALCULATED calendar,
/// while the start of Ramadan and the two Eids are fixed by moon sighting / official
/// announcement and can differ by a day, so the message says "expected" and not "is".
const Map<String, String> _expectedTomorrow = {
  'ar': '{n} غدًا بإذن الله (حسب التقويم الحسابي، وقد يختلف يومًا عن الإعلان الرسمي)',
  'en': '{n} is expected tomorrow (calculated calendar — may differ by a day from the official announcement)',
  'de': '{n} wird morgen erwartet (berechneter Kalender – kann um einen Tag vom offiziellen Termin abweichen)',
  'tr': '{n} yarın bekleniyor (hesaplanmış takvim — resmî ilandan bir gün farklı olabilir)',
  'fr': '{n} est attendu demain (calendrier calculé — peut différer d\'un jour de l\'annonce officielle)',
  'es': '{n} se espera mañana (calendario calculado; puede diferir un día del anuncio oficial)',
  'id': '{n} diperkirakan besok (kalender hisab — bisa berbeda satu hari dari pengumuman resmi)',
};

class IslamicOccasionsService {
  IslamicOccasionsService._();
  static const _idBase = 900000300;

  static Future<void> scheduleReminders() async {
    final today = DateTime.now();
    final lang = appSettings.locale.languageCode;
    for (final occasion in _occasions) {
      final nextDate = _findNextOccurrence(today, occasion.hijriMonth, occasion.hijriDay);
      if (nextDate == null) continue;
      final reminderTime = DateTime(nextDate.year, nextDate.month, nextDate.day - 1, 9, 0);
      if (reminderTime.isBefore(today)) continue;
      final names = _occasionNames[occasion.idOffset];
      final name = names[lang] ?? names['en']!;
      final template = _expectedTomorrow[lang] ?? _expectedTomorrow['en']!;
      await NotificationService.scheduleOneTime(
        id: _idBase + occasion.idOffset,
        title: 'Wirdi',
        body: template.replaceFirst('{n}', name),
        fireAt: reminderTime,
      );
    }
  }

  static DateTime? _findNextOccurrence(DateTime from, int hijriMonth, int hijriDay) {
    for (var offset = 0; offset < 380; offset++) {
      final candidate = DateTime(from.year, from.month, from.day + offset);
      final hijri = HijriDate.fromGregorian(candidate);
      if (hijri.month == hijriMonth && hijri.day == hijriDay) return candidate;
    }
    return null;
  }
}
