import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/quran_models.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';

/// A real "fill in the missing word" memorization game: picks a random
/// ayah from the chosen surah, hides one real word from its actual
/// text, and offers 4 choices -- the real correct word plus 3 other
/// real words drawn from the same surah's own text (not fabricated
/// distractors). Tracks score for the session.
class MemorizationGameScreen extends StatefulWidget {
  const MemorizationGameScreen({super.key});

  @override
  State<MemorizationGameScreen> createState() => _MemorizationGameScreenState();
}

class _MemorizationGameScreenState extends State<MemorizationGameScreen> {
  List<SurahModel> _surahs = [];
  SurahModel? _selected;
  bool _loading = true;

  int _score = 0;
  int _attempts = 0;
  String? _feedback;
  bool? _lastCorrect;

  List<String> _promptWords = [];
  int _hiddenIndex = -1;
  String _correctWord = '';
  List<String> _choices = [];
  final _random = Random();

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
      _selected = surahs.isNotEmpty ? surahs[0] : null;
      _loading = false;
    });
    _newRound();
  }

  void _newRound() {
    final surah = _selected;
    if (surah == null || surah.ayahs.isEmpty) return;

    // Collect every real word across the surah, to use as distractors.
    final allWords = <String>{};
    for (final a in surah.ayahs) {
      for (final w in a.text.split(' ')) {
        if (w.trim().length >= 3) allWords.add(w.trim());
      }
    }

    // Pick a random ayah with at least 3 words so hiding one still
    // leaves useful context.
    final candidates = surah.ayahs.where((a) => a.text.split(' ').where((w) => w.trim().isNotEmpty).length >= 3).toList();
    if (candidates.isEmpty) return;
    final ayah = candidates[_random.nextInt(candidates.length)];
    final words = ayah.text.split(' ').where((w) => w.trim().isNotEmpty).toList();
    final hideIndex = 1 + _random.nextInt(words.length - 1 > 0 ? words.length - 1 : 1);
    final safeIndex = hideIndex.clamp(0, words.length - 1);
    final correct = words[safeIndex];

    final distractorPool = allWords.where((w) => w != correct).toList()..shuffle(_random);
    final distractors = distractorPool.take(3).toList();
    final choices = [correct, ...distractors]..shuffle(_random);

    setState(() {
      _promptWords = words;
      _hiddenIndex = safeIndex;
      _correctWord = correct;
      _choices = choices;
      _feedback = null;
      _lastCorrect = null;
    });
  }

  void _choose(String word) {
    setState(() {
      _attempts += 1;
      _lastCorrect = word == _correctWord;
      if (_lastCorrect == true) _score += 1;
      _feedback = _lastCorrect == true ? null : _correctWord;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'اختبار الحفظ' : 'Memorization Test'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('$_score / $_attempts', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selected?.number,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: _surahs
                        .map((s) => DropdownMenuItem(value: s.number, child: Text('${s.number}. ${s.name}', textDirection: TextDirection.rtl)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selected = _surahs.firstWhere((s) => s.number == value));
                      _newRound();
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_promptWords.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.25)),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        textDirection: TextDirection.rtl,
                        spacing: 6,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _promptWords.length; i++)
                            i == _hiddenIndex
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.primaryEmerald, width: 1.5),
                                    ),
                                    child: Text(
                                      '.......',
                                      style: TextStyle(
                                        fontFamily: 'AmiriQuran',
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryEmerald,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _promptWords[i],
                                    style: const TextStyle(
                                      fontFamily: 'AmiriQuran',
                                      fontSize: 22,
                                      height: 1.9,
                                      color: Colors.black87,
                                    ),
                                  ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  ..._choices.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: AppColors.primaryEmerald.withValues(alpha: 0.4), width: 1.5),
                          ),
                          onPressed: _feedback == null && _lastCorrect == null ? () => _choose(w) : null,
                          child: Text(w, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      )),
                  if (_lastCorrect != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _lastCorrect == true
                          ? (isAr ? 'إجابة صحيحة!' : 'Correct!')
                          : (isAr ? 'الإجابة الصحيحة: $_correctWord' : 'Correct answer: $_correctWord'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _lastCorrect == true ? AppColors.primaryEmerald : Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _newRound, child: Text(isAr ? 'التالي' : 'Next')),
                  ],
                ],
              ),
            ),
    );
  }
}
