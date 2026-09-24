import 'dart:async';

import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/app_sources.dart';
import '../../core/models/prayer_models.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/prayer_display.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/moon_calculator.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/services/weather_service.dart';
import '../../core/services/sunrise_sunset_calculator.dart';
import 'package:geolocator/geolocator.dart';
import 'prayer_chart_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  bool _loading = true;
  PrayerAvailability? _availabilityError;
  PrayerTimesResult? _result;
  final ValueNotifier<String> _countdown = ValueNotifier<String>('--:--:--'); // v1.55: only the countdown Text rebuilds each second
  Timer? _timer;
  Set<String> _prayedToday = {};
  String? _remindedForPrayer; // avoids re-firing the reminder every second
  WeatherData? _weather;
  SunTimes? _sunTimes;
  final AudioPlayer _adhanPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrayedToday();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    _adhanPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPrayedToday() async {
    final prayed = await UserProgressService.prayedToday();
    if (mounted) setState(() => _prayedToday = prayed);
  }

  Future<void> _togglePrayed(String prayerId) async {
    final isPrayed = _prayedToday.contains(prayerId);
    await UserProgressService.setPrayed(prayerId, !isPrayed);
    await _loadPrayedToday();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _availabilityError = null;
    });

    try {
      final result = await PrayerService.fetchUsingSavedPreference();
      setState(() {
        _result = result;
        _loading = false;
      });
      _startCountdown();
      unawaited(_loadWeatherAndSun());
      if (mounted) {
        unawaited(PrayerNotificationScheduler.rescheduleFromResult(context, result));
      }
    } on PrayerAvailability catch (e) {
      setState(() {
        _availabilityError = e;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _availabilityError = PrayerAvailability.networkErrorNoCache;
        _loading = false;
      });
    }
  }

  Future<void> _loadWeatherAndSun() async {
    try {
      final w = await WeatherService.getWeatherAtPrayerTime('now');
      if (mounted) setState(() => _weather = w);
    } catch (_) {}
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 10));
      final sun = SunriseSunsetCalculator.calculate(position.latitude, position.longitude, DateTime.now());
      if (mounted) setState(() => _sunTimes = sun);
    } catch (_) {}
  }

  String _fmtTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _useGpsLocation() async {
    setState(() => _loading = true);
    try {
      final result = await PrayerService.fetchPrayerTimes();
      setState(() {
        _result = result;
        _availabilityError = null;
        _loading = false;
      });
      _startCountdown();
      if (mounted) {
        unawaited(PrayerNotificationScheduler.rescheduleFromResult(context, result));
      }
    } on PrayerAvailability catch (e) {
      setState(() {
        _availabilityError = e;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _availabilityError = PrayerAvailability.networkErrorNoCache;
        _loading = false;
      });
    }
  }

  Future<void> _pickCityManually() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _result?.locationLabel ?? '');

    final city = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.prayerSetCityManually),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.prayerCityHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(l10n.prayerSearch)),
        ],
      ),
    );

    if (city == null || city.isEmpty) return;
    if (!mounted) return;

    setState(() => _loading = true);
    try {
      final result = await PrayerService.fetchPrayerTimesForCity(city);
      setState(() {
        _result = result;
        _availabilityError = null;
        _loading = false;
      });
      _startCountdown();
      if (mounted) {
        unawaited(PrayerNotificationScheduler.rescheduleFromResult(context, result));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).prayerCityNotFound(city))),
        );
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _remindedForPrayer = null;
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  /// FIX: same root-cause race as home_dashboard_screen.dart's
  /// _updateCountdown() -- calling [_load] (a full re-fetch +
  /// PrayerNotificationScheduler.rescheduleFromResult, which cancels
  /// and re-adds every scheduled notification) the INSTANT this
  /// screen's own countdown reaches zero raced against and cancelled
  /// the "at prayer time" Adhan notification at the exact moment it
  /// was due to fire, and the freshly recomputed schedule then
  /// silently dropped it as already in the past. Fix: advance locally
  /// to the next prayer already present in today's fetched list (no
  /// network call, no reschedule) instead of re-fetching every single
  /// time a prayer boundary is crossed; only fall back to a real
  /// [_load] once today's list is exhausted.
  void _updateCountdown() {
    final result = _result;
    if (result == null) return;

    final diff = result.next.dateTime.difference(DateTime.now());
    if (diff.isNegative) {
      final upcoming = result.prayers.where((p) => p.dateTime.isAfter(DateTime.now())).toList();
      if (upcoming.isNotEmpty) {
        final updated = PrayerTimesResult(
          prayers: result.prayers,
          next: upcoming.first,
          isFromCache: result.isFromCache,
          cachedAt: result.cachedAt,
          locationLabel: result.locationLabel,
        );
        if (mounted) setState(() => _result = updated);
        return;
      }
      _load();
      return;
    }

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    if (mounted) _countdown.value = '$hours:$minutes:$seconds';

    _maybeFireReminder(diff, result.next.name);
  }

  void _maybeFireReminder(Duration remaining, String prayerId) {
    if (!appSettings.prayerReminderEnabled) return;
    if (appSettings.prayerReminderMode == 'off') return;
    if (_remindedForPrayer == prayerId) return;

    final thresholdSeconds = appSettings.prayerReminderMinutesBefore * 60;
    if (remaining.inSeconds <= thresholdSeconds) {
      _remindedForPrayer = prayerId;
      _fireReminder(prayerId);
    }
  }

  void _fireReminder(String prayerId) {
    final mode = appSettings.prayerReminderMode;

    if (mode == 'beep') {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } else if (mode == 'adhan') {
      _playAdhan();
    }

    if (mode != 'off') {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.prayerReminderApproaching(
              prayerDisplayName(l10n, prayerId),
              appSettings.prayerReminderMinutesBefore,
            )),
            duration: const Duration(seconds: 6),
            backgroundColor: AppColors.primaryEmerald,
          ),
        );
      }
    }
  }

  Future<void> _playAdhan() async {
    final option = AppSources.adhanOptions.firstWhere(
      (a) => a.id == appSettings.adhanId,
      orElse: () => AppSources.adhanOptions.first,
    );
    try {
      try {
        await _adhanPlayer.stop();
      } catch (_) {
        // Nothing loaded yet — expected on first play.
      }
      await _adhanPlayer.play(UrlSource(option.url));
    } catch (e, st) {
      AppLogger.error('Adhan playback failed', error: e, stackTrace: st);
    }
  }

  String _availabilityMessage(AppLocalizations l10n, PrayerAvailability e) => switch (e) {
        PrayerAvailability.locationServiceDisabled => l10n.prayerAvailabilityLocationDisabled,
        PrayerAvailability.permissionDenied => l10n.prayerAvailabilityPermissionDenied,
        PrayerAvailability.permissionDeniedForever => l10n.prayerAvailabilityPermissionDeniedForever,
        PrayerAvailability.networkErrorNoCache => l10n.prayerAvailabilityNetworkError,
        PrayerAvailability.ok => '',
      };

  /// Offsets are applied once, inside PrayerService (v1.55), so the list,
  /// countdown, notifications and widget agree; this only returns the text.
  String _calibratedTimeText(PrayerItem prayer) => prayer.timeText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_availabilityError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.prayerTimesTitle), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_outlined, size: 52, color: AppColors.mutedText),
                const SizedBox(height: 16),
                Text(_availabilityMessage(l10n, _availabilityError!),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.mutedText)),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _load, child: Text(l10n.prayerRetry)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickCityManually,
                  icon: const Icon(Icons.location_city),
                  label: Text(l10n.prayerSetCityManually),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final result = _result!;
    final isAr = l10n.localeName == 'ar';
    final moonAge = MoonCalculator.moonAgeDays(DateTime.now());
    final moonPhaseName = MoonCalculator.phaseName(moonAge, arabic: isAr);
    final moonImageAsset = MoonCalculator.phaseImageAsset(moonAge);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        flexibleSpace: _MosaicBg(col: 4, row: 0, opacity: 0.4),
        title: Text(l10n.prayerTimesTitle),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'gps') _useGpsLocation();
              if (value == 'city') _pickCityManually();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'gps', child: Text(l10n.prayerUseGps)),
              PopupMenuItem(value: 'city', child: Text(l10n.prayerSetCityManually)),
            ],
            icon: const Icon(Icons.tune),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: l10n.prayerRefresh),
          PopupMenuButton<String>(
            tooltip: l10n.navMore,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'chart') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerChartScreen()));
              } else if (value == 'weather') {
                () async {
                  try {
                    final w = await WeatherService.getWeatherAtPrayerTime('now');
                    if (!context.mounted) return;
                    showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Weather'),
                        content: Text('${w.temperature} -- ${w.condition}\nHumidity: ${w.humidity}, Wind: ${w.windSpeed}'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not load weather right now')),
                    );
                  }
                }();
              } else if (value == 'sun') {
                () async {
                  try {
                    final position = await Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
                    ).timeout(const Duration(seconds: 10));
                    final sun = SunriseSunsetCalculator.calculate(position.latitude, position.longitude, DateTime.now());
                    if (!context.mounted) return;
                    String fmt(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                    showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Sunrise / Sunset'),
                        content: Text('Sunrise: ${fmt(sun.sunrise)}\nSunset: ${fmt(sun.sunset)}'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not calculate sunrise/sunset right now')),
                    );
                  }
                }();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'chart',
                child: Row(children: [
                  const Icon(Icons.bar_chart_outlined, size: 20),
                  const SizedBox(width: 10),
                  const Text('Prayer chart'),
                ]),
              ),
              PopupMenuItem(
                value: 'weather',
                child: Row(children: [
                  const Icon(Icons.wb_sunny_outlined, size: 20),
                  const SizedBox(width: 10),
                  const Text('Weather'),
                ]),
              ),
              PopupMenuItem(
                value: 'sun',
                child: Row(children: [
                  const Icon(Icons.wb_twilight, size: 20),
                  const SizedBox(width: 10),
                  const Text('Sunrise/Sunset'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          if (result.isFromCache)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.goldAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.prayerOfflineBanner, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryEmerald, Color(0xFF115E56)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                if (result.locationLabel != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(result.locationLabel!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Text(l10n.prayerNextPrayerLabel, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Text(prayerDisplayName(l10n, result.next.name),
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ValueListenableBuilder<String>(
                  valueListenable: _countdown,
                  builder: (context, value, _) => Text(value, style: TextStyle(color: AppColors.goldAccent, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 6),
                Text(l10n.prayerTimeRemaining, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final moonSize = (constraints.maxWidth * 0.78).clamp(180.0, 250.0).toDouble();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            moonImageAsset,
                            width: moonSize,
                            height: moonSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.circle, size: moonSize, color: Colors.white54),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Text(
                            moonPhaseName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_weather != null || _sunTimes != null) ...[
                  const SizedBox(height: 18),
                  Container(height: 1, color: Colors.white24),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_weather != null)
                        Column(children: [
                          const Icon(Icons.wb_sunny_outlined, color: Colors.white70, size: 18),
                          const SizedBox(height: 4),
                          Text(_weather!.temperature, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text(_weather!.condition, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ]),
                      if (_sunTimes != null) ...[
                        Column(children: [
                          const Icon(Icons.wb_twilight, color: Colors.white70, size: 18),
                          const SizedBox(height: 4),
                          Text(_fmtTime(_sunTimes!.sunrise), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text(Localizations.localeOf(context).languageCode == 'ar' ? 'الشروق' : 'Sunrise', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ]),
                        Column(children: [
                          const Icon(Icons.nights_stay_outlined, color: Colors.white70, size: 18),
                          const SizedBox(height: 4),
                          Text(_fmtTime(_sunTimes!.sunset), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text(Localizations.localeOf(context).languageCode == 'ar' ? 'الغروب' : 'Sunset', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ]),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...result.prayers.map((prayer) {
            final isNext = prayer.name == result.next.name;
            final isPrayed = _prayedToday.contains(prayer.name);
            final hasPassed = prayer.dateTime.isBefore(DateTime.now());
            final displayName = prayerDisplayName(l10n, prayer.name);
            return Card(
              color: isNext ? AppColors.primaryEmerald.withValues(alpha: 0.08) : null,
              child: ListTile(
                leading: Icon(Icons.mosque_outlined, color: isNext ? AppColors.primaryEmerald : AppColors.mutedText),
                title: Text(displayName, style: TextStyle(fontWeight: isNext ? FontWeight.bold : FontWeight.w600)),
                subtitle: Text(_calibratedTimeText(prayer), style: TextStyle(fontWeight: FontWeight.bold, color: isNext ? AppColors.primaryEmerald : null)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      tooltip: isAr ? 'إعداد إشعار الصلاة' : 'Prayer notification',
                      icon: Icon(
                        appSettings.isPrayerReminderEnabledFor(prayer.name)
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: appSettings.isPrayerReminderEnabledFor(prayer.name) ? AppColors.primaryEmerald : AppColors.mutedText,
                      ),
                      onSelected: (mode) async {
                        if (mode == 'off') {
                          await appSettings.setPrayerReminderEnabledFor(prayer.name, false);
                        } else {
                          await appSettings.setPrayerReminderEnabledFor(prayer.name, true);
                          await appSettings.setPrayerSoundOverrideFor(prayer.name, mode);
                        }
                        if (mounted) setState(() {});
                        if (mounted) unawaited(PrayerNotificationScheduler.rescheduleFromResult(context, result));
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'off', child: Text(isAr ? 'إيقاف الإشعار' : 'Notifications off')),
                        PopupMenuItem(value: 'adhan', child: Text(isAr ? 'أذان' : 'Adhan')),
                        PopupMenuItem(value: 'beep', child: Text(isAr ? 'تنبيه صوتي' : 'Sound alert')),
                        PopupMenuItem(value: 'banner', child: Text(isAr ? 'إشعار فقط' : 'Notification only')),
                      ],
                    ),
                    Semantics(
                      button: hasPassed,
                      label: !hasPassed
                          ? l10n.prayerNotYetDue(displayName)
                          : (isPrayed ? l10n.prayerMarkedDone(displayName) : l10n.prayerNotDoneYet(displayName)),
                      child: Checkbox(
                        value: isPrayed,
                        activeColor: AppColors.primaryEmerald,
                        onChanged: hasPassed ? (_) => _togglePrayed(prayer.name) : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Text(
            l10n.prayerFootnote,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _MosaicBg extends StatefulWidget {
  final int col; // 0-indexed, 0..4
  final int row; // 0-indexed, 0..1
  final double opacity;
  const _MosaicBg({required this.col, required this.row, this.opacity = 0.4});

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
          Container(color: Colors.black.withValues(alpha: widget.opacity)),
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
