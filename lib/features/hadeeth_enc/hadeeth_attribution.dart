import 'package:flutter/material.dart';

import '../../core/services/hadeeth_enc_repository.dart';
import '../../core/theme/app_theme.dart';

String _t(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

/// Mandatory attribution footer per HadeethEnc.com's content-reuse terms.
class HadeethAttributionFooter extends StatefulWidget {
  const HadeethAttributionFooter({super.key});

  @override
  State<HadeethAttributionFooter> createState() => _HadeethAttributionFooterState();
}

class _HadeethAttributionFooterState extends State<HadeethAttributionFooter> {
  DateTime? _syncedAt;
  String? _loadedForLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_loadedForLanguageCode != languageCode) {
      _loadedForLanguageCode = languageCode;
      HadeethEncRepository.lastSyncDate(languageCode: languageCode).then((value) {
        if (mounted) setState(() => _syncedAt = value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final synced = _syncedAt;
    final dateLabel = synced == null
        ? _t(context, 'لم تتم المزامنة بعد', 'Not synced yet')
        : '${synced.year}-${synced.month.toString().padLeft(2, '0')}-${synced.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            _t(context, 'المصدر: HadeethEnc.com', 'Source: HadeethEnc.com'),
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            _t(context, 'آخر تحديث: $dateLabel', 'Last updated: $dateLabel'),
            style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
