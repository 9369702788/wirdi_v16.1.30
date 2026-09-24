/// Data models for the HadeethEnc.com hadith encyclopedia integration.
/// Kept completely separate from HadithModel (the existing 40 Hadith of
/// an-Nawawi, sourced from a different dataset) so neither can ever
/// collide or interfere with the other.
class HadeethCategoryModel {
  final String id;
  final String title;
  final String? parentId;
  final int hadeethsCount;

  const HadeethCategoryModel({
    required this.id,
    required this.title,
    this.parentId,
    required this.hadeethsCount,
  });

  factory HadeethCategoryModel.fromJson(Map<String, dynamic> json) {
    return HadeethCategoryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      hadeethsCount: int.tryParse(json['hadeeths_count']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'parent_id': parentId,
        'hadeeths_count': hadeethsCount.toString(),
      };
}

class HadeethSummaryModel {
  final String id;
  final String title;

  const HadeethSummaryModel({required this.id, required this.title});

  factory HadeethSummaryModel.fromJson(Map<String, dynamic> json) {
    return HadeethSummaryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  String get uid => 'hadeethenc_$id';
}

/// Full hadith detail. References (which contains authenticity grading
/// as published by HadeethEnc) is displayed verbatim, never parsed or
/// re-labelled, per the user's explicit instruction not to guess a
/// hadith grade.
class HadeethDetailModel {
  final String id;
  final String title;
  final String matn;
  final String? explanation;
  final String? fawaed;
  final String? wordMeanings;
  final String? references;

  const HadeethDetailModel({
    required this.id,
    required this.title,
    required this.matn,
    this.explanation,
    this.fawaed,
    this.wordMeanings,
    this.references,
  });

  static String? _nonEmpty(dynamic v) {
    final s = v?.toString();
    return (s == null || s.trim().isEmpty) ? null : s;
  }

  factory HadeethDetailModel.fromJson(Map<String, dynamic> json) {
    return HadeethDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      matn: json['matn']?.toString() ?? json['hadeeth']?.toString() ?? '',
      explanation: _nonEmpty(json['explanation']),
      fawaed: _nonEmpty(json['fawaed']) ?? _nonEmpty(json['hints']),
      wordMeanings: _nonEmpty(json['word_meanings']) ?? _nonEmpty(json['words_meanings']),
      references: _nonEmpty(json['references']) ?? _nonEmpty(json['reference']) ?? _nonEmpty(json['attribution']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'matn': matn,
        'explanation': explanation,
        'fawaed': fawaed,
        'word_meanings': wordMeanings,
        'references': references,
      };

  String get uid => 'hadeethenc_$id';
}
