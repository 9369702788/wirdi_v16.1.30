
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/data/radio_stations.dart';
import '../../core/models/radio_station.dart';
import '../../core/services/radio_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/radio_station_tile.dart';
import 'widgets/sleep_timer_sheet.dart';
import 'radio_now_playing_screen.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});
  @override State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _cats = ['all', 'quran', 'prayers', 'lectures', 'nasheed'];

  // FEATURE: station search -- when active, results are filtered by
  // name (Arabic or English) across ALL categories at once, ignoring
  // the currently selected tab, since a user searching for a specific
  // station by name usually doesn't know (or care) which category tab
  // it's filed under.
  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _cats.length, vsync: this);
    RadioService.instance.init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<RadioStation> _stationsFor(String cat, List<RadioStation> all) {
    if (cat == 'all') return all;
    return all.where((s) => s.category == cat).toList();
  }

  List<RadioStation> _searchResults(List<RadioStation> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((s) =>
        s.nameAr.toLowerCase().contains(q) ||
        s.nameEn.toLowerCase().contains(q) ||
        s.country.toLowerCase().contains(q)).toList();
  }

  void _startSearch() {
    setState(() => _searching = true);
  }

  void _stopSearch() {
    setState(() {
      _searching = false;
      _query = '';
      _searchController.clear();
    });
  }

  String _catLabel(String cat, AppLocalizations l) {
    if (cat == 'all') return l.radioAll;
    final lang = appSettings.locale.languageCode;
    return kRadioCategories[cat]?[lang] ?? kRadioCategories[cat]?['en'] ?? cat;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        flexibleSpace: _MosaicBg(col: 3, row: 1, opacity: 0.45),
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: l.radioSearchHint,
                  border: InputBorder.none,
                ),
                style: Theme.of(context).appBarTheme.titleTextStyle ??
                    const TextStyle(fontSize: 18),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(l.radioTitle),
        actions: [
          if (_searching)
            IconButton(
              tooltip: l.commonCancel,
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else
            IconButton(
              tooltip: l.radioSearchTooltip,
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
          // Refresh button
          ListenableBuilder(
            listenable: RadioService.instance,
            builder: (_, __) {
              final svc = RadioService.instance;
              return svc.loadingLive
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      tooltip: l.commonRefreshTooltip,
                      icon: const Icon(Icons.refresh),
                      onPressed: () => svc.refreshStations(),
                    );
            },
          ),
          // Sleep timer
          ListenableBuilder(
            listenable: RadioService.instance,
            builder: (_, __) => IconButton(
              tooltip: l.radioSleepTimer,
              icon: Stack(children: [
                const Icon(Icons.bedtime_outlined),
                if (RadioService.instance.hasSleepTimer)
                  Positioned(right: 0, top: 0,
                      child: Container(width: 8, height: 8,
                          decoration: BoxDecoration(
                              color: AppColors.goldAccent,
                              shape: BoxShape.circle))),
              ]),
              onPressed: () => showModalBottomSheet(
                  context: context, builder: (_) => const SafeArea(top: false, child: SleepTimerSheet())),
            ),
          ),
          // Favorites
          IconButton(
            tooltip: l.radioFavorites,
            icon: const Icon(Icons.favorite_border),
            onPressed: () => _showFavs(context, l),
          ),
        ],
        bottom: _searching
            ? null
            : TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _cats.map((c) => Tab(text: _catLabel(c, l))).toList(),
              ),
      ),
      body: ListenableBuilder(
        listenable: RadioService.instance,
        builder: (_, __) {
          final svc = RadioService.instance;
          final stations = svc.allStations;

          return Column(children: [
            // Error banner
            if (svc.state == RadioState.error && svc.errorMessage != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(svc.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12))),
                  TextButton(
                    onPressed: () {
                      if (svc.currentStation != null) svc.play(svc.currentStation!);
                    },
                    child: Text(l.commonRetry,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ]),
              ),

            // Source badge
            _SourceBadge(svc: svc),

            // Now playing banner
            if (svc.currentStation != null) _NowPlayingBanner(svc: svc, l: l),

            // Station list -- while searching, a single flat
            // cross-category list of matches; otherwise the normal
            // per-tab TabBarView.
            Expanded(
              child: stations.isEmpty && svc.loadingLive
                  ? const Center(child: CircularProgressIndicator())
                  : _searching
                      ? _buildSearchResults(stations, l)
                      : TabBarView(
                          controller: _tabs,
                          children: _cats.map((cat) {
                            final list = _stationsFor(cat, stations);
                            if (list.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.radio_outlined,
                                        size: 48, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(l.radioNoStations,
                                        style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      label: Text(l.commonRetry),
                                      onPressed: () => svc.refreshStations(),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return RefreshIndicator(
                              onRefresh: () => svc.refreshStations(),
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: list.length,
                                itemBuilder: (_, i) =>
                                    RadioStationTile(station: list[i]),
                              ),
                            );
                          }).toList(),
                        ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildSearchResults(List<RadioStation> stations, AppLocalizations l) {
    final results = _searchResults(stations);
    if (_query.trim().isEmpty) {
      return Center(
        child: Text(l.radioSearchHint, style: const TextStyle(color: Colors.grey)),
      );
    }
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(l.radioSearchNoResults, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: results.length,
      itemBuilder: (_, i) => RadioStationTile(station: results[i]),
    );
  }

  void _showFavs(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false, initialChildSize: 0.6,
          builder: (_, ctrl) => ListenableBuilder(
            listenable: RadioService.instance,
            builder: (_, __) {
              final favs = RadioService.instance.favoriteStations;
              return Column(children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Text(l.radioFavorites,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (favs.isEmpty)
                  Expanded(child: Center(child: Text(l.radioNoFavorites)))
                else
                  Expanded(child: ListView.builder(
                    controller: ctrl, itemCount: favs.length,
                    itemBuilder: (_, i) => RadioStationTile(station: favs[i]),
                  )),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _NowPlayingBanner extends StatelessWidget {
  final RadioService svc;
  final AppLocalizations l;
  const _NowPlayingBanner({required this.svc, required this.l});

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.locale.languageCode;
    final name = lang == 'ar'
        ? svc.currentStation!.nameAr : svc.currentStation!.nameEn;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RadioNowPlayingScreen())),
      child: Container(
        color: AppColors.primaryEmerald.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Icon(Icons.graphic_eq_rounded,
              color: AppColors.primaryEmerald, size: svc.isPlaying ? 28 : 24),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.radioNowPlaying,
                  style: TextStyle(fontSize: 11,
                      color: AppColors.primaryEmerald, fontWeight: FontWeight.w600)),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          if (svc.hasSleepTimer && svc.sleepMinutesRemaining != null)
            Padding(padding: const EdgeInsets.only(right: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bedtime, size: 14, color: AppColors.goldAccent),
                const SizedBox(width: 2),
                Text('${svc.sleepMinutesRemaining}m',
                    style: TextStyle(fontSize: 12,
                        color: AppColors.goldAccent, fontWeight: FontWeight.bold)),
              ])),
          if (svc.allStations.length > 1)
            IconButton(
              icon: Icon(Icons.skip_previous_rounded, color: AppColors.primaryEmerald),
              onPressed: () => svc.playPrevious(),
            ),
          svc.isLoading
              ? const SizedBox(width: 32, height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: Icon(svc.isPlaying
                      ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: AppColors.primaryEmerald),
                  onPressed: () {
                    if (svc.isPlaying) {
                      svc.pause();
                    } else if (svc.currentStation != null) {
                      svc.play(svc.currentStation!);
                    }
                  }),
          if (svc.allStations.length > 1)
            IconButton(
              icon: Icon(Icons.skip_next_rounded, color: AppColors.primaryEmerald),
              onPressed: () => svc.playNext(),
            ),
        ]),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final RadioService svc;
  const _SourceBadge({required this.svc});
  @override
  Widget build(BuildContext context) {
    if (svc.loadingStations) {
      return Container(
        color: Colors.grey.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(children: [
          const SizedBox(width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5)),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context).radioLoadingStations,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      );
    }
    final isVerified = svc.activeSource == RadioSource.dataRosy ||
        svc.activeSource == RadioSource.uthumany;
    final color = isVerified ? Colors.green.shade700 : Colors.orange.shade700;
    final icon = isVerified ? Icons.verified_rounded : Icons.offline_bolt_outlined;
    return Container(
      color: color.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(
          svc.stations.length.toString() + ' stations \u00B7 ' + svc.sourceLabel,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }
}


class _MosaicBg extends StatefulWidget {
  final int col; // 0-indexed, 0..4
  final int row; // 0-indexed, 0..1
  final double opacity;
  const _MosaicBg({required this.col, required this.row, this.opacity = 0.4});

  @override
  State<_MosaicBg> createState() => _MosaicBgState();
}

class _MosaicBgState extends State<_MosaicBg> {
  static ui.Image? _cachedImage;
  ui.Image? _image;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    if (_cachedImage != null) {
      _image = _cachedImage;
    } else {
      final stream = const AssetImage('assets/images/wirdi_mosaic.webp')
          .resolve(const ImageConfiguration());
      _listener = ImageStreamListener((info, _) {
        _cachedImage = info.image;
        if (mounted) setState(() => _image = info.image);
      });
      stream.addListener(_listener!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (img != null)
            CustomPaint(painter: _MosaicCellPainter(image: img, col: widget.col, row: widget.row))
          else
            Container(color: const Color(0xFF0F5132)),
          Container(color: Colors.black.withValues(alpha: widget.opacity)),
        ],
      ),
    );
  }
}

class _MosaicCellPainter extends CustomPainter {
  final ui.Image image;
  final int col;
  final int row;
  static const int cols = 5;
  static const int rows = 2;
  _MosaicCellPainter({required this.image, required this.col, required this.row});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = image.width / cols;
    final cellH = image.height / rows;
    final srcAspect = cellW / cellH;
    final dstAspect = size.width / size.height;
    Rect src;
    if (srcAspect > dstAspect) {
      final visW = cellH * dstAspect;
      final dx = (cellW - visW) / 2;
      src = Rect.fromLTWH(col * cellW + dx, row * cellH, visW, cellH);
    } else {
      final visH = cellW / dstAspect;
      final dy = (cellH - visH) / 2;
      src = Rect.fromLTWH(col * cellW, row * cellH + dy, cellW, visH);
    }
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _MosaicCellPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.col != col || oldDelegate.row != row;
}
