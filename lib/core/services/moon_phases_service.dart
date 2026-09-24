import 'moon_calculator.dart';

class MoonPhase {
  final String phase;
  final String date;
  final double illumination;
  final double ageDays;
  const MoonPhase({required this.phase, required this.date, required this.illumination, required this.ageDays});

  bool get isWaxing => ageDays < 14.765294430500001;
}

class MoonPhasesService {
  static Future<List<MoonPhase>> getMoonPhasesForMonth(int month, int year, {bool arabic = false}) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final result = <MoonPhase>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime.utc(year, month, d, 12);
      final age = MoonCalculator.moonAgeDays(date);
      result.add(MoonPhase(
        phase: MoonCalculator.phaseName(age, arabic: arabic),
        date: '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
        illumination: MoonCalculator.illuminationFraction(age),
        ageDays: age,
      ));
    }
    return result;
  }
}
