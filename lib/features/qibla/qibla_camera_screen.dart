import '../../core/services/magnetic_declination_service.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/qibla_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

enum _CameraQiblaStatus { loading, cameraUnavailable, locationError, ready }

class QiblaCameraScreen extends StatefulWidget {
  const QiblaCameraScreen({super.key});

  @override
  State<QiblaCameraScreen> createState() => _QiblaCameraScreenState();
}

class _QiblaCameraScreenState extends State<QiblaCameraScreen> {
  _CameraQiblaStatus _status = _CameraQiblaStatus.loading;
  CameraController? _controller;
  double? _qiblaBearing;
  double? _heading;
  double _declination = 0.0; // magnetic -> true north (v1.55)
  StreamSubscription<CompassEvent>? _compassSub;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _status = _CameraQiblaStatus.loading);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('location_disabled');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('location_denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));
      _declination = await MagneticDeclinationService.at(latitude: position.latitude, longitude: position.longitude);
      _qiblaBearing = QiblaService.bearingTo(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      if (mounted) setState(() => _status = _CameraQiblaStatus.locationError);
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('no_camera');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) return;
      _controller = controller;
      _startCompass();
      setState(() => _status = _CameraQiblaStatus.ready);
    } catch (e) {
      _errorDetail = e.toString();
      if (mounted) setState(() => _status = _CameraQiblaStatus.cameraUnavailable);
    }
  }

  void _startCompass() {
    final events = FlutterCompass.events;
    if (events == null) return;
    _compassSub = events.listen((event) {
      if (event.heading != null && mounted) {
        setState(() => _heading = MagneticDeclinationService.toTrue(event.heading!, _declination));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isAr ? 'القبلة بالكاميرا' : 'Camera Qibla'),
        centerTitle: true,
      ),
      body: _buildBody(l10n, isAr),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isAr) {
    switch (_status) {
      case _CameraQiblaStatus.loading:
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      case _CameraQiblaStatus.locationError:
        return _errorView(
          icon: Icons.location_off_outlined,
          message: isAr ? 'تعذّر تحديد موقعك. تأكد من تفعيل خدمة الموقع ومنح الإذن.' : 'Could not determine your location. Check that location services and permission are enabled.',
        );
      case _CameraQiblaStatus.cameraUnavailable:
        return _errorView(
          icon: Icons.videocam_off_outlined,
          message: (isAr
                  ? 'تعذّر تشغيل الكاميرا. إذا ظهرت هذه الرسالة رغم منح إذن الكاميرا، فقد يحتاج التطبيق إلى إضافة صلاحية الكاميرا في إعدادات النظام (AndroidManifest.xml) من قِبل المطوّر.'
                  : 'Could not start the camera. If this appears even after granting camera permission, the app may be missing the CAMERA permission declaration (AndroidManifest.xml) and needs a developer fix.') +
              (_errorDetail != null ? '\n\n($_errorDetail)' : ''),
        );
      case _CameraQiblaStatus.ready:
        return _buildCameraOverlay();
    }
  }

  Widget _errorView({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: Colors.white70),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _init, child: const Text('Retry')),
        ]),
      ),
    );
  }

  Widget _buildCameraOverlay() {
    final controller = _controller;
    final qibla = _qiblaBearing;
    final heading = _heading;
    if (controller == null || qibla == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

    final needleAngle = heading == null ? 0.0 : (qibla - heading) * math.pi / 180;
    final isAligned = heading != null && _angleDifference(qibla, heading) < 5;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        if (heading == null)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          )
        else
          Center(
            child: Transform.rotate(
              angle: needleAngle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mosque, size: 48, color: isAligned ? AppColors.goldAccent : Colors.white),
                  Container(width: 4, height: 160, color: isAligned ? AppColors.goldAccent : Colors.white),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text(
                isAligned ? (Localizations.localeOf(context).languageCode == 'ar' ? 'أنت متجه نحو القبلة' : 'You are facing the Qibla') : '${qibla.round()}°',
                style: TextStyle(color: isAligned ? AppColors.goldAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
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
