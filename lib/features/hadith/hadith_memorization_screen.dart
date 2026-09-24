import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/hadith_models.dart';
import '../../core/services/hadith_repository.dart';
import '../../core/theme/app_theme.dart';

class HadithMemorizationScreen extends StatefulWidget {
  const HadithMemorizationScreen({super.key});

  @override
  State<HadithMemorizationScreen> createState() => _HadithMemorizationScreenState();
}

class _HadithMemorizationScreenState extends State<HadithMemorizationScreen> {
  List<HadithModel> _hadiths = [];
  HadithModel? _selected;
  bool _loading = true;

  int _score = 0;
  int _attempts = 0;
  bool? _lastCorrect;

  List<String> _promptWords = [];
  int _hiddenIndex = -1;
  String _correctWord = '';
  List<String> _choices = [];
  final _random = Random();

  String? _loadedForLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_loadedForLanguageCode != languageCode) {
      _loadedForLanguageCode = languageCode;
      _load(languageCode);
    }
  }

  Future<void> _load(String languageCode) async {
    final hadiths = await HadithRepository.load(languageCode: languageCode);
    if (!mounted) return;
    setState(() {
      _hadiths = hadiths;
      _selected = hadiths.isNotEmpty ? hadiths.first : null;
      _loading = false;
    });
    _newRound();
  }

  void _newRound() {
    final hadith = _selected;
    if (hadith == null) return;

    final allWords = <String>{};
    for (final h in _hadiths) {
      for (final w in h.arabicText.split(' ')) {
        if (w.trim().length >= 3) allWords.add(w.trim());
      }
    }

    final words = hadith.arabicText.split(' ').where((w) => w.trim().isNotEmpty).toList();
    if (words.length < 3) return;
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
      _lastCorrect = null;
    });
  }

  void _choose(String word) {
    setState(() {
      _attempts += 1;
      _lastCorrect = word == _correctWord;
      if (_lastCorrect == true) _score += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'حفظ الأحاديث' : 'Hadith Memorization'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('$_score / $_attempts', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
        ],
      ),
      body: SafeArea(bottom: true, top: false, child: _loading
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
                    items: _hadiths
                        .map((h) => DropdownMenuItem(value: h.number, child: Text(isAr ? 'حديث ${h.number}' : 'Hadith ${h.number}')))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selected = _hadiths.firstWhere((h) => h.number == value));
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
                            Text(
                              i == _hiddenIndex ? '________' : _promptWords[i],
                              style: TextStyle(
                                fontSize: 18,
                                height: 1.8,
                                fontWeight: i == _hiddenIndex ? FontWeight.bold : FontWeight.normal,
                                color: i == _hiddenIndex ? AppColors.primaryEmerald : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  ..._choices.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton(
                          onPressed: _lastCorrect == null ? () => _choose(w) : null,
                          child: Text(w, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 16)),
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
            )),
    );
  }
}
