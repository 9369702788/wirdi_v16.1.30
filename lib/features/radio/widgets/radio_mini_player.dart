
import 'package:flutter/material.dart';
import '../../../core/services/radio_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../radio_now_playing_screen.dart';

class RadioMiniPlayer extends StatelessWidget {
  const RadioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RadioService.instance,
      builder: (_, __) {
        final svc = RadioService.instance;
        if (svc.currentStation == null) return const SizedBox.shrink();
        final lang = appSettings.locale.languageCode;
        final name = lang == 'ar'
            ? svc.currentStation!.nameAr
            : svc.currentStation!.nameEn;
        final l = AppLocalizations.of(context);

        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RadioNowPlayingScreen())),
          child: Container(
            height: 60,
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                blurRadius: 12, offset: const Offset(0, 4),
              )],
            ),
            child: Row(children: [
              const SizedBox(width: 6),
              if (svc.allStations.length > 1)
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 22),
                  onPressed: () => svc.playPrevious(),
                )
              else
                const SizedBox(width: 8),
              const Icon(Icons.graphic_eq_rounded, color: Colors.white70, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.radioNowPlaying,
                      style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  Text(name,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              if (svc.hasSleepTimer && svc.sleepMinutesRemaining != null)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bedtime, color: AppColors.goldAccent, size: 11),
                    const SizedBox(width: 2),
                    Text('${svc.sleepMinutesRemaining}m',
                        style: TextStyle(color: AppColors.goldAccent,
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              svc.isLoading
                  ? const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : IconButton(
                      icon: Icon(svc.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          color: Colors.white, size: 26),
                      onPressed: () {
                        if (svc.isPlaying) {
                          svc.pause();
                        } else if (svc.currentStation != null) {
                          svc.play(svc.currentStation!);
                        }
                      },
                    ),
              if (svc.allStations.length > 1)
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 22),
                  onPressed: () => svc.playPrevious(),
                )
              else
                const SizedBox(width: 8),
              const SizedBox(width: 2),
            ]),
          ),
        );
      },
    );
  }
}
