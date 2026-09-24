import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class _QuizQuestion {
  final String ar;
  final String en;
  final List<String> arOptions;
  final List<String> enOptions;
  final int correctIndex;
  const _QuizQuestion({
    required this.ar,
    required this.en,
    required this.arOptions,
    required this.enOptions,
    required this.correctIndex,
  });
}

const List<_QuizQuestion> _bank = [
  _QuizQuestion(ar: '\u0643\u0645 \u0639\u062f\u062f \u0633\u0648\u0631 \u0627\u0644\u0642\u0631\u0622\u0646 \u0627\u0644\u0643\u0631\u064a\u0645\u061f', en: 'How many surahs are in the Quran?', arOptions: ['\u0661\u0661\u0664', '\u0661\u0660\u0660', '\u0661\u0662\u0660', '\u0669\u0664'], enOptions: ['114', '100', '120', '94'], correctIndex: 0),
  _QuizQuestion(ar: '\u0645\u0627 \u0647\u064a \u0623\u0637\u0648\u0644 \u0633\u0648\u0631\u0629 \u0641\u064a \u0627\u0644\u0642\u0631\u0622\u0646\u061f', en: 'What is the longest surah in the Quran?', arOptions: ['\u0627\u0644\u0628\u0642\u0631\u0629', '\u0622\u0644 \u0639\u0645\u0631\u0627\u0646', '\u0627\u0644\u0646\u0633\u0627\u0621', '\u064a\u0648\u0633\u0641'], enOptions: ['Al-Baqarah', 'Aal-Imran', 'An-Nisa', 'Yusuf'], correctIndex: 0),
  _QuizQuestion(ar: '\u0641\u064a \u0623\u064a \u0634\u0647\u0631 \u0646\u0632\u0644 \u0627\u0644\u0642\u0631\u0622\u0646 \u0627\u0644\u0643\u0631\u064a\u0645\u061f', en: 'In which month was the Quran first revealed?', arOptions: ['\u0631\u0645\u0636\u0627\u0646', '\u0634\u0648\u0627\u0644', '\u0631\u062c\u0628', '\u0645\u062d\u0631\u0645'], enOptions: ['Ramadan', 'Shawwal', 'Rajab', 'Muharram'], correctIndex: 0),
  _QuizQuestion(ar: '\u0643\u0645 \u0639\u062f\u062f \u0623\u0631\u0643\u0627\u0646 \u0627\u0644\u0625\u0633\u0644\u0627\u0645\u061f', en: 'How many pillars of Islam are there?', arOptions: ['\u0665', '\u0664', '\u0666', '\u0663'], enOptions: ['5', '4', '6', '3'], correctIndex: 0),
  _QuizQuestion(ar: '\u0645\u0627 \u0647\u064a \u0627\u0644\u0642\u0628\u0644\u0629 \u0627\u0644\u0623\u0648\u0644\u0649 \u0642\u0628\u0644 \u0627\u0644\u0643\u0639\u0628\u0629\u061f', en: 'What was the first Qibla before the Kaaba?', arOptions: ['\u0627\u0644\u0645\u0633\u062c\u062f \u0627\u0644\u0623\u0642\u0635\u0649', '\u0627\u0644\u0645\u0633\u062c\u062f \u0627\u0644\u0646\u0628\u0648\u064a', '\u062c\u0628\u0644 \u0623\u062d\u062f', '\u063a\u0627\u0631 \u062d\u0631\u0627\u0621'], enOptions: ['Al-Aqsa Mosque', "The Prophet's Mosque", 'Mount Uhud', 'Cave of Hira'], correctIndex: 0),
  _QuizQuestion(ar: '\u0643\u0645 \u0639\u062f\u062f \u0645\u0631\u0627\u062a \u0627\u0644\u0635\u0644\u0627\u0629 \u0627\u0644\u0645\u0641\u0631\u0648\u0636\u0629 \u064a\u0648\u0645\u064a\u0627\u064b\u061f', en: 'How many obligatory prayers are there per day?', arOptions: ['\u0665', '\u0663', '\u0667', '\u0664'], enOptions: ['5', '3', '7', '4'], correctIndex: 0),
  _QuizQuestion(ar: '\u0645\u0627 \u0627\u0633\u0645 \u0623\u0645 \u0627\u0644\u0646\u0628\u064a \u0635\u0644\u0649 \u0627\u0644\u0644\u0647 \u0639\u0644\u064a\u0647 \u0648\u0633\u0644\u0645\u061f', en: "What was the name of the Prophet's mother?", arOptions: ['\u0622\u0645\u0646\u0629', '\u062e\u062f\u064a\u062c\u0629', '\u0641\u0627\u0637\u0645\u0629', '\u0639\u0627\u0626\u0634\u0629'], enOptions: ['Aminah', 'Khadijah', 'Fatimah', 'Aisha'], correctIndex: 0),
  _QuizQuestion(ar: '\u0643\u0645 \u0639\u062f\u062f \u0627\u0644\u0623\u0646\u0628\u064a\u0627\u0621 \u0623\u0648\u0644\u064a \u0627\u0644\u0639\u0632\u0645\u061f', en: 'How many prophets are given the title Ulul Azm (the resolute)?', arOptions: ['\u0665', '\u0663', '\u0667', '\u0662\u0665'], enOptions: ['5', '3', '7', '25'], correctIndex: 0),
  _QuizQuestion(ar: '\u0641\u064a \u0623\u064a \u063a\u0632\u0648\u0629 \u0627\u0646\u062a\u0635\u0631 \u0627\u0644\u0645\u0633\u0644\u0645\u0648\u0646 \u0631\u063a\u0645 \u0642\u0644\u0629 \u0639\u062f\u062f\u0647\u0645\u061f', en: 'In which battle did Muslims win despite being outnumbered?', arOptions: ['\u0628\u062f\u0631', '\u0623\u062d\u062f', '\u0627\u0644\u062e\u0646\u062f\u0642', '\u062d\u0646\u064a\u0646'], enOptions: ['Badr', 'Uhud', 'The Trench', 'Hunayn'], correctIndex: 0),
  _QuizQuestion(ar: '\u0645\u0627 \u0627\u0633\u0645 \u0627\u0644\u0645\u0644\u0627\u0643 \u0627\u0644\u0630\u064a \u064a\u0633\u0623\u0644 \u0627\u0644\u0645\u064a\u062a \u0641\u064a \u0627\u0644\u0642\u0628\u0631\u061f', en: 'What is the name given to the angels who question the deceased in the grave?', arOptions: ['\u0645\u0646\u0643\u0631 \u0648\u0646\u0643\u064a\u0631', '\u062c\u0628\u0631\u064a\u0644 \u0648\u0645\u064a\u0643\u0627\u0626\u064a\u0644', '\u0645\u0627\u0644\u0643 \u0648\u0631\u0636\u0648\u0627\u0646', '\u0647\u0627\u0631\u0648\u062a \u0648\u0645\u0627\u0631\u0648\u062a'], enOptions: ['Munkar and Nakir', 'Jibreel and Mikaeel', 'Malik and Ridwan', 'Harut and Marut'], correctIndex: 0),
  _QuizQuestion(ar: '\u0645\u0627 \u0645\u0639\u0646\u0649 \u0643\u0644\u0645\u0629 \u0642\u0631\u0622\u0646\u061f', en: 'What does the word "Quran" literally mean?', arOptions: ['\u0627\u0644\u0642\u0631\u0627\u0621\u0629/\u0627\u0644\u062a\u0644\u0627\u0648\u0629', '\u0627\u0644\u0643\u062a\u0627\u0628\u0629', '\u0627\u0644\u0648\u062d\u064a', '\u0627\u0644\u0646\u0648\u0631'], enOptions: ['The recitation', 'The writing', 'The revelation', 'The light'], correctIndex: 0),
  _QuizQuestion(ar: '\u0623\u064a \u0633\u0648\u0631\u0629 \u0641\u064a \u0627\u0644\u0642\u0631\u0622\u0646 \u0644\u0627 \u062a\u0628\u062f\u0623 \u0628\u0627\u0644\u0628\u0633\u0645\u0644\u0629\u061f', en: 'Which surah does not begin with Bismillah?', arOptions: ['\u0627\u0644\u062a\u0648\u0628\u0629', '\u0627\u0644\u0641\u0627\u062a\u062d\u0629', '\u0627\u0644\u0625\u062e\u0644\u0627\u0635', '\u0627\u0644\u0643\u0648\u062b\u0631'], enOptions: ['At-Tawbah', 'Al-Fatihah', 'Al-Ikhlas', 'Al-Kawthar'], correctIndex: 0),
  _QuizQuestion(ar: '\u0641\u064a \u0623\u064a \u0645\u062f\u064a\u0646\u0629 \u0648\u0644\u062f \u0627\u0644\u0646\u0628\u064a \u0635\u0644\u0649 \u0627\u0644\u0644\u0647 \u0639\u0644\u064a\u0647 \u0648\u0633\u0644\u0645\u061f', en: 'In which city was the Prophet born?', arOptions: ['\u0645\u0643\u0629', '\u0627\u0644\u0645\u062f\u064a\u0646\u0629', '\u0627\u0644\u0637\u0627\u0626\u0641', '\u0628\u063a\u062f\u0627\u062f'], enOptions: ['Makkah', 'Madinah', "Ta'if", 'Baghdad'], correctIndex: 0),
  _QuizQuestion(ar: '\u0643\u0645 \u0639\u062f\u062f \u0623\u064a\u0627\u0645 \u0635\u0648\u0645 \u0631\u0645\u0636\u0627\u0646 \u0639\u0627\u062f\u0629\u061f', en: 'How many days is Ramadan usually?', arOptions: ['\u0662\u0669 \u0623\u0648 \u0663\u0660', '\u0662\u0665', '\u0663\u0665', '\u0662\u0660'], enOptions: ['29 or 30', '25', '35', '20'], correctIndex: 0),
  _QuizQuestion(ar: '\u0645\u0627 \u0627\u0633\u0645 \u0623\u0648\u0644 \u0645\u0646 \u0622\u0645\u0646 \u0628\u0627\u0644\u0646\u0628\u064a \u0635\u0644\u0649 \u0627\u0644\u0644\u0647 \u0639\u0644\u064a\u0647 \u0648\u0633\u0644\u0645\u061f', en: 'Who was the first man to believe in the Prophet?', arOptions: ['\u0623\u0628\u0648 \u0628\u0643\u0631 \u0627\u0644\u0635\u062f\u064a\u0642', '\u0639\u0645\u0631 \u0628\u0646 \u0627\u0644\u062e\u0637\u0627\u0628', '\u0639\u062b\u0645\u0627\u0646 \u0628\u0646 \u0639\u0641\u0627\u0646', '\u0639\u0644\u064a \u0628\u0646 \u0623\u0628\u064a \u0637\u0627\u0644\u0628'], enOptions: ['Abu Bakr As-Siddiq', 'Umar ibn Al-Khattab', 'Uthman ibn Affan', 'Ali ibn Abi Talib'], correctIndex: 0),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _roundSize = 10;
  static const _bestScoreKey = 'quiz_best_score_v1';

  late List<_QuizQuestion> _round;
  int _index = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _startNewRound();
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _bestScore = prefs.getInt(_bestScoreKey) ?? 0);
  }

  Future<void> _maybeSaveBestScore() async {
    if (_score <= _bestScore) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestScoreKey, _score);
    if (mounted) setState(() => _bestScore = _score);
  }

  void _startNewRound() {
    final shuffled = List<_QuizQuestion>.from(_bank)..shuffle(Random());
    setState(() {
      _round = shuffled.take(_roundSize).toList();
      _index = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
    });
  }

  void _selectOption(int optionIndex) {
    if (_answered) return;
    setState(() {
      _selectedOption = optionIndex;
      _answered = true;
      if (optionIndex == _round[_index].correctIndex) _score++;
    });
  }

  void _next() {
    if (_index + 1 >= _round.length) {
      _maybeSaveBestScore();
      setState(() => _index = _round.length);
      return;
    }
    setState(() {
      _index++;
      _selectedOption = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final finished = _index >= _round.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? '\u0645\u0633\u0627\u0628\u0642\u0629 \u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0625\u0633\u0644\u0627\u0645\u064a\u0629' : 'Islamic Quiz'),
        centerTitle: true,
      ),
      body: SafeArea(child: finished ? _buildResults(context, isAr) : _buildQuestion(context, isAr)),
    );
  }

  Widget _buildResults(BuildContext context, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.emoji_events, size: 64, color: AppColors.goldAccent),
          const SizedBox(height: 16),
          Text(isAr ? '\u0646\u062a\u064a\u062c\u062a\u0643: $_score \u0645\u0646 ${_round.length}' : 'Your score: $_score of ${_round.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(isAr ? '\u0623\u0641\u0636\u0644 \u0646\u062a\u064a\u062c\u0629: $_bestScore' : 'Best score: $_bestScore', style: const TextStyle(color: AppColors.mutedText)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startNewRound,
            icon: const Icon(Icons.refresh),
            label: Text(isAr ? '\u062c\u0648\u0644\u0629 \u062c\u062f\u064a\u062f\u0629' : 'Play again'),
          ),
        ]),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, bool isAr) {
    final q = _round[_index];
    final options = isAr ? q.arOptions : q.enOptions;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LinearProgressIndicator(value: (_index) / _round.length, color: AppColors.primaryEmerald),
        const SizedBox(height: 8),
        Text(isAr ? '\u0633\u0624\u0627\u0644 ${_index + 1} \u0645\u0646 ${_round.length}' : 'Question ${_index + 1} of ${_round.length}', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        const SizedBox(height: 16),
        Text(isAr ? q.ar : q.en, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        for (var i = 0; i < options.length; i++) ...[
          _OptionButton(
            text: options[i],
            isAr: isAr,
            isSelected: _selectedOption == i,
            isCorrect: i == q.correctIndex,
            revealed: _answered,
            onTap: () => _selectOption(i),
          ),
          const SizedBox(height: 10),
        ],
        const Spacer(),
        if (_answered)
          FilledButton(onPressed: _next, child: Text(isAr ? '\u0627\u0644\u062a\u0627\u0644\u064a' : 'Next')),
      ]),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String text;
  final bool isAr;
  final bool isSelected;
  final bool isCorrect;
  final bool revealed;
  final VoidCallback onTap;
  const _OptionButton({
    required this.text,
    required this.isAr,
    required this.isSelected,
    required this.isCorrect,
    required this.revealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bg;
    if (revealed) {
      if (isCorrect) {
        bg = AppColors.primaryEmerald.withValues(alpha: 0.15);
      } else if (isSelected) {
        bg = Colors.red.withValues(alpha: 0.12);
      }
    }
    return InkWell(
      onTap: revealed ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: revealed && isCorrect ? AppColors.primaryEmerald : Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(child: Text(text, textDirection: isAr ? TextDirection.rtl : TextDirection.ltr, textAlign: isAr ? TextAlign.right : TextAlign.left)),
          if (revealed && isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          if (revealed && isSelected && !isCorrect) const Icon(Icons.cancel, color: Colors.red, size: 20),
        ]),
      ),
    );
  }
}
