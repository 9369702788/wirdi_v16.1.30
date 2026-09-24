import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Shared, public version of the small `_MosaicBg` app-bar background
/// already duplicated privately across several screens (qibla, moon,
/// azkar, prayer times, quran, radio, account). Crops one cell out of
/// the shared `assets/images/wirdi_mosaic.png` sprite sheet (5 columns
/// x 2 rows of real, brand-matched photography: mosques, the Kaaba,
/// the moon, a Ramadan lantern, the Quran, and the Wirdi mark) and
/// paints it behind an [AppBar] via `flexibleSpace`, with a dark
/// overlay so the title/icons stay readable.
///
/// Usage (identical to the existing private copies, so screens can be
/// switched to this shared widget later with zero behavior change):
/// ```dart
/// appBar: AppBar(
///   foregroundColor: Colors.white,
///   flexibleSpace: const MosaicBackground(col: 0, row: 1),
///   title: Text(...),
/// ),
/// ```
class MosaicBackground extends StatefulWidget {
  /// Column of the sprite sheet, 0-indexed, 0..4.
  final int col;

  /// Row of the sprite sheet, 0-indexed, 0..1.
  final int row;

  /// Darkening overlay opacity, 0..1. Higher keeps white app-bar text
  /// readable over brighter tiles (e.g. the daytime mosque tiles).
  final double opacity;

  const MosaicBackground({super.key, required this.col, required this.row, this.opacity = 0.4});

  @override
  State<MosaicBackground> createState() => _MosaicBackgroundState();
}

class _MosaicBackgroundState extends State<MosaicBackground> {
  static ui.Image? _cachedImage;
  ui.Image? _image;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    if (_cachedImage != null) {
      _image = _cachedImage;
    } else {
      final stream = const AssetImage('assets/images/wirdi_mosaic.png').resolve(const ImageConfiguration());
      _listener = ImageStreamListener((info, _) {
        _cachedImage = info.image;
        if (mounted) setState(() => _image = info.image);
      });
      stream.addListener(_listener!);
    }
  }

  @override
  void dispose() {
    if (_listener != null) {
      const AssetImage('assets/images/wirdi_mosaic.png').resolve(const ImageConfiguration()).removeListener(_listener!);
    }
    super.dispose();
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
            const ColoredBox(color: Color(0xFF0F766E)),
          ColoredBox(color: Colors.black.withValues(alpha: widget.opacity)),
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
