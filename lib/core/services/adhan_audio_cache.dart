import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/adhan_option.dart';
import '../data/app_sources.dart';
import 'app_logger.dart';

class AdhanAudioCache {
  AdhanAudioCache._();

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/adhan_audio');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _fileFor(String adhanId) async {
    final dir = await _dir();
    return File('${dir.path}/$adhanId.mp3');
  }

  static Future<String?> localPathFor(String adhanId) async {
    try {
      final file = await _fileFor(adhanId);
      if (!await file.exists()) return null;
      final size = await file.length();
      if (size < 1024) {
        await file.delete();
        return null;
      }
      return file.path;
    } catch (e, st) {
      AppLogger.error('AdhanAudioCache.localPathFor failed', error: e, stackTrace: st);
      return null;
    }
  }

  static AdhanOption? _findOption(String adhanId) {
    for (final o in AppSources.adhanOptions) {
      if (o.id == adhanId) return o;
    }
    return null;
  }

  static Future<void> ensureDownloaded(String adhanId) async {
    try {
      if (await localPathFor(adhanId) != null) return;
      final option = _findOption(adhanId);
      if (option == null) return;
      final response = await http.get(Uri.parse(option.url)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 || response.bodyBytes.length < 1024) {
        AppLogger.error('Adhan audio download failed or too small for $adhanId (status ${response.statusCode})');
        return;
      }
      final file = await _fileFor(adhanId);
      await file.writeAsBytes(response.bodyBytes);
    } catch (e, st) {
      AppLogger.error('AdhanAudioCache.ensureDownloaded failed for $adhanId', error: e, stackTrace: st);
    }
  }
}
