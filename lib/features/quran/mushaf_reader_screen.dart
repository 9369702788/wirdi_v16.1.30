import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/data/app_sources.dart';
import '../../core/models/quran_models.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/arabic_text_utils.dart';
import '../../core/services/audio_download_service.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/services/quran_audio_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/services/quran_translation_repository.dart';
import '../../core/services/tafsir_repository.dart';
import '../../core/services/sajda_tracker_service.dart';
import '../../core/services/word_by_word_repository.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/tajweed_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/bismillah.dart';

String _t(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

const Map<String, String> _quranFontFamilies = {
  'default': '',
  'QuranQPCHafs': 'QuranQPCHafs',
  'QuranKFGQPCUthmanic': 'QuranKFGQPCUthmanic',
};

/// Quran reader built on Wirdi's own QuranRepository (same source as the
/// existing quran_screen.dart) and wired directly into the existing,
/// already-proven QuranAudioService -- so playback, background/notification
/// controls, and offline downloads all reuse tested app-wide code instead of
/// a second, separate audio stack.
class MushafReaderScreen extends StatefulWidget {
  const MushafReaderScreen({super.key});
  @override
  State<MushafReaderScreen> createState() => _MushafReaderScreenState();
}

class _MushafReaderScreenState extends State<MushafReaderScreen> {
  List<SurahModel>? _allSurahs;
  String? _error;
  SurahModel? _selectedSurah;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _searchInVerses = false;
  bool _nightMode = false;
  // NEW: "calm reading mode" -- hides the whole-surah playback header
  // bar and removes the card-like tinted/rounded box around each
  // non-playing ayah, so the page reads more like continuous open
  // text (closer to a physical mushaf) instead of a list of discrete
  // UI cards. The currently-playing ayah's highlight is kept in both
  // modes since that's functional feedback, not decorative chrome.
  bool _focusMode = false;

  Map<int, String>? _translationData;
  bool _loadingTranslation = false;
  String? _translationLoadError;
  int? _translationSurahNumber;

  Map<String, String>? _tafsirData;
  bool _loadingTafsir = false;
  final Set<int> _expandedTafsirAyahs = {};

  final Set<int> _expandedWordsAyahs = {};
  final Map<int, List<WbwWord>> _wbwCache = {};
  bool _loadingWbw = false;
  Timer? _sleepTimer;
  int? _sleepMinutesRemaining;
  Map<String, dynamic>? _lastReadPosition;
  Set<int> _pinnedSurahs = {};

  @override
  void initState() {
    super.initState();
    _load();
    _loadPinnedSurahs();
    quranAudio.addListener(_onAudioChanged);
  }

  Future<void> _loadPinnedSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('pinned_surahs') ?? [];
    if (mounted) setState(() => _pinnedSurahs = saved.map((e) => int.tryParse(e) ?? 0).toSet());
  }

  Future<void> _togglePin(int surahNumber) async {
    setState(() {
      if (_pinnedSurahs.contains(surahNumber)) {
        _pinnedSurahs.remove(surahNumber);
      } else {
        _pinnedSurahs.add(surahNumber);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pinned_surahs', _pinnedSurahs.map((e) => e.toString()).toList());
  }

  @override
  void dispose() {
    quranAudio.removeListener(_onAudioChanged);
    _sleepTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onAudioChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final surahs = await QuranRepository.load();
      final lastPosition = await QuranRepository.getLastReadPosition();
      if (!mounted) return;
      setState(() {
        _allSurahs = surahs;
        _lastReadPosition = lastPosition;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = _t(context, '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0646\u0635 \u0627\u0644\u0642\u0631\u0622\u0646. \u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u062a\u0635\u0627\u0644\u0643 \u0648\u062d\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.', 'Could not load the Quran text. Check your connection and try again.'));
    }
  }

  void _startSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    setState(() => _sleepMinutesRemaining = minutes);
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      quranAudio.stop();
      if (mounted) setState(() => _sleepMinutesRemaining = null);
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    setState(() => _sleepMinutesRemaining = null);
  }

  Future<void> _downloadSurah(SurahModel surah, {bool isResume = false}) async {
    final allSurahs = _allSurahs;
    if (allSurahs == null) return;

    // Show the estimated file size before starting, using the same
    // per-ayah average (~0.4 MB) so the user can decide before spending data.
    final estimatedMb = (surah.ayahs.length * 0.4).toStringAsFixed(1);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(context, '\u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0633\u0648\u0631\u0629', 'Download surah')),
        content: Text(_t(context,
            '\u062d\u062c\u0645 \u0627\u0644\u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u062a\u0642\u0631\u064a\u0628\u064a: \u0644 $estimatedMb \u0645\u064a\u062c\u0627\u0628\u0627\u064a\u062a. \u0647\u0644 \u062a\u0631\u064a\u062f \u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629\u061f',
            'Estimated download size: $estimatedMb MB. Continue?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t(context, 'إلغاء', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_t(context, 'تحميل', 'Download')),
          ),
        ],
      ),
    );
    if (!isResume && proceed != true) return;
    if (!mounted) return;

    bool cancelled = false;
    bool paused = false;
    final progress = ValueNotifier<double>(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(context, '\u062c\u0627\u0631\u064a \u0627\u0644\u062a\u062d\u0645\u064a\u0644...', 'Downloading...')),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, value, __) => LinearProgressIndicator(value: value == 0 ? null : value),
        ),
        actions: [
          TextButton(
            onPressed: () {
              paused = true;
              Navigator.of(dialogContext).pop();
            },
            child: Text(_t(context, '\u0625\u064a\u0642\u0627\u0641\u0020\u0645\u0624\u0642\u062a', 'Pause')),
          ),
          TextButton(
            onPressed: () {
              cancelled = true;
              Navigator.of(dialogContext).pop();
            },
            child: Text(_t(context, '\u0625\u0644\u063a\u0627\u0621', 'Cancel')),
          ),
        ],
      ),
    );

    await AudioDownloadService.downloadSurah(
      reciterId: appSettings.reciterId,
      surah: surah,
      allSurahs: allSurahs,
      onProgress: (done, total) => progress.value = total == 0 ? 0 : done / total,
      isCancelled: () => cancelled || paused,
    );

    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    if (!cancelled && !paused) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(context, '\u062a\u0645\u0020\u062a\u062d\u0645\u064a\u0644\u0020\u0627\u0644\u0633\u0648\u0631\u0629\u0020\u0644\u0644\u0627\u0633\u062a\u0645\u0627\u0639\u0020\u0628\u062f\u0648\u0646\u0020\u0627\u062a\u0635\u0627\u0644', 'Surah downloaded for offline listening'))),
      );
    } else if (paused) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(context, '\u062a\u0645\u0020\u0625\u064a\u0642\u0627\u0641\u0020\u0627\u0644\u062a\u062d\u0645\u064a\u0644\u0020\u0645\u0624\u0642\u062a\u064b\u0627\u002e\u0020\u0627\u0636\u063a\u0637\u0020\u0022\u0627\u0633\u062a\u0626\u0646\u0627\u0641\u0022\u0020\u0644\u0644\u0645\u062a\u0627\u0628\u0639\u0629\u0020\u0645\u0646\u0020\u062d\u064a\u062b\u0020\u062a\u0648\u0642\u0641\u062a', 'Download paused. Tap Resume to continue where you left off')),
          action: SnackBarAction(
            label: _t(context, '\u0627\u0633\u062a\u0626\u0646\u0627\u0641', 'Resume'),
            onPressed: () => _downloadSurah(surah, isResume: true),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _showRangeDialog(SurahModel surah) async {
    final allSurahs = _allSurahs;
    if (allSurahs == null) return;
    final maxAyah = surah.ayahs.length;
    int start = 1;
    int end = maxAyah;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_t(context, '\u062a\u0634\u063a\u064a\u0644 \u0646\u0637\u0627\u0642 \u0622\u064a\u0627\u062a', 'Play a verse range')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_t(context, '\u0645\u0646 \u0622\u064a\u0629 $start \u0625\u0644\u0649 \u0622\u064a\u0629 $end', 'From ayah $start to ayah $end')),
            RangeSlider(
              values: RangeValues(start.toDouble(), end.toDouble()),
              min: 1, max: maxAyah.toDouble(),
              divisions: maxAyah > 1 ? maxAyah - 1 : 1,
              onChanged: (values) => setDialogState(() {
                start = values.start.round();
                end = values.end.round();
              }),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(_t(context, '\u0625\u0644\u063a\u0627\u0621', 'Cancel'))),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(_t(context, '\u062a\u0634\u063a\u064a\u0644', 'Play'))),
          ],
        ),
      ),
    );
    if (result == true) {
      quranAudio.playRange(surah, allSurahs, start, end);
    }
  }

  Future<void> _showRepeatDialog({required bool forSurah}) async {
    final options = [1, 2, 3, 5, 10, null];
    final choice = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(_t(context, '\u0639\u062f\u062f \u0645\u0631\u0627\u062a \u0627\u0644\u062a\u0643\u0631\u0627\u0631', 'Repeat count')),
        children: [
          for (final n in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, n),
              child: Text(n == null ? _t(context, '\u0644\u0627 \u0646\u0647\u0627\u0626\u064a (\u221e)', 'Infinite (\u221e)') : _t(context, '$n \u0645\u0631\u0627\u062a', '$n times')),
            ),
        ],
      ),
    );
    quranAudio.setRepeatCount(choice);
    if (forSurah) {
      if (!quranAudio.repeatSurah) quranAudio.toggleRepeatSurah();
    } else {
      if (!quranAudio.repeatCurrent) quranAudio.toggleRepeat();
    }
  }

  void _showReaderOptionsSheet(BuildContext context, SurahModel? surah) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              leading: const Icon(Icons.font_download_outlined),
              title: Text(_t(context, 'الخط', 'Font')),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickFontDialog();
              },
            ),
            ListTile(
              leading: Icon(_nightMode ? Icons.nightlight_round : Icons.nightlight_outlined),
              title: Text(_t(context, 'وضع القراءة الليلية', 'Night reading mode')),
              trailing: Switch(
                value: _nightMode,
                onChanged: (v) {
                  setState(() => _nightMode = v);
                  Navigator.pop(sheetContext);
                },
              ),
              onTap: () {
                setState(() => _nightMode = !_nightMode);
                Navigator.pop(sheetContext);
              },
            ),
            if (_selectedSurah != null)
              ListTile(
                leading: Icon(Icons.self_improvement, color: _focusMode ? AppColors.primaryEmerald : null),
                title: Text(_t(context, 'وضع القراءة الهادئة', 'Calm reading mode')),
                trailing: Switch(
                  value: _focusMode,
                  onChanged: (v) {
                    setState(() => _focusMode = v);
                    Navigator.pop(sheetContext);
                  },
                ),
                onTap: () {
                  setState(() => _focusMode = !_focusMode);
                  Navigator.pop(sheetContext);
                },
              ),
            if (_selectedSurah != null)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(_t(context, 'ملخص السورة', 'Surah summary')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showSurahSummary(_selectedSurah!);
                },
              ),
            if (surah != null) ...[
              ListTile(
                leading: const Icon(Icons.speed),
                title: Text(_t(context, 'سرعة التلاوة', 'Playback speed')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickSpeedDialog();
                },
              ),
              ListTile(
                leading: Icon(
                  quranAudio.repeatSurah || quranAudio.repeatCurrent ? Icons.repeat_on_rounded : Icons.repeat_rounded,
                  color: (quranAudio.repeatSurah || quranAudio.repeatCurrent) ? AppColors.goldAccent : null,
                ),
                title: Text(_t(context, 'تكرار', 'Repeat')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRepeatDialog(forSurah: quranAudio.playingWholeSurah);
                },
              ),
              ListTile(
                leading: Icon(_sleepMinutesRemaining != null ? Icons.bedtime : Icons.bedtime_outlined),
                title: Text(_t(context, 'مؤقت النوم', 'Sleep timer')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickSleepTimerDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(_t(context, 'تحميل للاستماع بدون اتصال', 'Download for offline')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _downloadSurah(surah);
                },
              ),
              ListTile(
                leading: const Icon(Icons.linear_scale),
                title: Text(_t(context, 'تشغيل نطاق آيات', 'Play a verse range')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRangeDialog(surah);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _pickFontDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(_t(context, 'اختر الخط', 'Choose font')),
        children: [
          for (final key in _quranFontFamilies.keys)
            SimpleDialogOption(
              onPressed: () {
                appSettings.setQuranFontFamily(key);
                Navigator.pop(dialogContext);
              },
              child: Row(children: [
                if (appSettings.quranFontFamily == key) const Icon(Icons.check, size: 18) else const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(key == 'default' ? _t(context, 'افتراضي', 'Default') : key.replaceFirst('Quran', '')),
              ]),
            ),
        ],
      ),
    );
  }

  void _pickSpeedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(_t(context, 'سرعة التلاوة', 'Playback speed')),
        children: [
          for (final rate in const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
            SimpleDialogOption(
              onPressed: () {
                quranAudio.setSpeed(rate);
                Navigator.pop(dialogContext);
              },
              child: Text(rate == 1.0 ? _t(context, '1.0x (عادي)', '1.0x (normal)') : '${rate}x'),
            ),
        ],
      ),
    );
  }

  void _pickSleepTimerDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(_t(context, 'مؤقت النوم', 'Sleep timer')),
        children: [
          if (_sleepMinutesRemaining != null)
            SimpleDialogOption(
              onPressed: () {
                _cancelSleepTimer();
                Navigator.pop(dialogContext);
              },
              child: Text(_t(context, 'إلغاء المؤقت', 'Cancel timer')),
            ),
          for (final minutes in const [5, 10, 15, 30])
            SimpleDialogOption(
              onPressed: () {
                _startSleepTimer(minutes);
                Navigator.pop(dialogContext);
              },
              child: Text(_t(context, '$minutes دقيقة', '$minutes minutes')),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surah = _selectedSurah;
    return Scaffold(
      backgroundColor: _nightMode ? const Color(0xFF1A1410) : null,
      appBar: AppBar(
        title: Text(surah == null ? _t(context, '\u0642\u0627\u0631\u0626 \u0627\u0644\u0642\u0631\u0622\u0646', 'Quran Reader') : surah.name),
        centerTitle: true,
        leading: surah != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedSurah = null))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: _t(context, 'خيارات القراءة', 'Reading options'),
            onPressed: () => _showReaderOptionsSheet(context, surah),
          ),
        ],
      ),
      body: _buildBody(surah),
    );
  }

  Widget _buildBody(SurahModel? surah) {
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)));
    }
    final allSurahs = _allSurahs;
    if (allSurahs == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (surah == null) {
      return Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _t(context, '\u0627\u0628\u062d\u062b \u0639\u0646 \u0633\u0648\u0631\u0629 \u0623\u0648 \u0622\u064a\u0629...', 'Search for a surah or ayah...'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(_t(context, '\u0627\u0644\u0633\u0648\u0631', 'Surahs')),
                  selected: !_searchInVerses,
                  onSelected: (_) => setState(() => _searchInVerses = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text(_t(context, '\u0627\u0644\u0622\u064a\u0627\u062a (\u0646\u0635 \u0643\u0627\u0645\u0644)', 'Verses (full text)')),
                  selected: _searchInVerses,
                  onSelected: (_) => setState(() => _searchInVerses = true),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              _searchInVerses
                  ? _t(context, 'ابحث بأي كلمة من نص الآية نفسه، أيًا كانت السورة', "Search by any word from the verse's own text, in any surah")
                  : _t(context, 'ابحث باسم السورة أو رقمها فقط', "Search by the surah's name or number only"),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
            ),
          ]),
        ),
        Expanded(
          child: _shouldShowVerseResults(allSurahs)
              ? _buildVerseSearchResults(allSurahs, _query.trim())
              : _buildSurahList(allSurahs),
        ),
      ]);
    }
    return _buildVerseList(surah, allSurahs);
  }

  /// If the user explicitly picked "Verses" mode, always search verse
  /// text. If they're in the default "Surahs" mode but their query matches
  /// no surah name/number at all, fall back to searching verse content too
  /// -- so typing part of an ayah always finds something instead of
  /// silently showing an empty surah list.
  bool _shouldShowVerseResults(List<SurahModel> allSurahs) {
    final q = _query.trim();
    if (q.isEmpty) return false;
    if (_searchInVerses) return true;
    final anySurahMatch = allSurahs.any((s) =>
        ArabicTextUtils.contains(s.name, q) ||
        s.englishName.toLowerCase().contains(q.toLowerCase()) ||
        s.number.toString() == q);
    return !anySurahMatch;
  }

  Widget _buildSurahList(List<SurahModel> allSurahs) {
    final filtered = _query.trim().isEmpty
        ? allSurahs
        : allSurahs.where((s) {
            final q = _query.trim();
            return ArabicTextUtils.contains(s.name, q) ||
                s.englishName.toLowerCase().contains(q.toLowerCase()) ||
                s.number.toString() == q;
          }).toList();
    final lastPos = _lastReadPosition;
    SurahModel? lastSurah;
    if (lastPos != null) {
      final num = lastPos['surah'] as int?;
      if (num != null) {
        for (final s in allSurahs) {
          if (s.number == num) {
            lastSurah = s;
            break;
          }
        }
      }
    }
    final showContinueCard = lastSurah != null && _query.trim().isEmpty;
    filtered.sort((a, b) {
      final aPin = _pinnedSurahs.contains(a.number) ? 0 : 1;
      final bPin = _pinnedSurahs.contains(b.number) ? 0 : 1;
      if (aPin != bPin) return aPin.compareTo(bPin);
      return a.number.compareTo(b.number);
    });
    return ListView.builder(
      itemCount: filtered.length + (showContinueCard ? 1 : 0),
      itemBuilder: (context, index) {
        if (showContinueCard) {
          if (index == 0) {
            return _buildContinueReadingCard(lastSurah!);
          }
          index -= 1;
        }
        final s = filtered[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.1),
            child: Text('${s.number}', style: TextStyle(color: AppColors.primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          title: Text(
            s.name,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 22, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? '${s.englishName} · ${s.ayahs.length} آيات'
                : '${s.englishName} · ${s.ayahs.length} verses',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
          trailing: IconButton(
            icon: Icon(
              _pinnedSurahs.contains(s.number) ? Icons.push_pin : Icons.push_pin_outlined,
              size: 18,
              color: _pinnedSurahs.contains(s.number) ? AppColors.primaryEmerald : AppColors.mutedText,
            ),
            onPressed: () => _togglePin(s.number),
          ),
          onTap: () {
            setState(() => _selectedSurah = s);
            QuranRepository.saveLastReadPosition(s.number, 1);
          },
        );
      },
    );
  }

  Future<void> _showSurahSummary(SurahModel surah) async {
    final summary = await QuranRepository.getSurahSummary(surah.number);
    if (!mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (summary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'ملخص هذه السورة غير متاح بعد' : 'Summary not available for this surah yet')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${summary['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${isAr ? 'النوع' : 'Type'}: ${summary['type']}'),
            const SizedBox(height: 6),
            Text('${isAr ? 'عدد الآيات' : 'Verses'}: ${summary['verses']}'),
            const SizedBox(height: 6),
            Text('${isAr ? 'الموضوع' : 'Theme'}: ${summary['theme']}'),
            const SizedBox(height: 6),
            Text('${isAr ? 'وقت القراءة التقديري' : 'Estimated reading time'}: ${((summary['verses'] as int) * 15 / 60).ceil()} ${isAr ? 'دقيقة' : 'min'}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(isAr ? 'إغلاق' : 'Close'))],
      ),
    );
  }

  Widget _buildContinueReadingCard(SurahModel lastSurah) {
    return Card(
      color: AppColors.primaryEmerald.withValues(alpha: 0.08),
      child: ListTile(
        leading: Icon(Icons.play_circle_outline, color: AppColors.primaryEmerald),
        title: Text(_t(context, 'متابعة القراءة', 'Continue reading')),
        subtitle: Text(lastSurah.name, textDirection: TextDirection.rtl),
        onTap: () {
          setState(() => _selectedSurah = lastSurah);
          QuranRepository.saveLastReadPosition(lastSurah.number, 1);
        },
      ),
    );
  }

  Widget _buildVerseSearchResults(List<SurahModel> allSurahs, String query) {
    final results = <MapEntry<SurahModel, AyahModel>>[];
    for (final s in allSurahs) {
      for (final a in s.ayahs) {
        if (ArabicTextUtils.contains(a.text, query)) {
          results.add(MapEntry(s, a));
          if (results.length >= 200) break;
        }
      }
      if (results.length >= 200) break;
    }
    if (results.isEmpty) {
      return Center(child: Text(_t(context, '\u0644\u0627 \u062a\u0648\u062c\u062f \u0646\u062a\u0627\u0626\u062c', 'No results')));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
        return ListTile(
          title: Text(entry.value.text, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18, height: 1.8)),
          subtitle: Text('${entry.key.name} \u2014 ${_t(context, '\u0622\u064a\u0629', 'Ayah')} ${entry.value.number}'),
          onTap: () {
            setState(() => _selectedSurah = entry.key);
            QuranRepository.saveLastReadPosition(entry.key.number, 1);
          },
        );
      },
    );
  }

  Future<void> _toggleTafsir(int ayahNumber) async {
    if (_expandedTafsirAyahs.contains(ayahNumber)) {
      setState(() => _expandedTafsirAyahs.remove(ayahNumber));
      return;
    }
    if (_tafsirData == null) {
      setState(() => _loadingTafsir = true);
      try {
        _tafsirData = await TafsirRepository.load();
      } catch (e, st) {
        AppLogger.error('Failed to load tafsir (Mushaf reader)', error: e, stackTrace: st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_t(context, '\u062a\u0639\u0630\u0651\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u062a\u0641\u0633\u064a\u0631', 'Failed to load tafsir')),
              action: SnackBarAction(
                label: _t(context, '\u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629', 'Retry'),
                onPressed: () => _toggleTafsir(ayahNumber),
              ),
            ),
          );
        }
        setState(() => _loadingTafsir = false);
        return;
      }
      setState(() => _loadingTafsir = false);
    }
    setState(() => _expandedTafsirAyahs.add(ayahNumber));
  }

  Widget _buildTafsirBlock(BuildContext context, int surahNumber, int ayahNumber) {
    final text = _tafsirData == null ? null : TafsirRepository.tafsirFor(_tafsirData!, surahNumber, ayahNumber);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _nightMode ? Colors.white10 : AppColors.goldAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text ?? _t(context, '\u0644\u0627 \u064a\u0648\u062c\u062f \u062a\u0641\u0633\u064a\u0631 \u0645\u062a\u0627\u062d', 'No tafsir available'),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(fontSize: 14, color: _nightMode ? Colors.white70 : AppColors.mutedText),
      ),
    );
  }

  Future<void> _toggleWords(int surahNumber, int ayahNumber) async {
    if (_expandedWordsAyahs.contains(ayahNumber)) {
      setState(() => _expandedWordsAyahs.remove(ayahNumber));
      return;
    }
    if (!_wbwCache.containsKey(ayahNumber)) {
      setState(() => _loadingWbw = true);
      try {
        _wbwCache[ayahNumber] = await WordByWordRepository.wordsFor(surahNumber, ayahNumber);
      } catch (e, st) {
        AppLogger.error('Failed to load word-by-word data', error: e, stackTrace: st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_t(context, '\u062a\u0639\u0630\u0651\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0643\u0644\u0645\u0627\u062a', 'Failed to load words'))),
          );
        }
        setState(() => _loadingWbw = false);
        return;
      }
      setState(() => _loadingWbw = false);
    }
    setState(() => _expandedWordsAyahs.add(ayahNumber));
  }

  Widget _buildWordsBlock(int ayahNumber) {
    final words = _wbwCache[ayahNumber] ?? [];
    if (words.isEmpty) {
      return Text(_t(context, '\u0644\u0627 \u062a\u0648\u062c\u062f \u0628\u064a\u0627\u0646\u0627\u062a \u0645\u062a\u0627\u062d\u0629', 'No data available'), style: TextStyle(color: _nightMode ? Colors.white70 : AppColors.mutedText));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final w in words)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _nightMode ? Colors.white10 : AppColors.goldAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(w.arabic, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18)),
              if (w.meaning.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(w.meaning, style: TextStyle(fontSize: 11, color: _nightMode ? Colors.white70 : AppColors.mutedText)),
              ],
            ]),
          ),
      ],
    );
  }

  Future<void> _confirmSajda(int surahNumber, int ayahNumber) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? '\u0633\u062c\u062f\u0629 \u062a\u0644\u0627\u0648\u0629' : 'Sajda Tilawah'),
        content: Text(isAr ? '\u0647\u0644 \u0633\u062c\u062f\u062a \u0627\u0644\u0622\u0646\u061f' : 'Did you prostrate just now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(isAr ? '\u0625\u0644\u063a\u0627\u0621' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(isAr ? '\u0646\u0639\u0645' : 'Yes')),
        ],
      ),
    );
    if (confirmed == true) {
      await SajdaTrackerService.logSajda(surahNumber, ayahNumber);
      final total = await SajdaTrackerService.totalCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? '\u062a\u0642\u0628\u0651\u0644 \u0627\u0644\u0644\u0647 \u2014 \u0625\u062c\u0645\u0627\u0644\u064a \u0633\u062c\u062f\u0627\u062a \u0627\u0644\u062a\u0644\u0627\u0648\u0629: $total' : 'Accepted, God willing \u2014 total sajdas: $total')),
        );
      }
    }
  }

  String? _translationKeyForLocale(BuildContext context) =>
      AppSources.quranEncTranslationKeyFor(Localizations.localeOf(context).languageCode);

  void _loadTranslationIfNeeded(BuildContext context, SurahModel surah) {
    final translationKey = _translationKeyForLocale(context);
    if (translationKey == null) return;
    if (_translationSurahNumber == surah.number && (_translationData != null || _loadingTranslation)) {
      return;
    }
    _loadTranslation(translationKey, surah.number);
  }

  Future<void> _loadTranslation(String translationKey, int surahNumber) async {
    setState(() {
      _loadingTranslation = true;
      _translationLoadError = null;
      _translationSurahNumber = surahNumber;
    });
    try {
      final data = await QuranTranslationRepository.loadSurah(
        translationKey: translationKey,
        surahNumber: surahNumber,
      );
      if (mounted) setState(() => _translationData = data);
    } catch (e, st) {
      AppLogger.error('Failed to load Quran translation (Mushaf reader)', error: e, stackTrace: st);
      if (mounted) setState(() => _translationLoadError = translationKey);
    } finally {
      if (mounted) setState(() => _loadingTranslation = false);
    }
  }

  Widget _buildTranslationBlock(BuildContext context, int ayahNumber) {
    if (_loadingTranslation && _translationData == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_translationLoadError != null && _translationData == null) {
      return Row(children: [
        Expanded(
          child: Text(
            _t(context, '\u062a\u0639\u0630\u0651\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u062a\u0631\u062c\u0645\u0629', 'Failed to load translation'),
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ),
        TextButton(
          onPressed: () => _loadTranslation(_translationLoadError!, _translationSurahNumber ?? 0),
          child: Text(_t(context, '\u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629', 'Retry'), style: const TextStyle(fontSize: 12)),
        ),
      ]);
    }
    final text = QuranTranslationRepository.translationFor(_translationData, ayahNumber);
    return Text(
      text ?? _t(context, '\u0627\u0644\u062a\u0631\u062c\u0645\u0629 \u063a\u064a\u0631 \u0645\u062a\u0648\u0641\u0631\u0629', 'Translation unavailable'),
      textAlign: TextAlign.start,
      style: TextStyle(fontSize: 14, color: _nightMode ? Colors.white70 : AppColors.mutedText, fontStyle: FontStyle.italic),
    );
  }

  Widget _buildVerseList(SurahModel surah, List<SurahModel> allSurahs) {
    _loadTranslationIfNeeded(context, surah);
    final isThisSurahPlaying = quranAudio.isSurahActive(surah.number) && quranAudio.playingWholeSurah;
    final showBismillah = Bismillah.shouldShowFor(surah.number);
    final fontKey = _quranFontFamilies[appSettings.quranFontFamily] ?? '';
    // Two independent things affect what background the reader sits on:
    // (1) the in-page night-reading toggle (_nightMode), and (2) the app's
    // GLOBAL theme (Settings > Mode: Light/Dark/System). Previously this
    // only accounted for (1) and assumed "not in reading-night-mode" always
    // meant a light background -- which is false when the global theme is
    // Dark, causing near-black text on a near-black background.
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = TextStyle(
      fontFamily: fontKey.isEmpty ? 'AmiriQuran' : fontKey,
      fontSize: 22,
      height: 2.0,
      color: _nightMode
          ? const Color(0xFFE8D9C5)
          : (isDarkTheme ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A)),
    );

    return Column(children: [
      if (!_focusMode)
      Container(
        color: _nightMode ? Colors.black : AppColors.primaryEmerald.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Icon(
            isThisSurahPlaying && !quranAudio.isPaused ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: AppColors.primaryEmerald,
          ),
          IconButton(
            icon: Icon(
              isThisSurahPlaying && !quranAudio.isPaused ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: AppColors.primaryEmerald,
            ),
            onPressed: () {
              if (isThisSurahPlaying) {
                quranAudio.isPaused ? quranAudio.resume() : quranAudio.pause();
              } else {
                quranAudio.playWholeSurah(surah, allSurahs);
              }
            },
          ),
          Expanded(child: Text(_t(context, '\u062a\u0634\u063a\u064a\u0644 \u0627\u0644\u0633\u0648\u0631\u0629 \u0643\u0627\u0645\u0644\u0629', 'Play whole surah'), style: TextStyle(fontSize: 12, color: _nightMode ? Colors.white70 : AppColors.mutedText))),
          if (quranAudio.isBuffering)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: surah.ayahs.length + (showBismillah ? 1 : 0),
          itemBuilder: (context, index) {
            if (showBismillah && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Text(
                    Bismillah.text,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: baseStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }
            final ayah = surah.ayahs[index - (showBismillah ? 1 : 0)];
            final isPlaying = quranAudio.isPlayingFor(surah.number, ayah.number);
            return Container(
              margin: EdgeInsets.only(bottom: _focusMode ? 22 : 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPlaying
                    ? (_nightMode ? Colors.white10 : AppColors.primaryEmerald.withValues(alpha: 0.08))
                    : null,
                borderRadius: BorderRadius.circular(_focusMode ? 0 : 10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                appSettings.showTajweedColoring
                    ? RichText(
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        text: TextSpan(children: TajweedHelper.buildSpans(ayah.text, baseStyle)),
                      )
                    : Text(ayah.text, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: baseStyle),
                if (_translationKeyForLocale(context) != null) ...[
                  const SizedBox(height: 6),
                  _buildTranslationBlock(context, ayah.number),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  Text('\u0622\u064a\u0629 ${ayah.number}', style: TextStyle(fontSize: 11, color: _nightMode ? Colors.white38 : AppColors.mutedText)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(isPlaying && !quranAudio.isPaused ? Icons.pause_circle : Icons.play_circle_outline, color: AppColors.primaryEmerald),
                    onPressed: () async {
                      try {
                        if (isPlaying) {
                          quranAudio.isPaused ? await quranAudio.resume() : await quranAudio.pause();
                        } else {
                          await quranAudio.playAyah(surah, allSurahs, ayah.number);
                        }
                      } catch (e) {
                        // One automatic retry -- covers transient network hiccups
                        // (the same class of issue the radio player hit) without
                        // making the user tap twice.
                        try {
                          await Future.delayed(const Duration(milliseconds: 500));
                          await quranAudio.playAyah(surah, allSurahs, ayah.number);
                        } catch (e2) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Playback error: ' + e2.toString())),
                            );
                          }
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    tooltip: _t(context, '\u0625\u0636\u0627\u0641\u0629 \u0625\u0634\u0627\u0631\u0629 \u0645\u0631\u062c\u0639\u064a\u0629', 'Add bookmark'),
                    onPressed: () async {
                      await BookmarkService.addBookmark(
                        surahNumber: surah.number,
                        surahName: surah.name,
                        ayahNumber: ayah.number,
                        ayahText: ayah.text,
                        note: '',
                        category: 'other',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_t(context, '\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0625\u0634\u0627\u0631\u0629 \u0627\u0644\u0645\u0631\u062c\u0639\u064a\u0629', 'Bookmark added'))),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _expandedTafsirAyahs.contains(ayah.number) ? Icons.menu_book : Icons.menu_book_outlined,
                      color: _expandedTafsirAyahs.contains(ayah.number) ? AppColors.goldAccent : null,
                    ),
                    tooltip: _t(context, '\u0627\u0644\u062a\u0641\u0633\u064a\u0631', 'Tafsir'),
                    onPressed: (_loadingTafsir && !_expandedTafsirAyahs.contains(ayah.number))
                        ? null
                        : () => _toggleTafsir(ayah.number),
                  ),
                  IconButton(
                    icon: Icon(
                      _expandedWordsAyahs.contains(ayah.number) ? Icons.view_column : Icons.view_column_outlined,
                      color: _expandedWordsAyahs.contains(ayah.number) ? AppColors.goldAccent : null,
                    ),
                    tooltip: _t(context, '\u0643\u0644\u0645\u0629 \u0628\u0643\u0644\u0645\u0629', 'Word by word'),
                    onPressed: (_loadingWbw && !_expandedWordsAyahs.contains(ayah.number))
                        ? null
                        : () => _toggleWords(surah.number, ayah.number),
                  ),
                  if (SajdaTrackerService.isSajdaVerse(surah.number, ayah.number))
                    IconButton(
                      icon: Icon(Icons.self_improvement, color: AppColors.primaryEmerald),
                      tooltip: _t(context, '\u0633\u062c\u062f\u0629 \u062a\u0644\u0627\u0648\u0629', 'Sajda Tilawah'),
                      onPressed: () => _confirmSajda(surah.number, ayah.number),
                    ),
                ]),
                if (_expandedTafsirAyahs.contains(ayah.number)) ...[
                  const SizedBox(height: 8),
                  _buildTafsirBlock(context, surah.number, ayah.number),
                ],
                if (_expandedWordsAyahs.contains(ayah.number)) ...[
                  const SizedBox(height: 8),
                  _buildWordsBlock(ayah.number),
                ],
              ]),
            );
          },
        ),
      ),
    ]);
  }
}
