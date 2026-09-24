import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

import '../models/progress_models.dart';

/// Persisted user progress/state shared across screens: favorites,
/// per-item azkar counters (with real daily reset), daily wird tracking,
/// and last-read position. Single source of truth so the Home Dashboard
/// reflects exactly what Quran/Azkar/Tasbeeh screens have recorded.
class UserProgressService {
  UserProgressService._();

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

static String _dayKeyFor(DateTime d) {
    final now = d;
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String dateKeyFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Real per-day activity for the current calendar week, **starting on
  /// Saturday** (the regional week-start convention), through Friday.
  /// Built from the same date-keyed storage already used for Azkar
  /// completion and prayer tracking, plus the date-keyed wird pages and
  /// Tasbeeh daily totals. This is a genuine history log, not a derived
  /// guess — each day's numbers were written on that day. Days later
  /// than today naturally show zero activity (they haven't happened
  /// yet), which is expected.
  static Future<List<DailyActivitySummary>> weekSummary({int weeksAgo = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysSinceSaturday = (today.weekday - 6 + 7) % 7;
    final thisSaturday = today.subtract(Duration(days: daysSinceSaturday));
    final saturday = thisSaturday.subtract(Duration(days: 7 * weeksAgo));

    final results = <DailyActivitySummary>[];

    for (var i = 0; i < 7; i++) {
      final date = saturday.add(Duration(days: i));
      final key = dateKeyFor(date);

      final wirdPages = prefs.getInt('wird_pages_$key') ?? 0;
      final wirdTarget = prefs.getInt('wird_target_pages') ?? 5;
      final azkarCompleted = (prefs.getStringList('azkar_completed_$key') ?? const []).length;
      final tasbeehTotal = prefs.getInt('tasbeeh_daily_total_$key') ?? 0;
      final prayersDone = (prefs.getStringList('prayed_$key') ?? const []).length;

      results.add(DailyActivitySummary(
        date: date,
        wirdPages: wirdPages,
        wirdTargetMet: wirdPages >= wirdTarget,
        azkarCompleted: azkarCompleted,
        tasbeehTotal: tasbeehTotal,
        prayersDone: prayersDone,
      ));
    }

    return results;
  }

  static Future<List<DailyActivitySummary>> last7DaysSummary() => weekSummary(weeksAgo: 0);

  // ---------------- Favorites (Quran ayahs + Azkar items) ----------------

  static Future<Set<String>> _getSet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? const []).toSet();
  }

  static Future<void> _saveSet(String key, Set<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value.toList());
  }

  static Future<Set<String>> favoriteAyahs() => _getSet('favorite_ayahs_all');

  static Future<void> toggleFavoriteAyah(String uid) async {
    final set = await favoriteAyahs();
    if (!set.add(uid)) set.remove(uid);
    await _saveSet('favorite_ayahs_all', set);
  }

  static Future<Set<String>> favoriteAzkar() => _getSet('favorite_azkar_all');

  static Future<void> toggleFavoriteAzkar(String uid) async {
    final set = await favoriteAzkar();
    if (!set.add(uid)) set.remove(uid);
    await _saveSet('favorite_azkar_all', set);
  }

  static Future<Set<String>> favoriteHadiths() => _getSet('favorite_hadiths_all');

  static Future<void> toggleFavoriteHadith(String uid) async {
    final set = await favoriteHadiths();
    if (!set.add(uid)) set.remove(uid);
    await _saveSet('favorite_hadiths_all', set);
  }

  static Future<int> totalFavoritesCount() async {
    final a = await favoriteAyahs();
    final b = await favoriteAzkar();
    final c = await favoriteHadiths();
    return a.length + b.length + c.length;
  }

  // ---------------- Azkar per-item counters (reset daily) ----------------

  static Future<int> azkarCount(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final storedDay = prefs.getString('azkar_count_day_$uid');
    if (storedDay != _todayKey()) return 0;
    return prefs.getInt('azkar_count_$uid') ?? 0;
  }

  static Future<int> incrementAzkarCount(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await azkarCount(uid);
    final next = current + 1;
    await prefs.setInt('azkar_count_$uid', next);
    await prefs.setString('azkar_count_day_$uid', _todayKey());
    return next;
  }

  /// Writes a known count directly (no read-then-increment round trip).
  /// Used when the caller has already computed the new value locally
  /// for an instant UI update, and just needs it persisted in the
  /// background.
  static Future<void> setAzkarCount(String uid, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('azkar_count_$uid', value);
    await prefs.setString('azkar_count_day_$uid', _todayKey());
  }

  static Future<void> resetAzkarCount(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('azkar_count_$uid', 0);
    await prefs.setString('azkar_count_day_$uid', _todayKey());
  }

  static Future<Set<String>> completedAzkarToday() =>
      _getSet('azkar_completed_${_todayKey()}');

  static Future<void> markAzkarCompleted(String uid) async {
    final set = await completedAzkarToday();
    final isNew = set.add(uid);
    await _saveSet('azkar_completed_${_todayKey()}', set);
    if (isNew) {
      final prefs = await SharedPreferences.getInstance();
      final total = (prefs.getInt('azkar_lifetime_total') ?? 0) + 1;
      await prefs.setInt('azkar_lifetime_total', total);
    }
  }

  static Future<int> lifetimeAzkarTotal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('azkar_lifetime_total') ?? 0;
  }

  // ---------------- Last read (Quran) ----------------

  static Future<void> saveLastReading({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_surah_number', surahNumber);
    await prefs.setString('last_surah_name', surahName);
    await prefs.setInt('last_ayah_number', ayahNumber);
  }

  static Future<Map<String, dynamic>?> lastReading() async {
    final prefs = await SharedPreferences.getInstance();
    final number = prefs.getInt('last_surah_number');
    if (number == null) return null;
    return {
      'surahNumber': number,
      'surahName': prefs.getString('last_surah_name') ?? '',
      'ayahNumber': prefs.getInt('last_ayah_number') ?? 1,
    };
  }

  // ---------------- Tasbeeh combined daily total (for 7-day history) ----------------

  static Future<int> incrementTasbeehDailyTotal() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tasbeeh_daily_total_${_todayKey()}';
    final next = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, next);
    final lifetimeTotal = (prefs.getInt('tasbeeh_lifetime_total') ?? 0) + 1;
    await prefs.setInt('tasbeeh_lifetime_total', lifetimeTotal);
    return next;
  }

  /// Returns the TRUE lifetime tasbeeh total across ALL phrases.
  /// Tasbeeh screen stores per-phrase totals as: tasbeeh_total_{phraseId}
  static Future<int> lifetimeTasbeehTotal() async {
    final prefs = await SharedPreferences.getInstance();
    int total = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('tasbeeh_total_')) {
        total += prefs.getInt(key) ?? 0;
      }
    }
    return total;
  }

  static Future<int> tasbeehTotalToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('tasbeeh_daily_total_${_todayKey()}') ?? 0;
  }

  // ---------------- Prayer completion (mark as prayed) ----------------

  static Future<Set<String>> prayedToday() => _getSet('prayed_${_todayKey()}');

  static Future<void> setPrayed(String prayerName, bool prayed) async {
    final set = await prayedToday();
    final wasAlreadyPrayed = set.contains(prayerName);
    if (prayed) {
      set.add(prayerName);
    } else {
      set.remove(prayerName);
    }
    await _saveSet('prayed_${_todayKey()}', set);
    if (prayed && !wasAlreadyPrayed) {
      final prefs = await SharedPreferences.getInstance();
      final total = (prefs.getInt('prayers_lifetime_total') ?? 0) + 1;
      await prefs.setInt('prayers_lifetime_total', total);
    }
  }

  static Future<int> lifetimePrayersTotal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('prayers_lifetime_total') ?? 0;
  }

  // ---------------- Fasting tracking (Ramadan / voluntary fasts) ----------------

  static Future<bool> isFastingToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('fasting_${_todayKey()}') ?? false;
  }

  static Future<bool> isFastingOn(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('fasting_$dateKey') ?? false;
  }

  static Future<void> setFastingToday(bool fasted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fasting_${_todayKey()}', fasted);
  }

  /// Count of fasting days logged within the given inclusive date range
  /// (e.g. the current Hijri month) — used for a simple Ramadan progress
  /// count without needing a separate history table.
  static Future<int> fastingDaysInRange(DateTime start, DateTime end) async {
    final prefs = await SharedPreferences.getInstance();
    var count = 0;
    var d = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(last)) {
      if (prefs.getBool('fasting_${dateKeyFor(d)}') ?? false) count++;
      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  // -------------- Taraweeh tracking (Ramadan night prayers) --------------

  static Future<bool> isTaraweehToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('taraweeh_${_todayKey()}') ?? false;
  }

  static Future<void> setTaraweehToday(bool prayed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('taraweeh_${_todayKey()}', prayed);
  }

  static Future<int> taraweehDaysInRange(DateTime start, DateTime end) async {
    final prefs = await SharedPreferences.getInstance();
    var count = 0;
    var d = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(last)) {
      if (prefs.getBool('taraweeh_${dateKeyFor(d)}') ?? false) count++;
      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  static Future<bool> duaReadToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dua_read_${_todayKey()}') ?? false;
  }

  static Future<void> setDuaReadToday(bool read) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dua_read_${_todayKey()}', read);
  }

  // ---------------- Quran completion (khatma progress) ----------------

  static const int totalSurahsInQuran = 114;

  static Future<Set<int>> completedSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('completed_surahs_all') ?? const [];
    return list.map(int.parse).toSet();
  }

  static Future<void> markSurahCompleted(int surahNumber) async {
    final set = await completedSurahs();
    if (set.add(surahNumber)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('completed_surahs_all', set.map((e) => e.toString()).toList());
    }
  }

  /// 0.0-1.0 fraction of the 114 surahs marked completed. This is a
  /// surah-level approximation of khatma progress (not page-accurate,
  /// since the underlying Quran data source doesn't carry mushaf page
  /// numbers) but is real, persisted progress — not a placeholder.
    static const List<int> _ayahCountBySurah = [7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6];

  static Future<double> quranCompletionRatio() async {
    final completed = await completedSurahs();
    var completedAyahs = 0;
    for (final surahNumber in completed) {
      if (surahNumber >= 1 && surahNumber <= 114) {
        completedAyahs += _ayahCountBySurah[surahNumber - 1];
      }
    }
    const totalAyahsInQuran = 6236;
    return completedAyahs / totalAyahsInQuran;
  }

  /// Resets khatma progress (e.g. after finishing a full reading and
  /// wanting to start a new one), independent of favorites/settings.
  static Future<void> resetKhatmaProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('completed_surahs_all');
  }

  static Future<int> khatmasCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('khatmas_completed_count') ?? 0;
  }

  static Future<void> recordKhatmaCompletionIfNeeded(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final counted = (prefs.getStringList('khatmas_completed_ids') ?? const []).toSet();
    if (counted.contains(planId)) return;
    counted.add(planId);
    await prefs.setStringList('khatmas_completed_ids', counted.toList());
    final count = (prefs.getInt('khatmas_completed_count') ?? 0) + 1;
    await prefs.setInt('khatmas_completed_count', count);
  }

  // ---------------- Daily Wird (pages) ----------------

  static Future<int> dailyWirdTarget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('wird_target_pages') ?? 5;
  }

  static Future<void> setDailyWirdTarget(int pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wird_target_pages', pages);
  }

  static Future<int> pagesReadToday() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDay = prefs.getString('wird_progress_day');
    if (storedDay != _todayKey()) return 0;
    return prefs.getInt('wird_progress_pages') ?? 0;
  }

  static Future<int> markPageRead() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await pagesReadToday();
    final next = current + 1;
    await prefs.setInt('wird_progress_pages', next);
    await prefs.setString('wird_progress_day', _todayKey());
    await prefs.setInt('wird_pages_${_todayKey()}', next);
    final lifetimeTotal = (prefs.getInt('wird_lifetime_pages_total') ?? 0) + 1;
    await prefs.setInt('wird_lifetime_pages_total', lifetimeTotal);
    return next;
  }

  static Future<int> lifetimePagesTotal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('wird_lifetime_pages_total') ?? 0;
  }

  static Future<int> pagesReadOn(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('wird_pages_$dateKey') ?? 0;
  }

  /// Current daily streak: counts consecutive days (ending today or
  /// yesterday) where the wird target was met. Stored as a simple
  /// incrementing counter updated whenever a day's target is completed.
  static Future<int> wirdStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('wird_streak') ?? 0;
  }

  static Future<void> _grantMonthlyStreakFreezeIfDue(SharedPreferences prefs) async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final lastGrantMonth = prefs.getString('wird_streak_freeze_last_grant_month');
    if (lastGrantMonth == monthKey) return;
    final current = prefs.getInt('wird_streak_freezes_available') ?? 0;
    final next = current + 1 > 2 ? 2 : current + 1;
    await prefs.setInt('wird_streak_freezes_available', next);
    await prefs.setString('wird_streak_freeze_last_grant_month', monthKey);
  }

  static Future<int> wirdStreakFreezesAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    await _grantMonthlyStreakFreezeIfDue(prefs);
    return prefs.getInt('wird_streak_freezes_available') ?? 0;
  }

  static Future<void> registerStreakCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompletedDay = prefs.getString('wird_streak_last_day');
    final target = await dailyWirdTarget();
    final progress = await pagesReadToday();

    if (progress < target) return;
    if (lastCompletedDay == _todayKey()) return; // already counted today

    await _grantMonthlyStreakFreezeIfDue(prefs);
    final yesterdayKey = _dayKeyFor(DateTime.now().subtract(const Duration(days: 1)));
    final twoDaysAgoKey = _dayKeyFor(DateTime.now().subtract(const Duration(days: 2)));
    final currentStreak = prefs.getInt('wird_streak') ?? 0;
    final freezesAvailable = prefs.getInt('wird_streak_freezes_available') ?? 0;

    int newStreak;
    if (lastCompletedDay == yesterdayKey) {
      newStreak = currentStreak + 1;
    } else if (lastCompletedDay == twoDaysAgoKey && freezesAvailable > 0) {
      await prefs.setInt('wird_streak_freezes_available', freezesAvailable - 1);
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }
    await prefs.setInt('wird_streak', newStreak);
    await prefs.setString('wird_streak_last_day', _todayKey());

    final longest = prefs.getInt('wird_longest_streak') ?? 0;
    if (newStreak > longest) {
      await prefs.setInt('wird_longest_streak', newStreak);
    }
  }

  static Future<int> longestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final longest = prefs.getInt('wird_longest_streak') ?? 0;
    final current = prefs.getInt('wird_streak') ?? 0;
    return longest > current ? longest : current;
  }

  // ---------------- Local data management ----------------

  static Future<void> clearAllLocalData() async {
    try {
      await NotificationService.cancelAllScheduled();
      await NotificationService.cancelAllRecurring();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
