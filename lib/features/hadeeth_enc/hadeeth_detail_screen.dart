import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/hadeeth_enc_models.dart';
import '../../core/services/hadeeth_enc_repository.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import 'hadeeth_attribution.dart';

String _t(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class HadeethDetailScreen extends StatefulWidget {
  final HadeethSummaryModel summary;
  const HadeethDetailScreen({super.key, required this.summary});

  @override
  State<HadeethDetailScreen> createState() => _HadeethDetailScreenState();
}

class _HadeethDetailScreenState extends State<HadeethDetailScreen> {
  Future<HadeethDetailModel>? _future;
  String? _loadedForLanguageCode;
  bool _isFavorite = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_loadedForLanguageCode != languageCode) {
      _loadedForLanguageCode = languageCode;
      _future = HadeethEncRepository.getHadeethDetail(id: widget.summary.id, languageCode: languageCode);
      _loadFavoriteState();
    }
  }

  Future<void> _loadFavoriteState() async {
    final favorites = await UserProgressService.favoriteHadiths();
    if (mounted) setState(() => _isFavorite = favorites.contains(widget.summary.uid));
  }

  Future<void> _toggleFavorite() async {
    await UserProgressService.toggleFavoriteHadith(widget.summary.uid);
    await _loadFavoriteState();
  }

  void _shareHadith(HadeethDetailModel detail) {
    final buffer = StringBuffer()
      ..writeln(detail.title)
      ..writeln()
      ..writeln(detail.matn);
    if (detail.references != null) {
      buffer
        ..writeln()
        ..writeln(detail.references);
    }
    buffer
      ..writeln()
      ..write(_t(context, 'المصدر: HadeethEnc.com', 'Source: HadeethEnc.com'));
    Share.share(buffer.toString());
  }

  Widget _section(String heading, String? body) {
    if (body == null || body.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(heading, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.mutedText)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'تفاصيل الحديث', 'Hadith detail')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_outline, color: _isFavorite ? AppColors.goldAccent : null),
            tooltip: _t(context, 'حفظ', 'Save'),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SafeArea(bottom: true, top: false, child: FutureBuilder<HadeethDetailModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _t(context, 'تعذّر تحميل هذا الحديث. تحقّق من الإنترنت وحاول مرة أخرى.',
                      'Could not load this hadith. Check your connection and try again.'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final detail = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primaryEmerald, const Color(0xFF115E56)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(detail.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(detail.matn, style: const TextStyle(fontFamily: 'AmiriQuran', color: Colors.white, fontSize: 20, height: 1.9)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _section(_t(context, 'الشرح', 'Explanation'), detail.explanation),
              _section(_t(context, 'الفوائد', 'Benefits'), detail.fawaed),
              _section(_t(context, 'معاني الكلمات', 'Word meanings'), detail.wordMeanings),
              _section(_t(context, 'التخريج', 'Reference'), detail.references),
              Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  onPressed: () => _shareHadith(detail),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(_t(context, 'مشاركة', 'Share')),
                ),
              ),
              const HadeethAttributionFooter(),
            ],
          );
        },
      )),
    );
  }
}
