import 'dart:convert';
import '../theme/app_theme.dart';
import 'hijri_date.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default prayer calculation method (AlAdhan method id) for a device region.
/// Previously every user got method 5 (Egyptian General Authority) whatever
/// their location; the Fajr/Isha angles differ enough elsewhere to shift the
/// times by 10-20 minutes. Only ids present in
/// AppSources.prayerCalculationMethods are returned. The user can always change it.
int defaultCalcMethodForRegion(Locale locale) {
  const byCountry = <String, int>{
    'EG': 5, 'SD': 5, 'LY': 5,
    'SA': 4, 'YE': 4, 'BH': 4, 'OM': 4,
    'AE': 16, 'QA': 10, 'KW': 9,
    'TR': 13,
    'US': 2, 'CA': 2, 'MX': 2,
    'PK': 1, 'IN': 1, 'BD': 1, 'AF': 1,
    'ID': 20, 'MY': 17,
    'MA': 21,
    'FR': 12,
    'GB': 3, 'IE': 3, 'DE': 3, 'NL': 3, 'BE': 3, 'AT': 3, 'CH': 3, 'ES': 3, 'IT': 3,
    'SE': 3, 'NO': 3, 'DK': 3, 'FI': 3, 'PL': 3, 'AU': 3, 'NZ': 3,
  };
  final country = (locale.countryCode ?? '').toUpperCase();
  final byRegion = byCountry[country];
  if (byRegion != null) return byRegion;
  // Unknown region: Arabic UI keeps the Egyptian default, everyone else gets
  // the Muslim World League method.
  return locale.languageCode == 'ar' ? 5 : 3;
}

/// Top-level aliases so the settings screen and main.dart can import
/// a single canonical list without accessing the class directly.
const List<Locale> kSupportedLocales = AppSettings.supportedLocales;

const Map<String, String> kLanguageNames = {
  'ar': 'العربية',
  'en': 'English',
  'de': 'Deutsch',
  'tr': 'Türkçe',
  'fr': 'Français',
  'es': 'Español',
  'id': 'Bahasa Indonesia',
};


/// App-wide settings, persisted and reactive via ChangeNotifier so
/// MaterialApp can rebuild its theme/text scale live without adding a
/// state-management package. Instantiate once and pass down; call
/// [load] before runApp so the first frame already has saved prefs.
class DailyReminderSetting {
  final bool enabled;
  final int hour;
  final int minute;
  const DailyReminderSetting({required this.enabled, required this.hour, required this.minute});

  DailyReminderSetting copyWith({bool? enabled, int? hour, int? minute}) => DailyReminderSetting(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'hour': hour, 'minute': minute};

  factory DailyReminderSetting.fromJson(Map<String, dynamic> json) => DailyReminderSetting(
        enabled: json['enabled'] as bool? ?? false,
        hour: json['hour'] as int? ?? 8,
        minute: json['minute'] as int? ?? 0,
      );
}

class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppColorTheme _colorTheme = AppColorTheme.emerald;
  double _fontScale = 1.0;
  String _reciterId = 'ar.alafasy';
  bool _loaded = false;

  /// null = follow system locale (falls back to Arabic if the system
  /// locale isn't one we support). Non-null = explicit user choice,
  /// persisted across launches.
  Locale? _locale;

  /// Locales the app ships real translations for. Order here also
  /// drives the order shown in the language picker.
  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('de'),
    Locale('tr'),
    Locale('fr'),
    Locale('es'),
    Locale('id'),
  ];

  static const List<String> _rtlLanguageCodes = ['ar'];

  static const List<String> remindablePrayerKeys = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  Set<String> _enabledPrayerReminders = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};
  bool _notifyAtPrayerTime = true;
  bool _postPrayerReminderEnabled = false;
  int _postPrayerReminderMinutesAfter = 30;
  int _prayerReminderMinutesBefore = 10;
  Set<String> _favoriteReciterIds = {};
  bool _highContrastEnabled = false;
  bool _amoledDarkMode = false;
  bool _widgetLocked = false;
  bool _autoDarkModeAtMaghrib = false;
  final Map<String, int> prayerOffsets = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};
  final Set<String> customAzkarReminders = {};
  int _prayerCalcMethod = 5;
  int _hijriDayOffset = 0;
  bool _ongoingPrayerNotificationEnabled = false;
  // 'banner' | 'beep' | 'adhan'
  String _prayerReminderMode = 'adhan';
  String _adhanId = 'a9';

  Map<String, String> _prayerSoundOverride = {};
  bool _showTransliteration = false;
  bool _showTajweedColoring = true;
  String _quranFontFamily = 'default';

  static const List<String> dailyReminderKeys = [
    'friday',
    'morningAzkar',
    'eveningAzkar',
    'dailyWird',
    'sleepAzkar',
    'sadaqah',
  ];

  final Map<String, DailyReminderSetting> _dailyReminders = {
    'friday': const DailyReminderSetting(enabled: false, hour: 8, minute: 0),
    'morningAzkar': const DailyReminderSetting(enabled: false, hour: 6, minute: 0),
    'eveningAzkar': const DailyReminderSetting(enabled: false, hour: 17, minute: 0),
    'dailyWird': const DailyReminderSetting(enabled: false, hour: 20, minute: 0),
    'sleepAzkar': const DailyReminderSetting(enabled: false, hour: 22, minute: 0),
    'sadaqah': const DailyReminderSetting(enabled: false, hour: 20, minute: 0),
  };

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  String get reciterId => _reciterId;
  bool get loaded => _loaded;
  bool get prayerReminderEnabled => _enabledPrayerReminders.isNotEmpty;
  Set<String> get enabledPrayerReminders => _enabledPrayerReminders;
  bool isPrayerReminderEnabledFor(String prayerId) => _enabledPrayerReminders.contains(prayerId);
  bool get notifyAtPrayerTime => _notifyAtPrayerTime;
  bool get postPrayerReminderEnabled => _postPrayerReminderEnabled;
  int get postPrayerReminderMinutesAfter => _postPrayerReminderMinutesAfter;
  int get prayerReminderMinutesBefore => _prayerReminderMinutesBefore;
  bool isFavoriteReciter(String id) => _favoriteReciterIds.contains(id);
  bool get highContrastEnabled => _highContrastEnabled;
  bool get amoledDarkMode => _amoledDarkMode;
  bool get widgetLocked => _widgetLocked;
  bool get autoDarkModeAtMaghrib => _autoDarkModeAtMaghrib;
  int get prayerCalcMethod => _prayerCalcMethod;
  int get hijriDayOffset => _hijriDayOffset;
  bool get ongoingPrayerNotificationEnabled => _ongoingPrayerNotificationEnabled;
  String get prayerReminderMode => _prayerReminderMode;

  String prayerSoundOverrideFor(String prayerId) => _prayerSoundOverride[prayerId] ?? 'default';

  String effectiveModeFor(String prayerId) {
    final override = _prayerSoundOverride[prayerId];
    if (override == null || override == 'default') return _prayerReminderMode;
    return override;
  }
  String get adhanId => _adhanId;
  bool get showTransliteration => _showTransliteration;
  bool get showTajweedColoring => _showTajweedColoring;
  String get quranFontFamily => _quranFontFamily;

  DailyReminderSetting dailyReminder(String key) =>
      _dailyReminders[key] ?? const DailyReminderSetting(enabled: false, hour: 8, minute: 0);

  /// The effective locale: explicit user choice, else the device locale
  /// if we support it, else Arabic (this app's original default).
  Locale get locale {
    if (_locale != null) return _locale!;
    final deviceLocale = PlatformDispatcher.instance.locale;
    final match = supportedLocales.firstWhere(
      (l) => l.languageCode == deviceLocale.languageCode,
      orElse: () => const Locale('ar'),
    );
    return match;
  }

  /// null means "follow system" — used by the settings UI to show the
  /// "System default" option as selected.
  Locale? get explicitLocale => _locale;

  TextDirection get textDirection =>
      _rtlLanguageCodes.contains(locale.languageCode) ? TextDirection.rtl : TextDirection.ltr;

  Future<bool> hasCustomAzkarReminder(String id) async => customAzkarReminders.contains(id);
  
  Future<void> addCustomAzkarReminder(String id) async {
    customAzkarReminders.add(id);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('settings_custom_azkar_reminders', customAzkarReminders.toList());
  }
  
  Future<void> removeCustomAzkarReminder(String id) async {
    customAzkarReminders.remove(id);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('settings_custom_azkar_reminders', customAzkarReminders.toList());
  }
  
  Future<String> exportDataAsJson() async {
    final prefs = await SharedPreferences.getInstance();
    final backup = {
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.51.0',
      'data': {
        'theme': _themeMode.toString(),
        'locale': _locale?.toString(),
        'fontScale': _fontScale,
        'highContrast': _highContrastEnabled,
        'favoriteReciter': _reciterId,
        'allSettings': prefs.getKeys().fold<Map<String, dynamic>>({}, (acc, key) {
          acc[key] = prefs.get(key);
          return acc;
        }),
      },
    };
    return jsonEncode(backup);
  }
  
  /// Restores settings previously produced by [exportDataAsJson]. Writes
  /// every key/value pair from the backup's `allSettings` map back into
  /// SharedPreferences (matching each value's real runtime type so it
  /// round-trips correctly), then reloads in-memory state via [load] so
  /// the change takes effect immediately without an app restart.
  Future<bool> importDataFromJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      final allSettings = data?['allSettings'] as Map<String, dynamic>?;
      if (allSettings == null) return false;

      final prefs = await SharedPreferences.getInstance();
      for (final entry in allSettings.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List) {
          await prefs.setStringList(key, value.map((e) => e.toString()).toList());
        }
      }
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final storedTheme = prefs.getString('settings_theme_mode');
    _themeMode = switch (storedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final storedColorTheme = prefs.getString('settings_color_theme');
    _colorTheme = AppColorTheme.values.firstWhere(
      (t) => t.name == storedColorTheme,
      orElse: () => AppColorTheme.emerald,
    );
    AppColors.updateCurrentTheme(_colorTheme);

    _fontScale = prefs.getDouble('settings_font_scale') ?? 1.0;
    _reciterId = prefs.getString('settings_reciter_id') ?? 'ar.alafasy';
    final storedEnabledPrayers = prefs.getStringList('settings_enabled_prayer_reminders');
    if (storedEnabledPrayers != null) {
      _enabledPrayerReminders = storedEnabledPrayers.toSet();
    } else {
      final legacyEnabled = prefs.getBool('settings_prayer_reminder_enabled') ?? false;
      _enabledPrayerReminders = legacyEnabled ? remindablePrayerKeys.toSet() : <String>{};
    }
    _favoriteReciterIds = (prefs.getStringList('settings_favorite_reciter_ids') ?? []).toSet();
    _highContrastEnabled = prefs.getBool('settings_high_contrast') ?? false;
    _amoledDarkMode = prefs.getBool('settings_amoled_dark_mode') ?? false;
    _widgetLocked = prefs.getBool('settings_widget_locked') ?? false;
    _autoDarkModeAtMaghrib = prefs.getBool('settings_auto_dark_maghrib') ?? false;
    final storedOffsets = prefs.getString('settings_prayer_offsets');
    if (storedOffsets != null) {
      try {
        final decoded = jsonDecode(storedOffsets) as Map<String, dynamic>;
        for (final key in prayerOffsets.keys) {
          if (decoded[key] is int) prayerOffsets[key] = decoded[key] as int;
        }
      } catch (_) {
        // Corrupt data -- keep defaults.
      }
    }
    customAzkarReminders
      ..clear()
      ..addAll(prefs.getStringList('settings_custom_azkar_reminders') ?? []);
    _hijriDayOffset = prefs.getInt('settings_hijri_day_offset') ?? 0;
    HijriDate.dayOffset = _hijriDayOffset;
    final storedCalcMethod = prefs.getInt('settings_prayer_calc_method');
    if (storedCalcMethod != null) {
      _prayerCalcMethod = storedCalcMethod;
    } else {
      _prayerCalcMethod = defaultCalcMethodForRegion(PlatformDispatcher.instance.locale);
      await prefs.setInt('settings_prayer_calc_method', _prayerCalcMethod);
    }
    _ongoingPrayerNotificationEnabled = prefs.getBool('settings_ongoing_prayer_notification') ?? false;
    final storedOverride = prefs.getString('settings_prayer_sound_override');
    if (storedOverride != null) {
      try {
        final decoded = jsonDecode(storedOverride) as Map<String, dynamic>;
        _prayerSoundOverride = decoded.map((k, v) => MapEntry(k, v as String));
      } catch (_) {
        _prayerSoundOverride = {};
      }
    }
    _notifyAtPrayerTime = prefs.getBool('settings_notify_at_prayer_time') ?? true;
    _postPrayerReminderEnabled = prefs.getBool('settings_post_prayer_reminder_enabled') ?? false;
    _postPrayerReminderMinutesAfter = prefs.getInt('settings_post_prayer_reminder_minutes') ?? 30;
    _prayerReminderMinutesBefore = prefs.getInt('settings_prayer_reminder_minutes') ?? 10;
    _prayerReminderMode = prefs.getString('settings_prayer_reminder_mode') ?? 'adhan';
    _adhanId = prefs.getString('settings_adhan_id') ?? 'a9';
    _showTransliteration = prefs.getBool('settings_show_transliteration') ?? false;
    _showTajweedColoring = prefs.getBool('settings_show_tajweed_coloring') ?? true;
    // Fonts removed in v1.54 (licence terms did not allow redistribution):
    // fall back to the default font if one of them was saved earlier.
    const removedQuranFonts = {'QuranAlQuranNeo', 'QuranIndopakNastaleeq', 'QuranMeQuranVolt'};
    final storedQuranFont = prefs.getString('settings_quran_font_family') ?? 'default';
    _quranFontFamily = removedQuranFonts.contains(storedQuranFont) ? 'default' : storedQuranFont;

    final storedDailyReminders = prefs.getString('settings_daily_reminders_json');
    if (storedDailyReminders != null) {
      try {
        final decoded = jsonDecode(storedDailyReminders) as Map<String, dynamic>;
        for (final key in dailyReminderKeys) {
          final raw = decoded[key];
          if (raw is Map<String, dynamic>) {
            _dailyReminders[key] = DailyReminderSetting.fromJson(raw);
          }
        }
      } catch (_) {
        // Corrupt/legacy data -- keep the defaults rather than crashing load().
      }
    }

    final storedLocale = prefs.getString('settings_locale');
    _locale = storedLocale == null ? null : Locale(storedLocale);

    _loaded = true;
    notifyListeners();
  }

  /// Pass null to reset to "follow system".
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove('settings_locale');
    } else {
      await prefs.setString('settings_locale', locale.languageCode);
    }
  }

  Future<void> setShowTransliteration(bool value) async {
    _showTransliteration = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_show_transliteration', value);
  }

  Future<void> setDailyReminder(String key, DailyReminderSetting setting) async {
    _dailyReminders[key] = setting;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_dailyReminders.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString('settings_daily_reminders_json', encoded);
  }

  Future<void> setAdhanId(String id) async {
    _adhanId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_adhan_id', id);
  }

  Future<void> setReciterId(String id) async {
    _reciterId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_reciter_id', id);
  }

  Future<void> setPrayerReminderEnabledFor(String prayerId, bool enabled) async {
    if (enabled) {
      _enabledPrayerReminders.add(prayerId);
    } else {
      _enabledPrayerReminders.remove(prayerId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('settings_enabled_prayer_reminders', _enabledPrayerReminders.toList());
  }

  Future<void> setNotifyAtPrayerTime(bool value) async {
    _notifyAtPrayerTime = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_notify_at_prayer_time', value);
  }

  Future<void> setPostPrayerReminderEnabled(bool value) async {
    _postPrayerReminderEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_post_prayer_reminder_enabled', value);
  }

  Future<void> setPostPrayerReminderMinutesAfter(int minutes) async {
    _postPrayerReminderMinutesAfter = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_post_prayer_reminder_minutes', minutes);
  }

  Future<void> setPrayerReminderMinutesBefore(int minutes) async {
    _prayerReminderMinutesBefore = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_prayer_reminder_minutes', minutes);
  }

  Future<void> setPrayerSoundOverrideFor(String prayerId, String mode) async {
    if (mode == 'default') {
      _prayerSoundOverride.remove(prayerId);
    } else {
      _prayerSoundOverride[prayerId] = mode;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_prayer_sound_override', jsonEncode(_prayerSoundOverride));
  }

  Future<void> toggleFavoriteReciter(String id) async {
    if (_favoriteReciterIds.contains(id)) {
      _favoriteReciterIds.remove(id);
    } else {
      _favoriteReciterIds.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('settings_favorite_reciter_ids', _favoriteReciterIds.toList());
  }

  Future<void> setHighContrastEnabled(bool value) async {
    _highContrastEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_high_contrast', value);
  }

  Future<void> setAmoledDarkMode(bool value) async {
    _amoledDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_amoled_dark_mode', value);
  }

  Future<void> setWidgetLocked(bool value) async {
    _widgetLocked = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_widget_locked', value);
  }

  Future<void> setAutoDarkModeAtMaghrib(bool value) async {
    _autoDarkModeAtMaghrib = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_auto_dark_maghrib', value);
  }

  Future<void> setPrayerOffset(String prayerName, int minutes) async {
    prayerOffsets[prayerName] = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_prayer_offsets', jsonEncode(prayerOffsets));
  }

  Future<void> setHijriDayOffset(int days) async {
    final v = days < -2 ? -2 : (days > 2 ? 2 : days);
    _hijriDayOffset = v;
    HijriDate.dayOffset = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_hijri_day_offset', v);
  }

  Future<void> setPrayerCalcMethod(int method) async {
    _prayerCalcMethod = method;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_prayer_calc_method', method);
  }

  Future<void> setOngoingPrayerNotificationEnabled(bool value) async {
    _ongoingPrayerNotificationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_ongoing_prayer_notification', value);
  }

  Future<void> setPrayerReminderMode(String mode) async {
    _prayerReminderMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_prayer_reminder_mode', mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_theme_mode', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  AppColorTheme get colorTheme => _colorTheme;

  Future<void> setColorTheme(AppColorTheme theme) async {
    _colorTheme = theme;
    AppColors.updateCurrentTheme(theme);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_color_theme', theme.name);
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('settings_font_scale', scale);
  }
  Future<void> setShowTajweedColoring(bool value) async {
    _showTajweedColoring = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_show_tajweed_coloring', value);
  }

  Future<void> setQuranFontFamily(String family) async {
    _quranFontFamily = family;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_quran_font_family', family);
  }
}

/// Single app-wide instance. Simple top-level singleton — avoids pulling
/// in Provider/Riverpod purely to broadcast theme changes.
final AppSettings appSettings = AppSettings();
