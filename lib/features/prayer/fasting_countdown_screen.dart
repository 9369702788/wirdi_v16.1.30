import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/prayer_models.dart';
import '../../core/services/prayer_service.dart';
import '../../core/theme/app_theme.dart';

class FastingCountdownScreen extends StatefulWidget {
  const FastingCountdownScreen({super.key});

  @override
  State<FastingCountdownScreen> createState() => _FastingCountdownScreenState();
}

class _FastingCountdownScreenState extends State<FastingCountdownScreen> {
  PrayerTimesResult? _result;
  bool _loading = true;
  String? _error;
  Timer? _ticker;
  DateTime _now = DateTime.now();
  List<PrayerItem>? _tomorrowPrayers;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await PrayerService.fetchPrayerTimes();
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
      PrayerService.fetchTomorrowPrayers().then((tomorrow) {
        if (mounted && tomorrow != null) setState(() => _tomorrowPrayers = tomorrow);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  PrayerItem? _find(String name) {
    final result = _result;
    if (result == null) return null;
    for (final p in result.prayers) {
      if (p.name.toLowerCase().contains(name.toLowerCase())) return p;
    }
    return null;
  }

  PrayerItem? _findIn(List<PrayerItem>? prayers, String name) {
    if (prayers == null) return null;
    for (final p in prayers) {
      if (p.name.toLowerCase().contains(name.toLowerCase())) return p;
    }
    return null;
  }

  PrayerItem? _suhoorTarget() {
    final today = _find('Fajr');
    if (today != null && today.dateTime.isAfter(_now)) return today;
    return _findIn(_tomorrowPrayers, 'Fajr') ?? today;
  }

  Widget _countdownCard({required String title, required PrayerItem? target, required bool isAr}) {
    if (target == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(isAr ? 'تعذّر إيجاد هذا الوقت' : 'Could not find this time', textAlign: TextAlign.center),
        ),
      );
    }
    final diff = target.dateTime.difference(_now);
    final passed = diff.isNegative;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(target.timeText, style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
            const SizedBox(height: 16),
            if (passed)
              Text(
                isAr ? 'انتهى الوقت لهذا اليوم' : 'Time has passed for today',
                style: const TextStyle(fontSize: 16, color: AppColors.mutedText),
              )
            else
              Text(
                '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'عداد الإفطار والسحور' : 'Iftar & Suhoor Countdown'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _countdownCard(title: isAr ? 'وقت الإفطار (المغرب)' : 'Iftar time (Maghrib)', target: _find('Maghrib'), isAr: isAr),
                    const SizedBox(height: 16),
                    _countdownCard(title: isAr ? 'نهاية وقت السحور (الفجر)' : 'End of Suhoor (Fajr)', target: _suhoorTarget(), isAr: isAr),
                  ],
                )),
    );
  }
}
