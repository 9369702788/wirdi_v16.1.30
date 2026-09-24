import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/prayer_service.dart';
import '../../core/models/prayer_models.dart';
import '../../core/theme/app_theme.dart';

class PrayerCalendarExportScreen extends StatefulWidget {
  const PrayerCalendarExportScreen({super.key});
  @override
  State<PrayerCalendarExportScreen> createState() => _PrayerCalendarExportScreenState();
}

class _PrayerCalendarExportScreenState extends State<PrayerCalendarExportScreen> {
  PrayerTimesResult? _result;
  bool _loading = true;
  String? _error;
  bool _exporting = false;
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
  String _icsTimestamp(DateTime d) {
    final utc = d.toUtc();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${p(utc.month)}${p(utc.day)}T${p(utc.hour)}${p(utc.minute)}${p(utc.second)}Z';
  }
  Future<void> _export() async {
    final result = _result;
    if (result == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln('BEGIN:VCALENDAR');
      buffer.writeln('VERSION:2.0');
      buffer.writeln('PRODID:-//Wirdi//Prayer Times//EN');
      for (final prayer in result.prayers) {
        final start = prayer.dateTime;
        final end = start.add(const Duration(minutes: 30));
        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('UID:wirdi-${prayer.name}-${_icsTimestamp(start)}@wirdi.app');
        buffer.writeln('DTSTAMP:${_icsTimestamp(DateTime.now())}');
        buffer.writeln('DTSTART:${_icsTimestamp(start)}');
        buffer.writeln('DTEND:${_icsTimestamp(end)}');
        buffer.writeln('SUMMARY:${prayer.name}');
        buffer.writeln('END:VEVENT');
      }
      buffer.writeln('END:VCALENDAR');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/wirdi_prayer_times.ics');
      await file.writeAsString(buffer.toString());
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'تصدير المواقيت للتقويم' : 'Export Prayer Times to Calendar'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        isAr
                            ? 'سيتم إنشاء ملف تقويم (.ics) بمواقيت صلاة اليوم الخمس، يمكنك استيراده مباشرة في تقويم جوجل أو أبل.'
                            : "An .ics calendar file with today's 5 prayer times will be created for import into any calendar app.",
                        style: const TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_result != null)
                      ..._result!.prayers.map((p) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(leading: Icon(Icons.event_outlined, color: AppColors.primaryEmerald), title: Text(p.name), trailing: Text(p.timeText, style: const TextStyle(fontWeight: FontWeight.bold))),
                          )),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _exporting ? null : _export,
                      icon: _exporting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.calendar_month_outlined),
                      label: Text(isAr ? 'تصدير إلى ملف تقويم' : 'Export to calendar file'),
                    ),
                  ]),
                ),
    );
  }
}
