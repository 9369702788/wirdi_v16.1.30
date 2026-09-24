import 'package:flutter/material.dart';
import '../../../core/services/quran_audio_service.dart';
import '../../../core/theme/app_theme.dart';
import '../mushaf_reader_screen.dart';

String _t(BuildContext c, String ar, String en) =>
    Localizations.localeOf(c).languageCode == 'ar' ? ar : en;

/// Global floating mini-player, shown app-wide (via root_shell.dart)
/// whenever Quran recitation is active -- mirrors RadioMiniPlayer's exact
/// pattern so both feel consistent. Tapping it opens the Quran Reader;
/// the play/pause button controls playback directly via the same
/// app-wide QuranAudioService used everywhere else.
class QuranMiniPlayer extends StatelessWidget {
  const QuranMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: quranAudio,
      builder: (_, __) {
        final ayah = quranAudio.playingAyah;
        if (ayah == null) return const SizedBox.shrink();
        final surahNumber = quranAudio.currentSurahNumber;
        final label = _t(context, 'سورة ${surahNumber ?? '-'} - آية $ayah', 'Surah ${surahNumber ?? '-'} - Ayah $ayah');

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MushafReaderScreen()),
          ),
          child: Container(
            height: 60,
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(fit: StackFit.expand, children: [
              Row(children: [
              const SizedBox(width: 14),
              const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t(context, 'تلاوة قرآن', 'Quran Recitation'), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              quranAudio.isBuffering
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    )
                  : IconButton(
                      icon: Icon(
                        quranAudio.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        quranAudio.isPaused ? quranAudio.resume() : quranAudio.pause();
                      },
                    ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                tooltip: _t(context, 'إيقاف', 'Stop'),
                onPressed: () => quranAudio.stop(),
              ),
              const SizedBox(width: 4),
              ]),
              // Surah-level progress (v1.55): how far through the whole surah, not the ayah.
              Positioned(
                left: 14,
                right: 14,
                bottom: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: quranAudio.surahProgress,
                    minHeight: 3,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
