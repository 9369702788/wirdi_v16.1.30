import 'package:flutter/material.dart';
import '../../../core/services/quran_audio_service.dart';
import '../../../core/theme/app_theme.dart';

/// h:mm:ss / mm:ss clock text.
String _formatClock(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// Bottom playback bar for Quran recitation.
///
/// v1.55: the slider shows progress through the WHOLE SURAH (or the played
/// range), not through the single ayah that happens to be playing. Dragging is
/// only applied when the finger is released, so scrubbing never fires a
/// network fetch per pixel.
class QuranPlaybackBar extends StatefulWidget {
  const QuranPlaybackBar({super.key});

  @override
  State<QuranPlaybackBar> createState() => _QuranPlaybackBarState();
}

class _QuranPlaybackBarState extends State<QuranPlaybackBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: quranAudio,
      builder: (context, _) {
        final playing = quranAudio.playingAyah;
        if (playing == null) return const SizedBox.shrink();

        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        final surahName = quranAudio.currentSurahName ?? (isAr ? '' : 'Surah');
        final total = quranAudio.totalAyahsInSurah;
        final dragging = _dragValue != null;
        final progress = _dragValue ?? quranAudio.surahProgress;
        final shownAyah = dragging ? quranAudio.ayahAtSurahProgress(_dragValue!) : playing;
        final ayahText = total > 0 ? '$shownAyah / $total' : '$shownAyah';

        final elapsed = quranAudio.surahElapsed;
        final estimatedTotal = quranAudio.surahEstimatedTotal;
        final totalPrefix = quranAudio.isSurahTotalExact ? '' : '~';
        final clockText = '${_formatClock(elapsed)} / $totalPrefix${_formatClock(estimatedTotal)}';

        return Material(
          elevation: 10,
          color: AppColors.primaryEmerald,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: progress < 0 ? 0.0 : (progress > 1 ? 1.0 : progress),
                  min: 0,
                  max: 1,
                  onChanged: (v) => setState(() => _dragValue = v),
                  onChangeEnd: (v) async {
                    await quranAudio.seekToSurahProgress(v);
                    if (mounted) setState(() => _dragValue = null);
                  },
                  semanticFormatterCallback: (v) => '${(v * 100).round()}%',
                  activeColor: AppColors.goldAccent,
                  inactiveColor: Colors.white24,
                ),
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAr ? '$surahName   الآية $ayahText' : '$surahName  Ayah $ayahText',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            clockText,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: quranAudio.isPaused ? (isAr ? 'متابعة' : 'Resume') : (isAr ? 'إيقاف مؤقت' : 'Pause'),
                      icon: Icon(quranAudio.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white),
                      onPressed: () => quranAudio.isPaused ? quranAudio.resume() : quranAudio.pause(),
                    ),
                    IconButton(
                      tooltip: isAr ? 'إيقاف' : 'Stop',
                      icon: const Icon(Icons.stop_rounded, color: Colors.white70),
                      onPressed: quranAudio.stop,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
