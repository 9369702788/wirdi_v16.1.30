import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// Thrown by SyncService methods when there is no signed-in user to
/// sync for -- previously uploadAll()/downloadAll() just silently
/// returned in that case, which the UI (account_screen._sync())
/// misread as "sync completed successfully" and showed a false
/// success message even though nothing was actually synced.
class NotSignedInException implements Exception {
  @override
  String toString() => 'Not signed in';
}

/// Collects any per-section failures that happened during an otherwise
/// "successful" upload/download so the UI can show a partial-failure
/// warning instead of silently claiming complete success.
class PartialSyncException implements Exception {
  final List<String> failedSections;
  PartialSyncException(this.failedSections);
  @override
  String toString() => 'Sync completed with errors in: ${failedSections.join(", ")}';
}

/// Thrown when a sync attempt fails in the specific pattern that means
/// Firestore's security rules were never actually Published on the live
/// Firebase Console for this project (they exist only as documentation
/// in FIRESTORE_RULES.md, which this app cannot deploy for you). This
/// is the most common reason sync "does nothing at all" between two
/// devices signed into the same account: every read AND write is
/// rejected with permission-denied, so data never leaves either device.
class FirestoreRulesNotPublishedException implements Exception {
  @override
  String toString() =>
      'Cloud sync is blocked by Firestore security rules. Open the Firebase Console for this project, '
      'go to Firestore Database > Rules, paste the rules from FIRESTORE_RULES.md, and click Publish.';
}

/// All Firestore documents (users/{uid}/data/{name}) that sync reads/writes.
/// Single source of truth used by account deletion.
const List<String> allSyncedDocumentNames = [
  'settings', 'quran_progress', 'tasbeeh', 'profile', 'favorites', 'prayer_log', 'progress_stats',
  'bookmarks', 'khatma', 'tasbeeh_custom', 'my_duas', 'custom_azkar', 'sadaqah', 'qada',
  'muhasabah', 'recitation_mistakes',
];

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _syncing = false;
  DateTime? _lastSyncAt;
  bool get isSyncing => _syncing;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  // Firestore document paths need an EVEN number of segments --
  // 'users/{uid}/settings' (3 segments) is invalid and throws
  // immediately. 'users/{uid}/data/settings' (4 segments) is correct.
  DocumentReference<Map<String, dynamic>> _doc(String path) => _db.doc('users/$_uid/data/$path');

  /// Converts a Firestore numeric field to an int, tolerating both
  /// int and double representations (Firestore/JS interop can return
  /// either depending on how a value was originally written) -- a bare
  /// `as int` cast would crash on a double and, before this fix, that
  /// crash silently aborted every remaining section of downloadAll(),
  /// which is exactly why some devices ended up with partially-restored
  /// data (e.g. tasbeeh synced but favorites/bookmarks/khatma did not).
  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  /// ROOT CAUSE FIX: uploadAll()/downloadAll() used to be single try/catch
  /// blocks around ALL sections -- one bad field in one section (a type
  /// cast error, a malformed document, etc.) threw and aborted every
  /// section after it with ZERO indication to the user of what actually
  /// made it through. This runs each named section in total isolation:
  /// a failure is logged and collected, but every other section still
  /// runs. The caller finds out via [PartialSyncException] if anything
  /// failed, instead of a full sync silently only doing part of the job.
  Future<void> _runIsolated(String name, Future<void> Function() body, List<String> failures) async {
    try {
      await body();
    } catch (e, st) {
      failures.add(name);
      AppLogger.error('Sync section "$name" failed', error: e, stackTrace: st);
      debugPrint('[SyncService] Section "$name" failed: $e');
    }
  }

  /// ROOT CAUSE FIX: every section below except "tasbeeh" was reading
  /// SharedPreferences keys that DO NOT MATCH what the real owning
  /// service actually uses -- e.g. this used to read
  /// 'theme_mode'/'locale'/'font_size' while settings_service.dart
  /// actually stores 'settings_theme_mode'/'settings_locale'/
  /// 'settings_font_scale'; 'favorites_data' doesn't exist anywhere
  /// (real favorites are THREE separate lists: favorite_ayahs_all/
  /// favorite_azkar_all/favorite_hadiths_all in
  /// user_progress_service.dart); 'bookmarks_data' should be
  /// 'advanced_bookmarks_v1'; 'khatma_plans_v2' should be
  /// 'khatma_plans_v2_json'; 'last_reading_surah'/'last_reading_ayah'/
  /// 'total_pages_read' should be 'last_surah_number'/
  /// 'last_ayah_number'/'wird_lifetime_pages_total'; and
  /// 'prayer_log_data' doesn't exist at all -- real prayer history is
  /// stored per-day under keys like 'prayed_2026-08-31'. Every one of
  /// these mismatches meant uploadAll() always read a key that was
  /// null/default and wrote a Firestore field nothing ever read back
  /// correctly -- sync silently did nothing for that section on every
  /// run, without ever throwing an error, since a missing local key
  /// just resolves to a harmless-looking default. "tasbeeh" was the
  /// ONE section that already happened to use the real key prefix
  /// ('tasbeeh_total_'), which is exactly why it was the only thing
  /// that ever actually synced. The fake "achievements" section is
  /// removed entirely -- 'unlocked_achievements' was never written by
  /// any real feature; achievements are computed live from
  /// already-synced stats (see achievement_service.dart), so they
  /// don't need their own sync section.
  Future<void> uploadAll() async {
    if (_uid == null) throw NotSignedInException();
    _syncing = true;
    final failures = <String>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = FieldValue.serverTimestamp();

      await _runIsolated('settings', () async {
        await _doc('settings').set({
          'themeMode': prefs.getString('settings_theme_mode') ?? 'system',
          'colorTheme': prefs.getString('settings_color_theme') ?? 'emerald',
          'locale': prefs.getString('settings_locale') ?? 'ar',
          'fontScale': prefs.getDouble('settings_font_scale') ?? 1.0,
          'wirdTarget': prefs.getInt('wird_target_pages') ?? 5,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }, failures);

      await _runIsolated('quran_progress', () async {
        await _doc('quran_progress').set({
          'lastSurahNumber': prefs.getInt('last_surah_number'),
          'lastSurahName': prefs.getString('last_surah_name'),
          'lastAyahNumber': prefs.getInt('last_ayah_number'),
          'lifetimePagesTotal': prefs.getInt('wird_lifetime_pages_total') ?? 0,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }, failures);

      await _runIsolated('tasbeeh', () async {
        final tasbeehData = <String, dynamic>{};
        int grandTotal = 0;
        for (final key in prefs.getKeys()) {
          if (key.startsWith('tasbeeh_total_')) {
            final phraseId = key.replaceFirst('tasbeeh_total_', '');
            final val = prefs.getInt(key) ?? 0;
            tasbeehData[phraseId] = val;
            grandTotal += val;
          }
        }
        await _doc('tasbeeh').set({'phrases': tasbeehData, 'grandTotal': grandTotal, 'updatedAt': now}, SetOptions(merge: true));
      }, failures);

      await _runIsolated('profile', () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _doc('profile').set({'displayName': user.displayName ?? '', 'email': user.email ?? '', 'photoUrl': user.photoURL ?? '', 'lastSyncAt': now}, SetOptions(merge: true));
        }
      }, failures);

      await _runIsolated('favorites', () async {
        await _doc('favorites').set({
          'ayahs': prefs.getStringList('favorite_ayahs_all') ?? [],
          'azkar': prefs.getStringList('favorite_azkar_all') ?? [],
          'hadiths': prefs.getStringList('favorite_hadiths_all') ?? [],
          // NEW (v121): radio station favorites are a SEPARATE feature
          // with their own storage (RadioService's 'radio_favorites'
          // key, a Set<String> of station ids) -- not the same list as
          // Quran ayah / Azkar / Hadith favorites above. Found by
          // auditing every screen the user mentioned (Quran, Azkar,
          // Dua, Radio) individually rather than assuming "favorites"
          // is one single feature across the app.
          'radioStations': prefs.getStringList('radio_favorites') ?? [],
          'updatedAt': now,
        }, SetOptions(merge: true));
      }, failures);

      await _runIsolated('prayer_log', () async {
        final byDate = <String, dynamic>{};
        for (final key in prefs.getKeys()) {
          if (key.startsWith('prayed_')) {
            byDate[key.replaceFirst('prayed_', '')] = prefs.getStringList(key) ?? [];
          }
        }
        await _doc('prayer_log').set({'byDate': byDate, 'updatedAt': now}, SetOptions(merge: true));
      }, failures);

      // NEW (v120): every lifetime/streak/daily-history stat tracked by
      // UserProgressService that ISN'T already covered above --
      // lifetime azkar/tasbeeh/prayers counters, wird streaks, khatma
      // completion count, completed-surahs set, and the full per-day
      // history maps (wird pages, azkar completed, tasbeeh daily
      // totals, fasting, dua-read) that back the 7-day activity
      // summary and Home Dashboard percentages. Previously NONE of
      // this synced at all -- only the per-phrase tasbeeh totals and
      // today's prayer checklist did -- which is exactly why a second
      // device showed 0%/empty progress widgets despite a first
      // device having real accumulated history.
      await _runIsolated('progress_stats', () async {
        final wirdPagesByDate = <String, dynamic>{};
        final azkarCompletedByDate = <String, dynamic>{};
        final tasbeehDailyByDate = <String, dynamic>{};
        final fastingByDate = <String, dynamic>{};
        final duaReadByDate = <String, dynamic>{};
        for (final key in prefs.getKeys()) {
          if (key.startsWith('wird_pages_')) {
            wirdPagesByDate[key.replaceFirst('wird_pages_', '')] = prefs.getInt(key) ?? 0;
          } else if (key.startsWith('azkar_completed_')) {
            azkarCompletedByDate[key.replaceFirst('azkar_completed_', '')] = prefs.getStringList(key) ?? [];
          } else if (key.startsWith('tasbeeh_daily_total_')) {
            tasbeehDailyByDate[key.replaceFirst('tasbeeh_daily_total_', '')] = prefs.getInt(key) ?? 0;
          } else if (key.startsWith('fasting_')) {
            fastingByDate[key.replaceFirst('fasting_', '')] = prefs.getBool(key) ?? false;
          } else if (key.startsWith('dua_read_')) {
            duaReadByDate[key.replaceFirst('dua_read_', '')] = prefs.getBool(key) ?? false;
          }
        }
        await _doc('progress_stats').set({
          'azkarLifetimeTotal': prefs.getInt('azkar_lifetime_total') ?? 0,
          'tasbeehLifetimeTotal': prefs.getInt('tasbeeh_lifetime_total') ?? 0,
          'prayersLifetimeTotal': prefs.getInt('prayers_lifetime_total') ?? 0,
          'khatmasCompletedCount': prefs.getInt('khatmas_completed_count') ?? 0,
          'khatmasCompletedIds': prefs.getStringList('khatmas_completed_ids') ?? [],
          'completedSurahsAll': prefs.getStringList('completed_surahs_all') ?? [],
          'wirdProgressPages': prefs.getInt('wird_progress_pages') ?? 0,
          'wirdProgressDay': prefs.getString('wird_progress_day'),
          'wirdStreak': prefs.getInt('wird_streak') ?? 0,
          'wirdStreakLastDay': prefs.getString('wird_streak_last_day'),
          'wirdLongestStreak': prefs.getInt('wird_longest_streak') ?? 0,
          'congregationLifetimeTotal': prefs.getInt('congregation_lifetime_total') ?? 0,
          'wirdPagesByDate': wirdPagesByDate,
          'azkarCompletedByDate': azkarCompletedByDate,
          'tasbeehDailyByDate': tasbeehDailyByDate,
          'fastingByDate': fastingByDate,
          'duaReadByDate': duaReadByDate,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }, failures);

      for (final e in {'bookmarks': 'advanced_bookmarks_v1', 'khatma': 'khatma_plans_v2_json', 'tasbeeh_custom': 'tasbeeh_custom_phrases_v1', 'my_duas': 'my_duas_v1', 'custom_azkar': 'custom_azkar_items_v1', 'sadaqah': 'sadaqah_entries_v1', 'qada': 'qada_counts_v1'}.entries) {
        await _runIsolated(e.key, () async {
          final val = prefs.getString(e.value);
          if (val != null) await _doc(e.key).set({'data': val, 'updatedAt': now}, SetOptions(merge: true));
        }, failures);
      }

      for (final e in {'muhasabah': 'muhasabah_entries_v1', 'recitation_mistakes': 'recitation_mistakes_v1'}.entries) {
        await _runIsolated(e.key, () async {
          final val = prefs.getStringList(e.value);
          if (val != null) await _doc(e.key).set({'data': val, 'updatedAt': now}, SetOptions(merge: true));
        }, failures);
      }

      _lastSyncAt = DateTime.now();
      debugPrint('[SyncService] Upload complete' + (failures.isEmpty ? '' : ' (with failures in: ${failures.join(", ")})'));
      if (failures.isNotEmpty) throw PartialSyncException(failures);
    } finally { _syncing = false; }
  }

  /// Mirror-image fix of [uploadAll]'s ROOT CAUSE FIX -- see its doc
  /// comment for the full explanation of the key mismatches this
  /// corrects. Also drops the fake "achievements" download (nothing
  /// real ever wrote that key -- see achievement_service.dart).
  // ---- Merge helpers (v1.55) ------------------------------------------------
  // A download used to overwrite local values field by field, so anything done
  // on THIS device since the last sync (a bigger streak, new favorites, today's
  // prayer ticks) could be replaced by an older cloud copy. The rules now are:
  // counters/totals keep the LARGER value, lists keep the UNION, per-day flags
  // keep "done" if either side has it. (Trade-off: an item removed on another
  // device can reappear; losing data is the worse failure.)
  Future<void> _setIntMax(SharedPreferences prefs, String key, int cloud) async {
    final local = prefs.getInt(key) ?? 0;
    if (cloud > local) await prefs.setInt(key, cloud);
  }

  Future<void> _setListUnion(SharedPreferences prefs, String key, List<String> cloud) async {
    final local = prefs.getStringList(key) ?? const <String>[];
    final merged = <String>[...local];
    for (final v in cloud) {
      if (!merged.contains(v)) merged.add(v);
    }
    if (merged.length != local.length) await prefs.setStringList(key, merged);
  }

  Future<void> downloadAll() async {
    if (_uid == null) throw NotSignedInException();
    _syncing = true;
    final failures = <String>[];
    try {
      final prefs = await SharedPreferences.getInstance();

      await _runIsolated('settings', () async {
        final s = await _doc('settings').get();
        if (s.exists) {
          final d = s.data()!;
          // FIX: 'themeMode' kept the SAME Firestore field name across
          // the v118 key-mapping rewrite, but its TYPE changed (used to
          // be an int written by the old, wrong-key code; is a String
          // now). A device that had ever synced with the pre-v118 code
          // left an int-typed 'themeMode' sitting in Firestore -- a
          // bare `d['themeMode']` passed straight to setString() then
          // throws a real TypeError ("type 'int' is not a subtype of
          // type 'String'") the instant a v118+ device downloads that
          // stale document, landing this whole section in
          // PartialSyncException ("Sync completed with errors in:
          // settings") despite nothing being conceptually wrong with
          // the NEW code by itself. Type-checking each field before
          // assigning means old, differently-typed leftover data is
          // safely skipped (as if absent) instead of crashing --
          // the next successful upload from either device overwrites
          // it with the correct type regardless.
          if (d['themeMode'] is String) await prefs.setString('settings_theme_mode', d['themeMode']);
          if (d['colorTheme'] is String) await prefs.setString('settings_color_theme', d['colorTheme']);
          if (d['locale'] is String) await prefs.setString('settings_locale', d['locale']);
          if (d['fontScale'] is num) await prefs.setDouble('settings_font_scale', (d['fontScale'] as num).toDouble());
          if (d['wirdTarget'] != null) await prefs.setInt('wird_target_pages', _asInt(d['wirdTarget']));
        }
      }, failures);

      await _runIsolated('quran_progress', () async {
        final q = await _doc('quran_progress').get();
        if (q.exists) {
          final d = q.data()!;
          if (d['lastSurahNumber'] != null) await prefs.setInt('last_surah_number', _asInt(d['lastSurahNumber']));
          if (d['lastSurahName'] is String) await prefs.setString('last_surah_name', d['lastSurahName']);
          if (d['lastAyahNumber'] != null) await prefs.setInt('last_ayah_number', _asInt(d['lastAyahNumber']));
          if (d['lifetimePagesTotal'] != null) await _setIntMax(prefs, 'wird_lifetime_pages_total', _asInt(d['lifetimePagesTotal']));
        }
      }, failures);

      await _runIsolated('tasbeeh', () async {
        final t = await _doc('tasbeeh').get();
        if (t.exists) {
          for (final e in ((t.data()!['phrases'] as Map<String, dynamic>?) ?? {}).entries) {
            await _setIntMax(prefs, 'tasbeeh_total_' + e.key, _asInt(e.value));
          }
        }
      }, failures);

      await _runIsolated('favorites', () async {
        final f = await _doc('favorites').get();
        if (f.exists) {
          final d = f.data()!;
          if (d['ayahs'] != null) await _setListUnion(prefs, 'favorite_ayahs_all', List<String>.from(d['ayahs']));
          if (d['azkar'] != null) await _setListUnion(prefs, 'favorite_azkar_all', List<String>.from(d['azkar']));
          if (d['hadiths'] != null) await _setListUnion(prefs, 'favorite_hadiths_all', List<String>.from(d['hadiths']));
          if (d['radioStations'] != null) await _setListUnion(prefs, 'radio_favorites', List<String>.from(d['radioStations']));
        }
      }, failures);

      await _runIsolated('prayer_log', () async {
        final doc = await _doc('prayer_log').get();
        if (doc.exists) {
          final byDate = (doc.data()!['byDate'] as Map<String, dynamic>?) ?? {};
          for (final e in byDate.entries) {
            await _setListUnion(prefs, 'prayed_' + e.key, List<String>.from(e.value ?? []));
          }
        }
      }, failures);

      await _runIsolated('progress_stats', () async {
        final doc = await _doc('progress_stats').get();
        if (doc.exists) {
          final d = doc.data()!;
          if (d['azkarLifetimeTotal'] != null) await _setIntMax(prefs, 'azkar_lifetime_total', _asInt(d['azkarLifetimeTotal']));
          if (d['tasbeehLifetimeTotal'] != null) await _setIntMax(prefs, 'tasbeeh_lifetime_total', _asInt(d['tasbeehLifetimeTotal']));
          if (d['prayersLifetimeTotal'] != null) await _setIntMax(prefs, 'prayers_lifetime_total', _asInt(d['prayersLifetimeTotal']));
          if (d['khatmasCompletedCount'] != null) await _setIntMax(prefs, 'khatmas_completed_count', _asInt(d['khatmasCompletedCount']));
          if (d['khatmasCompletedIds'] != null) await _setListUnion(prefs, 'khatmas_completed_ids', List<String>.from(d['khatmasCompletedIds']));
          if (d['completedSurahsAll'] != null) await _setListUnion(prefs, 'completed_surahs_all', List<String>.from(d['completedSurahsAll']));
          if (d['wirdProgressPages'] != null) await prefs.setInt('wird_progress_pages', _asInt(d['wirdProgressPages']));
          if (d['wirdProgressDay'] is String) await prefs.setString('wird_progress_day', d['wirdProgressDay']);
          if (d['wirdStreak'] != null) {
            final cloudLast = d['wirdStreakLastDay'] is String ? d['wirdStreakLastDay'] as String : '';
            final localLast = prefs.getString('wird_streak_last_day') ?? '';
            final cloudStreak = _asInt(d['wirdStreak']);
            final localStreak = prefs.getInt('wird_streak') ?? 0;
            if (cloudLast.compareTo(localLast) > 0 || (cloudLast == localLast && cloudStreak > localStreak)) {
              await prefs.setInt('wird_streak', cloudStreak);
              if (cloudLast.isNotEmpty) await prefs.setString('wird_streak_last_day', cloudLast);
            }
          }
          if (d['wirdLongestStreak'] != null) await _setIntMax(prefs, 'wird_longest_streak', _asInt(d['wirdLongestStreak']));
          if (d['congregationLifetimeTotal'] != null) await _setIntMax(prefs, 'congregation_lifetime_total', _asInt(d['congregationLifetimeTotal']));
          final wirdPagesByDate = (d['wirdPagesByDate'] as Map<String, dynamic>?) ?? {};
          for (final e in wirdPagesByDate.entries) {
            await _setIntMax(prefs, 'wird_pages_' + e.key, _asInt(e.value));
          }
          final azkarCompletedByDate = (d['azkarCompletedByDate'] as Map<String, dynamic>?) ?? {};
          for (final e in azkarCompletedByDate.entries) {
            await _setListUnion(prefs, 'azkar_completed_' + e.key, List<String>.from(e.value ?? []));
          }
          final tasbeehDailyByDate = (d['tasbeehDailyByDate'] as Map<String, dynamic>?) ?? {};
          for (final e in tasbeehDailyByDate.entries) {
            await _setIntMax(prefs, 'tasbeeh_daily_total_' + e.key, _asInt(e.value));
          }
          final fastingByDate = (d['fastingByDate'] as Map<String, dynamic>?) ?? {};
          for (final e in fastingByDate.entries) {
            if (e.value == true) await prefs.setBool('fasting_' + e.key, true);
          }
          final duaReadByDate = (d['duaReadByDate'] as Map<String, dynamic>?) ?? {};
          for (final e in duaReadByDate.entries) {
            if (e.value == true) await prefs.setBool('dua_read_' + e.key, true);
          }
        }
      }, failures);

      for (final e in {'bookmarks': 'advanced_bookmarks_v1', 'khatma': 'khatma_plans_v2_json', 'tasbeeh_custom': 'tasbeeh_custom_phrases_v1', 'my_duas': 'my_duas_v1', 'custom_azkar': 'custom_azkar_items_v1', 'sadaqah': 'sadaqah_entries_v1', 'qada': 'qada_counts_v1'}.entries) {
        await _runIsolated(e.key, () async {
          final doc = await _doc(e.key).get();
          if (doc.exists && doc.data()!['data'] != null) await prefs.setString(e.value, doc.data()!['data']);
        }, failures);
      }

      for (final e in {'muhasabah': 'muhasabah_entries_v1', 'recitation_mistakes': 'recitation_mistakes_v1'}.entries) {
        await _runIsolated(e.key, () async {
          final doc = await _doc(e.key).get();
          if (doc.exists && doc.data()!['data'] != null) await _setListUnion(prefs, e.value, List<String>.from(doc.data()!['data']));
        }, failures);
      }

      _lastSyncAt = DateTime.now();
      debugPrint('[SyncService] Download complete' + (failures.isEmpty ? '' : ' (with failures in: ${failures.join(", ")})'));
      if (failures.isNotEmpty) throw PartialSyncException(failures);
    } finally { _syncing = false; }
  }

  static const String _localLastSyncedKey = 'sync_local_last_synced_at_ms';

  /// Reads the 'settings' document's server-written updatedAt as a proxy
  /// for cloud data freshness overall -- uploadAll() writes it in the
  /// same section as everything else.
  /// True after the most recent [_reconcile] call if reading the cloud
  /// freshness marker failed for a reason worth surfacing to the user
  /// (most importantly: a Firestore permission-denied error, which
  /// almost always means the security rules documented in
  /// FIRESTORE_RULES.md were never actually pasted into and Published
  /// on the live Firebase Console -- that markdown file is
  /// documentation only, publishing it is a manual one-time step this
  /// code cannot do for you). Previously this failure was logged
  /// internally and then silently treated exactly like "the cloud has
  /// no data yet", so a fully-blocked Firestore project looked
  /// identical to a brand-new empty one: every sync would silently
  /// fall through to uploadAll(), which ALSO fails permission-denied
  /// (and gets correctly collected into a PartialSyncException) -- but
  /// nothing ever pointed specifically at "your Firestore rules are not
  /// published" as the likely root cause.
  bool lastReconcileHadPermissionError = false;

  Future<DateTime?> _cloudLastUpdated() async {
    if (_uid == null) return null;
    try {
      final snap = await _doc('settings').get();
      final ts = snap.data()?['updatedAt'];
      if (ts is Timestamp) return ts.toDate();
    } on FirebaseException catch (e, st) {
      if (e.code == 'permission-denied') {
        lastReconcileHadPermissionError = true;
      }
      AppLogger.error('Failed to read cloud updatedAt (code: ${e.code})', error: e, stackTrace: st);
    } catch (e, st) {
      AppLogger.error('Failed to read cloud updatedAt', error: e, stackTrace: st);
    }
    return null;
  }

  /// ROOT CAUSE FIX (v100): this used to store DateTime.now() -- the
  /// DEVICE's own local wall clock -- as "when this device last
  /// synced", and then compare that directly against [_cloudLastUpdated],
  /// which is a FIRESTORE SERVER timestamp. Those are two different
  /// clock domains. If a device's local clock is off from real time by
  /// even a few minutes (wrong timezone, wrong date, clock drift -- all
  /// common, especially on test devices), the comparison in
  /// [_reconcileImpl] silently stops making sense: a device whose clock
  /// reads "ahead" of the server will conclude the cloud can never be
  /// newer than its own last-synced marker ever again, so it always
  /// takes the upload branch and never downloads -- even when the
  /// cloud genuinely has newer data from the other device. This exactly
  /// matches "sync reports success on both devices, but nothing ever
  /// actually moves between them."
  ///
  /// Fix: never store a device-local timestamp for this comparison at
  /// all. Instead, immediately re-read the cloud's own timestamp right
  /// after a successful upload/download and store THAT -- so both sides
  /// of the freshness comparison always come from the same clock
  /// (Firestore's server time), and device clock skew can no longer
  /// affect the decision.
  Future<void> _markLocalSynced() async {
    final confirmedCloudTime = await _cloudLastUpdated();
    if (confirmedCloudTime == null) {
      // Could not confirm the cloud's timestamp right now (e.g. a
      // transient network blip immediately after a successful sync) --
      // leave the previous marker in place rather than clearing it or
      // writing something unreliable.
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localLastSyncedKey, confirmedCloudTime.millisecondsSinceEpoch);
  }

  /// ROOT CAUSE FIX (v96): this used to be the ONLY place that ever
  /// downloaded from the cloud -- it only ran once, at sign-in time.
  /// Every other sync trigger in the app (the manual "Sync Now" button
  /// in account_screen.dart, AND the automatic sync fired from
  /// root_shell.dart on every app open) called syncNow(), which was a
  /// blind upload-only operation. That meant: every time EITHER device
  /// was simply opened, it silently overwrote the cloud with its own
  /// local state regardless of whether the cloud actually had newer
  /// data from the OTHER device -- so whichever device was opened most
  /// recently always "won", and the other device could never receive
  /// updates at all. That is the exact "sync doesn't work between two
  /// devices" symptom. Fix: extract the freshness check into a shared
  /// [_reconcile] method and have BOTH syncOnSignIn() and syncNow() use
  /// it, so every sync trigger in the app -- automatic or manual --
  /// actually checks whether the cloud has newer data before deciding
  /// to push local data over it, instead of only the one-time
  /// sign-in path doing that check.
  ///
  /// This is still a whole-document/whole-sync freshness comparison,
  /// not a true per-field merge, so a local edit made after a sync but
  /// on the losing side of a comparison can still be overwritten -- but
  /// it fixes the much bigger, actively-breaking bug where cross-device
  /// sync could never receive updates via normal app usage at all.
  /// GUARD (v99): nothing previously stopped multiple overlapping
  /// _reconcile() calls from running concurrently -- e.g. rapid
  /// lock/unlock cycles during testing each fire
  /// didChangeAppLifecycleState(resumed) in root_shell.dart, and each
  /// one called syncNow() with no check for a sync already in
  /// progress. Concurrent reconciles can each read a similar "cloud
  /// freshness" snapshot and then independently decide to upload,
  /// multiplying writes without any of them being individually wrong --
  /// consistent with the very high write-to-read ratio observed in the
  /// real Firestore usage graphs. This makes a second concurrent call
  /// simply wait for the first one to finish and then return, instead
  /// of starting a fully independent second reconcile.
  Future<void>? _inFlightReconcile;

  Future<void> _reconcile() async {
    if (_inFlightReconcile != null) {
      debugPrint('[SyncService] _reconcile() already in progress -- awaiting the existing call instead of starting a new one.');
      return _inFlightReconcile!;
    }
    final completer = Completer<void>();
    _inFlightReconcile = completer.future;
    try {
      await _reconcileImpl();
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inFlightReconcile = null;
    }
  }

  Future<void> _reconcileImpl() async {
    lastReconcileHadPermissionError = false;
    final cloudUpdatedAt = await _cloudLastUpdated();
    final prefs = await SharedPreferences.getInstance();
    final localLastSyncedMs = prefs.getInt(_localLastSyncedKey);

    final cloudIsNewer = cloudUpdatedAt != null &&
        (localLastSyncedMs == null || cloudUpdatedAt.millisecondsSinceEpoch > localLastSyncedMs);

    try {
      if (cloudIsNewer) {
        await downloadAll();
      } else {
        await uploadAll();
      }
    } on PartialSyncException {
      // Every section failing AND the freshness check having already
      // hit permission-denied is the unambiguous "Firestore rules were
      // never published" signature -- surface it as its own exception
      // so the UI can show one clear, actionable message instead of a
      // generic "partially failed: settings, quran_progress, ...".
      if (lastReconcileHadPermissionError) {
        await _markLocalSynced();
        throw FirestoreRulesNotPublishedException();
      }
      rethrow;
    }
    await _markLocalSynced();
  }

  Future<void> syncOnSignIn() async => _reconcile();

  /// Was previously `await uploadAll(); await _markLocalSynced();` --
  /// a blind, direction-less upload. See [_reconcile] doc above for why
  /// that silently broke cross-device sync. Now shares the exact same
  /// freshness-aware logic as syncOnSignIn().
  Future<void> syncNow() async => _reconcile();

  /// Deletes all user data from Firestore (called before account deletion).
  Future<void> deleteAllCloudData() async {
    if (_uid == null) return;
    // Every document SyncService ever writes under users/{uid}/data/. This list
    // MUST cover all of them: after the account is deleted the security rules
    // (auth.uid == userId) make it impossible to remove anything later.
    // (v1.55: custom_azkar, sadaqah, qada, muhasabah and recitation_mistakes
    // were missing, so they survived account deletion.)
    final collections = <String>[
      ...allSyncedDocumentNames,
    ];
    for (final col in collections) {
      try {
        await _doc(col).delete();
      } catch (e, st) {
        AppLogger.error('Failed to delete cloud collection "' + col + '" during account deletion', error: e, stackTrace: st);
      }
    }
    debugPrint('[SyncService] All cloud data deleted');
  }
}
