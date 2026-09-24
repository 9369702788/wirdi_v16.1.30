import 'dart:math' as math;

class MoonCalculator {
  MoonCalculator._();
  static final DateTime referenceNewMoon = DateTime.utc(2000, 1, 6, 18, 14);
  static const double synodicMonthDays = 29.530588861;

  static double moonAgeDays(DateTime date) {
    final diffMinutes = date.toUtc().difference(referenceNewMoon).inMinutes;
    final diffDays = diffMinutes / (60 * 24);
    var age = diffDays % synodicMonthDays;
    if (age < 0) age += synodicMonthDays;
    return age;
  }

  static double illuminationFraction(double ageDays) {
    final radians = (2 * math.pi * ageDays) / synodicMonthDays;
    return (1 - math.cos(radians)) / 2;
  }

  /// AI-generated, photorealistic (NASA/telescope-style) images -- not
  /// copyrighted third-party photos -- one per canonical phase. Boundaries
  /// deliberately mirror phaseName() exactly so the image and the text
  /// label shown next to it always agree.
  static String phaseImageAsset(double ageDays) {
    if (ageDays < 1.0 || ageDays >= synodicMonthDays - 1.0) return 'assets/images/moon_phases/new_moon.webp';
    if (ageDays < 6.4) return 'assets/images/moon_phases/waxing_crescent.webp';
    if (ageDays < 8.4) return 'assets/images/moon_phases/first_quarter.webp';
    if (ageDays < 13.8) return 'assets/images/moon_phases/waxing_gibbous.webp';
    if (ageDays < 15.8) return 'assets/images/moon_phases/full_moon.webp';
    if (ageDays < 21.2) return 'assets/images/moon_phases/waning_gibbous.webp';
    if (ageDays < 23.2) return 'assets/images/moon_phases/last_quarter.webp';
    return 'assets/images/moon_phases/waning_crescent.webp';
  }

  static String phaseName(double ageDays, {bool arabic = false}) {
    if (ageDays < 1.0 || ageDays >= synodicMonthDays - 1.0) return arabic ? 'محاق' : 'New Moon';
    if (ageDays < 6.4) return arabic ? 'هلال متزايد' : 'Waxing Crescent';
    if (ageDays < 8.4) return arabic ? 'تربيع أول' : 'First Quarter';
    if (ageDays < 13.8) return arabic ? 'أحدب متزايد' : 'Waxing Gibbous';
    if (ageDays < 15.8) return arabic ? 'بدر' : 'Full Moon';
    if (ageDays < 21.2) return arabic ? 'أحدب متناقص' : 'Waning Gibbous';
    if (ageDays < 23.2) return arabic ? 'تربيع أخير' : 'Last Quarter';
    return arabic ? 'هلال متناقص' : 'Waning Crescent';
  }
}
