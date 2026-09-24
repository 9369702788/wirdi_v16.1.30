import 'moon_calculator.dart';

class MoonSightingInfo {
  final String date;
  final String hijriMonth;
  final String visibility;
  final String location;
  final String description;
  final double illumination;
  final double ageDays;
  const MoonSightingInfo({
    required this.date,
    required this.hijriMonth,
    required this.visibility,
    required this.location,
    required this.description,
    required this.illumination,
    required this.ageDays,
  });

  bool get isWaxing => ageDays < 14.765294430500001;
}

class MoonSightingService {
  static Future<MoonSightingInfo> getMoonSightingInfo({bool arabic = false}) async {
    final now = DateTime.now();
    final age = MoonCalculator.moonAgeDays(now);
    final illumination = MoonCalculator.illuminationFraction(age);
    final phase = MoonCalculator.phaseName(age, arabic: arabic);
    final nearNewCrescent = age < 2.0 || age > MoonCalculator.synodicMonthDays - 2.0;
    return MoonSightingInfo(
      date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      hijriMonth: '',
      visibility: arabic
          ? (nearNewCrescent ? 'قد يُرى الهلال الصغير قرب غروب الشمس (تقدير فلكي فقط)' : 'خارج نطاق ظهور الهلال الجديد')
          : (nearNewCrescent ? 'Young crescent may be observable near sunset (astronomical estimate only)' : 'Not in the new-crescent window'),
      location: '',
      description: arabic
          ? 'عمر القمر: ${age.toStringAsFixed(1)} يوم -- $phase (${(illumination * 100).round()}% إضاءة). هذا تقدير فلكي محسوب، وليس إعلانًا رسميًا من لجنة رؤية الهلال.'
          : 'Moon age: ${age.toStringAsFixed(1)} days -- $phase (${(illumination * 100).round()}% illuminated). This is a calculated estimate, not a moon-sighting committee announcement.',
    
      illumination: illumination,
      ageDays: age,
    );
  }
}
