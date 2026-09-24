import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/data/app_sources.dart';
import '../../core/services/settings_service.dart';

class MonthlyPrayerCalendarScreen extends StatefulWidget {
  const MonthlyPrayerCalendarScreen({super.key});
  @override
  State<MonthlyPrayerCalendarScreen> createState() => _MonthlyPrayerCalendarScreenState();
}

class _MonthlyPrayerCalendarScreenState extends State<MonthlyPrayerCalendarScreen> {
  List<Map<String, dynamic>>? _days;
  bool _loading = true;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location service disabled');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));
      final now = DateTime.now();
      final url = AppSources.prayerCalendarUrl(latitude: position.latitude, longitude: position.longitude, month: now.month, year: now.year, method: appSettings.prayerCalcMethod);
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded['data'] as List<dynamic>;
      final days = data.map((d) {
        final timings = d['timings'] as Map<String, dynamic>;
        final dateInfo = d['date'] as Map<String, dynamic>;
        String clean(String key) => (timings[key] as String).split(' ').first;
        return {
          'day': int.tryParse('${(dateInfo['gregorian'] as Map<String, dynamic>)['day']}') ?? -1,
          'fajr': clean('Fajr'),
          'dhuhr': clean('Dhuhr'),
          'asr': clean('Asr'),
          'maghrib': clean('Maghrib'),
          'isha': clean('Isha'),
        };
      }).toList();
      if (!mounted) return;
      setState(() { _days = days; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }
  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'جدول الشهر لمواقيت الصلاة' : 'Monthly Prayer Times Table'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.primaryEmerald.withValues(alpha: 0.1)),
                      columns: [
                        DataColumn(label: Text(isAr ? 'اليوم' : 'Day', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'الفجر' : 'Fajr', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'الظهر' : 'Dhuhr', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'العصر' : 'Asr', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'المغرب' : 'Maghrib', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(isAr ? 'العشاء' : 'Isha', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: (_days ?? []).map((d) {
                            final isToday = d['day'] == DateTime.now().day;
                            final cellStyle = isToday ? const TextStyle(fontWeight: FontWeight.bold) : null;
                            return DataRow(
                              color: isToday ? WidgetStateProperty.all(AppColors.primaryEmerald.withValues(alpha: 0.18)) : null,
                              cells: [
                                DataCell(Text('${d['day']}', style: cellStyle)),
                                DataCell(Text('${d['fajr']}', style: cellStyle)),
                                DataCell(Text('${d['dhuhr']}', style: cellStyle)),
                                DataCell(Text('${d['asr']}', style: cellStyle)),
                                DataCell(Text('${d['maghrib']}', style: cellStyle)),
                                DataCell(Text('${d['isha']}', style: cellStyle)),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                )),
    );
  }
}
