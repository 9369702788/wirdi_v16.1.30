import '../../core/services/magnetic_declination_service.dart';
import 'dart:async';
import 'dart:math' as math;

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/qibla_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'qibla_camera_screen.dart';

enum _QiblaStatus { loading, locationServiceDisabled, permissionDenied, error, ready }

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  _QiblaStatus _status = _QiblaStatus.loading;
  double? _qiblaBearing;
  double? _distanceKm;
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;
  double _declination = 0.0; // magnetic -> true north (v1.55)
  bool _hasCompassSensor = true;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    setState(() => _status = _QiblaStatus.loading);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _status = _QiblaStatus.locationServiceDisabled);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        (permission != LocationPermission.always && permission != LocationPermission.whileInUse)) {
      if (mounted) setState(() => _status = _QiblaStatus.permissionDenied);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));
      _declination = await MagneticDeclinationService.at(latitude: position.latitude, longitude: position.longitude);

      final bearing = QiblaService.bearingTo(latitude: position.latitude, longitude: position.longitude);
      final distance = QiblaService.distanceKmTo(latitude: position.latitude, longitude: position.longitude);
      if (!mounted) return;
      setState(() {
        _qiblaBearing = bearing;
        _distanceKm = distance;
        _status = _QiblaStatus.ready;
      });
      _startCompass();
    } catch (_) {
      if (mounted) setState(() => _status = _QiblaStatus.error);
    }
  }

  void _startCompass() {
    // FlutterCompass.events is null on devices with no magnetometer at
    // all (some tablets, most emulators) — checked once up front so the
    // UI can fall back to showing the numeric bearing instead of a dial
    // that will never move.
    final events = FlutterCompass.events;
    if (events == null) {
      setState(() => _hasCompassSensor = false);
      return;
    }
    _compassSub = events.listen((event) {
      if (event.heading != null && mounted) {
        setState(() => _heading = MagneticDeclinationService.toTrue(event.heading!, _declination));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        flexibleSpace: _MosaicBg(col: 0, row: 1, opacity: 0.4),
        title: Text(l10n.qiblaTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'القبلة بالكاميرا' : 'Camera Qibla',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaCameraScreen())),
          ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_status) {
      case _QiblaStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case _QiblaStatus.locationServiceDisabled:
        return _StatusView(
          icon: Icons.location_off_outlined,
          message: l10n.qiblaLocationServiceDisabled,
          retryLabel: l10n.qiblaRetry,
          onRetry: _resolveLocation,
        );

      case _QiblaStatus.permissionDenied:
        return _StatusView(
          icon: Icons.location_off_outlined,
          message: l10n.qiblaPermissionDenied,
          retryLabel: l10n.qiblaRetry,
          onRetry: _resolveLocation,
        );

      case _QiblaStatus.error:
        return _StatusView(
          icon: Icons.error_outline,
          message: l10n.qiblaLocationError,
          retryLabel: l10n.qiblaRetry,
          onRetry: _resolveLocation,
        );

      case _QiblaStatus.ready:
        return _buildCompass(l10n);
    }
  }

  Widget _buildCompass(AppLocalizations l10n) {
    final qibla = _qiblaBearing!;

    if (!_hasCompassSensor) {
      // No magnetometer on this device — still genuinely useful: show
      // the numeric bearing so the person can orient with any compass
      // app, a physical compass, or the sun.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 56, color: AppColors.mutedText),
              const SizedBox(height: 16),
              Text(l10n.qiblaNoCompassSensor, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
              const SizedBox(height: 20),
              Text('${qibla.round()}°', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
              const SizedBox(height: 6),
              Text(l10n.qiblaBearingFromNorth, style: const TextStyle(color: AppColors.mutedText)),
              if (_distanceKm != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${l10n.qiblaDistanceLabel}: ${l10n.qiblaDistanceValue(_distanceKm!.round())}',
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final heading = _heading;
    if (heading == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Angle to rotate the Qibla needle by, relative to the phone's own
    // orientation: when this reaches 0, the needle points wherever the
    // top of the phone is currently facing, which is correct once that
    // also equals the real-world Qibla bearing.
    final needleAngle = (qibla - heading) * math.pi / 180;
    final isAligned = _angleDifference(qibla, heading) < 5;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.15), width: 2),
                  ),
                ),
                // Rotates opposite the device heading, so North on the
                // dial always points to real-world North.
                Transform.rotate(
                  angle: -heading * math.pi / 180,
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 8,
                          child: Text(l10n.qiblaCompassNorth, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mutedText)),
                        ),
                        Positioned(
                          bottom: 8,
                          child: Text(l10n.qiblaCompassSouth, style: const TextStyle(color: AppColors.mutedText)),
                        ),
                        Positioned(
                          left: 8,
                          child: Text(l10n.qiblaCompassWest, style: const TextStyle(color: AppColors.mutedText)),
                        ),
                        Positioned(
                          right: 8,
                          child: Text(l10n.qiblaCompassEast, style: const TextStyle(color: AppColors.mutedText)),
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: needleAngle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mosque, size: 40, color: isAligned ? AppColors.goldAccent : AppColors.primaryEmerald),
                      Container(width: 4, height: 90, color: isAligned ? AppColors.goldAccent : AppColors.primaryEmerald),
                    ],
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (isAligned)
                Text(l10n.qiblaAligned, style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold, fontSize: 16))
              else
                Text(l10n.qiblaNotAligned, style: const TextStyle(color: AppColors.mutedText)),
              const SizedBox(height: 8),
              Text(l10n.qiblaBearingValue(qibla.round()), style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
              if (_distanceKm != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${l10n.qiblaDistanceLabel}: ${l10n.qiblaDistanceValue(_distanceKm!.round())}',
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l10n.qiblaCalibrationHint, style: const TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static double _angleDifference(double a, double b) {
    final diff = (a - b).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _StatusView({required this.icon, required this.message, required this.retryLabel, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.mutedText),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.mutedText)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
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
