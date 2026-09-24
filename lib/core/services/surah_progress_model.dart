/// Maps "which ayah is playing + how far into it" onto ONE progress value for
/// the whole surah (or the played range), so the player can show surah-level
/// progress instead of restarting from 0 on every ayah.
///
/// No audio plugin is involved here on purpose: it is plain arithmetic, so it is
/// unit-testable and cannot itself disturb playback.
///
/// How it estimates: the length of a recitation is roughly proportional to the
/// number of letters. Each ayah therefore gets a weight = its letter count.
/// The progress BAR uses these weights (stable: it never jumps backwards when a
/// real duration becomes known). The TIME labels use real durations for ayahs
/// whose audio length is already known and letter-based estimates for the rest,
/// with the estimate calibrated on the ayahs that were actually measured.
double _clamp01(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);

int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

class SurahProgressModel {
  SurahProgressModel({
    List<double> weights = const [],
    int scopeStart = 1,
    int scopeEnd = 0,
  })  : _weights = weights,
        _scopeStart = scopeStart,
        _scopeEnd = scopeEnd == 0 ? weights.length : scopeEnd;

  /// Seconds of recitation per letter, used until real durations are measured.
  static const double defaultSecondsPerLetter = 0.42;

  List<double> _weights;
  int _scopeStart;
  int _scopeEnd;

  /// Real durations measured from the audio itself, keyed by ayah number.
  final Map<int, Duration> _known = {};

  /// Letter count of [text] (Arabic letters only; diacritics, spaces and
  /// Quranic annotation marks are ignored). Never below 1.
  static double weightOfText(String text) {
    var count = 0;
    for (final rune in text.runes) {
      if ((rune >= 0x0621 && rune <= 0x064A) || rune == 0x0671) count++;
    }
    return count > 0 ? count.toDouble() : 1.0;
  }

  bool get isEmpty => _weights.isEmpty;
  int get ayahCount => _weights.length;
  int get scopeStart => _scopeStart;
  int get scopeEnd => _scopeEnd;

  /// Replaces the weights (a new surah). Measured durations are cleared because
  /// they belong to a specific surah/reciter.
  void reset(List<double> weights) {
    _weights = weights;
    _scopeStart = 1;
    _scopeEnd = weights.length;
    _known.clear();
  }

  /// Limits progress to ayahs [start]..[end] (inclusive, 1-based). Passing null
  /// for [end] means "to the end of the surah".
  void setScope({int? start, int? end}) {
    final last = _weights.length;
    _scopeStart = _clampInt(start ?? 1, 1, last < 1 ? 1 : last);
    _scopeEnd = _clampInt(end ?? last, _scopeStart, last < _scopeStart ? _scopeStart : last);
  }

  void clearKnownDurations() => _known.clear();

  void setKnownDuration(int ayah, Duration duration) {
    if (duration > Duration.zero) _known[ayah] = duration;
  }

  Duration? knownDuration(int ayah) => _known[ayah];

  double weightOf(int ayah) {
    final i = ayah - 1;
    return (i >= 0 && i < _weights.length) ? _weights[i] : 1.0;
  }

  double get totalWeight {
    var sum = 0.0;
    for (var a = _scopeStart; a <= _scopeEnd; a++) {
      sum += weightOf(a);
    }
    return sum;
  }

  /// Progress through the scope, 0.0 - 1.0, for [ayah] being [position] into an
  /// ayah whose length is [duration] (pass zero when not yet known).
  double progress({required int ayah, required Duration position, required Duration duration}) {
    final total = totalWeight;
    if (total <= 0 || ayah < _scopeStart) return 0.0;
    if (ayah > _scopeEnd) return 1.0;
    var done = 0.0;
    for (var a = _scopeStart; a < ayah; a++) {
      done += weightOf(a);
    }
    final fraction = duration.inMilliseconds > 0
        ? _clamp01(position.inMilliseconds / duration.inMilliseconds)
        : 0.0;
    return _clamp01((done + weightOf(ayah) * fraction) / total);
  }

  /// Seconds per letter, calibrated on the ayahs measured so far in the scope.
  double get secondsPerLetter {
    var seconds = 0.0;
    var letters = 0.0;
    for (var a = _scopeStart; a <= _scopeEnd; a++) {
      final d = _known[a];
      if (d != null) {
        seconds += d.inMilliseconds / 1000.0;
        letters += weightOf(a);
      }
    }
    return (letters > 0 && seconds > 0) ? seconds / letters : defaultSecondsPerLetter;
  }

  Duration _lengthOf(int ayah, double spl) =>
      _known[ayah] ?? Duration(milliseconds: (weightOf(ayah) * spl * 1000).round());

  /// Estimated length of the whole scope.
  Duration get estimatedTotal {
    final spl = secondsPerLetter;
    var ms = 0;
    for (var a = _scopeStart; a <= _scopeEnd; a++) {
      ms += _lengthOf(a, spl).inMilliseconds;
    }
    return Duration(milliseconds: ms);
  }

  /// True when every ayah in the scope has a measured duration (the total is
  /// then exact rather than an estimate).
  bool get isTotalExact {
    for (var a = _scopeStart; a <= _scopeEnd; a++) {
      if (!_known.containsKey(a)) return false;
    }
    return true;
  }

  /// Time already played inside the scope.
  Duration elapsed({required int ayah, required Duration position, required Duration duration}) {
    if (ayah < _scopeStart) return Duration.zero;
    final spl = secondsPerLetter;
    var ms = 0;
    final upTo = ayah > _scopeEnd ? _scopeEnd + 1 : ayah;
    for (var a = _scopeStart; a < upTo; a++) {
      ms += _lengthOf(a, spl).inMilliseconds;
    }
    if (ayah <= _scopeEnd) {
      final cap = duration > Duration.zero ? duration.inMilliseconds : position.inMilliseconds;
      ms += position.inMilliseconds < cap ? position.inMilliseconds : cap;
    }
    return Duration(milliseconds: ms);
  }

  /// Which ayah a surah-level [fraction] (0.0 - 1.0) falls in, and how far
  /// through that ayah (0.0 - 1.0). Used for seeking with the surah slider.
  ({int ayah, double within}) locate(double fraction) {
    final f = _clamp01(fraction);
    final target = f * totalWeight;
    var acc = 0.0;
    for (var a = _scopeStart; a <= _scopeEnd; a++) {
      final w = weightOf(a);
      if (target <= acc + w || a == _scopeEnd) {
        final within = w > 0 ? _clamp01((target - acc) / w) : 0.0;
        return (ayah: a, within: within);
      }
      acc += w;
    }
    return (ayah: _scopeEnd, within: 1.0);
  }
}
