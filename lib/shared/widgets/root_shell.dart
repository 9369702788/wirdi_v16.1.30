
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/services/daily_reminder_scheduler.dart';
import '../../core/services/settings_service.dart';
import '../../core/models/prayer_models.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../features/home/home_dashboard_screen.dart';
import '../../features/radio/widgets/radio_mini_player.dart';
import '../../features/quran/widgets/quran_mini_player.dart';
import '../../core/services/wirdi_audio_handler.dart';
import '../../features/prayer/prayer_times_screen.dart';
import '../../features/tasbeeh/tasbeeh_screen.dart';
import '../../features/quran/quran_screen.dart';
import '../../features/azkar/azkar_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/radio/radio_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 0;
  int? _lastTimezoneOffsetMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rememberTimezoneOffset();

    // v1.55: keep the recurring (daily/Friday) reminders on the right local hour
    // after a DST or time-zone change, even if the app was closed when it happened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DailyReminderScheduler.rescheduleIfTimeZoneChanged(AppLocalizations.of(context)).catchError((_) {});
    });

    // Surfaces a background-notification setup failure directly in the
    // app -- previously this only ever went to a debugPrint nobody could
    // see while running a real (non-debug-attached) build.
    if (audioServiceInitError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Background notification setup failed'),
            content: SingleChildScrollView(child: Text(audioServiceInitError!)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK')),
            ],
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-sync when app comes back to foreground
    if (state == AppLifecycleState.resumed &&
        AuthService.instance.isSignedIn) {
      SyncService.instance.syncNow().catchError((_) {});
    }
    // FIX: "Auto dark mode at Maghrib" is normally driven by a per-second
    // timer that only lives in HomeDashboardScreen -- while the phone's
    // screen is off or the app is backgrounded, Android throttles that
    // timer, so the theme could stay stale (e.g. still light well after
    // Maghrib) until that timer happened to tick again. Re-checking with
    // the real current time right when the app is resumed/reopened fixes
    // that up immediately instead of leaving the user waiting.
    if (state == AppLifecycleState.resumed) {
      _refreshAutoDarkModeOnResume();
      _refreshPrayerDataAfterTimezoneChange();
    }
  }

  Future<void> _rememberTimezoneOffset() async {
    _lastTimezoneOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
  }

  Future<void> _refreshPrayerDataAfterTimezoneChange() async {
    final currentOffset = DateTime.now().timeZoneOffset.inMinutes;
    final previousOffset = _lastTimezoneOffsetMinutes;
    _lastTimezoneOffsetMinutes = currentOffset;
    if (previousOffset == null || previousOffset == currentOffset) return;

    try {
      await PrayerService.invalidatePrayerCache();
      final result = await PrayerService.fetchUsingSavedPreference();
      if (!mounted) return;
      await PrayerNotificationScheduler.rescheduleFromResult(context, result);
      if (!mounted) return;
      await DailyReminderScheduler.rescheduleIfTimeZoneChanged(AppLocalizations.of(context));
    } catch (_) {
      // Best effort: the next normal prayer-time refresh will recover.
    }
  }

  Future<void> _refreshAutoDarkModeOnResume() async {
    if (!appSettings.autoDarkModeAtMaghrib) return;
    try {
      final result = await PrayerService.fetchUsingSavedPreference();
      PrayerItem? maghrib;
      PrayerItem? fajr;
      for (final p in result.prayers) {
        if (p.name == 'Maghrib') maghrib = p;
        if (p.name == 'Fajr') fajr = p;
      }
      if (maghrib == null || fajr == null) return;
      final now = DateTime.now();
      final isNight = now.isAfter(maghrib.dateTime) || now.isBefore(fajr.dateTime);
      final targetMode = isNight ? ThemeMode.dark : ThemeMode.light;
      if (appSettings.themeMode == targetMode) return;
      await appSettings.setThemeMode(targetMode);
    } catch (_) {
      // Best-effort safety net only -- the Home tab's per-second check
      // remains the primary mechanism while the app is actively open.
    }
  }

  // ORDER MUST EXACTLY MATCH the BottomNavigationBar items below:
  // 0=Home  1=Quran  2=Azkar  3=Prayer  4=Tasbeeh  5=Radio  6=More(Settings)
  static final List<Widget> _screens = [
    const HomeDashboardScreen(),   // 0
    const QuranScreen(),           // 1
    const AzkarScreen(),           // 2
    const PrayerTimesScreen(),     // 3
    const TasbeehScreen(),         // 4
    const RadioScreen(),           // 5  ← Radio BEFORE Settings
    const SettingsScreen(),        // 6
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: _screens,
            ),
          ),
          // Mini player — visible whenever a radio station is active
          const RadioMiniPlayer(),
          // Mini player -- visible whenever Quran recitation is active
          const QuranMiniPlayer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(                          // 0
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          BottomNavigationBarItem(                          // 1
            icon: const Icon(Icons.menu_book_outlined),
            activeIcon: const Icon(Icons.menu_book),
            label: l10n.navQuran,
          ),
          BottomNavigationBarItem(                          // 2
            icon: const Icon(Icons.volunteer_activism_outlined),
            activeIcon: const Icon(Icons.volunteer_activism),
            label: l10n.navAzkar,
          ),
          BottomNavigationBarItem(                          // 3
            icon: const Icon(Icons.mosque_outlined),
            activeIcon: const Icon(Icons.mosque),
            label: l10n.navPrayer,
          ),
          BottomNavigationBarItem(                          // 4
            icon: const Icon(Icons.fingerprint),
            activeIcon: const Icon(Icons.fingerprint),
            label: l10n.navTasbeeh,
          ),
          BottomNavigationBarItem(                          // 5  ← Radio
            icon: const Icon(Icons.podcasts_outlined),
            activeIcon: const Icon(Icons.podcasts),
            label: l10n.radioTitle,
          ),
          BottomNavigationBarItem(                          // 6  ← Settings/More
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}
