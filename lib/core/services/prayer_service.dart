import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_sources.dart';
import '../models/prayer_models.dart';
import 'app_logger.dart';
import 'mathhab_service.dart';
import 'settings_service.dart';

// The AlAdhan API's own field names ('Fajr', 'Dhuhr', ...) are used as
// PrayerItem.name — a locale-independent, stable ID. It's stored as the
// per-day "prayed" checkbox key (see UserProgressService.setPrayed) and
// compared across screens, so it must not change with the UI language.
// The UI layer (prayer_times_screen.dart, home_dashboard_screen.dart)
// maps this ID to a localized display name via prayerDisplayName().
const List<String> _kOrderedApiKeys = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

/// Single source of truth for prayer times: real GPS + AlAdhan API, with
/// an offline fallback to the last successful response (clearly marked
/// as cached, never presented as live), an optional manually-entered
/// city, and a resolved human-readable location label. Used by both the
/// Prayer Times screen and the Home Dashboard so "next prayer" always
/// agrees.
class PrayerService {
  PrayerService._();

  static const _cacheTimingsKey = 'cache_prayer_timings_v2';
  static const _cacheDateKey = 'cache_prayer_timings_date_v2';
  static const _cacheLocationLabelKey = 'cache_prayer_location_label_v2';
  static const _cacheModeKey = 'cache_prayer_mode_v2'; // 'gps' | 'manual'
  static const _cacheManualCityKey = 'cache_prayer_manual_city_v2';
  static const _cacheLatKey = 'cache_prayer_lat_v1';
  static const _cacheLonKey = 'cache_prayer_lon_v1';
  static const _cacheTzKey = 'cache_prayer_tz_v1';

  // ---- Time zone handling (v1.55) ------------------------------------------
  // AlAdhan returns clock times ("05:03") in the time zone of the REQUESTED
  // coordinates, not of this device. They used to be stamped onto the device's
  // own date/zone, which is wrong whenever the two zones differ (a manually
  // chosen city in another zone, travel, VPN...). The API's `meta.timezone`
  // is now used to turn each clock time into the correct absolute instant.
  static bool _tzReady = false;

  static tz.Location? _locationOrNull(String? name) {
    if (name == null || name.isEmpty) return null;
    try {
      if (!_tzReady) {
        tz_data.initializeTimeZones();
        _tzReady = true;
      }
      return tz.getLocation(name);
    } catch (_) {
      return null;
    }
  }

  static String? _tzNameFrom(dynamic decoded) {
    try {
      final meta = decoded['data']['meta'];
      final name = meta is Map ? meta['timezone'] : null;
      return name is String && name.isNotEmpty ? name : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheTimingsKey);
    await prefs.remove(_cacheDateKey);
  }

  /// Whether the user last used GPS or a manually-entered city, so the
  /// app can restore the right mode on next launch without re-asking.
  static Future<String> savedMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheModeKey) ?? 'gps';
  }

  static Future<String?> savedManualCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheManualCityKey);
  }

  /// Throws a [PrayerAvailability] (not an Exception) on failure so the
  /// UI can render an exact, real reason rather than a generic message.
  static Future<int> _schoolFromMathhab() async {
    final mathhab = await MathhabService.getMathhab();
    return mathhab == 'Hanafi' ? 1 : 0;
  }

  static Future<PrayerTimesResult> fetchPrayerTimes() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final cached = await _tryLoadCache();
      if (cached != null) return cached;
      throw PrayerAvailability.locationServiceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      final cached = await _tryLoadCache();
      if (cached != null) return cached;
      throw PrayerAvailability.permissionDeniedForever;
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      final cached = await _tryLoadCache();
      if (cached != null) return cached;
      throw PrayerAvailability.permissionDenied;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));

      final url = AppSources.prayerTimesUrl(
        latitude: position.latitude,
        longitude: position.longitude,
        method: appSettings.prayerCalcMethod,
        school: await _schoolFromMathhab(),
      );

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final timings = decoded['data']['timings'] as Map<String, dynamic>;

      final locationLabel = await _reverseGeocode(position.latitude, position.longitude);
      final tzName = _tzNameFrom(decoded);

      await _saveCache(
        timings: timings,
        locationLabel: locationLabel,
        mode: 'gps',
        manualCity: null,
        latitude: position.latitude,
        longitude: position.longitude,
        tzName: tzName,
      );

      return _buildResult(timings, isFromCache: false, cachedAt: DateTime.now(), locationLabel: locationLabel, tzName: tzName);
    } catch (e, st) {
      AppLogger.error('Prayer times fetch failed, falling back to cache', error: e, stackTrace: st);
      final cached = await _tryLoadCache();
      if (cached != null) return cached;
      throw PrayerAvailability.networkErrorNoCache;
    }
  }

  /// Fetches prayer times for a manually-entered city/address using
  /// AlAdhan's geocoding-enabled `timingsByAddress` endpoint — no GPS
  /// involved. Throws a plain [Exception] with a message on failure
  /// (city not found / network error) since this is a user-initiated
  /// action with its own error path in the UI, not the app-startup flow.
  static Future<PrayerTimesResult> fetchPrayerTimesForCity(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) {
      throw Exception('يرجى إدخال اسم مدينة');
    }

    try {
      // ROOT CAUSE FIX: AlAdhan's `timingsByAddress` endpoint relies on
      // ITS OWN server-side geocoding, which frequently fails to
      // resolve valid city names (especially Arabic-script names, or a
      // bare city name without ", Country") and returns a non-200
      // response -- showing "city not found" even for cities that
      // clearly exist. Nominatim forward-geocoding is used here
      // instead (the SAME reliable service already used for
      // reverse-geocoding above), converting the city name to
      // coordinates ourselves, then calling the plain lat/lon `timings`
      // endpoint already proven to work for GPS-based lookups.
      final coords = await _forwardGeocode(trimmed);
      if (coords == null) {
        throw Exception('لم يتم العثور على هذه المدينة. جرّب كتابتها بصيغة "المدينة، الدولة"');
      }

      final url = AppSources.prayerTimesUrl(
        latitude: coords.$1,
        longitude: coords.$2,
        method: appSettings.prayerCalcMethod,
        school: await _schoolFromMathhab(),
      );
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('تعذّر جلب مواقيت الصلاة لهذه المدينة، حاول مرة أخرى');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final timings = decoded['data']['timings'] as Map<String, dynamic>;

      final tzName = _tzNameFrom(decoded);

      await _saveCache(
        timings: timings,
        locationLabel: trimmed,
        mode: 'manual',
        manualCity: trimmed,
        latitude: coords.$1,
        longitude: coords.$2,
        tzName: tzName,
      );

      return _buildResult(timings, isFromCache: false, cachedAt: DateTime.now(), locationLabel: trimmed, tzName: tzName);
    } catch (e, st) {
      AppLogger.error('Manual city prayer times fetch failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Forward-geocodes a free-text city name to (latitude, longitude)
  /// using Nominatim -- the same OpenStreetMap service already used for
  /// reverse-geocoding in this file, now used in the other direction.
  static Future<(double, double)?> _forwardGeocode(String city) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(city)}&limit=1&accept-language=ar',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': AppSources.httpUserAgent},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;
      return (lat, lon);
    } catch (e, st) {
      AppLogger.error('Forward geocoding failed for city search', error: e, stackTrace: st);
      return null;
    }
  }

  /// Restores the last-used mode (GPS or manual city) on app start,
  /// falling back to cache if a fresh fetch isn't possible right now.
  static Future<PrayerTimesResult> fetchUsingSavedPreference() async {
    final mode = await savedMode();
    if (mode == 'manual') {
      final city = await savedManualCity();
      if (city != null && city.isNotEmpty) {
        try {
          return await fetchPrayerTimesForCity(city);
        } catch (_) {
          final cached = await _tryLoadCache();
          if (cached != null) return cached;
          rethrow;
        }
      }
    }
    return fetchPrayerTimes();
  }

  static Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&accept-language=ar&zoom=10',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': AppSources.httpUserAgent},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final address = decoded['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'];
      final country = address['country'];

      if (city != null && country != null) return '$city، $country';
      if (city != null) return city.toString();
      return decoded['display_name']?.toString();
    } catch (e, st) {
      // Reverse geocoding is a nice-to-have label, not critical — log
      // and continue without it rather than failing the whole fetch.
      AppLogger.error('Reverse geocoding failed', error: e, stackTrace: st);
      return null;
    }
  }

  static Future<void> _saveCache({
    required Map<String, dynamic> timings,
    required String? locationLabel,
    required String mode,
    required String? manualCity,
    double? latitude,
    double? longitude,
    String? tzName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (tzName != null) {
      await prefs.setString(_cacheTzKey, tzName);
    } else {
      await prefs.remove(_cacheTzKey);
    }
    await prefs.setString(_cacheTimingsKey, jsonEncode(timings));
    await prefs.setString(_cacheDateKey, DateTime.now().toIso8601String());
    await prefs.setString(_cacheModeKey, mode);
    if (locationLabel != null) {
      await prefs.setString(_cacheLocationLabelKey, locationLabel);
    }
    if (manualCity != null) {
      await prefs.setString(_cacheManualCityKey, manualCity);
    } else if (mode == 'gps') {
      await prefs.remove(_cacheManualCityKey);
    }
    if (latitude != null && longitude != null) {
      await prefs.setDouble(_cacheLatKey, latitude);
      await prefs.setDouble(_cacheLonKey, longitude);
    }
  }

  static Future<PrayerTimesResult?> _tryLoadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheTimingsKey);
    final dateRaw = prefs.getString(_cacheDateKey);
    if (raw == null) return null;

    final timings = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = dateRaw != null ? DateTime.tryParse(dateRaw) : null;
    final locationLabel = prefs.getString(_cacheLocationLabelKey);

    // Clock times (HH:mm) are re-applied to *today's* date. This is a
    // reasonable offline approximation (times shift by only ~1-2 min/day)
    // and is always labeled isFromCache=true in the UI, never presented
    // as a live reading.
    return _buildResult(timings, isFromCache: true, cachedAt: cachedAt, locationLabel: locationLabel, tzName: prefs.getString(_cacheTzKey));
  }

  static PrayerTimesResult _buildResult(
    Map<String, dynamic> timings, {
    required bool isFromCache,
    DateTime? cachedAt,
    String? locationLabel,
    String? tzName,
  }) {
    final now = DateTime.now();
    // "Today" is the date in the prayer location's zone (equals the device date
    // when both share a zone).
    final loc = _locationOrNull(tzName);
    final today = loc != null ? tz.TZDateTime.now(loc) : now;
    final prayers = _buildPrayersForDate(timings, today.year, today.month, today.day, tzName: tzName);

    final next = _nextPrayer(prayers, now);

    return PrayerTimesResult(
      prayers: prayers,
      next: next,
      isFromCache: isFromCache,
      cachedAt: cachedAt,
      locationLabel: locationLabel,
    );
  }

  static PrayerItem _nextPrayer(List<PrayerItem> prayers, DateTime now) {
    for (final prayer in prayers) {
      if (prayer.dateTime.isAfter(now)) return prayer;
    }
    final fajrTomorrow = prayers.first.dateTime.add(const Duration(days: 1));
    return PrayerItem(
      name: prayers.first.name,
      timeText: prayers.first.timeText,
      dateTime: fajrTomorrow,
    );
  }

  /// Fetches the next [days] days of prayer times (starting tomorrow) for
  /// notification scheduling, using ONE calendar request per month touched.
  /// Uses the coordinates saved by the last successful fetch (GPS or manual
  /// city); never asks for location permission. Returns an empty map when no
  /// location is known yet or the network is unavailable  the caller then just
  /// schedules what it has (today's notifications are unaffected).
  ///
  /// Key = date at midnight (device-local calendar date of the prayer instant's
  /// location day), value = that day's prayers with the user's offsets applied.
  static Future<Map<DateTime, List<PrayerItem>>> fetchUpcomingPrayers({int days = 14}) async {
    final result = <DateTime, List<PrayerItem>>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_cacheLatKey);
      final lon = prefs.getDouble(_cacheLonKey);
      if (lat == null || lon == null) return result;
      final school = await _schoolFromMathhab();
      final method = appSettings.prayerCalcMethod;

      final start = DateTime.now().add(const Duration(days: 1));
      final wanted = <DateTime>[
        for (var i = 0; i < days; i++) DateTime(start.year, start.month, start.day + i),
      ];
      final months = <(int, int)>{for (final d in wanted) (d.year, d.month)};

      for (final (year, month) in months) {
        final url = AppSources.prayerCalendarUrl(latitude: lat, longitude: lon, month: month, year: year, method: method, school: school);
        final response = await http.get(Uri.parse(url), headers: {'User-Agent': AppSources.httpUserAgent}).timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) continue;
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decoded['data'];
        if (data is! List) continue;
        for (final entry in data) {
          if (entry is! Map) continue;
          final gregorian = (entry['date'] as Map?)?['gregorian'] as Map?;
          final day = int.tryParse('${gregorian?['day']}');
          final timings = entry['timings'];
          if (day == null || timings is! Map) continue;
          final wantedDay = wanted.where((d) => d.year == year && d.month == month && d.day == day);
          if (wantedDay.isEmpty) continue;
          final meta = entry['meta'];
          final tzName = meta is Map && meta['timezone'] is String ? meta['timezone'] as String : null;
          result[wantedDay.first] = _buildPrayersForDate(Map<String, dynamic>.from(timings), year, month, day, tzName: tzName);
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to fetch upcoming prayer times for scheduling', error: e, stackTrace: st);
    }
    return result;
  }

  /// Tomorrow's prayers only (kept for callers that need just the next day).
  static Future<List<PrayerItem>?> fetchTomorrowPrayers() async {
    final upcoming = await fetchUpcomingPrayers(days: 1);
    return upcoming.isEmpty ? null : upcoming.values.first;
  }

  /// Builds the day's prayers as absolute instants (see the time zone note
  /// above) with the user's per-prayer offsets applied ONCE, here, so the
  /// list, the countdown, the notifications and the widget can never disagree.
  static List<PrayerItem> _buildPrayersForDate(
    Map<String, dynamic> timings,
    int year,
    int month,
    int day, {
    String? tzName,
  }) {
    final loc = _locationOrNull(tzName);
    final prayers = <PrayerItem>[];
    for (final key in _kOrderedApiKeys) {
      final clean = _cleanTime(timings[key]);
      final parts = clean.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final offset = appSettings.prayerOffsets[key] ?? 0;

      final base = loc != null
          ? DateTime.fromMillisecondsSinceEpoch(tz.TZDateTime(loc, year, month, day, hour, minute).millisecondsSinceEpoch)
          : DateTime(year, month, day, hour, minute);

      final shown = (((hour * 60 + minute + offset) % 1440) + 1440) % 1440;
      final timeText = '${(shown ~/ 60).toString().padLeft(2, '0')}:${(shown % 60).toString().padLeft(2, '0')}';

      prayers.add(PrayerItem(
        name: key,
        timeText: timeText,
        dateTime: base.add(Duration(minutes: offset)),
      ));
    }
    return prayers;
  }

  static String _cleanTime(dynamic value) {
    final text = value.toString();
    if (text.contains(' ')) return text.split(' ').first;
    return text;
  }

  /// Invalidate cached prayer times.
  /// NOTE: not yet wired to any automatic timezone/time-change trigger --
  /// call this manually (e.g. on app resume) until a real native
  /// TIMEZONE_CHANGED listener is implemented. See README known limitations.
  static Future<void> invalidatePrayerCache() async {
    AppLogger.info('[prayer_service] Invalidating cached prayer times...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_prayer_times');
    await prefs.remove('prayer_times_timestamp');
    AppLogger.info('[prayer_service] Prayer cache invalidated');
  }

}
