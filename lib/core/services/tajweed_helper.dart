import 'package:flutter/material.dart';

/// Simplified, rule-based Tajweed color-coding applied directly to plain
/// vocalized (fully-diacritized) Arabic Unicode text -- NOT dependent on the
/// QCF page-image font system (whose data file, qcf4.zip, is missing from
/// the Al-Furkan source). Covers the most common, visually useful rules:
/// qalqalah, ghunnah, and noon-sakinah/tanween (idgham/iqlab/ikhfa). This is
/// intentionally not a scholarly-complete tajweed engine.
class TajweedColors {
  TajweedColors._();
  static const ghunnah = Color(0xFF2E7D32);
  static const idghamGhunnah = Color(0xFF1565C0);
  static const idghamNoGhunnah = Color(0xFF6A1B9A);
  static const ikhfa = Color(0xFFEF6C00);
  static const iqlab = Color(0xFFAD1457);
  static const qalqalah = Color(0xFFC62828);
}

class _Cluster {
  final String base;
  final String marks;
  final int start;
  final int end;
  _Cluster(this.base, this.marks, this.start, this.end);
}

class TajweedHelper {
  TajweedHelper._();

  static const _ikhfaLetters = '\u062A\u062B\u062C\u062F\u0630\u0632\u0633\u0634\u0635\u0636\u0637\u0638\u0641\u0642\u0643';
  static const _idghamGhunnahLetters = '\u064A\u0645\u0646\u0648';
  static const _idghamNoGhunnahLetters = '\u0644\u0631';
  static const _qalqalahLetters = '\u0642\u0637\u0628\u062C\u062F';

  static bool _isDiacritic(int r) =>
      (r >= 0x064B && r <= 0x065F) || r == 0x0670 || (r >= 0x06D6 && r <= 0x06ED) || (r >= 0x08D4 && r <= 0x08FF);

  static List<_Cluster> _clusters(String text) {
    final result = <_Cluster>[];
    var base = '';
    var marks = '';
    var startIdx = 0;
    var i = 0;
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (_isDiacritic(rune)) {
        marks += ch;
      } else {
        if (base.isNotEmpty || marks.isNotEmpty) {
          result.add(_Cluster(base, marks, startIdx, i));
        }
        base = ch;
        marks = '';
        startIdx = i;
      }
      i += ch.length;
    }
    if (base.isNotEmpty || marks.isNotEmpty) result.add(_Cluster(base, marks, startIdx, text.length));
    return result;
  }

  static List<InlineSpan> buildSpans(String text, TextStyle base) {
    final clusters = _clusters(text);
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var idx = 0; idx < clusters.length; idx++) {
      final c = clusters[idx];
      if (c.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, c.start), style: base));
      }
      Color? color;
      if (_qalqalahLetters.contains(c.base) && c.marks.contains('\u0652')) {
        color = TajweedColors.qalqalah;
      }
      if ((c.base == '\u0646' || c.base == '\u0645') && c.marks.contains('\u0651')) {
        color = TajweedColors.ghunnah;
      }
      final isNoonSakinah = c.base == '\u0646' && c.marks.contains('\u0652');
      final hasTanween = c.marks.contains('\u064B') || c.marks.contains('\u064C') || c.marks.contains('\u064D');
      if (isNoonSakinah || hasTanween) {
        var j = idx + 1;
        while (j < clusters.length && clusters[j].base.trim().isEmpty) {
          j++;
        }
        if (j < clusters.length) {
          final next = clusters[j].base;
          if (_idghamGhunnahLetters.contains(next)) {
            color = TajweedColors.idghamGhunnah;
          } else if (_idghamNoGhunnahLetters.contains(next)) {
            color = TajweedColors.idghamNoGhunnah;
          } else if (next == '\u0628') {
            color = TajweedColors.iqlab;
          } else if (_ikhfaLetters.contains(next)) {
            color = TajweedColors.ikhfa;
          }
        }
      }
      spans.add(TextSpan(
        text: text.substring(c.start, c.end),
        style: color == null ? base : base.copyWith(color: color),
      ));
      cursor = c.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return spans;
  }
}
