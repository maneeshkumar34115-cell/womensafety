// SafeGuardHer - Places Service
// Fetches REAL nearby places using OpenStreetMap Overpass API (FREE, no API key).
// Features: 3x auto-retry with exponential backoff, offline caching.

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NearbyPlace {
  final String name;
  final String type;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final double distanceKm;
  final String? placeId;

  NearbyPlace({
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.placeId,
  });

  /// Serialize to Map for caching
  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'address': address,
        'phone': phone,
        'lat': lat,
        'lng': lng,
        'distanceKm': distanceKm,
        'placeId': placeId,
      };

  /// Deserialize from Map
  factory NearbyPlace.fromMap(Map<String, dynamic> map) => NearbyPlace(
        name: map['name'] ?? 'Unknown',
        type: map['type'] ?? 'Help Center',
        address: map['address'] ?? '',
        phone: map['phone'] ?? '',
        lat: (map['lat'] as num?)?.toDouble() ?? 0,
        lng: (map['lng'] as num?)?.toDouble() ?? 0,
        distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
        placeId: map['placeId'],
      );
}

class PlacesService {
  static const int _maxRetries = 3;
  static const String _cacheKeyPrefix = 'cached_places_';
  static const String _overpassUrl =
      'https://overpass-api.de/api/interpreter';

  // ─── Haversine distance calculation ─────────────────────────────────────

  static double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  // ─── Fetch with auto-retry (3 attempts, exponential backoff) ────────────

  static Future<http.Response> _postWithRetry(
      Uri url, String body) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await http
            .post(url, body: body, headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            })
            .timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          return response;
        }
        if (attempt >= _maxRetries) {
          throw Exception('Overpass API returned status ${response.statusCode}');
        }
      } catch (e) {
        if (attempt >= _maxRetries) rethrow;
      }
      // Exponential backoff: 1s, 2s, 4s
      await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
    }
  }

  // ─── Cache helpers ──────────────────────────────────────────────────────

  static Future<void> _cachePlaces(
      String type, List<NearbyPlace> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(places.map((p) => p.toMap()).toList());
      await prefs.setString('$_cacheKeyPrefix$type', data);
      await prefs.setInt(
          '$_cacheKeyPrefix${type}_ts', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<List<NearbyPlace>?> _getCachedPlaces(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_cacheKeyPrefix$type');
      if (data == null) return null;
      final List decoded = jsonDecode(data);
      return decoded.map((e) => NearbyPlace.fromMap(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // ─── Fetch nearby places using OpenStreetMap Overpass API ──────────────

  static Future<List<NearbyPlace>> fetchNearbyPlaces({
    required double lat,
    required double lng,
    required String type,
    int radiusMeters = 5000,
  }) async {
    String osmTag = '';
    String displayType = '';

    if (type == 'police') {
      osmTag = '["amenity"="police"]';
      displayType = 'Police';
    } else if (type == 'hospital') {
      osmTag = '["amenity"="hospital"]';
      displayType = 'Hospital';
    } else {
      osmTag = '["amenity"~"social_facility|community_centre|shelter"]';
      displayType = 'Help Center';
    }

    // Overpass QL query to find nodes and ways within radius
    final query = '''
[out:json][timeout:15];
(
  node$osmTag(around:$radiusMeters,$lat,$lng);
  way$osmTag(around:$radiusMeters,$lat,$lng);
);
out center body;
''';

    try {
      final url = Uri.parse(_overpassUrl);
      final response = await _postWithRetry(url, 'data=$query');
      final data = jsonDecode(response.body);

      final elements = data['elements'] as List? ?? [];
      final List<NearbyPlace> places = [];

      for (final el in elements) {
        // Get coordinates: for nodes use lat/lng directly, for ways use center
        double? placeLat;
        double? placeLng;

        if (el['type'] == 'node') {
          placeLat = (el['lat'] as num?)?.toDouble();
          placeLng = (el['lon'] as num?)?.toDouble();
        } else if (el['type'] == 'way' && el['center'] != null) {
          placeLat = (el['center']['lat'] as num?)?.toDouble();
          placeLng = (el['center']['lon'] as num?)?.toDouble();
        }

        if (placeLat == null || placeLng == null) continue;

        final tags = el['tags'] as Map<String, dynamic>? ?? {};
        String name = tags['name'] ?? tags['name:en'] ?? 'Unknown $displayType';
        String address = _buildAddress(tags);
        String phone = tags['phone'] ?? tags['contact:phone'] ?? '';

        // Clean phone number
        phone = phone.replaceAll(RegExp(r'[^+0-9\s]'), '').trim();

        final distanceKm = _haversineDistance(lat, lng, placeLat, placeLng);

        places.add(NearbyPlace(
          name: name,
          type: displayType,
          address: address.isNotEmpty ? address : 'Near your location',
          phone: phone,
          lat: placeLat,
          lng: placeLng,
          distanceKm: distanceKm,
          placeId: el['id']?.toString(),
        ));
      }

      places.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      // Cache successful result
      await _cachePlaces(displayType, places);

      return places;
    } catch (e) {
      // On failure, try to load cached data
      final cached = await _getCachedPlaces(displayType);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// Build a human-readable address from OSM tags
  static String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    if (tags['addr:street'] != null) parts.add(tags['addr:street']);
    if (tags['addr:housenumber'] != null) parts.add(tags['addr:housenumber']);
    if (tags['addr:city'] != null) parts.add(tags['addr:city']);
    if (tags['addr:postcode'] != null) parts.add(tags['addr:postcode']);

    if (parts.isEmpty && tags['address'] != null) return tags['address'];
    return parts.join(', ');
  }

  /// Fetch all place types (police + hospital + help centers)
  static Future<List<NearbyPlace>> fetchAllNearbyPlaces({
    required double lat,
    required double lng,
  }) async {
    final types = ['police', 'hospital', 'local_government_office'];
    final allPlaces = <NearbyPlace>[];
    final errors = <String>[];

    // Fetch each type independently so partial results still work
    for (final type in types) {
      try {
        final places = await fetchNearbyPlaces(lat: lat, lng: lng, type: type);
        allPlaces.addAll(places);
      } catch (e) {
        errors.add(e.toString().replaceAll('Exception: ', ''));
      }
    }

    // If we got at least some results, return them even if some types failed
    if (allPlaces.isNotEmpty) {
      allPlaces.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return allPlaces;
    }

    // All three failed — try loading ALL cached data as fallback
    final allCached = <NearbyPlace>[];
    for (final label in ['Police', 'Hospital', 'Help Center']) {
      final cached = await _getCachedPlaces(label);
      if (cached != null) allCached.addAll(cached);
    }
    if (allCached.isNotEmpty) {
      allCached.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return allCached;
    }

    // All failed and no cache — throw meaningful error
    throw Exception(
        'Could not load nearby places. Check your internet connection and try again.');
  }

  /// Fetch phone number — for OSM data, phone is usually in the initial fetch.
  /// This is kept for API compatibility with the screen.
  static Future<String> fetchPhoneNumber(String placeId) async {
    // OSM doesn't have a separate "details" API like Google.
    // Phone numbers are already included in the initial Overpass query.
    return '';
  }
}
