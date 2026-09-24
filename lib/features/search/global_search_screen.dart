import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/azkar_models.dart';
import '../../core/models/hadith_models.dart';
import '../../core/models/quran_models.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/arabic_text_utils.dart';
import '../../core/services/azkar_repository.dart';
import '../../core/services/hadith_repository.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';
import '../azkar/azkar_screen.dart';
import '../hadith/hadith_collection_screen.dart';
import '../quran/quran_screen.dart';

class _QuranHit {
  final SurahModel surah;
  final AyahModel ayah;
  const _QuranHit(this.surah, this.ayah);
}

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});
  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _controller = TextEditingController();
  List<String> _recentSearches = [];
  static const _historyKey = 'global_search_history_v1';
  List<SurahModel>? _surahs;
  List<HadithModel>? _hadiths;
  List<AzkarCategoryModel>? _azkarCategories;
  bool _loading = true;
  String? _loadError;

  List<_QuranHit> _quranResults = [];
  List<HadithModel> _hadithResults = [];
  final List<(AzkarCategoryModel, AzkarItemModel)> _azkarResults = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _saveToHistory(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(_recentSearches);
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > 10) list.removeRange(10, list.length);
    await prefs.setStringList(_historyKey, list);
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _loadAll() async {
    try {
      List<SurahModel> surahs = [];
      List<HadithModel> hadiths = [];
      List<AzkarCategoryModel> azkarCategories = [];
      
      try {
        surahs = await QuranRepository.load();
      } catch (e) {
        AppLogger.error('Failed to load Quran', error: e);
      }
      
      try {
        hadiths = await HadithRepository.load(languageCode: Localizations.localeOf(context).languageCode);
      } catch (e) {
        AppLogger.error('Failed to load Hadith', error: e);
      }
      
      try {
        azkarCategories = await AzkarRepository.load();
      } catch (e) {
        AppLogger.error('Failed to load Azkar', error: e);
      }
      
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _hadiths = hadiths;
        _azkarCategories = azkarCategories;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  void _search(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _quranResults = [];
        _hadithResults = [];
        _azkarResults.clear();
      });
      return;
    }
    final quranHits = <_QuranHit>[];
    if (_surahs != null) {
      outer:
      for (final surah in _surahs!) {
        for (final ayah in surah.ayahs) {
          if (ArabicTextUtils.contains(ayah.text, q)) {
            quranHits.add(_QuranHit(surah, ayah));
            if (quranHits.length >= 30) break outer;
          }
        }
      }
    }
    final hadithHits = <HadithModel>[];
    if (_hadiths != null) {
      for (final h in _hadiths!) {
        if (ArabicTextUtils.contains(h.arabicText, q) || ArabicTextUtils.contains(h.translatedText, q)) {
          hadithHits.add(h);
          if (hadithHits.length >= 30) break;
        }
      }
    }
    final azkarHits = <(AzkarCategoryModel, AzkarItemModel)>[];
    if (_azkarCategories != null) {
      outer2:
      for (final cat in _azkarCategories!) {
        for (final item in cat.items) {
          if (ArabicTextUtils.contains(item.text, q)) {
            azkarHits.add((cat, item));
            if (azkarHits.length >= 30) break outer2;
          }
        }
      }
    }
    setState(() {
      _quranResults = quranHits;
      _hadithResults = hadithHits;
      _azkarResults
        ..clear()
        ..addAll(azkarHits);
    });
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr;
    final hasQuery = _controller.text.trim().isNotEmpty;
    final totalResults = _quranResults.length + _hadithResults.length + _azkarResults.length;

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? '\u0628\u062d\u062b \u0634\u0627\u0645\u0644' : 'Global Search'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textDirection: TextDirection.rtl,
              autofocus: true,
              onChanged: _search,
              onSubmitted: _saveToHistory,
              decoration: InputDecoration(
                hintText: isAr ? '\u0627\u0628\u062d\u062b \u0641\u064a \u0627\u0644\u0642\u0631\u0622\u0646 \u0648\u0627\u0644\u062d\u062f\u064a\u062b \u0648\u0627\u0644\u0623\u0630\u0643\u0627\u0631...' : 'Search Quran, Hadith, Azkar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: hasQuery ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _controller.clear(); _search(''); }) : null,
              ),
            ),
          ),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_loadError != null)
            Expanded(child: Center(child: Text(isAr ? '\u062a\u0639\u0630\u0651\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a \u0644\u0644\u0628\u062d\u062b' : 'Failed to load search data', style: const TextStyle(color: AppColors.mutedText)))),
          if (!_loading && _loadError == null && !hasQuery && _recentSearches.isNotEmpty)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text(isAr ? '\u0622\u062e\u0631 \u0639\u0645\u0644\u064a\u0627\u062a \u0627\u0644\u0628\u062d\u062b' : 'Recent searches', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final q in _recentSearches)
                        ActionChip(
                          label: Text(q),
                          onPressed: () {
                            _controller.text = q;
                            _search(q);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (!_loading && _loadError == null && hasQuery && totalResults == 0)
            Expanded(child: Center(child: Text(isAr ? '\u0644\u0627 \u062a\u0648\u062c\u062f \u0646\u062a\u0627\u0626\u062c' : 'No results', style: const TextStyle(color: AppColors.mutedText)))),
          if (!_loading && _loadError == null && totalResults > 0)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_quranResults.isNotEmpty) ...[
                    _SectionHeader(isAr ? '\u0627\u0644\u0642\u0631\u0622\u0646 (${_quranResults.length})' : 'Quran (${_quranResults.length})'),
                    for (final hit in _quranResults)
                      Card(
                        child: ListTile(
                          title: Text(hit.ayah.text, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 19, height: 1.9)),
                          subtitle: Text('${hit.surah.name} \u2022 ${hit.ayah.number}'),
                          onTap: () {
                            _saveToHistory(_controller.text);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => QuranScreen(initialSurahNumber: hit.surah.number, initialAyah: hit.ayah.number)));
                          },
                        ),
                      ),
                  ],
                  if (_hadithResults.isNotEmpty) ...[
                    _SectionHeader(isAr ? '\u0627\u0644\u062d\u062f\u064a\u062b (${_hadithResults.length})' : 'Hadith (${_hadithResults.length})'),
                    for (final h in _hadithResults)
                      Card(
                        child: ListTile(
                          title: Text(h.translatedText, maxLines: 3, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, textAlign: TextAlign.right),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithCollectionScreen())),
                        ),
                      ),
                  ],
                  if (_azkarResults.isNotEmpty) ...[
                    _SectionHeader(isAr ? '\u0627\u0644\u0623\u0630\u0643\u0627\u0631 \u0648\u0627\u0644\u0623\u062f\u0639\u064a\u0629 (${_azkarResults.length})' : 'Azkar & Duas (${_azkarResults.length})'),
                    for (final pair in _azkarResults)
                      Card(
                        child: ListTile(
                          title: Text(pair.$2.text, maxLines: 3, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl, textAlign: TextAlign.right),
                          subtitle: Text(pair.$1.category),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkarScreen())),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      )),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primaryEmerald)),
    );
  }
}
