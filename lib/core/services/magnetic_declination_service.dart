import 'package:flutter/services.dart';

/// Magnetic declination (the angle between magnetic north and true north) for
/// a location, from Android's built-in World Magnetic Model
/// (`android.hardware.GeomagneticField`), exposed by the local
/// `flutter_compass_v2` plugin over the `wirdi/declination` channel.
///
/// The compass sensor reports a MAGNETIC heading while the Qibla bearing is
/// measured from TRUE north. Without this correction the needle is off by the
/// local declination (about +5 in Cairo, -13 in New York, +12 in Sydney).
class MagneticDeclinationService {
  MagneticDeclinationService._();

  static const MethodChannel _channel = MethodChannel('wirdi/declination');

  /// Declination in degrees (east positive). Returns 0.0 when unavailable so a
  /// failure can never break the compass.
  static Future<double> at({required double latitude, required double longitude}) async {
    try {
      final value = await _channel.invokeMethod<double>('getDeclination', {'lat': latitude, 'lon': longitude});
      return value ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Converts a magnetic heading to a true heading (0 - 360).
  static double toTrue(double magneticHeading, double declination) {
    final v = (magneticHeading + declination) % 360.0;
    return v < 0 ? v + 360.0 : v;
  }
}
