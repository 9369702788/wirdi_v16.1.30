import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/data/asma_ul_husna.dart';
import '../../core/theme/app_theme.dart';

class AsmaUlHusnaQuizScreen extends StatefulWidget {
  const AsmaUlHusnaQuizScreen({super.key});

  @override
  State<AsmaUlHusnaQuizScreen> createState() => _AsmaUlHusnaQuizScreenState();
}

class _AsmaUlHusnaQuizScreenState extends State<AsmaUlHusnaQuizScreen> {
  final _random = Random();
  int _score = 0;
  int _attempts = 0;
  late AsmaName _correct;
  List<AsmaName> _choices = [];
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final all = List<AsmaName>.from(AsmaUlHusna.all)..shuffle(_random);
    final correct = all.first;
    final distractors = all.skip(1).take(3).toList();
    final choices = [correct, ...distractors]..shuffle(_random);
    setState(() {
      _correct = correct;
      _choices = choices;
      _lastCorrect = null;
    });
  }

  void _choose(AsmaName name) {
    setState(() {
      _attempts += 1;
      _lastCorrect = name.arabic == _correct.arabic;
      if (_lastCorrect == true) _score += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'اختبار الأسماء الحسنى' : 'Names of Allah Quiz'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text("$_score / $_attempts", style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    isAr ? 'ما اسم الله الذي معناه:' : 'Which Name of Allah means:',
                    style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _correct.meaningFor(languageCode),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ..._choices.map((name) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: _lastCorrect == null ? () => _choose(name) : null,
                    child: Text(name.arabic, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 18)),
                  ),
                )),
            if (_lastCorrect != null) ...[
              const SizedBox(height: 12),
              Text(
                _lastCorrect == true
                    ? (isAr ? 'إجابة صحيحة!' : 'Correct!')
                    : (isAr ? "الإجابة الصحيحة: ${_correct.arabic}" : "Correct answer: ${_correct.arabic}"),
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
