import 'quran_audio_service.dart';
import 'radio_service.dart';

/// Wirdi has two independent audio engines -- Islamic Radio and Quran
/// recitation -- that don't know about each other. Without this, starting
/// one while the other is already playing would overlap both audio
/// streams at once. Call these at the start of each engine's play path
/// so only one source is ever audible (and shown in the system media
/// notification) at a time.
///
/// NOTE: this class previously also owned a screen wakelock (WakelockPlus)
/// as a workaround for audio stopping when the screen locked. The real
/// cause of that was a separate, since-fixed bug: AudioService.init() was
/// silently failing every launch due to a notification-channel config
/// conflict (androidNotificationOngoing + androidStopForegroundOnPause),
/// so the app was never actually running as a real Android foreground
/// service -- which IS what's supposed to keep audio alive with the
/// screen off, the same way any music app works. With that root cause
/// fixed, keeping the screen lit during playback is no longer necessary
/// and has been removed entirely (AudioContext(stayAwake: true) in
/// main.dart remains, which only keeps the CPU -- never the screen --
/// active, and only for as long as something is genuinely playing).
class PlaybackCoordinator {
  PlaybackCoordinator._();

  static Future<void> stopRadioForQuran() => RadioService.instance.stop();
  static Future<void> stopQuranForRadio() => quranAudio.stop();
}
