import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final String temperature;
  final String condition;
  final String humidity;
  final String windSpeed;
  const WeatherData({required this.temperature, required this.condition, required this.humidity, required this.windSpeed});
}

class WeatherService {
  static Future<WeatherData> getWeatherAtPrayerTime(String prayer) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    ).timeout(const Duration(seconds: 10));
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${position.latitude}&longitude=${position.longitude}'
      '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to load weather (HTTP ${response.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final current = decoded['current'] as Map<String, dynamic>;
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;
    return WeatherData(
      temperature: '${((current['temperature_2m'] as num?) ?? 0).round()}°C',
      condition: _conditionFromCode(code),
      humidity: '${((current['relative_humidity_2m'] as num?) ?? 0).round()}%',
      windSpeed: '${((current['wind_speed_10m'] as num?) ?? 0).round()} km/h',
    );
  }

  static String _conditionFromCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Rain showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}
