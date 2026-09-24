import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../core/models/quran_models.dart';
import '../../core/services/hifz_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';

String _ht(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

enum HifzVisibility { visible, blurred, hidden }

class HifzScreen extends StatefulWidget {
  const HifzScreen({super.key});
  @override
  State<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends State<HifzScreen> {
  List<SurahModel>? _allSurahs;
  SurahModel? _selectedSurah;
  HifzVisibility _globalMode = HifzVisibility.visible;
  final Map<int, HifzVisibility> _perAyahOverride = {};

  List<HifzPlan> _plans = [];
  int _streak = 0;
  final Map<int, int> _repsCache = {};

  @override
  void initState() {
    super.initState();
    QuranRepository.load().then((s) {
      if (mounted) setState(() => _allSurahs = s);
    });
    _loadPlansAndStreak();
  }

  Future<void> _loadPlansAndStreak() async {
    final plans = await HifzService.getAllPlans();
    final streak = await HifzService.getStreak();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _streak = streak;
    });
  }

  HifzPlan? _planForSurah(int surahNumber) {
    for (final p in _plans) {
      if (p.surahNumber == surahNumber) return p;
    }
    return null;
  }

  Future<void> _loadRepsForSurah(SurahModel surah) async {
    final plan = _planForSurah(surah.number);
    if (plan == null) return;
    final entries = <int, int>{};
    for (var a = plan.startAyah; a <= plan.endAyah; a++) {
      entries[a] = await HifzService.getTodayReps(plan.id, surah.number, a);
    }
    if (!mounted) return;
    setState(() => _repsCache.addAll(entries));
  }

  Future<void> _incrementRep(int ayahNumber) async {
    final surah = _selectedSurah;
    if (surah == null) return;
    final plan = _planForSurah(surah.number);
    if (plan == null) return;
    final updated = await HifzService.incrementReps(plan.id, plan.surahNumber, ayahNumber, plan.targetReps);
    final result = await HifzService.checkAndUpdateStreakIfPlanCompleted(plan);
    if (result.planCompletedNow) {
      await HifzService.markPortionMemorized(plan.surahNumber, plan.startAyah, plan.endAyah);
    }
    if (!mounted) return;
    setState(() {
      _repsCache[ayahNumber] = updated;
      _streak = result.streak;
    });
  }

  HifzVisibility _modeFor(int ayahNumber) => _perAyahOverride[ayahNumber] ?? _globalMode;

  void _cycleAyah(int ayahNumber) {
    setState(() {
      final current = _modeFor(ayahNumber);
      _perAyahOverride[ayahNumber] = switch (current) {
        HifzVisibility.visible => HifzVisibility.blurred,
        HifzVisibility.blurred => HifzVisibility.hidden,
        HifzVisibility.hidden => HifzVisibility.visible,
      };
    });
  }

  Future<void> _addNewPlan() async {
    final surahs = _allSurahs;
    if (surahs == null) return;
    final result = await showDialog<HifzPlan>(
      context: context,
      builder: (context) => _PlanEditorDialog(surahs: surahs),
    );
    if (result != null) {
      await HifzService.addPlan(result);
      _repsCache.clear();
      await _loadPlansAndStreak();
    }
  }

  Future<void> _deletePlan(String id) async {
    await HifzService.removePlan(id);
    _repsCache.clear();
    await _loadPlansAndStreak();
  }

  @override
  Widget build(BuildContext context) {
    final surah = _selectedSurah;
    return Scaffold(
      appBar: AppBar(
        title: Text(surah == null ? _ht(context, 'وضع الحفظ', 'Hifz Mode') : surah.name),
        centerTitle: true,
        leading: surah != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() {
                _selectedSurah = null;
                _perAyahOverride.clear();
              }))
            : null,
        actions: surah == null
            ? null
            : [
                PopupMenuButton<HifzVisibility>(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: _ht(context, 'وضع الإخفاء', 'Hide mode'),
                  onSelected: (mode) => setState(() {
                    _globalMode = mode;
                    _perAyahOverride.clear();
                  }),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: HifzVisibility.visible, child: Text(_ht(context, 'مرئي', 'Visible'))),
                    PopupMenuItem(value: HifzVisibility.blurred, child: Text(_ht(context, 'مضبّب', 'Blurred'))),
                    PopupMenuItem(value: HifzVisibility.hidden, child: Text(_ht(context, 'مخفي', 'Hidden'))),
                  ],
                ),
              ],
      ),
      body: SafeArea(bottom: true, top: false, child: surah == null ? _buildSurahList() : _buildAyahList(surah)),
    );
  }

  SurahModel? _findSurah(int number) {
    final surahs = _allSurahs;
    if (surahs == null) return null;
    for (final s in surahs) {
      if (s.number == number) return s;
    }
    return null;
  }

  Widget _buildPlansSection() {
    final surahs = _allSurahs;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryEmerald, AppColors.goldAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            _streak > 0
                ? _ht(context, 'سلسلة $_streak يوم', 'Streak: $_streak days')
                : _ht(context, 'ابدأ سلسلتك اليوم', 'Start your streak today'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          TextButton(
            onPressed: surahs == null ? null : _addNewPlan,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(_ht(context, '+ خطة جديدة', '+ New plan')),
          ),
        ]),
        if (_plans.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _ht(context, 'لا توجد خطط حالياً. أضف خطة للبدء -- يمكنك إضافة أكثر من خطة في نفس الوقت.',
                  'No plans yet. Add one to get started -- you can have more than one plan active at the same time.'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          )
        else
          for (final activePlan in _plans)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Expanded(
                  child: Builder(builder: (context) {
                    final s = _findSurah(activePlan.surahNumber);
                    final label = s == null
                        ? _ht(context, 'سورة ${activePlan.surahNumber}', 'Surah ${activePlan.surahNumber}')
                        : '${s.name} (${activePlan.startAyah}-${activePlan.endAyah})';
                    return Text(
                      '$label • ${_ht(context, 'الهدف', 'target')}: ${activePlan.targetReps}×',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }),
                ),
                InkWell(
                  onTap: () => _deletePlan(activePlan.id),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white70, size: 16),
                  ),
                ),
              ]),
            ),
      ]),
    );
  }

  Widget _buildSurahList() {
    final surahs = _allSurahs;
    if (surahs == null) return const Center(child: CircularProgressIndicator());
    return ListView(
      children: [
        _buildPlansSection(),
        ...surahs.map((s) => ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.1),
                child: Text('${s.number}', style: TextStyle(color: AppColors.primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              title: Text(s.name, textDirection: TextDirection.rtl),
              subtitle: Text('${s.ayahs.length} ${_ht(context, 'آية', 'verses')}', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              onTap: () {
                setState(() => _selectedSurah = s);
                _repsCache.clear();
                _loadRepsForSurah(s);
              },
            )),
      ],
    );
  }

  Widget _buildAyahList(SurahModel surah) {
    final activePlan = _planForSurah(surah.number);
    final planActiveHere = activePlan != null;
    return Column(children: [
      Container(
        width: double.infinity,
        color: AppColors.primaryEmerald.withValues(alpha: 0.06),
        padding: const EdgeInsets.all(10),
        child: Text(
          _ht(context, 'اضغط على أي آية لتغيير وضعها (مرئي ← مضبّب ← مخفي)',
              'Tap any verse to cycle its state (visible → blurred → hidden)'),
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          textAlign: TextAlign.center,
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: surah.ayahs.length,
          itemBuilder: (context, index) {
            final ayah = surah.ayahs[index];
            final mode = _modeFor(ayah.number);
            final showReps = planActiveHere && ayah.number >= activePlan.startAyah && ayah.number <= activePlan.endAyah;
            final reps = _repsCache[ayah.number] ?? 0;
            return GestureDetector(
              onTap: () => _cycleAyah(ayah.number),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (mode == HifzVisibility.hidden)
                    Center(
                      child: Icon(Icons.remove_red_eye_outlined, color: Colors.grey.shade400),
                    )
                  else if (mode == HifzVisibility.blurred)
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Text(
                        ayah.text,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 1.9),
                      ),
                    )
                  else
                    Text(
                      ayah.text,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 1.9),
                    ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('آية ${ayah.number}', style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                    if (showReps) ...[
                      const Spacer(),
                      Text('$reps/${activePlan.targetReps}', style: TextStyle(fontSize: 11, color: reps >= activePlan.targetReps ? AppColors.primaryEmerald : AppColors.mutedText, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: reps >= activePlan.targetReps ? null : () => _incrementRep(ayah.number),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            reps >= activePlan.targetReps ? Icons.check_circle : Icons.add_circle_outline,
                            size: 18,
                            color: reps >= activePlan.targetReps ? AppColors.primaryEmerald : AppColors.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _PlanEditorDialog extends StatefulWidget {
  final List<SurahModel> surahs;
  const _PlanEditorDialog({required this.surahs});

  @override
  State<_PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<_PlanEditorDialog> {
  late SurahModel _surah;
  late int _startAyah;
  late int _endAyah;
  late int _targetReps;

  @override
  void initState() {
    super.initState();
    _surah = widget.surahs.first;
    _startAyah = 1;
    _endAyah = _surah.ayahs.isNotEmpty ? _surah.ayahs.first.number : 1;
    _targetReps = 5;
  }

  @override
  Widget build(BuildContext context) {
    final maxAyah = _surah.ayahs.isEmpty ? 1 : _surah.ayahs.last.number;
    return AlertDialog(
      title: Text(_ht(context, 'خطة حفظ جديدة', 'New Hifz Plan')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<SurahModel>(
            initialValue: _surah,
            isExpanded: true,
            items: widget.surahs
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name, textDirection: TextDirection.rtl)))
                .toList(),
            onChanged: (s) {
              if (s == null) return;
              setState(() {
                _surah = s;
                _startAyah = 1;
                _endAyah = s.ayahs.isNotEmpty ? s.ayahs.first.number : 1;
              });
            },
            decoration: InputDecoration(labelText: _ht(context, 'السورة', 'Surah')),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('start_${_surah.number}'),
                initialValue: '$_startAyah',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _ht(context, 'من آية', 'From ayah')),
                onChanged: (v) => _startAyah = int.tryParse(v)?.clamp(1, maxAyah) ?? _startAyah,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                key: ValueKey('end_${_surah.number}'),
                initialValue: '$_endAyah',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _ht(context, 'إلى آية', 'To ayah')),
                onChanged: (v) => _endAyah = int.tryParse(v)?.clamp(1, maxAyah) ?? _endAyah,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: '$_targetReps',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: _ht(context, 'عدد مرات التكرار لكل آية', 'Repeats per ayah')),
            onChanged: (v) => _targetReps = int.tryParse(v)?.clamp(1, 50) ?? _targetReps,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_ht(context, 'إلغاء', 'Cancel'))),
        FilledButton(
          onPressed: () {
            final start = _startAyah <= _endAyah ? _startAyah : _endAyah;
            final end = _startAyah <= _endAyah ? _endAyah : _startAyah;
            Navigator.pop(
              context,
              HifzPlan(
                id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
                surahNumber: _surah.number,
                startAyah: start,
                endAyah: end,
                targetReps: _targetReps,
              ),
            );
          },
          child: Text(_ht(context, 'حفظ', 'Save')),
        ),
      ],
    );
  }
}
