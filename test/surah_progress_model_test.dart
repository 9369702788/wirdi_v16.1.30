import 'package:flutter_test/flutter_test.dart';
import 'package:wirdi/core/services/surah_progress_model.dart';

void main() {
  group('SurahProgressModel.weightOfText', () {
    test('counts Arabic letters only, ignoring diacritics and spaces', () {
      // "بسم الله" = 7 letters (ب س م ا ل ل ه)
      expect(SurahProgressModel.weightOfText('بِسْمِ اللَّهِ'), 7.0);
    });
    test('never returns less than 1', () {
      expect(SurahProgressModel.weightOfText(''), 1.0);
      expect(SurahProgressModel.weightOfText('123 ...'), 1.0);
    });
  });

  group('progress', () {
    // 4 ayahs with weights 10, 20, 30, 40  (total 100)
    SurahProgressModel model() => SurahProgressModel(weights: [10, 20, 30, 40]);

    test('starts at 0 and ends at 1', () {
      final m = model();
      expect(m.progress(ayah: 1, position: Duration.zero, duration: const Duration(seconds: 5)), 0.0);
      expect(m.progress(ayah: 4, position: const Duration(seconds: 5), duration: const Duration(seconds: 5)), 1.0);
    });

    test('is measured across the whole surah, not per ayah', () {
      final m = model();
      // Start of ayah 3 = weights of ayah 1+2 = 30 / 100
      expect(m.progress(ayah: 3, position: Duration.zero, duration: const Duration(seconds: 8)), closeTo(0.30, 1e-9));
      // Halfway through ayah 3 = (30 + 15) / 100
      expect(m.progress(ayah: 3, position: const Duration(seconds: 4), duration: const Duration(seconds: 8)), closeTo(0.45, 1e-9));
    });

    test('never decreases as playback advances', () {
      final m = model();
      var last = -1.0;
      for (var ayah = 1; ayah <= 4; ayah++) {
        for (var s = 0; s <= 10; s++) {
          final p = m.progress(ayah: ayah, position: Duration(seconds: s), duration: const Duration(seconds: 10));
          expect(p, greaterThanOrEqualTo(last));
          last = p;
        }
      }
    });

    test('unknown ayah duration does not break the value', () {
      final m = model();
      expect(m.progress(ayah: 2, position: const Duration(seconds: 3), duration: Duration.zero), closeTo(0.10, 1e-9));
    });

    test('respects a played range', () {
      final m = model()..setScope(start: 2, end: 3); // weights 20 + 30 = 50
      expect(m.totalWeight, 50.0);
      expect(m.progress(ayah: 2, position: Duration.zero, duration: const Duration(seconds: 5)), 0.0);
      expect(m.progress(ayah: 3, position: Duration.zero, duration: const Duration(seconds: 5)), closeTo(0.4, 1e-9));
    });
  });

  group('locate', () {
    test('maps a surah fraction to ayah and position inside it', () {
      final m = SurahProgressModel(weights: [10, 20, 30, 40]);
      final a = m.locate(0.0);
      expect(a.ayah, 1);
      expect(a.within, 0.0);
      final b = m.locate(0.45); // inside ayah 3 (30..60): (45-30)/30 = 0.5
      expect(b.ayah, 3);
      expect(b.within, closeTo(0.5, 1e-9));
      final c = m.locate(1.0);
      expect(c.ayah, 4);
      expect(c.within, closeTo(1.0, 1e-9));
    });

    test('is the inverse of progress()', () {
      final m = SurahProgressModel(weights: [7, 13, 21, 5, 34]);
      for (final f in [0.05, 0.2, 0.5, 0.77, 0.95]) {
        final t = m.locate(f);
        final back = m.progress(
          ayah: t.ayah,
          position: Duration(milliseconds: (t.within * 1000).round()),
          duration: const Duration(seconds: 1),
        );
        expect(back, closeTo(f, 1e-3));
      }
    });
  });

  group('time labels', () {
    test('elapsed uses measured durations and an estimate for the rest', () {
      final m = SurahProgressModel(weights: [10, 20, 30])
        ..setKnownDuration(1, const Duration(seconds: 5))
        ..setKnownDuration(2, const Duration(seconds: 10));
      // Playing ayah 3, 4 s in: 5 + 10 + 4
      expect(
        m.elapsed(ayah: 3, position: const Duration(seconds: 4), duration: const Duration(seconds: 15)),
        const Duration(seconds: 19),
      );
      // Calibrated pace = 15 s / 30 letters = 0.5 s per letter -> ayah 3 estimated 15 s.
      expect(m.estimatedTotal, const Duration(seconds: 30));
      expect(m.isTotalExact, isFalse);
      m.setKnownDuration(3, const Duration(seconds: 14));
      expect(m.isTotalExact, isTrue);
      expect(m.estimatedTotal, const Duration(seconds: 29));
    });
  });
}
