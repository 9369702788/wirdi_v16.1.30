import '../../core/services/magnetic_declination_service.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart' as compass_v2;
import 'package:geolocator/geolocator.dart';
import '../../core/services/qibla_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'qibla_camera_screen.dart';

enum _AdvQiblaStatus { loading, locationServiceDisabled, permissionDenied, error, ready }

class AdvancedQiblaScreen extends StatefulWidget {
  const AdvancedQiblaScreen({super.key});
  @override
  State<AdvancedQiblaScreen> createState() => _AdvancedQiblaScreenState();
}

class _AdvancedQiblaScreenState extends State<AdvancedQiblaScreen> {
  _AdvQiblaStatus _status = _AdvQiblaStatus.loading;
  double? _qiblaBearing;
  double? _distanceKm;
  StreamSubscription<compass_v2.CompassEvent>? _compassSub;
  double? _heading;
  double _declination = 0.0; // magnetic -> true north (v1.55)
  double? _accuracy;
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
    setState(() => _status = _AdvQiblaStatus.loading);
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _status = _AdvQiblaStatus.locationServiceDisabled);
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        (permission != LocationPermission.always && permission != LocationPermission.whileInUse)) {
      if (mounted) setState(() => _status = _AdvQiblaStatus.permissionDenied);
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
        _status = _AdvQiblaStatus.ready;
      });
      _startCompass();
    } catch (_) {
      if (mounted) setState(() => _status = _AdvQiblaStatus.error);
    }
  }

  void _startCompass() {
    final events = compass_v2.FlutterCompass.events;
    if (events == null) {
      setState(() => _hasCompassSensor = false);
      return;
    }
    _compassSub = events.listen((event) {
      if (event.heading != null && mounted) {
        setState(() {
          _heading = MagneticDeclinationService.toTrue(event.heading!, _declination);
          _accuracy = event.accuracy;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.qiblaTitle} Pro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'القبلة بالكاميرا' : 'Camera Qibla',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaCameraScreen())),
          ),
        ],
      ),
      body: SafeArea(bottom: true, top: false, child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_status) {
      case _AdvQiblaStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case _AdvQiblaStatus.locationServiceDisabled:
        return _StatusView(icon: Icons.location_off_outlined, message: l10n.qiblaLocationServiceDisabled, retryLabel: l10n.qiblaRetry, onRetry: _resolveLocation);
      case _AdvQiblaStatus.permissionDenied:
        return _StatusView(icon: Icons.location_off_outlined, message: l10n.qiblaPermissionDenied, retryLabel: l10n.qiblaRetry, onRetry: _resolveLocation);
      case _AdvQiblaStatus.error:
        return _StatusView(icon: Icons.error_outline, message: l10n.qiblaLocationError, retryLabel: l10n.qiblaRetry, onRetry: _resolveLocation);
      case _AdvQiblaStatus.ready:
        return _buildCompass(l10n);
    }
  }

  Widget _buildCompass(AppLocalizations l10n) {
    final qibla = _qiblaBearing!;
    if (!_hasCompassSensor) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.explore_off_outlined, size: 56, color: AppColors.mutedText),
            const SizedBox(height: 16),
            Text(l10n.qiblaNoCompassSensor, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 20),
            Text('${qibla.round()}°', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
          ]),
        ),
      );
    }
    final heading = _heading;
    if (heading == null) return const Center(child: CircularProgressIndicator());
    final needleAngle = (qibla - heading) * math.pi / 180;
    final isAligned = _angleDifference(qibla, heading) < 5;

    return SingleChildScrollView(
      child: Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.satellite_alt_outlined, size: 16, color: AppColors.primaryEmerald),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Precision mode: geomagnetic true-north model'
                '${_accuracy != null ? " - accuracy +/-${_accuracy!.round()} deg" : ""}',
                style: TextStyle(color: AppColors.primaryEmerald, fontSize: 12)),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Stack(alignment: Alignment.center, children: [
            Container(width: 280, height: 280,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.15), width: 2))),
            Transform.rotate(
              angle: -heading * math.pi / 180,
              child: SizedBox(
                width: 260, height: 260,
                child: Stack(alignment: Alignment.center, children: [
                  Positioned(top: 8, child: Text(l10n.qiblaCompassNorth, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mutedText))),
                  Positioned(bottom: 8, child: Text(l10n.qiblaCompassSouth, style: const TextStyle(color: AppColors.mutedText))),
                  Positioned(left: 8, child: Text(l10n.qiblaCompassWest, style: const TextStyle(color: AppColors.mutedText))),
                  Positioned(right: 8, child: Text(l10n.qiblaCompassEast, style: const TextStyle(color: AppColors.mutedText))),
                ]),
              ),
            ),
            Transform.rotate(
              angle: needleAngle,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.mosque, size: 40, color: isAligned ? AppColors.goldAccent : AppColors.primaryEmerald),
                Container(width: 4, height: 90, color: isAligned ? AppColors.goldAccent : AppColors.primaryEmerald),
              ]),
            ),
            Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.mutedText)),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          if (isAligned)
            Text(l10n.qiblaAligned, style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold, fontSize: 16))
          else
            Text(l10n.qiblaNotAligned, style: const TextStyle(color: AppColors.mutedText)),
          const SizedBox(height: 8),
          Text(l10n.qiblaBearingValue(qibla.round()), style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
          if (_distanceKm != null) ...[
            const SizedBox(height: 4),
            Text('${l10n.qiblaDistanceLabel}: ${l10n.qiblaDistanceValue(_distanceKm!.round())}', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
          ],
        ]),
      ),
      ]),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 52, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.mutedText)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
        ]),
      ),
    );
  }
}
