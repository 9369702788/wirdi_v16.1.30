import 'package:flutter/material.dart';
import '../../core/models/prayer_models.dart';
import '../../core/services/prayer_service.dart';
import '../../core/theme/app_theme.dart';

class PrayerChartScreen extends StatefulWidget {
  const PrayerChartScreen({super.key});
  @override
  State<PrayerChartScreen> createState() => _PrayerChartScreenState();
}

class _PrayerChartScreenState extends State<PrayerChartScreen> {
  PrayerTimesResult? _result;
  bool _loading = true;
  String? _error;
  static const List<Color> _colors = [Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFC93C), Color(0xFFFF9F68), Color(0xFF6C5CE7)];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final result = await PrayerService.fetchPrayerTimes();
      if (!mounted) return;
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'رسم مواقيت الصلاة' : 'Prayer Times Chart'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null || _result == null)
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? '', textAlign: TextAlign.center)))
              : _buildChart(_result!)),
    );
  }

  Widget _buildChart(PrayerTimesResult result) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final prayers = result.prayers;
    if (prayers.isEmpty) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          isAr
              ? 'يمثل طول كل شريط المدة الزمنية من هذه الصلاة حتى الصلاة التالية'
              : 'Each bar\'s length represents the time from that prayer until the next one',
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: Row(children: [
            for (var i = 0; i < prayers.length; i++)
              Expanded(
                flex: (i == prayers.length - 1
                        ? prayers.first.dateTime.add(const Duration(days: 1)).difference(prayers[i].dateTime)
                        : prayers[i + 1].dateTime.difference(prayers[i].dateTime))
                    .inMinutes
                    .clamp(1, 1 << 30),
                child: Container(margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: _colors[i % _colors.length], borderRadius: BorderRadius.circular(4))),
              ),
          ]),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < prayers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: _colors[i % _colors.length], shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(prayers[i].name, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(prayers[i].timeText, style: const TextStyle(color: AppColors.mutedText)),
            ]),
          ),
      ],
    );
  }
}
