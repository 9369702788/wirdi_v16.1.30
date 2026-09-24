import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import '../../core/models/khatma_models.dart';
import '../../core/services/khatma_service.dart';
import 'khatma_calendar_screen.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../quran/quran_screen.dart';

class KhatmaTrackerScreen extends StatefulWidget {
  const KhatmaTrackerScreen({super.key});

  @override
  State<KhatmaTrackerScreen> createState() => _KhatmaTrackerScreenState();
}

class _KhatmaTrackerScreenState extends State<KhatmaTrackerScreen> {
  static const int _totalSurahs = UserProgressService.totalSurahsInQuran;

  void _shareProgress(AppLocalizations l10n) {
    final completedCount = _globalCompleted.length;
    final percent = _totalSurahs == 0 ? 0 : ((completedCount / _totalSurahs) * 100).round();
    final isAr = l10n.localeName == 'ar';
    final text = isAr
        ? '\u0623\u0646\u0627 \u062e\u0644\u0651\u0635\u062a $completedCount \u0645\u0646 $_totalSurahs \u0633\u0648\u0631\u0629 \u0641\u064a \u062e\u062a\u0645\u062a\u064a ($percent%) \u{1F4D6}\u2728\n\u0648\u0631\u062f\u064a'
        : "I've completed $completedCount of $_totalSurahs surahs in my Khatma ($percent%) \u{1F4D6}\u2728\nWirdi app";
    Share.share(text);
  }

  List<KhatmaPlan> _plans = [];
  Set<int> _globalCompleted = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await KhatmaService.allPlans();
    final completed = await UserProgressService.completedSurahs();
    for (final plan in plans) {
      if (plan.newlyCompletedCount(completed) >= _totalSurahs) {
        await UserProgressService.recordKhatmaCompletionIfNeeded(plan.id);
      }
    }
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _globalCompleted = completed;
      _loading = false;
    });
  }

  Future<void> _createPlan(int days, String label) async {
    final target = DateTime.now().add(Duration(days: days));
    await KhatmaService.createPlan(label: label, targetDate: target);
    await _load();
  }

  Future<void> _createPlanCustomDate(DateTime target, String label) async {
    await KhatmaService.createPlan(label: label, targetDate: target);
    await _load();
  }

  Future<void> _showNewPlanSheet() async {
    final l10n = AppLocalizations.of(context);
    final labelController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + MediaQuery.of(sheetContext).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.khatmaStartNewPlan, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  hintText: l10n.khatmaPlanLabelHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.khatmaChooseDuration, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _DurationChip(
                    label: l10n.khatmaDuration7Days,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _createPlan(7, labelController.text.trim());
                    },
                  ),
                  _DurationChip(
                    label: l10n.khatmaDuration30Days,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _createPlan(30, labelController.text.trim());
                    },
                  ),
                  _DurationChip(
                    label: l10n.khatmaDuration60Days,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _createPlan(60, labelController.text.trim());
                    },
                  ),
                  _DurationChip(
                    label: l10n.khatmaDuration90Days,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _createPlan(90, labelController.text.trim());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: now.add(const Duration(days: 30)),
                    firstDate: now.add(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 3650)),
                    helpText: l10n.khatmaChooseDuration,
                  );
                  if (picked == null) return;
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  await _createPlanCustomDate(picked, labelController.text.trim());
                },
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(l10n.khatmaCustomDate),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(KhatmaPlan plan) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.khatmaDeletePlanTitle),
        content: Text(l10n.khatmaDeletePlanBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.khatmaDeletePlanConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    await KhatmaService.deletePlan(plan.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.khatmaMyPlans),
        centerTitle: true,
        actions: [
          if (!_loading && _plans.isNotEmpty)
            IconButton(
              tooltip: l10n.localeName == 'ar' ? '\u0645\u0634\u0627\u0631\u0643\u0629 \u0627\u0644\u062a\u0642\u062f\u0645' : 'Share progress',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareProgress(l10n),
            ),
          IconButton(
            tooltip: l10n.khatmaCalendarTooltip,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KhatmaCalendarScreen())),
          ),
        ],
      ),
      floatingActionButton: (_loading || _plans.isEmpty)
          ? null
          : FloatingActionButton.extended(
              onPressed: _showNewPlanSheet,
              icon: const Icon(Icons.add),
              label: Text(l10n.khatmaAddAnother),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? _buildEmptyState(context, l10n)
              : _buildPlansList(context, l10n),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return ListView(padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
      children: [
        const SizedBox(height: 12),
        Icon(Icons.menu_book_outlined, size: 64, color: AppColors.primaryEmerald),
        const SizedBox(height: 16),
        Text(
          l10n.khatmaNoPlanTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.khatmaNoPlanBody,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.mutedText),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: _showNewPlanSheet,
            icon: const Icon(Icons.add),
            label: Text(l10n.khatmaStartNewPlan),
          ),
        ),
      ],
    );
  }

  Widget _buildPlansList(BuildContext context, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return _KhatmaPlanCard(
            plan: plan,
            index: index,
            globalCompleted: _globalCompleted,
            totalSurahs: _totalSurahs,
            onDelete: () => _confirmDelete(plan),
          );
        },
      ),
    );
  }
}

class _KhatmaPlanCard extends StatelessWidget {
  final KhatmaPlan plan;
  final int index;
  final Set<int> globalCompleted;
  final int totalSurahs;
  final VoidCallback onDelete;

  const _KhatmaPlanCard({
    required this.plan,
    required this.index,
    required this.globalCompleted,
    required this.totalSurahs,
    required this.onDelete,
  });

  // Standard ayah count per surah (1-114), used only to give a much more
  // meaningful progress breakdown than raw surah count -- a completed
  // Al-Ikhlas (4 ayahs) is not equivalent to a completed Al-Baqarah (286
  // ayahs), which was the exact complaint that led to this.
  static const List<int> _ayahCounts = [7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6];
  static const int _totalAyahs = 6236;
  static const int _totalPages = 604; // standard Madani mushaf page count
  static const int _totalJuz = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rawCompleted = plan.newlyCompletedCount(globalCompleted);
    final completedCount = rawCompleted > totalSurahs ? totalSurahs : rawCompleted;
    final ratio = totalSurahs == 0 ? 0.0 : (completedCount / totalSurahs).clamp(0.0, 1.0);

    // Weighted by actual ayah count, not just surah count.
    var ayahsCompleted = 0;
    for (final surahNumber in globalCompleted) {
      if (surahNumber >= 1 && surahNumber <= _ayahCounts.length) {
        ayahsCompleted += _ayahCounts[surahNumber - 1];
      }
    }
    final ayahRatio = (ayahsCompleted / _totalAyahs).clamp(0.0, 1.0);
    final pagesCompletedEstimate = (ayahRatio * _totalPages).round();
    final juzCompletedEstimate = (ayahRatio * _totalJuz).round();

    final expectedByNow = plan.totalDays == 0 ? 0 : ((totalSurahs * plan.daysElapsed) / plan.totalDays).round();
    final behindByRaw = expectedByNow - completedCount;
    final behindBy = behindByRaw > 0 ? behindByRaw : 0;

    final remainingRaw = totalSurahs - completedCount;
    final remaining = remainingRaw > 0 ? remainingRaw : 0;

    final isComplete = completedCount >= totalSurahs;
    final onTrack = behindBy == 0;
    final newPace = plan.daysRemaining == 0 ? remaining : (remaining / plan.daysRemaining).ceil();

    final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
    final label = plan.label.trim().isEmpty ? l10n.khatmaDefaultPlanLabel(index + 1) : plan.label.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(
                  tooltip: l10n.commonDeleteTooltip,
                  icon: const Icon(Icons.delete_outline, color: AppColors.mutedText),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 6,
                        backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(isComplete ? AppColors.goldAccent : AppColors.primaryEmerald),
                      ),
                      Text('${(ratio * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.khatmaProgressLabel(completedCount, totalSurahs), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? '~$pagesCompletedEstimate/$_totalPages صفحة  •  ~$juzCompletedEstimate/$_totalJuz جزء  •  $ayahsCompleted/$_totalAyahs آية'
                            : '~$pagesCompletedEstimate/$_totalPages pages  •  ~$juzCompletedEstimate/$_totalJuz juz  •  $ayahsCompleted/$_totalAyahs ayahs',
                        style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.khatmaTargetDate}: ${dateFormat.format(plan.targetDate)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isComplete)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.khatmaCompletedCelebration,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: onTrack ? AppColors.primaryEmerald.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      onTrack ? Icons.check_circle_outline : Icons.timer_outlined,
                      color: onTrack ? AppColors.primaryEmerald : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            onTrack ? l10n.khatmaOnTrack : l10n.khatmaBehindByCount(behindBy),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            onTrack ? l10n.khatmaPaceNeeded(newPace) : l10n.khatmaNewPaceLabel(newPace),
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen())),
                icon: const Icon(Icons.menu_book, size: 18),
                label: Text(l10n.khatmaContinueReading),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DurationChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.08),
    );
  }
}
