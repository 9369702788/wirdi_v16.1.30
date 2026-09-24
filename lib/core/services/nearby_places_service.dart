import '../data/app_sources.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/nearby_place.dart';
import 'app_logger.dart';

/// Finds nearby mosques and halal restaurants using:
/// 1. Fast Overpass API mirrors with optimized query
/// 2. Automatic fallback to OpenStreetMap Nominatim Search API
///    if Overpass instances are down or throttled.
class NearbyPlacesService {
  NearbyPlacesService._();

  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  static Future<List<NearbyPlace>> findMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    String fallbackName = 'Mosque',
  }) async {
    final query = '[out:json][timeout:15];'
        '('
        'node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);'
        'way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);'
        'node["building"="mosque"](around:$radiusMeters,$latitude,$longitude);'
        'way["building"="mosque"](around:$radiusMeters,$latitude,$longitude);'
        'node["amenity"="place_of_worship"](around:$radiusMeters,$latitude,$longitude);'
        ');'
        'out center 40;';

    final results = await _queryOverpass(query, latitude, longitude, fallbackName);
    if (results.isNotEmpty) return results;

    // Fallback to Nominatim if Overpass returned empty or failed
    return _queryNominatim('مسجد', latitude, longitude, fallbackName);
  }

  static Future<List<NearbyPlace>> findHalalRestaurants({
    required double latitude,
    required double longitude,
    int radiusMeters = 8000,
    String fallbackName = 'Halal Restaurant',
  }) async {
    final query = '[out:json][timeout:15];'
        '('
        'node["amenity"="restaurant"]["diet:halal"="yes"](around:$radiusMeters,$latitude,$longitude);'
        'way["amenity"="restaurant"]["diet:halal"="yes"](around:$radiusMeters,$latitude,$longitude);'
        'node["amenity"="restaurant"](around:$radiusMeters,$latitude,$longitude);'
        'node["amenity"="fast_food"](around:$radiusMeters,$latitude,$longitude);'
        ');'
        'out center 40;';

    final results = await _queryOverpass(query, latitude, longitude, fallbackName);
    if (results.isNotEmpty) return results;

    // Fallback to Nominatim search
    return _queryNominatim('مطعم', latitude, longitude, fallbackName);
  }

  static Future<List<NearbyPlace>> _queryOverpass(
    String overpassQuery,
    double lat,
    double lon,
    String fallbackName,
  ) async {
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'User-Agent': AppSources.httpUserAgent,
                'Accept': 'application/json',
              },
              body: {'data': overpassQuery},
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode != 200) continue;

        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final elements = decoded['elements'] as List<dynamic>? ?? [];
        if (elements.isEmpty) continue;

        final places = <NearbyPlace>[];
        for (final el in elements) {
          final map = el as Map<String, dynamic>;
          final center = map['center'] as Map<String, dynamic>?;
          final placeLat = (map['lat'] as num?)?.toDouble() ?? (center?['lat'] as num?)?.toDouble();
          final placeLon = (map['lon'] as num?)?.toDouble() ?? (center?['lon'] as num?)?.toDouble();
          if (placeLat == null || placeLon == null) continue;

          final tags = map['tags'] as Map<String, dynamic>? ?? {};
          final rawName = tags['name']?.toString() ?? tags['name:ar']?.toString();
          final name = (rawName == null || rawName.trim().isEmpty) ? fallbackName : rawName;

          final addressParts = [
            tags['addr:street']?.toString(),
            tags['addr:city']?.toString(),
          ].where((p) => p != null && p.isNotEmpty).join('، ');

          places.add(NearbyPlace(
            name: name,
            latitude: placeLat,
            longitude: placeLon,
            distanceMeters: _distanceMeters(lat, lon, placeLat, placeLon),
            address: addressParts.isEmpty ? null : addressParts,
          ));
        }

        if (places.isNotEmpty) {
          places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
          return places;
        }
      } catch (e) {
        AppLogger.info('Overpass endpoint $endpoint failed: $e');
      }
    }
    return [];
  }

  static Future<List<NearbyPlace>> _queryNominatim(
    String queryTerm,
    double lat,
    double lon,
    String fallbackName,
  ) async {
    try {
      final delta = 0.08; // ~8km bounding box
      final left = lon - delta;
      final right = lon + delta;
      final top = lat + delta;
      final bottom = lat - delta;

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$queryTerm&format=json&bounded=1&viewbox=$left,$top,$right,$bottom&limit=30',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': AppSources.httpUserAgent,
          'Accept-Language': 'ar,en',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final places = <NearbyPlace>[];

      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        final placeLat = double.tryParse('${map['lat']}');
        final placeLon = double.tryParse('${map['lon']}');
        if (placeLat == null || placeLon == null) continue;

        final displayName = map['display_name']?.toString() ?? fallbackName;
        final rawName = map['name']?.toString();
        final name = (rawName != null && rawName.isNotEmpty)
            ? rawName
            : displayName.split(',').first;

        places.add(NearbyPlace(
          name: name,
          latitude: placeLat,
          longitude: placeLon,
          distanceMeters: _distanceMeters(lat, lon, placeLat, placeLon),
          address: displayName,
        ));
      }

      places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return places;
    } catch (e) {
      AppLogger.info('Nominatim fallback failed: $e');
      return [];
    }
  }

  static double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
