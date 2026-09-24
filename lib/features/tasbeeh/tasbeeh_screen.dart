import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class _TasbeehPhrase {
  final String id;
  final String text; // Always Arabic — the dhikr itself, recited as-is
  final bool isCustom;
  final int target;

  /// Key into AppLocalizations for this phrase's transliteration+meaning
  /// gloss, shown under the counter for non-Arabic UI languages. Null
  /// for custom (user-authored) phrases, which have no known gloss.
  final String? Function(AppLocalizations)? glossFor;

  const _TasbeehPhrase(this.id, this.text, this.target, {this.isCustom = false, this.glossFor});
}

final _builtInPhrases = [
  _TasbeehPhrase('subhanallah', 'سبحان الله', 33, glossFor: (l10n) => l10n.tasbeehGlossSubhanallah),
  _TasbeehPhrase('alhamdulillah', 'الحمد لله', 33, glossFor: (l10n) => l10n.tasbeehGlossAlhamdulillah),
  _TasbeehPhrase('allahuakbar', 'الله أكبر', 33, glossFor: (l10n) => l10n.tasbeehGlossAllahuakbar),
  _TasbeehPhrase('la_ilaha', 'لا إله إلا الله', 100, glossFor: (l10n) => l10n.tasbeehGlossLaIlaha),
  _TasbeehPhrase('astaghfirullah', 'أستغفر الله', 100, glossFor: (l10n) => l10n.tasbeehGlossAstaghfirullah),
  _TasbeehPhrase('salawat', 'اللهم صل على محمد', 100, glossFor: (l10n) => l10n.tasbeehGlossSalawat),
];

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  List<_TasbeehPhrase> _customPhrases = [];
  late _TasbeehPhrase _selected = _builtInPhrases.first;
  int _today = 0;
  int _cycleCount = 0;
  int _total = 0;
  int _grandTotal = 0;

  List<_TasbeehPhrase> get _allPhrases => [..._builtInPhrases, ..._customPhrases];

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  void initState() {
    super.initState();
    _loadCustomPhrases().then((_) => _load());
  }

  Future<void> _loadCustomPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tasbeeh_custom_phrases_v1');
    if (raw == null) return;

    final decoded = jsonDecode(raw) as List<dynamic>;
    setState(() {
      _customPhrases = decoded.map((item) {
        final map = item as Map<String, dynamic>;
        return _TasbeehPhrase(map['id'], map['text'], map['target'], isCustom: true);
      }).toList();
    });
  }

  Future<void> _saveCustomPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_customPhrases
        .map((p) => {'id': p.id, 'text': p.text, 'target': p.target})
        .toList());
    await prefs.setString('tasbeeh_custom_phrases_v1', encoded);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDay = prefs.getString('tasbeeh_day_${_selected.id}');
    final todayCount = storedDay == _todayKey() ? (prefs.getInt('tasbeeh_today_${_selected.id}') ?? 0) : 0;
    final storedCycle = storedDay == _todayKey() ? (prefs.getInt('tasbeeh_cycle_${_selected.id}') ?? (todayCount % _selected.target)) : 0;

    // NOTE: this used to "self-correct" by bumping the persisted lifetime
    // total UP to match today's count whenever total < today. Under
    // correct operation this should never legitimately happen (every tap
    // increments both by exactly 1 together, and resetting only zeroes
    // today, never total) -- so the only time this condition actually
    // fired was a benign, harmless timing gap between the optimistic UI
    // update and the SharedPreferences write finishing, right as the user
    // switched to a different phrase. Firing then silently inflated the
    // lifetime total with no real tap behind it -- exactly the "count
    // increases when I switch phrases" bug. Removed: just read the real
    // persisted value, with no silent rewriting.
    final total = prefs.getInt('tasbeeh_total_${_selected.id}') ?? 0;
    setState(() {
      _today = todayCount;
      _cycleCount = storedCycle;
      _total = total;
    });
    await _loadGrandTotal();
  }

  /// Combined total across every phrase (built-in + custom), separate
  /// from [_total] which is per-phrase only.
  Future<void> _loadGrandTotal() async {
    final prefs = await SharedPreferences.getInstance();
    var sum = 0;
    for (final phrase in _allPhrases) {
      sum += prefs.getInt('tasbeeh_total_${phrase.id}') ?? 0;
    }
    if (mounted) setState(() => _grandTotal = sum);
  }

  Future<void> _increment() async {
    HapticFeedback.mediumImpact();

    final nextDaily = _today + 1;
    final nextCycle = _cycleCount + 1;
    final nextTotal = _total + 1;
    final completedCycle = nextCycle >= _selected.target;

    // The daily total NEVER resets. Only the visual tasbeeh cycle resets
    // after the selected target, so the ring starts a fresh round while
    // today's count and lifetime totals continue to accumulate.
    setState(() {
      _today = nextDaily;
      _cycleCount = completedCycle ? 0 : nextCycle;
      _total = nextTotal;
      _grandTotal += 1;
    });

    unawaited(_persistIncrement(nextDaily, nextTotal, completedCycle: completedCycle));

    if (completedCycle) {
      HapticFeedback.heavyImpact();
    }
  }
  Future<void> _persistIncrement(int next, int nextTotal, {bool completedCycle = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_today_${_selected.id}', next);
    await prefs.setInt('tasbeeh_cycle_${_selected.id}', completedCycle ? 0 : (next % _selected.target));
    await prefs.setString('tasbeeh_day_${_selected.id}', _todayKey());
    await prefs.setInt('tasbeeh_total_${_selected.id}', nextTotal);
    await UserProgressService.incrementTasbeehDailyTotal();
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_cycle_${_selected.id}', 0);
    await prefs.setString('tasbeeh_day_${_selected.id}', _todayKey());
    setState(() => _cycleCount = 0);
  }

  void _selectPhrase(_TasbeehPhrase phrase) {
    setState(() => _selected = phrase);
    _load();
  }

  Future<void> _addCustomPhrase() async {
    final l10n = AppLocalizations.of(context);
    final textController = TextEditingController();
    final targetController = TextEditingController(text: '100');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tasbeehAddCustomTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(labelText: l10n.tasbeehPhraseTextLabel, hintText: l10n.tasbeehPhraseTextHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.tasbeehTargetLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.tasbeehAdd)),
        ],
      ),
    );

    if (result != true) return;
    final text = textController.text.trim();
    final target = int.tryParse(targetController.text.trim()) ?? 100;
    if (text.isEmpty) return;

    final phrase = _TasbeehPhrase('custom_${DateTime.now().millisecondsSinceEpoch}', text, target, isCustom: true);
    setState(() {
      _customPhrases = [..._customPhrases, phrase];
      _selected = phrase;
    });
    await _saveCustomPhrases();
    _load();
  }

  Future<void> _deleteCustomPhrase(_TasbeehPhrase phrase) async {
    setState(() {
      _customPhrases = _customPhrases.where((p) => p.id != phrase.id).toList();
      if (_selected.id == phrase.id) _selected = _builtInPhrases.first;
    });
    await _saveCustomPhrases();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = (_cycleCount / _selected.target).clamp(0.0, 1.0);
    final gloss = _selected.glossFor?.call(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasbeehTitle),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.refresh), tooltip: l10n.tasbeehResetToday),
        ],
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final circleSize = landscape
                ? math.min(220.0, constraints.maxHeight * 0.58)
                : math.min(300.0, constraints.maxWidth - 32);
            final progressSize = math.max(0.0, circleSize - 20);
            final content = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _allPhrases.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == _allPhrases.length) {
                        return ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: Text(l10n.tasbeehCustom),
                          onPressed: _addCustomPhrase,
                        );
                      }
                      final phrase = _allPhrases[index];
                      final isSelected = phrase.id == _selected.id;
                      return GestureDetector(
                        onLongPress: phrase.isCustom ? () => _deleteCustomPhrase(phrase) : null,
                        child: ChoiceChip(
                          label: Text(phrase.text),
                          selected: isSelected,
                          onSelected: (_) => _selectPhrase(phrase),
                          selectedColor: AppColors.primaryEmerald.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryEmerald : null,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: landscape ? 8 : 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatChip(label: l10n.tasbeehToday, value: '$_today'),
                        const SizedBox(width: 10),
                        _StatChip(label: l10n.tasbeehTarget, value: '${_selected.target}'),
                        const SizedBox(width: 10),
                        _StatChip(label: l10n.tasbeehPhraseTotal, value: '$_total'),
                        const SizedBox(width: 10),
                        _StatChip(label: l10n.tasbeehGrandTotal, value: '$_grandTotal'),
                      ],
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.tasbeehCounterLabel(_selected.text, _today, _selected.target),
                  child: GestureDetector(
                    onTap: _increment,
                    child: SizedBox(
                      width: circleSize,
                      height: circleSize,
                      child: CustomPaint(
                        painter: _TasbeehBeadsPainter(
                          count: _selected.target,
                          litCount: _cycleCount.clamp(0, _selected.target),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [AppColors.primaryEmerald, const Color(0xFF115E56)]),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: progressSize,
                                height: progressSize,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('$_cycleCount', style: TextStyle(color: Colors.white, fontSize: landscape ? 48 : 64, fontWeight: FontWeight.w700)),
                                  ),
                                  Text(_selected.text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (gloss != null && gloss.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(gloss, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l10n.tasbeehTapHint, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                ),
              ],
            );
            return landscape
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(child: content),
                  )
                : content;
          },
        ),
      ),
    );
  }
}

class _TasbeehBeadsPainter extends CustomPainter {
  final int count;
  final int litCount;
  const _TasbeehBeadsPainter({required this.count, required this.litCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0) return;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final beadRadius = math.max(2.2, math.min(5.5, radius * 0.035));
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final lit = i < litCount;
      paint.color = lit
          ? AppColors.goldAccent
          : Colors.white.withValues(alpha: 0.32);
      canvas.drawCircle(point, beadRadius + (lit ? 1.2 : 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TasbeehBeadsPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.litCount != litCount;
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryEmerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
        ],
      ),
    );
  }
}
