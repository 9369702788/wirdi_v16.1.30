import 'package:shared_preferences/shared_preferences.dart';

class AmbianceService {
  static const List<String> ambianceOptions = [
    'None',
    'Rain Sound',
    'Ocean Waves',
    'Birds Chirping',
    'Forest Ambiance',
    'Meditation Bell',
  ];
  
  static Future<void> setAmbiance(String ambianceType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_ambiance', ambianceType);
  }

  static Future<String> getAmbiance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_ambiance') ?? 'None';
  }
}
