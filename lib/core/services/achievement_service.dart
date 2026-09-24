import 'hifz_service.dart';
import 'sajda_tracker_service.dart';
import 'user_progress_service.dart';

class AchievementStats {
  final int longestStreak;
  final double quranRatio;
  final int khatmasCompleted;
  final int lifetimePages;
  final int lifetimeAzkar;
  final int lifetimeTasbeeh;
  final int lifetimePrayers;
  final int favoritesCount;
  final int lifetimeSajdaCount;
  final int wirdStreakFreezes;
  final int hifzStreakFreezes;

  const AchievementStats({
    required this.longestStreak,
    required this.quranRatio,
    required this.khatmasCompleted,
    required this.lifetimePages,
    required this.lifetimeAzkar,
    required this.lifetimeTasbeeh,
    required this.lifetimePrayers,
    required this.favoritesCount,
    required this.lifetimeSajdaCount,
    required this.wirdStreakFreezes,
    required this.hifzStreakFreezes,
  });

  static Future<AchievementStats> load() async {
    final longest = await UserProgressService.longestStreak();
    final ratio = await UserProgressService.quranCompletionRatio();
    final khatmas = await UserProgressService.khatmasCompletedCount();
    final pages = await UserProgressService.lifetimePagesTotal();
    final azkar = await UserProgressService.lifetimeAzkarTotal();
    final tasbeeh = await UserProgressService.lifetimeTasbeehTotal();
    final prayers = await UserProgressService.lifetimePrayersTotal();
    final favorites = await UserProgressService.totalFavoritesCount();
    final sajdaCount = await SajdaTrackerService.totalCount();
    final wirdFreezes = await UserProgressService.wirdStreakFreezesAvailable();
    final hifzFreezes = await HifzService.streakFreezesAvailable();
    return AchievementStats(
      longestStreak: longest,
      quranRatio: ratio,
      khatmasCompleted: khatmas,
      lifetimePages: pages,
      lifetimeAzkar: azkar,
      lifetimeTasbeeh: tasbeeh,
      lifetimePrayers: prayers,
      favoritesCount: favorites,
      lifetimeSajdaCount: sajdaCount,
      wirdStreakFreezes: wirdFreezes,
      hifzStreakFreezes: hifzFreezes,
    );
  }
}
