import 'package:shared_preferences/shared_preferences.dart';

class MathhabService {
  static const List<String> mathhabs = [
    'Hanafi',
    'Maliki',
    'Shafi\'i',
    'Hanbali',
  ];
  
  static Future<void> setMathhab(String mathhab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_mathhab', mathhab);
  }
  
  /// BUGFIX: defaulted to 'Hanafi' when the user had never explicitly
  /// chosen a mathhab -- that silently used the Hanafi Asr calculation
  /// (shadow length = 2x object height) for every new install, delaying
  /// Asr by roughly an hour versus the standard/Shafi'i calculation
  /// (shadow length = 1x object height) that matches the actual local
  /// Adhan timing most users -- especially in Egypt and most of the
  /// Muslim world outside the Indian subcontinent/Central Asia/Turkey --
  /// expect and hear from their local mosque. Shafi'i is now the
  /// default; Hanafi remains one tap away for anyone who wants it.
  static Future<String> getMathhab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_mathhab') ?? 'Shafi\'i';
  }
  
  static Future<Map<String, dynamic>> getPrayerTimesForMathhab(String mathhab) async {
    return {
      'asr_calculation': mathhab == 'Hanafi' ? 'Standard' : 'Shadow ratio',
      'maghrib_isha_gap': mathhab == 'Maliki' ? '30 min' : '20 min',
    };
  }
}
