import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';

class ShareableTextCardScreen extends StatefulWidget {
  final String mainText;
  final String? subText;
  final String referenceLabel;
  final String pageTitle;

  const ShareableTextCardScreen({
    super.key,
    required this.mainText,
    required this.subText,
    required this.referenceLabel,
    required this.pageTitle,
  });

  @override
  State<ShareableTextCardScreen> createState() => _ShareableTextCardScreenState();
}

class _ShareableTextCardScreenState extends State<ShareableTextCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/wirdi_share_card.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(widget.pageTitle), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryEmerald, Color(0xFF0B3D36)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.format_quote, color: AppColors.goldAccent, size: 28),
                        const SizedBox(height: 16),
                        Text(
                          widget.mainText,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 20,
                            height: 1.9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.subText != null) ...[
                          const SizedBox(height: 20),
                          Container(height: 1, width: 60, color: AppColors.goldAccent.withValues(alpha: 0.5)),
                          const SizedBox(height: 20),
                          Text(
                            widget.subText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          widget.referenceLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.goldAccent, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 28),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mosque, size: 16, color: Colors.white70),
                            SizedBox(width: 6),
                            Text(
                              'Wirdi',
                              style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSharing ? null : _share,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share),
                  label: Text(isAr ? 'مشاركة كصورة' : 'Share as image'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
