import 'dart:math' as math;

class SunTimes {
  final DateTime sunrise;
  final DateTime sunset;
  const SunTimes({required this.sunrise, required this.sunset});
}

class SunriseSunsetCalculator {
  SunriseSunsetCalculator._();

  static double _deg2rad(double deg) => deg * math.pi / 180;
  static double _rad2deg(double rad) => rad * 180 / math.pi;

  static SunTimes calculate(double latitude, double longitude, DateTime date) {
    return SunTimes(
      sunrise: _calcTime(latitude, longitude, date, isSunrise: true),
      sunset: _calcTime(latitude, longitude, date, isSunrise: false),
    );
  }

  static DateTime _calcTime(double lat, double lon, DateTime date, {required bool isSunrise}) {
    final dayOfYear = DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(date.year, 1, 1)).inDays + 1;
    final lngHour = lon / 15;
    final t = isSunrise ? dayOfYear + ((6 - lngHour) / 24) : dayOfYear + ((18 - lngHour) / 24);
    final m = (0.9856 * t) - 3.289;
    var l = m + (1.916 * math.sin(_deg2rad(m))) + (0.020 * math.sin(_deg2rad(2 * m))) + 282.634;
    l = l % 360;
    if (l < 0) l += 360;
    var ra = _rad2deg(math.atan(0.91764 * math.tan(_deg2rad(l))));
    ra = ra % 360;
    if (ra < 0) ra += 360;
    final lQuadrant = (l / 90).floor() * 90;
    final raQuadrant = (ra / 90).floor() * 90;
    ra = ra + (lQuadrant - raQuadrant);
    ra = ra / 15;
    final sinDec = 0.39782 * math.sin(_deg2rad(l));
    final cosDec = math.cos(math.asin(sinDec));
    final cosH = (math.cos(_deg2rad(90.833)) - (sinDec * math.sin(_deg2rad(lat)))) / (cosDec * math.cos(_deg2rad(lat)));
    final cosHClamped = cosH.clamp(-1.0, 1.0);
    var h = isSunrise ? 360 - _rad2deg(math.acos(cosHClamped)) : _rad2deg(math.acos(cosHClamped));
    h = h / 15;
    final tLocal = h + ra - (0.06571 * t) - 6.622;
    var ut = tLocal - lngHour;
    ut = ut % 24;
    if (ut < 0) ut += 24;
    final hours = ut.floor();
    final minutes = ((ut - hours) * 60).round();
    final utcDate = DateTime.utc(date.year, date.month, date.day, hours, minutes);
    return utcDate.toLocal();
  }
}
