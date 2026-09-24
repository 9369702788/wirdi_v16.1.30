import 'package:flutter/material.dart';

import '../../core/services/prayer_service.dart';
import '../../core/models/prayer_models.dart';
import '../../core/theme/app_theme.dart';

class OtherCityPrayerTimesScreen extends StatefulWidget {
  const OtherCityPrayerTimesScreen({super.key});

  @override
  State<OtherCityPrayerTimesScreen> createState() => _OtherCityPrayerTimesScreenState();
}

class _OtherCityPrayerTimesScreenState extends State<OtherCityPrayerTimesScreen> {
  final _cityController = TextEditingController();
  PrayerTimesResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await PrayerService.fetchPrayerTimesForCity(city);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'مواقيت مدينة أخرى' : 'Prayer Times in Another City'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: isAr ? 'اسم المدينة' : 'City name',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _search, child: Text(isAr ? 'بحث' : 'Search')),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!, textAlign: TextAlign.center)),
            if (_result != null)
              Expanded(
                child: ListView(
                  children: [
                    if (_result!.locationLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_result!.locationLabel!, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                      ),
                    ..._result!.prayers.map((p) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(Icons.mosque_outlined, color: AppColors.primaryEmerald),
                            title: Text(p.name),
                            trailing: Text(p.timeText, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )),
                  ],
                ),
              ),
          ],
        ),
      )),
    );
  }
}
