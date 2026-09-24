import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/islamic_occasions_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/local_cache_service.dart';
import 'core/services/radio_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/wirdi_audio_handler.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'shared/widgets/root_shell.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Tajawal is bundled (assets/google_fonts). Never download fonts at runtime:
    // it works offline and no request is sent to Google's font servers.
    GoogleFonts.config.allowRuntimeFetching = false;

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('[UncaughtError] $error\n$stack');
      return true;
    };

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      debugPrint('[main] Firebase.initializeApp failed -- continuing without cloud features: $e\n$st');
    }

    // Fixes Radio/Quran audio silently stopping after the screen locks or
    // the app backgrounds for a while: without an explicit AudioContext,
    // audioplayers has no dedicated audio-focus request or wake lock on
    // Android. Setting this once, globally, applies to every AudioPlayer
    // instance created afterwards app-wide.
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    } catch (e, st) {
      debugPrint('[main] Setting global AudioContext failed -- background playback may be less reliable: $e\n$st');
    }

    try {
      wirdiAudioHandler = await AudioService.init(
        builder: () => WirdiAudioHandler(),
        config: AudioServiceConfig(
          // Rotated from 'com.wirdi.wirdi.audio' -- Android permanently
          // remembers a per-channel notification setting even across app
          // updates/reinstalls, so an earlier test build accidentally
          // leaving this channel disabled would silently block every
          // future notification on this channel ID forever. A fresh ID
          // guarantees a clean, default-enabled channel.
          androidNotificationChannelId: 'com.wirdi.wirdi.audio.v2',
          androidNotificationChannelName: 'Wirdi Playback',
          // androidNotificationOngoing: true was combined with
          // androidStopForegroundOnPause: false in the ORIGINAL Wirdi code
          // (before this merge) -- audio_service asserts against this exact
          // combination (its own message: androidNotificationOngoing "will
          // make no effect with androidStopForegroundOnPause set to false"),
          // so AudioService.init() has been throwing on every single launch
          // since before this merge, silently caught by the try/catch below.
          // That's the confirmed root cause of the notification never
          // appearing. Removing it costs nothing (the assertion message says
          // it has no effect in this configuration anyway) and fixes the crash.
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'drawable/ic_stat_wirdi',
        ),
      );
    } catch (e, st) {
      audioServiceInitError = e.toString();
      debugPrint('[main] AudioService.init failed -- media notification will be unavailable: $e\n$st');
    }

    // Ask for notification permission (Android 13+) right away, at
    // startup -- not just when the user opts into a prayer reminder.
    // Without this granted, no notification can ever show, including
    // the Radio/Quran playback one, no matter how correctly everything
    // else is wired.
    // v1.54: first-run users are asked right after onboarding (see
    // _afterOnboarding) instead of the instant the app opens; returning users
    // keep the previous behaviour.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      unawaited(IslamicOccasionsService.scheduleReminders());
      // v1.54: Azkar and Mushaf-page data are bundled now; drop the ~2 MB copies that
      // older versions cached in SharedPreferences (it is loaded whole at app start).
      unawaited(LocalCacheService.clearAll(['cache_azkar_json_v1', 'cache_mushaf_pages_json_v1']));
      final startupPrefs = await SharedPreferences.getInstance();
      if (startupPrefs.getBool(_onboardingCompleteKey) ?? false) {
        unawaited(NotificationService.requestPermission());
      }
    });

    await appSettings.load();
    await RadioService.instance.init();
    await initializeDateFormatting();

    // Keeps the CPU awake during audio playback so Radio/Quran recitation
    // doesn't get suspended by the OS a few seconds/minutes after the
    // screen locks or the app backgrounds. Complements the AudioContext
    // (audio focus) set above -- that alone wasn't enough to survive
    // screen-lock on this device.
    runApp(const WirdiApp());
  }, (Object error, StackTrace stack) {
    debugPrint('[runZonedGuarded] Uncaught error: $error\n$stack');
  });
}

const _onboardingCompleteKey = 'onboarding_complete';

Future<void> _afterSplash(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool(_onboardingCompleteKey) ?? false;
  if (context.mounted) {
    Navigator.pushReplacementNamed(context, done ? '/home' : '/onboarding');
  }
}

Future<void> _afterOnboarding(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingCompleteKey, true);
  unawaited(NotificationService.requestPermission());
  if (context.mounted) {
    Navigator.pushReplacementNamed(context, '/home');
  }
}

class WirdiApp extends StatelessWidget {
  const WirdiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        final locale = appSettings.locale;
        final isRtl  = locale.languageCode == 'ar';
        return MaterialApp(
          title: 'Wirdi | \u0648\u0631\u062f\u064a',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(appSettings.colorTheme), darkTheme: AppTheme.dark(appSettings.colorTheme), themeMode: appSettings.themeMode,
          builder: (context, child) {
            final nightMode = appSettings.amoledDarkMode;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(appSettings.fontScale),
                highContrast: appSettings.highContrastEnabled,
                boldText: appSettings.highContrastEnabled,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: nightMode ? Colors.black : Colors.transparent,
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                ),
              ),
            );
          },
          initialRoute: '/splash',
          routes: {
            '/splash':     (context) => SplashScreen(onFinished: () => _afterSplash(context)),
            '/onboarding': (context) => OnboardingScreen(onFinished: () => _afterOnboarding(context)),
            '/login':      (_) => const LoginScreen(),
            '/home':       (_) => const RootShell(),
          },
        );
      },
    );
  }
}
