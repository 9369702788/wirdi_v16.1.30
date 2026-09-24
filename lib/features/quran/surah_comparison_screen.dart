import 'package:flutter/material.dart';

import '../../core/models/quran_models.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// Compares two surahs side by side using real, computed data from the
/// app's own Quran text (verse count, total character count, average
/// verse length) -- not fabricated or looked-up classification data.
class SurahComparisonScreen extends StatefulWidget {
  const SurahComparisonScreen({super.key});

  @override
  State<SurahComparisonScreen> createState() => _SurahComparisonScreenState();
}

class _SurahComparisonScreenState extends State<SurahComparisonScreen> {
  List<SurahModel> _surahs = [];
  bool _loading = true;
  SurahModel? _a;
  SurahModel? _b;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final surahs = await QuranRepository.load();
    if (!mounted) return;
    setState(() {
      _surahs = surahs;
      _a = surahs.isNotEmpty ? surahs[0] : null;
      _b = surahs.length > 1 ? surahs[1] : null;
      _loading = false;
    });
  }

  Map<String, String> _stats(SurahModel s, bool isAr) {
    final totalChars = s.ayahs.fold<int>(0, (sum, a) => sum + a.text.length);
    final avg = s.ayahs.isEmpty ? 0 : (totalChars / s.ayahs.length).round();
    return {
      isAr ? 'عدد الآيات' : 'Verse count': '${s.ayahs.length}',
      isAr ? 'إجمالي الأحرف' : 'Total characters': '$totalChars',
      isAr ? 'متوسط طول الآية' : 'Avg. verse length': '$avg ${isAr ? 'حرف' : 'chars'}',
    };
  }

  Widget _pickerAndCard(SurahModel? selected, ValueChanged<SurahModel?> onChanged, bool isAr) {
    return Expanded(
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: selected?.number,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            items: _surahs
                .map((s) => DropdownMenuItem(value: s.number, child: Text('${s.number}. ${s.name}', textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (value) => onChanged(_surahs.firstWhere((s) => s.number == value)),
          ),
          const SizedBox(height: 12),
          if (selected != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(selected.name, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                    Text(selected.englishName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    const Divider(height: 20),
                    ..._stats(selected, isAr).entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Text(e.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              Text(e.key, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'معلومات عن السور' : 'Surah Information'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pickerAndCard(_a, (s) => setState(() => _a = s), isAr),
                  const SizedBox(width: 12),
                  _pickerAndCard(_b, (s) => setState(() => _b = s), isAr),
                ],
              ),
            ),
    );
  }
}
