import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/hadith_models.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/arabic_text_utils.dart';
import '../../core/services/hadith_repository.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../quran/shareable_text_card_screen.dart';

class HadithCollectionScreen extends StatefulWidget {
  final int? initialHadithNumber;
  const HadithCollectionScreen({super.key, this.initialHadithNumber});

  @override
  State<HadithCollectionScreen> createState() => _HadithCollectionScreenState();
}

class _HadithCollectionScreenState extends State<HadithCollectionScreen> {
  Future<List<HadithModel>>? _future;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Set<String> _favorites = {};
  String? _loadedForLanguageCode;
  final Map<int, GlobalKey> _itemKeys = {};
  bool _didScrollToInitial = false;
  int _scrollToInitialAttempts = 0;

  GlobalKey _keyFor(int number) => _itemKeys.putIfAbsent(number, () => GlobalKey());

  void _maybeScrollToInitial() {
    final target = widget.initialHadithNumber;
    if (target == null || _didScrollToInitial) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryScrollToInitial(target));
  }

  void _tryScrollToInitial(int target) {
    if (_didScrollToInitial || !mounted) return;
    final ctx = _itemKeys[target]?.currentContext;
    if (ctx != null) {
      _didScrollToInitial = true;
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1, curve: Curves.easeInOut);
      return;
    }
    _scrollToInitialAttempts++;
    if (_scrollToInitialAttempts > 80 || !_scrollController.hasClients) {
      _didScrollToInitial = true;
      return;
    }
    final maxExtent = _scrollController.position.maxScrollExtent;
    final next = (_scrollController.offset + 700).clamp(0.0, maxExtent);
    _scrollController.jumpTo(next);
    if (next >= maxExtent) {
      _didScrollToInitial = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryScrollToInitial(target));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload if the active language changes so the translation edition
    // switches too — Localizations.localeOf(context) isn't safe to read
    // in initState (see quran_screen.dart's SurahReaderScreen for the
    // same pattern and why).
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_loadedForLanguageCode != languageCode) {
      _loadedForLanguageCode = languageCode;
      _future = HadithRepository.load(languageCode: languageCode);
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    final favs = await UserProgressService.favoriteHadiths();
    if (mounted) setState(() => _favorites = favs);
  }

  Future<void> _toggleFavorite(HadithModel hadith) async {
    await UserProgressService.toggleFavoriteHadith(hadith.uid);
    await _loadFavorites();
  }

  void _copyHadith(HadithModel hadith) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: hadith.translatedText.isEmpty ? hadith.arabicText : '${hadith.arabicText}\n\n${hadith.translatedText}'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hadithCopiedSnackbar)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hadithTitle), centerTitle: true),
      body: FutureBuilder<List<HadithModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (_future == null || snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            AppLogger.error('Hadith collection failed to load', error: snapshot.error);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.mutedText),
                    const SizedBox(height: 12),
                    Text(l10n.hadithLoadError, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _future = HadithRepository.load(languageCode: languageCode, forceRefresh: true);
                      }),
                      child: Text(l10n.hadithRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final all = snapshot.data!;
          _maybeScrollToInitial();
          final query = _searchController.text.trim();
          final filtered = query.isEmpty
              ? all
              : all
                  .where((h) =>
                      ArabicTextUtils.contains(h.arabicText, query) ||
                      h.translatedText.toLowerCase().contains(query.toLowerCase()) ||
                      h.number.toString() == query)
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Text(
                      l10n.hadithSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.hadithSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (languageCode == 'de') ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.hadithTranslationNote,
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text(l10n.hadithNoResults))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final hadith = filtered[index];
                          final isFavorite = _favorites.contains(hadith.uid);
                          final isHighlighted = hadith.number == widget.initialHadithNumber;

                          return Card(
                            key: _keyFor(hadith.number),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: isHighlighted
                                ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: AppColors.goldAccent, width: 2))
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l10n.hadithNumberLabel(hadith.number),
                                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryEmerald),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    hadith.arabicText,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18, height: 1.9),
                                  ),
                                  if (hadith.translatedText.isNotEmpty) ...[
                                    const Divider(height: 24),
                                    Text(
                                      hadith.translatedText,
                                      style: const TextStyle(fontSize: 14, height: 1.6),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        tooltip: l10n.hadithCopyTooltip,
                                        onPressed: () => _copyHadith(hadith),
                                        icon: const Icon(Icons.copy_outlined, color: AppColors.mutedText),
                                      ),
                                      IconButton(
                                        tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'مشاركة كصورة' : 'Share as image',
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ShareableTextCardScreen(
                                              mainText: hadith.arabicText,
                                              subText: hadith.translatedText.isEmpty ? null : hadith.translatedText,
                                              referenceLabel: Localizations.localeOf(context).languageCode == 'ar' ? 'حديث رقم ${hadith.number}' : 'Hadith ${hadith.number}',
                                              pageTitle: Localizations.localeOf(context).languageCode == 'ar' ? 'مشاركة حديث' : 'Share Hadith',
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.share_outlined, color: AppColors.mutedText),
                                      ),
                                      Semantics(
                                        button: true,
                                        label: isFavorite ? l10n.hadithRemoveFromFavoritesLabel : l10n.hadithAddToFavoritesLabel,
                                        child: IconButton(
                                          tooltip: l10n.hadithAddToFavoritesLabel,
                                          onPressed: () => _toggleFavorite(hadith),
                                          icon: Icon(
                                            isFavorite ? Icons.favorite : Icons.favorite_border,
                                            color: isFavorite ? AppColors.goldAccent : AppColors.mutedText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
