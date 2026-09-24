import '../../core/services/tajweed_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/data/bismillah.dart';
import '../../core/data/reciters.dart';
import '../../core/models/mushaf_models.dart';
import '../../core/models/quran_models.dart';
import '../../core/services/mushaf_repository.dart';
import '../../core/services/quran_audio_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../quran/widgets/quran_playback_bar.dart';
import '../quran/quran_screen.dart';

class MushafViewScreen extends StatefulWidget {
  final int? initialPage;
  final int? initialSurahNumber;
  final int? initialAyah;
  const MushafViewScreen({super.key, this.initialPage, this.initialSurahNumber, this.initialAyah});

  @override
  State<MushafViewScreen> createState() => _MushafViewScreenState();
}

class _MushafViewScreenState extends State<MushafViewScreen> {
  late Future<(List<MushafPage>, List<SurahModel>)> _future;
  late PageController _pageController;

  // BUGFIX: pinch-to-zoom on a Mushaf page wasn't working because the
  // InteractiveViewer living inside each _MushafPageView is nested
  // INSIDE this PageView -- a well-known Flutter gesture-arena
  // conflict where the PageView's own horizontal-swipe recognizer can
  // win the arena on a 2-finger touch before InteractiveViewer's scale
  // recognizer gets a chance, silently swallowing the pinch gesture.
  // Fix: each page reports (via onMultiTouch, using a raw Listener
  // that counts pointers BEFORE gesture-arena resolution, so it is
  // never itself out-competed) whenever 2+ fingers are on screen, and
  // we freeze the PageView's physics for that duration so it cannot
  // steal the gesture. Released back to normal the instant a finger
  // lifts and fewer than 2 remain.
  bool _multiTouchActive = false;

  /// Toggles between the classic page-flip Mushaf (default, swipe left/right)
  /// and a continuous vertical scroll through the same page cards -- some
  /// readers prefer scrolling top-to-bottom over flipping discrete pages.
  bool _continuousScroll = false;

  int _currentPageIndex = 0;
  ScrollController? _continuousScrollController;
  double _fontScale = 1.0;

  /// Cached once [_loadAll] resolves, so [_onAudioChanged] (which fires
  /// on every ayah transition, independent of the FutureBuilder) can
  /// look up which page a given ayah belongs to without re-awaiting
  /// the future.
  List<MushafPage>? _pages;
  List<SurahModel>? _allSurahs;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
    _currentPageIndex = (widget.initialPage ?? 1) - 1;
    _pageController = PageController(initialPage: (widget.initialPage ?? 1) - 1);
    quranAudio.addListener(_onAudioChanged);
    // FIX: keep the screen awake while reading the Mushaf, same as a
    // real physical copy never "locks itself" while you're reading it.
    // WakelockPlus only suppresses the device's AUTOMATIC screen
    // timeout -- it does NOT block the user's own power button or any
    // manual lock action, so "the user locking the screen themselves"
    // still works exactly as normal. Disabled again in dispose() so
    // leaving this screen doesn't keep the whole app awake elsewhere.
    WakelockPlus.enable();
  }

  Future<(List<MushafPage>, List<SurahModel>)> _loadAll() async {
    final results = await Future.wait([MushafRepository.load(), QuranRepository.load()]);
    final pages = results[0] as List<MushafPage>;
    _pages = pages;
    _allSurahs = results[1] as List<SurahModel>;
    if (widget.initialSurahNumber != null && widget.initialAyah != null) {
      for (var i = 0; i < pages.length; i++) {
        if (pages[i].ayahs.any((a) => a.surahNumber == widget.initialSurahNumber && a.ayahNumber == widget.initialAyah)) {
          _currentPageIndex = i;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(i);
            }
          });
          break;
        }
      }
    }
    return (pages, results[1] as List<SurahModel>);
  }

  /// FIX: during continuous "play whole surah" playback, the currently
  /// playing ayah advances automatically and this screen already
  /// highlights whichever ayah is playing -- but nothing previously
  /// moved the VISIBLE page forward when playback crossed a Mushaf
  /// page boundary, so once a page's last ayah finished, the next
  /// ayah's highlight kept advancing on a page the user could no
  /// longer see, with no indication to swipe forward. This finds which
  /// page the currently-playing ayah belongs to and animates there
  /// automatically whenever it's not the page already on screen.
  void _onAudioChanged() {
    final pages = _pages;
    final surah = quranAudio.currentSurahNumber;
    final ayah = quranAudio.playingAyah;
    if (pages == null || surah == null || ayah == null) return;
    if (!_pageController.hasClients) return;

    final targetIndex = pages.indexWhere(
      (p) => p.ayahs.any((a) => a.surahNumber == surah && a.ayahNumber == ayah),
    );
    if (targetIndex == -1) return;

    final currentIndex = _pageController.page?.round() ?? _pageController.initialPage;
    if (targetIndex == currentIndex) return;

    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 30),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    quranAudio.removeListener(_onAudioChanged);
    _pageController.dispose();
    _continuousScrollController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _playWholeSurahFromCurrentPage() async {
    final pages = _pages;
    final surahs = _allSurahs;
    if (pages == null || surahs == null || pages.isEmpty) return;
    int? surahNumber = quranAudio.currentSurahNumber;
    if (surahNumber == null) {
      final page = pages[_currentPageIndex.clamp(0, pages.length - 1).toInt()];
      if (page.ayahs.isNotEmpty) surahNumber = page.ayahs.first.surahNumber;
    }
    if (surahNumber == null) return;
    final surah = surahs.firstWhere((s) => s.number == surahNumber, orElse: () => surahs.first);
    await quranAudio.playWholeSurah(surah, surahs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mushafTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'القراءة العادية' : 'Normal Quran view',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () {
              final pages = _pages;
              final surahs = _allSurahs;
              if (pages == null || surahs == null || pages.isEmpty) return;
              final playingSurah = quranAudio.currentSurahNumber;
              final playingAyah = quranAudio.playingAyah;
              MushafAyahRef? ref;
              if (playingSurah != null && playingAyah != null) {
                for (final page in pages) {
                  for (final ayah in page.ayahs) {
                    if (ayah.surahNumber == playingSurah && ayah.ayahNumber == playingAyah) {
                      ref = ayah;
                      break;
                    }
                  }
                  if (ref != null) break;
                }
              }
              if (ref == null) {
                final page = pages[_currentPageIndex.clamp(0, pages.length - 1).toInt()];
                if (page.ayahs.isEmpty) return;
                ref = page.ayahs.first;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuranScreen(initialSurahNumber: ref!.surahNumber, initialAyah: ref.ayahNumber),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'خيارات القراءة' : 'Reading options',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (value) async {
              if (value == 'fontDec') {
                setState(() => _fontScale = (_fontScale - 0.1).clamp(0.7, 1.6));
              } else if (value == 'fontInc') {
                setState(() => _fontScale = (_fontScale + 0.1).clamp(0.7, 1.6));
              } else if (value == 'reciter') {
                final languageCode = Localizations.localeOf(context).languageCode;
                final chosen = await showModalBottomSheet<String>(
                  context: context,
                  builder: (sheetContext) => SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(padding: const EdgeInsets.all(16), child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'اختيار القارئ' : 'Choose reciter', style: const TextStyle(fontWeight: FontWeight.w700))),
                        for (final reciter in Reciters.all)
                          ListTile(
                            title: Text(reciter.displayNameFor(languageCode)),
                            trailing: reciter.id == appSettings.reciterId ? Icon(Icons.check, color: AppColors.primaryEmerald) : null,
                            onTap: () => Navigator.pop(sheetContext, reciter.id),
                          ),
                      ],
                    ),
                  ),
                );
                if (chosen != null && chosen != appSettings.reciterId) {
                  final activeSurahNumber = quranAudio.currentSurahNumber ?? widget.initialSurahNumber;
                  final activeSurah = activeSurahNumber == null
                      ? null
                      : _allSurahs?.firstWhere((s) => s.number == activeSurahNumber, orElse: () => _allSurahs!.first);
                  if (activeSurah != null && _allSurahs != null) {
                    await quranAudio.changeReciter(chosen, surah: activeSurah, allSurahs: _allSurahs!);
                  } else {
                    await appSettings.setReciterId(chosen);
                  }
                  if (mounted) setState(() {});
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'reciter', child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'القارئ' : 'Reciter')),
              PopupMenuItem(value: 'fontDec', child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تصغير الخط' : 'Decrease font')),
              PopupMenuItem(value: 'fontInc', child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تكبير الخط' : 'Increase font')),
            ],
          ),
          ListenableBuilder(
            listenable: quranAudio,
            builder: (context, _) {
              final activeWhole = quranAudio.playingWholeSurah;
              final paused = quranAudio.isPaused;
              return IconButton(
                tooltip: paused ? (Localizations.localeOf(context).languageCode == 'ar' ? 'استكمال السورة' : 'Resume surah') : (activeWhole ? (Localizations.localeOf(context).languageCode == 'ar' ? 'إيقاف مؤقت' : 'Pause') : (Localizations.localeOf(context).languageCode == 'ar' ? 'تشغيل السورة كاملة' : 'Play whole surah')),
                icon: Icon(paused ? Icons.play_arrow_rounded : (activeWhole ? Icons.pause_rounded : Icons.play_circle_outline)),
                onPressed: paused ? quranAudio.resume : (activeWhole ? quranAudio.pause : _playWholeSurahFromCurrentPage),
              );
            },
          ),
          IconButton(
            tooltip: _continuousScroll
                ? (Localizations.localeOf(context).languageCode == 'ar' ? 'وضع الصفحات' : 'Page-flip mode')
                : (Localizations.localeOf(context).languageCode == 'ar' ? 'وضع التمرير المستمر' : 'Continuous scroll mode'),
            icon: Icon(_continuousScroll ? Icons.auto_stories_outlined : Icons.swap_vert),
            onPressed: () {
              final itemHeight = MediaQuery.sizeOf(context).height * 0.92;
              if (!_continuousScroll) {
                if (_pageController.hasClients) {
                  _currentPageIndex = _pageController.page?.round() ?? _pageController.initialPage;
                }
                _continuousScrollController?.dispose();
                _continuousScrollController = ScrollController(initialScrollOffset: _currentPageIndex * itemHeight);
              } else {
                final controller = _continuousScrollController;
                if (controller != null && controller.hasClients) {
                  _currentPageIndex = (controller.offset / itemHeight).round().clamp(0, 1 << 20);
                }
                controller?.dispose();
                _continuousScrollController = null;
              }
              setState(() => _continuousScroll = !_continuousScroll);
              if (_continuousScroll == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) _pageController.jumpToPage(_currentPageIndex);
                });
              }
            },
          ),
          ListenableBuilder(
            listenable: quranAudio,
            builder: (context, _) {
              if (quranAudio.playingAyah == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: l10n.mushafStopAudioTooltip,
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: () => quranAudio.stop(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const QuranPlaybackBar(),
      body: FutureBuilder<(List<MushafPage>, List<SurahModel>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.mutedText),
                    const SizedBox(height: 12),
                    Text(l10n.mushafLoadError, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _future = _loadAll()),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final (pages, allSurahs) = snapshot.data!;

          // FIX: Quran pages are ALWAYS read right-to-left, regardless of
          // the app's current UI language. `reverse: true` on its own
          // reverses page order RELATIVE to the ambient Directionality --
          // that gave the right feel when the app locale was LTR
          // (English/German/etc.), but DOUBLE-flipped it back to
          // LTR-feeling navigation when the app locale is Arabic (RTL),
          // since the ambient Directionality is already RTL there.
          // Wrapping in an explicit, locale-independent RTL
          // Directionality and dropping `reverse` makes page-flip
          // direction consistent no matter what language the rest of
          // the app's UI is in.
          if (_continuousScroll) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                controller: _continuousScrollController,
                // BUGFIX: this physics line existed on PageView.builder below
                // (mirrors it) but was simply never added here, so a 2-finger
                // pinch on a page could also drag the whole feed at the same
                // time. Mirroring the already-working PageView pattern:
                // disable list scrolling for the duration of a 2+ finger
                // touch (so InteractiveViewer owns it exclusively), restore
                // normal scrolling the instant it drops back to 0-1 fingers.
                physics: _multiTouchActive ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return _MushafPageView(
                    page: page,
                    allSurahs: allSurahs,
                    targetHeight: MediaQuery.sizeOf(context).height * 0.92,
                    onMultiTouch: (active) {
                      if (mounted && _multiTouchActive != active) setState(() => _multiTouchActive = active);
                    },
                    fontScale: _fontScale,
                  );
                },
              ),
            );
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pageController,
              physics: _multiTouchActive ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
              itemCount: pages.length,
              onPageChanged: (index) {
                _currentPageIndex = index;
                if (pages[index].ayahs.isNotEmpty) {
                  final firstAyah = pages[index].ayahs.first;
                  final surah = allSurahs.firstWhere(
                    (s) => s.number == firstAyah.surahNumber,
                    orElse: () => allSurahs.first,
                  );
                  UserProgressService.saveLastReading(
                    surahNumber: firstAyah.surahNumber,
                    surahName: surah.name,
                    ayahNumber: firstAyah.ayahNumber,
                  );
                }
              },
              itemBuilder: (context, index) {
                final page = pages[index];
                return _MushafPageView(
                  page: page,
                  allSurahs: allSurahs,
                  onMultiTouch: (active) {
                    if (mounted && _multiTouchActive != active) setState(() => _multiTouchActive = active);
                  },
                  fontScale: _fontScale,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MushafPageView extends StatefulWidget {
  final MushafPage page;
  final List<SurahModel> allSurahs;
  final ValueChanged<bool>? onMultiTouch;
  // Explicit height for continuous-scroll mode -- see BUGFIX note in
  // _MushafPageViewState.build() below for why this is required instead
  // of relying on LayoutBuilder's constraints.maxHeight in that mode.
  final double? targetHeight;
  final double fontScale;
  const _MushafPageView({required this.page, required this.allSurahs, this.onMultiTouch, this.targetHeight, this.fontScale = 1.0});

  @override
  State<_MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<_MushafPageView> {
  final List<TapGestureRecognizer> _recognizers = [];
  final ScrollController _innerScrollController = ScrollController();

  // Raw pointer count, tracked via Listener (fires before gesture-arena
  // resolution -- see the BUGFIX note on _multiTouchActive above).
  int _activePointers = 0;

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers == 2) widget.onMultiTouch?.call(true);
  }

  void _handlePointerUp(PointerEvent event) {
    if (_activePointers > 0) _activePointers--;
    if (_activePointers < 2) widget.onMultiTouch?.call(false);
  }

  @override
  void initState() {
    super.initState();
    quranAudio.addListener(_onAudioChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToPlayingAyahIfNeeded());
  }

  void _onAudioChanged() {
    if (mounted) setState(() {});
    _scrollToPlayingAyahIfNeeded();
  }

  void _scrollToPlayingAyahIfNeeded() {
    final surah = quranAudio.currentSurahNumber;
    final ayahNumber = quranAudio.playingAyah;
    if (surah == null || ayahNumber == null) return;
    if (!_innerScrollController.hasClients) return;

    final ayahs = widget.page.ayahs;
    final index = ayahs.indexWhere((a) => a.surahNumber == surah && a.ayahNumber == ayahNumber);
    if (index == -1) return;
    if (ayahs.length <= 1) return;

    final maxExtent = _innerScrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    final fraction = (index / (ayahs.length - 1)).clamp(0.0, 1.0);
    final target = (maxExtent * fraction).clamp(0.0, maxExtent);
    _innerScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    quranAudio.removeListener(_onAudioChanged);
    _disposeRecognizers();
    _innerScrollController.dispose();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  SurahModel? _surahFor(int number) {
    for (final s in widget.allSurahs) {
      if (s.number == number) return s;
    }
    return null;
  }

  void _playAyah(MushafAyahRef ayah) {
    final surah = _surahFor(ayah.surahNumber);
    if (surah == null) return;
    if (quranAudio.isPlayingFor(ayah.surahNumber, ayah.ayahNumber)) {
      quranAudio.stop();
    } else {
      quranAudio.playAyah(surah, widget.allSurahs, ayah.ayahNumber);
    }
  }

  TapGestureRecognizer _makeRecognizer(VoidCallback onTap) {
    final recognizer = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _disposeRecognizers();

    final groups = <int, List<MushafAyahRef>>{};
    for (final ayah in widget.page.ayahs) {
      groups.putIfAbsent(ayah.surahNumber, () => []).add(ayah);
    }

    // FIX: on a tablet, this card previously only grew as tall as its
    // text content needed, leaving a large empty gap below it instead
    // of filling the screen like a real Mushaf page. LayoutBuilder
    // gives us the actual available height so the card can be told to
    // fill AT LEAST that much -- while still allowed to grow taller and
    // scroll internally (via the existing SingleChildScrollView) for
    // any page whose content is genuinely longer than the viewport.
    final cardContent = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in groups.entries) ...[
              if (entry.value.isNotEmpty && entry.value.first.ayahNumber == 1) ...[
                _SurahHeaderBanner(surah: _surahFor(entry.key)),
                if (Bismillah.shouldShowFor(entry.key)) ...[
                  const SizedBox(height: 14),
                  Text(
                    Bismillah.text,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 24 * widget.fontScale, fontWeight: FontWeight.normal),
                  ),
                ],
                const SizedBox(height: 16),
              ],
              Text.rich(
                TextSpan(
                  children: [
                    for (final ayah in entry.value) ...(() {
                      // NOTE: a TapGestureRecognizer set on a TextSpan only
                      // fires for that span's OWN `text`, never for its
                      // `children` -- this is a well-known Flutter gotcha.
                      // The previous version set `recognizer` on the wrapping
                      // parent span (which had no `text` of its own, only
                      // `children`), so the tap target was effectively an
                      // empty, zero-length span that could never actually be
                      // tapped. Fixed by attaching the SAME recognizer to
                      // every leaf span that actually renders visible glyphs
                      // (each Tajweed-colored segment, or the plain-text
                      // span, plus the ayah-number marker) so the whole
                      // rendered ayah -- including its number -- is tappable.
                      final isPlaying = quranAudio.isPlayingFor(ayah.surahNumber, ayah.ayahNumber);
                      final playingStyle = isPlaying
                          ? TextStyle(backgroundColor: AppColors.goldAccent.withValues(alpha: 0.35))
                          : null;
                      final leafSpans = <TextSpan>[
                        if (appSettings.showTajweedColoring)
                          ...TajweedService.analyze(ayah.text).map((segment) {
                            final color = TajweedService.colorFor(segment.rule);
                            return TextSpan(
                              text: segment.text,
                              style: (color != null ? TextStyle(color: color) : const TextStyle()).merge(playingStyle),
                              recognizer: _makeRecognizer(() => _playAyah(ayah)),
                            );
                          })
                        else
                          TextSpan(
                            text: ayah.text,
                            style: playingStyle,
                            recognizer: _makeRecognizer(() => _playAyah(ayah)),
                          ),
                        TextSpan(
                          text: ' \uFD3F${ayah.ayahNumber}\uFD3E ',
                          style: playingStyle,
                          recognizer: _makeRecognizer(() => _playAyah(ayah)),
                        ),
                      ];
                      return leafSpans;
                    })(),
                  ],
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontFamily: appSettings.quranFontFamily == 'default' ? 'AmiriQuran' : appSettings.quranFontFamily,
                  fontSize: 22 * widget.fontScale,
                  height: 2.4,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(height: 32),
            // FIX: confirmed via screenshot -- "RIGHT OVERFLOWED BY 68
            // PIXELS" in German. None of these 3 Text widgets had any
            // flexible sizing, so each took its full intrinsic (natural)
            // width -- fine for short Arabic/English strings, but
            // German's much longer translated hint text pushed the
            // Row's total width past the screen. Wrapping each in
            // Flexible/Expanded with ellipsis overflow makes this safe
            // for a string of ANY length in any current or future
            // language, not just a fix for German specifically.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    l10n.quranJuzNumber(widget.page.juzNumber),
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.mushafTapAyahHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    l10n.mushafPageNumber(widget.page.pageNumber),
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
              ],
            );

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      child: LayoutBuilder(
      builder: (context, constraints) {
        final verticalMargin = widget.targetHeight != null ? 12.0 + 20.0 + MediaQuery.of(context).padding.bottom : 0.0;
        // BUGFIX: in continuous-scroll mode this widget lives inside a
        // ListView.builder item slot, which gives LayoutBuilder an
        // UNBOUNDED (infinite) constraints.maxHeight -- that produced an
        // infinite minCardHeight below, which in turn handed
        // BoxConstraints(minHeight: infinity) to the Container/
        // SingleChildScrollView further down. A SingleChildScrollView
        // REQUIRES a bounded height along its scroll axis to lay out at
        // all; given infinity it fails to render -- the page went
        // completely blank. widget.targetHeight (passed explicitly by
        // the continuous-scroll caller) sidesteps this entirely by never
        // depending on the ambient (unbounded) constraints in that mode.
        final effectiveMaxHeight = widget.targetHeight ?? constraints.maxHeight;
        final minCardHeight = effectiveMaxHeight - verticalMargin;
        // NEW: pinch-to-zoom on the Mushaf page. InteractiveViewer with
        // panEnabled: false deliberately does NOT claim single-finger
        // drag gestures -- those still reach the ancestor PageView
        // unchanged, so swipe-to-turn-page keeps working exactly as
        // before. Only 2-finger pinch/zoom gestures are captured here.
        final pageCard = Container(
          margin: widget.targetHeight != null
              ? EdgeInsets.fromLTRB(14, 12, 14, 20 + MediaQuery.of(context).padding.bottom)
              : EdgeInsets.zero,
          padding: const EdgeInsets.all(22),
          constraints: widget.targetHeight != null
              // Continuous-scroll mode: NO maxHeight cap -- let the card grow
              // to its natural content height. It is a normal ListView item
              // now (single scrollable = the outer list), so being taller
              // than one screen is completely fine and expected.
              ? BoxConstraints(minHeight: minCardHeight > 0 ? minCardHeight : 0)
              // Single-page mode: cap maxHeight too (min == max) so the
              // inner SingleChildScrollView above gets a genuinely BOUNDED
              // height to scroll within -- a minHeight-only constraint left
              // maxHeight at its default of infinity, invalid for a
              // vertical SingleChildScrollView's viewport.
              : BoxConstraints(
                  minHeight: minCardHeight > 0 ? minCardHeight : 0,
                  maxHeight: minCardHeight > 0 ? minCardHeight : double.infinity,
                ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: widget.targetHeight != null
              // In continuous-scroll mode there is only ONE scrollable in
              // the whole tree: the outer ListView.builder. Wrapping each
              // page ALSO in its own SingleChildScrollView created two
              // nested vertical scrollables fighting over the same drag
              // gesture -- the inner one would capture the touch and
              // refuse to release it until it hit its own scroll limits,
              // making the outer continuous feed feel like it "stopped"
              // scrolling. In this mode we just render the Column
              // directly and let the Container grow to its natural
              // (unbounded) height -- the ListView.builder item is free
              // to be taller than one screen with zero clipping.
              ? cardContent
              // In single-page (PageView) mode the page card DOES need
              // its own scroll -- PageView gives it a fixed viewport
              // height, so any page whose content is taller than that
              // must scroll internally to avoid being clipped.
              : SingleChildScrollView(controller: _innerScrollController, child: cardContent),
        );

        // BUGFIX: InteractiveViewer (added for pinch-to-zoom) claims
        // single-finger vertical drag gestures at the gesture-arena
        // level even with panEnabled: false. That is harmless when the
        // ancestor scrollable moves on a DIFFERENT axis (single-page
        // mode's PageView swipes horizontally, left/right) -- but the
        // continuous-scroll ancestor is a vertical ListView, the SAME
        // axis InteractiveViewer also watches for single-finger pan.
        // InteractiveViewer wins that gesture-arena contest every time,
        // so the ListView never receives the drag at all and the whole
        // feed gets permanently stuck on one page. Skipping
        // InteractiveViewer entirely in continuous-scroll mode (no
        // pinch-zoom there, only in single-page mode, where the axes
        // don't collide) is what actually restores scrolling.
        // BUGFIX (3rd attempt, now REVERTED to the safe choice): every
        // way of nesting InteractiveViewer inside the continuous-scroll
        // ListView.builder's unbounded-height item slot has broken
        // something different each time -- first it fully froze the
        // outer scroll, then (with constrained:false, trying to fix
        // that) it went back to rendering a blank page, because
        // InteractiveViewer's own viewport layout also needs a genuinely
        // bounded size to work, same underlying class of bug as the
        // SingleChildScrollView issue fixed earlier in this file.
        // Conclusion: pinch-zoom and this specific continuous-scroll
        // architecture (a plain ListView.builder of naturally-sized
        // items) do not reliably coexist in Flutter without much more
        // invasive, harder-to-verify custom gesture/layout work. Zoom
        // stays available in single-page mode (still wrapped below,
        // where PageView's bounded-per-page layout has never had this
        // problem). In continuous mode we return the page directly --
        // guaranteed correct, bounded, single-scrollable layout, at the
        // cost of no pinch-zoom there.
        if (widget.targetHeight != null) {
          return pageCard;
        }
        return InteractiveViewer(
          panEnabled: false,
          minScale: 0.8,
          maxScale: 2.2,
          child: pageCard,
        );
      },
    ),
    );
  }
}

class _SurahHeaderBanner extends StatelessWidget {
  final SurahModel? surah;
  const _SurahHeaderBanner({required this.surah});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentSurah = surah;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.goldAccent, width: 1.5),
        borderRadius: BorderRadius.circular(10),
        color: AppColors.primaryEmerald.withValues(alpha: 0.07),
      ),
      alignment: Alignment.center,
      child: Text(
        currentSurah != null ? l10n.quranSurahAppBarTitle(currentSurah.name) : '',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald),
      ),
    );
  }
}
