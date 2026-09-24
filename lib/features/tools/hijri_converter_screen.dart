import 'package:flutter/material.dart';

import '../../core/services/hijri_date.dart';
import '../../core/theme/app_theme.dart';

class HijriConverterScreen extends StatefulWidget {
  const HijriConverterScreen({super.key});

  @override
  State<HijriConverterScreen> createState() => _HijriConverterScreenState();
}

class _HijriConverterScreenState extends State<HijriConverterScreen> {
  DateTime _gregorian = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final hijriDate = HijriDate.fromGregorian(_gregorian);
    final hijri = '${hijriDate.toStringLocalized(Localizations.localeOf(context).languageCode)} ${isAr ? 'هـ' : 'AH'}';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'محول التاريخ الهجري' : 'Hijri Converter'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(isAr ? 'التاريخ الميلادي' : 'Gregorian date', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${_gregorian.year}-${_gregorian.month.toString().padLeft(2, '0')}-${_gregorian.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _gregorian,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2200),
                );
                if (picked != null) setState(() => _gregorian = picked);
              },
              icon: const Icon(Icons.calendar_month),
              label: Text(isAr ? 'اختر تاريخ' : 'Pick a date'),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryEmerald, const Color(0xFF115E56)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(isAr ? 'التاريخ الهجري المقابل' : 'Equivalent Hijri date', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(hijri, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
