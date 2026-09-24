/// Computes the traditional Abjad (Hisab al-Jummal) numeral value of an
/// Arabic string -- the classical letter-to-number system where each
/// Arabic letter carries a fixed numeric value (Alif=1, Ba=2, ... up to
/// Ghayn=1000). Diacritics (tashkeel), tatweel, and non-Arabic-letter
/// characters are ignored; hamza forms are folded to their base letter.
class AbjadCalculator {
  AbjadCalculator._();

  static const Map<String, int> _values = {
    'ا': 1, 'أ': 1, 'إ': 1, 'آ': 1, 'ء': 1, 'ٱ': 1,
    'ب': 2,
    'ج': 3,
    'د': 4,
    'ه': 5, 'ة': 5,
    'و': 6, 'ؤ': 6,
    'ز': 7,
    'ح': 8,
    'ط': 9,
    'ي': 10, 'ى': 10, 'ئ': 10,
    'ك': 20,
    'ل': 30,
    'م': 40,
    'ن': 50,
    'س': 60,
    'ع': 70,
    'ف': 80,
    'ص': 90,
    'ق': 100,
    'ر': 200,
    'ش': 300,
    'ت': 400,
    'ث': 500,
    'خ': 600,
    'ذ': 700,
    'ض': 800,
    'ظ': 900,
    'غ': 1000,
  };

  static String _stripDiacritics(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final isDiacritic = (rune >= 0x064B && rune <= 0x0652) ||
          rune == 0x0670 ||
          rune == 0x0640 ||
          (rune >= 0x06D6 && rune <= 0x06ED);
      if (!isDiacritic) buffer.writeCharCode(rune);
    }
    return buffer.toString();
  }

  static int value(String text) {
    final stripped = _stripDiacritics(text);
    var total = 0;
    for (final char in stripped.split('')) {
      total += _values[char] ?? 0;
    }
    return total;
  }
}
