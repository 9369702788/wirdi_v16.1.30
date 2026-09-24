import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HifzPlan {
  final String id;
  final int surahNumber;
  final int startAyah;
  final int endAyah;
  final int targetReps;

  const HifzPlan({
    required this.id,
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
    required this.targetReps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'surahNumber': surahNumber,
        'startAyah': startAyah,
        'endAyah': endAyah,
        'targetReps': targetReps,
      };

  factory HifzPlan.fromJson(Map<String, dynamic> json) => HifzPlan(
        id: json['id'] as String,
        surahNumber: json['surahNumber'] as int,
        startAyah: json['startAyah'] as int,
        endAyah: json['endAyah'] as int,
        targetReps: json['targetReps'] as int,
      );
}

/// Persists Hifz (memorization) progress: how many times each ayah has
/// been repeated TODAY per plan, the user's active daily plans (each a
/// surah + ayah range + target repeats per ayah -- now a LIST, so more
/// than one surah can be memorized at the same time), and a simple
/// day-streak counter that advances when at least one plan is fully
/// completed each day.
class HifzService {
  HifzService._();

  static const List<int> _leitnerIntervalsDays = [1, 3, 7, 16, 35];

  static const _planKey = 'hifz_plan_v1'; // legacy single-plan keys, migration-only
  static const _plansListKey = 'hifz_plans_v2';
  static const _repsPrefix = 'hifz_reps_v2_';
  static const _streakKey = 'hifz_streak_v1';
  static const _lastCompletedDateKey = 'hifz_last_completed_date_v1';
  static const _revisionKey = 'hifz_revision_portions_v1';

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _repKey(String planId, int surahNumber, int ayahNumber) =>
      '$_repsPrefix${planId}_${surahNumber}_${ayahNumber}_${_todayKey()}';

  static Future<int> getTodayReps(String planId, int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_repKey(planId, surahNumber, ayahNumber)) ?? 0;
  }

  static Future<int> incrementReps(String planId, int surahNumber, int ayahNumber, int cap) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _repKey(planId, surahNumber, ayahNumber);
    final current = prefs.getInt(key) ?? 0;
    final next = current >= cap ? current : current + 1;
    await prefs.setInt(key, next);
    return next;
  }

  static Future<HifzPlan?> _getLegacyPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final surahNumber = prefs.getInt('${_planKey}_surah');
    final startAyah = prefs.getInt('${_planKey}_start');
    final endAyah = prefs.getInt('${_planKey}_end');
    final targetReps = prefs.getInt('${_planKey}_target');
    if (surahNumber == null || startAyah == null || endAyah == null || targetReps == null) {
      return null;
    }
    return HifzPlan(id: 'plan_migrated_v1', surahNumber: surahNumber, startAyah: startAyah, endAyah: endAyah, targetReps: targetReps);
  }

  static Future<void> _clearLegacyPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_planKey}_surah');
    await prefs.remove('${_planKey}_start');
    await prefs.remove('${_planKey}_end');
    await prefs.remove('${_planKey}_target');
  }

  static Future<void> _savePlans(List<HifzPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_plansListKey, plans.map((p) => jsonEncode(p.toJson())).toList());
  }

  static Future<List<HifzPlan>> getAllPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_plansListKey);
    if (raw != null) {
      return raw.map((e) => HifzPlan.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    }
    final legacy = await _getLegacyPlan();
    if (legacy != null) {
      await _savePlans([legacy]);
      await _clearLegacyPlan();
      return [legacy];
    }
    await _savePlans(const []);
    return [];
  }

  static Future<void> addPlan(HifzPlan plan) async {
    final plans = await getAllPlans();
    plans.add(plan);
    await _savePlans(plans);
  }

  static Future<void> removePlan(String id) async {
    final plans = await getAllPlans();
    plans.removeWhere((p) => p.id == id);
    await _savePlans(plans);
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  static const _planCompletedPrefix = 'hifz_plan_completed_';

  static Future<({int streak, bool planCompletedNow})> checkAndUpdateStreakIfPlanCompleted(HifzPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _todayKey();

    for (var a = plan.startAyah; a <= plan.endAyah; a++) {
      final reps = await getTodayReps(plan.id, plan.surahNumber, a);
      if (reps < plan.targetReps) {
        return (streak: prefs.getInt(_streakKey) ?? 0, planCompletedNow: false);
      }
    }

    final planDoneKey = '$_planCompletedPrefix${plan.id}_$todayStr';
    if (prefs.getBool(planDoneKey) ?? false) {
      return (streak: prefs.getInt(_streakKey) ?? 0, planCompletedNow: false);
    }
    await prefs.setBool(planDoneKey, true);

    final lastCompleted = prefs.getString(_lastCompletedDateKey);
    if (lastCompleted == todayStr) {
      return (streak: prefs.getInt(_streakKey) ?? 0, planCompletedNow: true);
    }

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final twoDaysAgoStr =
        '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}';
    final currentStreak = prefs.getInt(_streakKey) ?? 0;
    await _grantMonthlyStreakFreezeIfDue(prefs);
    final freezesAvailable = prefs.getInt(_freezesKey) ?? 0;

    int newStreak;
    if (lastCompleted == yesterdayStr) {
      newStreak = currentStreak + 1;
    } else if (lastCompleted == twoDaysAgoStr && freezesAvailable > 0) {
      await prefs.setInt(_freezesKey, freezesAvailable - 1);
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }
    await prefs.setInt(_streakKey, newStreak);
    await prefs.setString(_lastCompletedDateKey, todayStr);
    return (streak: newStreak, planCompletedNow: true);
  }

  static const _freezesKey = 'hifz_streak_freezes_available';
  static const _freezeLastGrantMonthKey = 'hifz_streak_freeze_last_grant_month';

  static Future<void> _grantMonthlyStreakFreezeIfDue(SharedPreferences prefs) async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final lastGrantMonth = prefs.getString(_freezeLastGrantMonthKey);
    if (lastGrantMonth == monthKey) return;
    final current = prefs.getInt(_freezesKey) ?? 0;
    final next = current + 1 > 2 ? 2 : current + 1;
    await prefs.setInt(_freezesKey, next);
    await prefs.setString(_freezeLastGrantMonthKey, monthKey);
  }

  static Future<int> streakFreezesAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    await _grantMonthlyStreakFreezeIfDue(prefs);
    return prefs.getInt(_freezesKey) ?? 0;
  }

  static Future<List<Map<String, dynamic>>> _loadRevisionPortions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_revisionKey) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> _saveRevisionPortions(List<Map<String, dynamic>> portions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_revisionKey, portions.map((p) => jsonEncode(p)).toList());
  }

  static Future<void> markPortionMemorized(int surahNumber, int startAyah, int endAyah) async {
    final portions = await _loadRevisionPortions();
    final id = '${surahNumber}_${startAyah}_$endAyah';
    portions.removeWhere((p) => p['id'] == id);
    portions.add({
      'id': id,
      'surah': surahNumber,
      'start': startAyah,
      'end': endAyah,
      'lastRevisedAt': DateTime.now().toIso8601String(),
      'box': 1,
    });
    await _saveRevisionPortions(portions);
  }

  static Future<void> markPortionRevised(String id) async {
    final portions = await _loadRevisionPortions();
    for (final p in portions) {
      if (p['id'] == id) {
        p['lastRevisedAt'] = DateTime.now().toIso8601String();
        final currentBox = (p['box'] as int?) ?? 1;
        p['box'] = currentBox >= _leitnerIntervalsDays.length ? _leitnerIntervalsDays.length : currentBox + 1;
      }
    }
    await _saveRevisionPortions(portions);
  }

  static Future<void> markPortionForgot(String id) async {
    final portions = await _loadRevisionPortions();
    for (final p in portions) {
      if (p['id'] == id) {
        p['lastRevisedAt'] = DateTime.now().toIso8601String();
        p['box'] = 1;
      }
    }
    await _saveRevisionPortions(portions);
  }

  static Future<List<Map<String, dynamic>>> getPortionsDueForRevision({int intervalDays = 7}) async {
    final portions = await _loadRevisionPortions();
    final now = DateTime.now();
    return portions.where((p) {
      final last = DateTime.parse(p['lastRevisedAt'] as String);
      final box = (p['box'] as int?) ?? 1;
      final clampedBox = box < 1 ? 1 : (box > _leitnerIntervalsDays.length ? _leitnerIntervalsDays.length : box);
      final requiredInterval = _leitnerIntervalsDays[clampedBox - 1];
      return now.difference(last).inDays >= requiredInterval;
    }).toList();
  }

  static Future<int> totalMemorizedPortions() async {
    final portions = await _loadRevisionPortions();
    return portions.length;
  }
}
