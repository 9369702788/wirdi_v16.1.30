import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/services/radio_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/sleep_timer_sheet.dart';

/// Full-screen "Now Playing" player for the Radio tab, opened from the
/// mini player or the inline now-playing banner. Shows the Kaaba
/// background (cropped from the shared app-wide mosaic image), an
/// animated equalizer, elapsed listening time, and Previous/Play-Pause/
/// Next controls that move between stations in [RadioService.allStations].
///
/// NOTE on the equalizer: `audioplayers` does not expose real-time
/// amplitude/frequency data for a playing stream, so this is a smooth
/// simulated animation (active while playing, flat while paused) rather
/// than a true audio-reactive visualizer -- getting a genuinely
/// audio-reactive equalizer would require native platform audio-engine
/// access outside this package's scope.
class RadioNowPlayingScreen extends StatefulWidget {
  const RadioNowPlayingScreen({super.key});

  @override
  State<RadioNowPlayingScreen> createState() => _RadioNowPlayingScreenState();
}

class _RadioNowPlayingScreenState extends State<RadioNowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _eqController;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  String? _lastStationId;

  @override
  void initState() {
    super.initState();
    _eqController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final svc = RadioService.instance;
      if (svc.currentStation?.id != _lastStationId) {
        _lastStationId = svc.currentStation?.id;
        _elapsedSeconds = 0;
      }
      if (svc.isPlaying) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _eqController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String _fmt(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return ListenableBuilder(
      listenable: RadioService.instance,
      builder: (context, _) {
        final svc = RadioService.instance;
        final station = svc.currentStation;
        final lang = appSettings.locale.languageCode;
        final name = station == null ? '' : (lang == 'ar' ? station.nameAr : station.nameEn);
        final subtitle = station == null ? '' : '${station.country} · ${station.category}';
        final canSkip = svc.allStations.length > 1;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Kaaba background, cropped from the shared mosaic image.
              const _MosaicBg(col: 0, row: 1, opacity: 0.7),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              l.radioTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            name.isEmpty ? (isAr ? 'لا يوجد تشغيل حالياً' : 'Nothing playing') : name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: AnimatedBuilder(
                        animation: _eqController,
                        builder: (context, _) => CustomPaint(
                          size: const Size(double.infinity, 56),
                          painter: _EqualizerPainter(
                            animationValue: _eqController.value,
                            active: svc.isPlaying,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(_elapsedSeconds), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          Text(isAr ? 'بث مباشر' : 'Live', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                          onPressed: canSkip ? () => svc.playNext() : null,
                          tooltip: isAr ? 'المحطة التالية' : 'Next station',
                        ),
                        const SizedBox(width: 18),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.goldAccent),
                          child: svc.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(22),
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : IconButton(
                                  iconSize: 38,
                                  icon: Icon(svc.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                                  onPressed: () {
                                    if (svc.isPlaying) {
                                      svc.pause();
                                    } else if (station != null) {
                                      svc.play(station);
                                    }
                                  },
                                ),
                        ),
                        const SizedBox(width: 18),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                          onPressed: canSkip ? () => svc.playPrevious() : null,
                          tooltip: isAr ? 'المحطة السابقة' : 'Previous station',
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              station != null && svc.isFavorite(station.id) ? Icons.favorite : Icons.favorite_border,
                              color: station != null && svc.isFavorite(station.id) ? AppColors.goldAccent : Colors.white,
                            ),
                            onPressed: station == null ? null : () => svc.toggleFavorite(station.id),
                          ),
                          IconButton(
                            icon: Stack(clipBehavior: Clip.none, children: [
                              const Icon(Icons.bedtime_outlined, color: Colors.white),
                              if (svc.hasSleepTimer)
                                Positioned(
                                  right: -2, top: -2,
                                  child: Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(color: AppColors.goldAccent, shape: BoxShape.circle),
                                  ),
                                ),
                            ]),
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              builder: (_) => const SafeArea(top: false, child: SleepTimerSheet()),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
                            tooltip: isAr ? 'قائمة المحطات' : 'Station list',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Simulated audio equalizer: a row of vertical bars animating smoothly
/// while [active] is true, resting flat when paused/stopped.
class _EqualizerPainter extends CustomPainter {
  final double animationValue;
  final bool active;
  final Color color;
  _EqualizerPainter({required this.animationValue, required this.active, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 42;
    final barWidth = size.width / (barCount * 1.7);
    final gap = barWidth * 0.7;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    for (int i = 0; i < barCount; i++) {
      final seed = (i * 13 % 97) / 97.0;
      final phase = (animationValue + seed) % 1.0;
      final wave = 0.5 + 0.5 * sin(phase * 2 * pi + i * 0.7);
      final base = active ? (0.18 + 0.75 * wave) : 0.10;
      final h = size.height * base.clamp(0.08, 1.0);
      final x = i * (barWidth + gap) + barWidth / 2;
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) => true;
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
            Container(color: const Color(0xFF0F5132)),
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
