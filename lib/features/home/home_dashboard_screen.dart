import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/verse_of_the_day_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/models/hadith_models.dart';
import '../../core/services/hadith_repository.dart';
import '../hadith/hadith_collection_screen.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/data/daily_quotes.dart';
import '../../core/models/prayer_models.dart';
import '../../core/models/progress_models.dart';
import '../../core/services/hijri_date.dart';
import '../../core/services/moon_calculator.dart';
import '../../core/services/prayer_display.dart';
import '../../core/services/weather_service.dart';
import '../../core/services/sunrise_sunset_calculator.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/widget_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/wirdi_identity_background.dart';
import '../../l10n/generated/app_localizations.dart';
import '../azkar/azkar_screen.dart';
import '../favorites/favorites_screen.dart';
import '../insights/wirdi_insights_screen.dart';
import '../khatma/khatma_tracker_screen.dart';
import '../prayer/prayer_times_screen.dart';
import '../qibla/qibla_screen.dart';
import '../quran/quran_screen.dart';
import '../ramadan/ramadan_companion_screen.dart';
import '../settings/settings_screen.dart';
import '../tasbeeh/tasbeeh_screen.dart';
import '../tools/islamic_tools_screen.dart';
import '../wird/my_wirdi_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  PrayerTimesResult? _prayer;
  bool _prayerFailed = false;
  Timer? _timer;
  // v1.55: only this Text rebuilds every second (was: the whole 1,000-line screen,
  // even while another tab was showing, since every tab stays alive in RootShell).
  final ValueNotifier<String> _countdown = ValueNotifier<String>('--:--:--');
  bool? _autoDarkAppliedState;

  Map<String, dynamic>? _lastReading;
  int _favoritesCount = 0;
  int _pagesToday = 0;
  int _wirdTarget = 5;
  int _prayedCount = 0;
  int _streak = 0;
  double _khatmaRatio = 0.0;
  double _myWirdiPercent = 0.0;
  List<DailyActivitySummary> _weekSummary = [];
  HadithModel? _hadithOfToday;
  int _hadithStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    super.dispose();
  }

  Future<int> _updateHadithStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastDate = prefs.getString('last_hadith_view_date');
    var streak = prefs.getInt('hadith_streak') ?? 0;
    if (lastDate == todayKey) {
      return streak;
    }
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    streak = (lastDate == yesterdayKey) ? streak + 1 : 1;
    await prefs.setString('last_hadith_view_date', todayKey);
    await prefs.setInt('hadith_streak', streak);
    return streak;
  }

  Future<void> _loadAll() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    unawaited(_loadPrayer());

    var lastReading = await UserProgressService.lastReading();
    if (lastReading != null && (lastReading['surahName'] as String? ?? '').trim().isEmpty) {
      try {
        final surahs = await QuranRepository.load();
        final number = lastReading['surahNumber'] as int?;
        if (number != null) {
          final match = surahs.firstWhere((s) => s.number == number, orElse: () => surahs.first);
          lastReading = {...lastReading, 'surahName': match.name};
          await UserProgressService.saveLastReading(
            surahNumber: number,
            surahName: match.name,
            ayahNumber: lastReading['ayahNumber'] as int? ?? 1,
          );
        }
      } catch (_) {}
    }
    final favCount = await UserProgressService.totalFavoritesCount();
    final pagesToday = await UserProgressService.pagesReadToday();
    final target = await UserProgressService.dailyWirdTarget();
    final streak = await UserProgressService.wirdStreak();
    final khatmaRatio = await UserProgressService.quranCompletionRatio();
    final weekSummary = await UserProgressService.last7DaysSummary();
    final hadith = await HadithRepository.forToday(languageCode);
    final hadithStreak = await _updateHadithStreak();
    final myWirdi = await MyWirdiStats.load();
    final prayed = await UserProgressService.prayedToday();

    if (!mounted) return;
    setState(() {
      _lastReading = lastReading;
      _favoritesCount = favCount;
      _pagesToday = pagesToday;
      _wirdTarget = target;
      _streak = streak;
      _khatmaRatio = khatmaRatio;
      _weekSummary = weekSummary;
      _hadithOfToday = hadith;
      _hadithStreak = hadithStreak;
      _myWirdiPercent = myWirdi.overallPercent;
      _prayedCount = prayed.length;
    });
    unawaited(WidgetService.updateHadith(hadith));
    unawaited(WidgetService.updateProgress(pagesToday, target, khatmaRatio));
  }

  Future<void> _loadPrayer() async {
    try {
      final result = await PrayerService.fetchUsingSavedPreference();
      if (!mounted) return;
      setState(() {
        _prayer = result;
        _prayerFailed = false;
      });
      unawaited(WidgetService.updatePrayerTimes(result.prayers, result.next));
      _startCountdown();
      unawaited(PrayerNotificationScheduler.rescheduleFromResult(context, result));
      unawaited(_loadWeatherAndSun());
    } catch (_) {
      if (!mounted) return;
      setState(() => _prayerFailed = true);
    }
  }

  WeatherData? _weather;
  SunTimes? _sunTimes;

  Future<void> _loadWeatherAndSun() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 10));
      final sun = SunriseSunsetCalculator.calculate(position.latitude, position.longitude, DateTime.now());
      if (mounted) setState(() => _sunTimes = sun);
    } catch (_) {
      // no-op -- sunrise/sunset row just won't show
    }
    try {
      final weather = await WeatherService.getWeatherAtPrayerTime('now');
      if (mounted) setState(() => _weather = weather);
    } catch (_) {
      // no-op -- weather row just won't show
    }
  }

  String _fmtSunTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _startCountdown() {
    _timer?.cancel();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  /// ROOT CAUSE FIX: this used to call [_loadPrayer] the INSTANT the
  /// visible countdown reached zero -- i.e. exactly when a prayer time
  /// arrives. [_loadPrayer] re-fetches prayer times and reschedules
  /// ALL prayer notifications via
  /// PrayerNotificationScheduler.rescheduleFromResult ->
  /// NotificationService.scheduleAll(), which starts by CANCELLING
  /// every currently-scheduled notification before re-adding them.
  /// With the home dashboard open right as a prayer time arrives
  /// (exactly when its own countdown reaches zero -- an extremely
  /// common case, not an edge case), this raced against and CANCELLED
  /// the "at prayer time" notification (the one with the real Adhan
  /// sound) at the exact moment it was due to fire. By the time the
  /// freshly recomputed schedule ran a moment later, that prayer's
  /// time was already in the past, so scheduleAll()'s "never schedule
  /// something already in the past" guard silently dropped it
  /// forever -- it never got a second chance to fire. The earlier
  /// "X minutes before" reminder was unaffected because it had
  /// already fired well before this race could occur -- exactly the
  /// reported symptom: the early reminder works, the real Adhan
  /// notification at the actual prayer time does not.
  ///
  /// Fix: advance to the next prayer already present in TODAY's
  /// already-fetched list -- a purely local state update with no
  /// network call and no reschedule, so nothing can race the
  /// notifications already correctly scheduled for the rest of the
  /// day. Only fall back to a real [_loadPrayer] (now safe to
  /// reschedule against, since it only runs once per day when today's
  /// list is exhausted) once every prayer in today's list has passed.
  void _updateCountdown() {
    final prayer = _prayer;
    if (prayer == null) return;
    _applyAutoDarkModeIfEnabled(prayer);
    final diff = prayer.next.dateTime.difference(DateTime.now());
    if (diff.isNegative) {
      final upcoming = prayer.prayers.where((p) => p.dateTime.isAfter(DateTime.now())).toList();
      if (upcoming.isNotEmpty) {
        final updated = PrayerTimesResult(
          prayers: prayer.prayers,
          next: upcoming.first,
          isFromCache: prayer.isFromCache,
          cachedAt: prayer.cachedAt,
          locationLabel: prayer.locationLabel,
        );
        if (mounted) setState(() => _prayer = updated);
        return;
      }
      _loadPrayer();
      return;
    }
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    if (mounted) _countdown.value = '$h:$m:$s';
  }

  void _applyAutoDarkModeIfEnabled(PrayerTimesResult prayer) {
    if (!appSettings.autoDarkModeAtMaghrib) return;
    PrayerItem? maghrib;
    PrayerItem? fajr;
    for (final p in prayer.prayers) {
      if (p.name == 'Maghrib') maghrib = p;
      if (p.name == 'Fajr') fajr = p;
    }
    if (maghrib == null || fajr == null) return;
    final now = DateTime.now();
    final isNight = now.isAfter(maghrib.dateTime) || now.isBefore(fajr.dateTime);
    if (_autoDarkAppliedState == isNight) return;
    _autoDarkAppliedState = isNight;
    appSettings.setThemeMode(isNight ? ThemeMode.dark : ThemeMode.light);
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 5) return l10n.homeGreetingNight;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 17) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final wirdProgress = _wirdTarget == 0 ? 0.0 : (_pagesToday / _wirdTarget).clamp(0.0, 1.0);
    final moonAge = MoonCalculator.moonAgeDays(DateTime.now());
    final moonPhaseName = MoonCalculator.phaseName(moonAge, arabic: languageCode == 'ar');
    final moonImageAsset = MoonCalculator.phaseImageAsset(moonAge);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        // v1.55: the flat 2-color gradient was replaced with the shared
        // WirdiIdentityBackground (mosque-skyline + crescent vector art),
        // matching the visual-identity brief's photographic header look
        // without adding any image asset. Purely decorative -- everything
        // else in this AppBar (title, actions) is unchanged.
        flexibleSpace: const WirdiIdentityBackground(),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IslamicToolsScreen())),
            icon: const Icon(Icons.apps_outlined, color: Colors.white),
            label: Text(l10n.homeIslamicTools, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: l10n.commonSettingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
          children: [
            Text(_greeting(l10n), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              _streak > 0 ? l10n.homeStreakDays(_streak) : l10n.homeContinueToday,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.homePrayersToday(_prayedCount, 5),
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
            if (_khatmaRatio > 0) ...[
              const SizedBox(height: 2),
              Semantics(
                button: true,
                label: l10n.homeKhatmaProgress((_khatmaRatio * 100).round()),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KhatmaTrackerScreen())),
                child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KhatmaTrackerScreen()),
                ),
                child: Text(
                  l10n.homeKhatmaProgress((_khatmaRatio * 100).round()),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              ),
            ],
            const SizedBox(height: 6),
            Builder(builder: (context) {
              final now = DateTime.now();
              final hijri = HijriDate.fromGregorian(now);
              final gregorian = DateFormat('EEEE d MMMM y', languageCode).format(now);
              return Text(
                '$gregorian — ${hijri.toStringLocalized(languageCode)}',
                style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
              );
            }),
            const SizedBox(height: 16),

            Semantics(
              button: true,
              label: l10n.toolMyWirdiTitle,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWirdiScreen())),
              child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWirdiScreen())),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _myWirdiPercent,
                            strokeWidth: 5,
                            backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(AppColors.primaryEmerald),
                          ),
                          Text(
                            '${(_myWirdiPercent * 100).round()}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.homeMyWirdiCardTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            _myWirdiPercent >= 1.0
                                ? l10n.myWirdiCompleted
                                : l10n.myWirdiRemaining((100 - (_myWirdiPercent * 100).round()).clamp(0, 100)),
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: AppColors.mutedText),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 16),

            Builder(builder: (context) {
              final currentHijri = HijriDate.fromGregorian(DateTime.now());
              if (!currentHijri.isRamadan) return const SizedBox.shrink();
              return Column(
                children: [
                  Semantics(
                    button: true,
                    label: l10n.homeRamadanBannerTitle(currentHijri.day),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RamadanCompanionScreen())),
                    child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RamadanCompanionScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF0B3D36), AppColors.primaryEmerald]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.nightlight_round, color: AppColors.goldAccent, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.homeRamadanBannerTitle(currentHijri.day),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(l10n.homeRamadanBannerSubtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),

            // Next prayer — real data from PrayerService, or a clear
            // "unavailable" state, never a hardcoded placeholder.
            Semantics(
              button: true,
              label: l10n.homeNextPrayerCardLabel,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
              child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/generated/mosque_sunrise.webp',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.darkBackground.withValues(alpha: 0.78),
                              AppColors.primaryEmerald.withValues(alpha: 0.78),
                              AppColors.darkBackground.withValues(alpha: 0.58),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.homeNextPrayer, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    if (_prayer != null) ...[
                      Text(prayerDisplayName(l10n, _prayer!.next.name), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<String>(
                        valueListenable: _countdown,
                        builder: (context, value, _) => Text(l10n.homeInLabel(value), style: TextStyle(color: AppColors.goldAccent, fontSize: 16)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              moonImageAsset,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.circle, size: 40, color: Colors.white54),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(moonPhaseName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      if (_prayer!.isFromCache)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(l10n.homeCachedPrayerTimes, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ),
                      if (_weather != null || _sunTimes != null) ...[
                        const SizedBox(height: 14),
                        Container(height: 1, color: Colors.white24),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_weather != null)
                              Column(children: [
                                const Icon(Icons.wb_sunny_outlined, color: Colors.white70, size: 16),
                                const SizedBox(height: 2),
                                Text(_weather!.temperature, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                              ]),
                            if (_sunTimes != null) ...[
                              Column(children: [
                                const Icon(Icons.wb_twilight, color: Colors.white70, size: 16),
                                const SizedBox(height: 2),
                                Text(_fmtSunTime(_sunTimes!.sunrise), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                              ]),
                              Column(children: [
                                const Icon(Icons.nightlight_round, color: Colors.white70, size: 16),
                                const SizedBox(height: 2),
                                Text(_fmtSunTime(_sunTimes!.sunset), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                              ]),
                            ],
                          ],
                        ),
                      ],
                    ] else if (_prayerFailed)
                      Text(l10n.homeEnableLocationForPrayer, style: const TextStyle(color: Colors.white70, fontSize: 15))
                    else
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                      ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 16),

            _DashboardCard(
              icon: Icons.donut_large,
              title: l10n.homeDailyWird,
              subtitle: _pagesToday >= _wirdTarget
                  ? l10n.homeWirdCompleted
                  : l10n.homeWirdProgress(_pagesToday, _wirdTarget),
              trailing: _MiniProgress(value: wirdProgress, l10n: l10n),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen())),
            ),
            const SizedBox(height: 12),

            _DashboardCard(
              icon: Icons.bookmark_outline,
              title: l10n.homeContinueReading,
              subtitle: _lastReading == null
                  ? l10n.homeNoLastReading
                  : l10n.homeLastReadingSubtitle(
                      _lastReading!['surahName'] as String? ?? '',
                      _lastReading!['ayahNumber'] as int? ?? 0,
                    ),
              trailing: const Icon(Icons.chevron_left, color: AppColors.mutedText),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuranScreen(
                    initialSurahNumber: _lastReading?['surahNumber'] as int?,
                    initialAyah: _lastReading?['ayahNumber'] as int?,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _DashboardCard(
              icon: Icons.favorite_outline,
              title: l10n.homeFavorites,
              subtitle: _favoritesCount == 0 ? l10n.homeNoFavoritesYet : l10n.homeFavoritesSavedCount(_favoritesCount),
              trailing: const Icon(Icons.chevron_left, color: AppColors.mutedText),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
            ),
            const SizedBox(height: 12),

            _DashboardCard(
              icon: Icons.format_quote,
              title: l10n.homeQuoteOfTheDay,
              subtitle: DailyQuotes.forToday().displayFor(languageCode),
              trailing: const SizedBox.shrink(),
              onTap: null,
            ),
            const SizedBox(height: 20),

            if (_weekSummary.isNotEmpty) ...[
              Semantics(
                button: true,
                label: l10n.homeWeeklyInsightsCardLabel,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WirdiInsightsScreen())),
                child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WirdiInsightsScreen()),
                ),
                child: _WeekSummaryCard(summary: _weekSummary),
              ),
              ),
              const SizedBox(height: 20),
            ],
            
            const SizedBox(height: 12),
            _DashboardCard(
              icon: Icons.menu_book_outlined,
              title: l10n.localeName == 'ar' ? 'آية اليوم' : 'Verse of the Day',
              subtitle: '${VerseOfTheDayService.forToday().arabicText}\n${VerseOfTheDayService.forToday().surahName} - ${VerseOfTheDayService.forToday().ayahNumber}',
              trailing: const Icon(Icons.chevron_left, color: AppColors.mutedText),
              onTap: () {
                final verse = VerseOfTheDayService.forToday();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuranScreen(initialSurahNumber: verse.surahNumber, initialAyah: verse.ayahNumber)),
                );
              },
            ),
            if (_hadithOfToday != null) ...[
              const SizedBox(height: 12),
              _DashboardCard(
                icon: Icons.auto_stories_outlined,
                title: '${l10n.homeHadithOfTheDay}${_hadithStreak > 1 ? '  \u{1F525} ${l10n.insightsDaysCount(_hadithStreak)}' : ''}',
                subtitle: _hadithOfToday!.translatedText.isNotEmpty ? _hadithOfToday!.translatedText : _hadithOfToday!.arabicText,
                subtitleMaxLines: 4,
                trailing: IconButton(
                  tooltip: l10n.homeShareHadith,
                  icon: const Icon(Icons.share_outlined, color: AppColors.mutedText),
                  onPressed: () {
                    final text = '${_hadithOfToday!.arabicText}\n\n${_hadithOfToday!.translatedText}\n\n${l10n.homeHadithSource}';
                    Share.share(text);
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HadithCollectionScreen(initialHadithNumber: _hadithOfToday!.number),
                  ),
                ),
              ),
            ],

            Text(l10n.homeQuickActions, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.favorite_outline,
                    label: l10n.homeQuickAzkar,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AzkarScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.fingerprint,
                    label: l10n.homeQuickTasbeeh,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbeehScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.access_time,
                    label: l10n.homeQuickPrayer,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.explore_outlined,
                    label: l10n.homeQuickQibla,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
                  ),
                ),
              ],
            ),
          ],
            ),
          ),
        ],
      ),
    );
  }
}
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final int subtitleMaxLines;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.subtitleMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white.withValues(alpha: 0.94),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primaryEmerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 3),
                    Text(subtitle, maxLines: subtitleMaxLines, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mutedText, fontSize: 14)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  final double value;
  final AppLocalizations l10n;
  const _MiniProgress({required this.value, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: l10n.homeCompletionPercent((value * 100).round()),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: 4,
              backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(AppColors.goldAccent),
            ),
            Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _WeekSummaryCard extends StatelessWidget {
  final List<DailyActivitySummary> summary;
  const _WeekSummaryCard({required this.summary});

  // summary[0] is always Saturday (see UserProgressService.last7DaysSummary),
  // so this list is used positionally, not via weekday lookup.
  static String _dayName(AppLocalizations l10n, int i) => [
        l10n.dayNameSat,
        l10n.dayNameSun,
        l10n.dayNameMon,
        l10n.dayNameTue,
        l10n.dayNameWed,
        l10n.dayNameThu,
        l10n.dayNameFri,
      ][i];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final pastOrTodayDays = summary.where((d) => !d.date.isAfter(todayOnly)).toList();
    final activeDays = pastOrTodayDays.where((d) => d.hasAnyActivity).length;
    final targetMetDays = pastOrTodayDays.where((d) => d.wirdTargetMet).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.homeThisWeek, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(
                  l10n.homeActiveDaysOf(activeDays, pastOrTodayDays.length),
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(summary.length, (i) {
                final day = summary[i];
                final isFuture = day.date.isAfter(todayOnly);
                final isToday = day.date.isAtSameMomentAs(todayOnly);
                final intensity = isFuture
                    ? 0.06
                    : (day.wirdTargetMet ? 1.0 : (day.hasAnyActivity ? 0.5 : 0.12));
                final dayName = _dayName(l10n, i);

                return Expanded(
                  child: Column(
                    children: [
                      Semantics(
                        label: isFuture
                            ? l10n.homeDayNotYet(dayName)
                            : l10n.homeDaySummary(dayName, day.wirdPages, day.azkarCompleted, day.tasbeehTotal, day.prayersDone),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryEmerald.withValues(alpha: intensity),
                            border: isToday ? Border.all(color: AppColors.goldAccent, width: 2) : null,
                          ),
                          alignment: Alignment.center,
                          child: (!isFuture && day.wirdTargetMet)
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: isFuture ? AppColors.mutedText.withValues(alpha: 0.5) : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.homeWirdTargetMetSummary(targetMetDays, pastOrTodayDays.length),
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryEmerald.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryEmerald),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MosaicBg extends StatefulWidget {
  final int col; // 0-indexed, 0..4
  final int row; // 0-indexed, 0..1
  const _MosaicBg({required this.col, required this.row});

  @override
  State<_MosaicBg> createState() => _MosaicBgState();
}

class _MosaicBgState extends State<_MosaicBg> {
  static ui.Image? _cachedImage;
  ui.Image? _image;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    if (_cachedImage != null) {
      _image = _cachedImage;
    } else {
      final stream = const AssetImage('assets/images/wirdi_mosaic.webp')
          .resolve(const ImageConfiguration());
      _listener = ImageStreamListener((info, _) {
        _cachedImage = info.image;
        if (mounted) setState(() => _image = info.image);
      });
      stream.addListener(_listener!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (img != null)
            CustomPaint(painter: _MosaicCellPainter(image: img, col: widget.col, row: widget.row))
          else
            Container(color: const Color(0xFF0F766E)),
          Container(color: Colors.black.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

class _MosaicCellPainter extends CustomPainter {
  final ui.Image image;
  final int col;
  final int row;
  static const int cols = 5;
  static const int rows = 2;
  _MosaicCellPainter({required this.image, required this.col, required this.row});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = image.width / cols;
    final cellH = image.height / rows;
    final srcAspect = cellW / cellH;
    final dstAspect = size.width / size.height;
    Rect src;
    if (srcAspect > dstAspect) {
      final visW = cellH * dstAspect;
      final dx = (cellW - visW) / 2;
      src = Rect.fromLTWH(col * cellW + dx, row * cellH, visW, cellH);
    } else {
      final visH = cellW / dstAspect;
      final dy = (cellH - visH) / 2;
      src = Rect.fromLTWH(col * cellW, row * cellH + dy, cellW, visH);
    }
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _MosaicCellPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.col != col || oldDelegate.row != row;
}
