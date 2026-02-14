import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_key_manager.dart';

class DjangoApiService {
  // Single source of truth for backend URL
  static const String baseUrl = AppConfig.djangoBaseUrl;
  static const String defaultPassword = 'Bismilah165\$';
  
  // API Endpoints
  static const String hospitalFinderEndpoint = '$baseUrl/hospital-finder/';
  static const String analyticsEndpoint = '$baseUrl/analytics/';
  static const String hospitalsSearchEndpoint = '$baseUrl/hospitals/search/';
  static const String hospitalDetailsEndpoint = '$baseUrl/hospitals/details/';
  static const String waitTimesEndpoint = '$baseUrl/hospitals/wait-times/';
  static const String ratingsEndpoint = '$baseUrl/hospitals/ratings/';
  static const String feedbackEndpoint = '$baseUrl/feedback/submit/';
  static const String healthCheckEndpoint = '$baseUrl/health/';
  static const String mapConfigEndpoint = '$baseUrl/map-config/';
  static const String apiKeysEndpoint = '$baseUrl/api-keys/';
  
  String? authToken;
  
  // Headers
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ERTime-Flutter-App/${AppConfig.version}',
    'X-App-Type': 'flutter',
    if (authToken != null) 'Authorization': 'Token $authToken',
  };
  
  /// Test connection to Django backend (tries /health/ then base URL)
  Future<bool> testConnection() async {
    try {
      // Many backends return 200 on /api/health/ but 404/301 on GET /api/
      var response = await http.get(
        Uri.parse(healthCheckEndpoint),
        headers: headers,
      ).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) return true;
      response = await http.get(
        Uri.parse(baseUrl),
        headers: headers,
      ).timeout(Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
  
  /// Sort option for hospital search (backend param: sort_by).
  static const String sortByDistance = 'distance';
  static const String sortByRating = 'rating';
  static const String sortByWaitTime = 'wait_time';
  static const String sortByName = 'name';

  /// Search for hospitals: merges Django + OSM + TomTom + Google (page 1 only for external APIs).
  Future<List<Hospital>> searchHospitals({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String sortOrder = 'asc',
  }) async {
    final allHospitals = <Hospital>[];
    
    // 1. Django backend (supports pagination & sort)
    try {
      final radiusM = (radius * 1000).round();
      final params = <String, String>{
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'radius_m': radiusM.toString(),
        'limit': pageSize.toString(),
        'page': page.toString(),
      };
      if (sortBy != null && sortBy.isNotEmpty) {
        params['sort_by'] = sortBy;
        params['sort_order'] = sortOrder;
      }
      final searchUri = Uri.parse(hospitalsSearchEndpoint).replace(queryParameters: params);
      final response = await http.get(searchUri, headers: headers).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final List<dynamic> hospitalsList = responseData['data'];
          print('Django: found ${hospitalsList.length} hospitals (page $page)');
          final hospitals = _parseHospitalList(hospitalsList, latitude, longitude);
          allHospitals.addAll(hospitals);
        }
      } else {
        // Try list endpoint
        final listUri = Uri.parse('$baseUrl/hospitals/');
        final listResponse = await http.get(listUri, headers: headers).timeout(Duration(seconds: 15));
        if (listResponse.statusCode == 200) {
          final listData = json.decode(listResponse.body) as Map<String, dynamic>;
          if (listData['status'] == 'success' && listData['data'] != null) {
            final list = listData['data'] as List<dynamic>;
            final hospitals = _parseHospitalList(list, latitude, longitude);
            List<Hospital> nearby = hospitals.where((h) => h.distance <= radius).toList();
            print('Django list: found ${nearby.length} hospitals within radius');
            allHospitals.addAll(nearby);
          }
        }
      }
    } catch (e) {
      print('Django hospital search error: $e');
    }

    // For page > 1, only Django supports pagination; return Django results only
    if (page > 1) {
      allHospitals.sort((a, b) => a.distance.compareTo(b.distance));
      return allHospitals;
    }

    // 2. OpenStreetMap (page 1 only)
    final osm = await _searchHospitalsOpenStreetMap(latitude, longitude, radius);
    if (osm != null && osm.isNotEmpty) {
      print('OpenStreetMap: found ${osm.length} hospitals');
      allHospitals.addAll(osm);
    }

    // 3. TomTom (page 1 only)
    final tomtom = await _searchHospitalsTomTom(latitude, longitude, radius);
    if (tomtom != null && tomtom.isNotEmpty) {
      print('TomTom: found ${tomtom.length} hospitals');
      allHospitals.addAll(tomtom);
    }

    // 4. Google Places (page 1 only)
    final google = await _searchHospitalsGoogle(latitude, longitude, radius);
    if (google != null && google.isNotEmpty) {
      print('Google Places: found ${google.length} hospitals');
      allHospitals.addAll(google);
    }

    // Deduplicate (same location or very similar name)
    final deduplicated = _deduplicateHospitals(allHospitals);
    print('Total after merge & dedup: ${deduplicated.length} hospitals');
    deduplicated.sort((a, b) => a.distance.compareTo(b.distance));
    return deduplicated;
  }

  static const String _overpassEndpoint = 'https://overpass-api.de/api/interpreter';

  /// OpenStreetMap (Overpass API) - no API key required.
  Future<List<Hospital>?> _searchHospitalsOpenStreetMap(double lat, double lon, double radiusKm) async {
    try {
      final radiusM = (radiusKm * 1000).round().clamp(100, 25000);
      final query = '[out:json][timeout:25];(node(around:$radiusM,$lat,$lon)[amenity=hospital];node(around:$radiusM,$lat,$lon)[healthcare=hospital];way(around:$radiusM,$lat,$lon)[amenity=hospital];);out center tags;';
      final uri = Uri.parse(_overpassEndpoint).replace(queryParameters: {'data': query});
      final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>?;
      final elements = data?['elements'] as List<dynamic>? ?? [];
      final hospitals = <Hospital>[];
      for (final el in elements) {
        final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
        final name = (tags['name'] ?? tags['brand'] ?? 'Hospital') as String;
        double? elat = _safeParseDouble(el['lat']);
        double? elon = _safeParseDouble(el['lon']);
        if (elat == null || elon == null) {
          final center = el['center'] as Map<String, dynamic>?;
          if (center != null) {
            elat = _safeParseDouble(center['lat']);
            elon = _safeParseDouble(center['lon']);
          }
        }
        if (elat == null || elon == null) continue;
        final address = [tags['addr:street'], tags['addr:housenumber'], tags['addr:city']].whereType<String>().join(', ');
        final city = tags['addr:city'] as String? ?? '';
        final state = tags['addr:state'] as String? ?? '';
        final distance = _calculateDistance(lat, lon, elat, elon);
        final id = 'osm_${el['type']}_${el['id']}';
        hospitals.add(Hospital(
          id: id,
          name: name,
          address: address.isEmpty ? 'Address not specified' : address,
          city: city,
          state: state,
          latitude: elat,
          longitude: elon,
          distance: distance,
          rating: 4.0,
          phone: '',
          website: tags['website'] ?? '',
          specialties: ['Emergency Medicine'],
          imageUrl: '',
          estimatedWaitTimeMinutes: null,
        ));
      }
      hospitals.sort((a, b) => a.distance.compareTo(b.distance));
      return hospitals;
    } catch (e) {
      print('OpenStreetMap hospital search error: $e');
      return null;
    }
  }

  /// TomTom POI Search - requires TomTom API key (Settings or Django).
  Future<List<Hospital>?> _searchHospitalsTomTom(double lat, double lon, double radiusKm) async {
    try {
      final key = await ApiKeyManager.getActiveTomTomApiKey();
      if (key == null || key.isEmpty) return null;
      final radiusM = (radiusKm * 1000).round();
      final uri = Uri.parse('https://api.tomtom.com/search/2/poiSearch/hospital.json').replace(
        queryParameters: {'key': key, 'lat': '$lat', 'lon': '$lon', 'radius': '$radiusM', 'limit': '50'},
      );
      final response = await http.get(uri, headers: headers).timeout(Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>?;
      final results = data?['results'] as List<dynamic>? ?? [];
      final hospitals = <Hospital>[];
      for (final r in results) {
        final pos = r['position'] as Map<String, dynamic>?;
        final lat2 = _safeParseDouble(pos?['lat']);
        final lon2 = _safeParseDouble(pos?['lon']);
        if (lat2 == null || lon2 == null) continue;
        final name = (r['poi'] as Map<String, dynamic>?)?['name'] as String? ?? 'Hospital';
        final addressData = r['address'] as Map<String, dynamic>? ?? {};
        final addr = addressData['freeformAddress'] as String? ?? '';
        final city = addressData['municipality'] as String? ?? addressData['localName'] as String? ?? '';
        final state = addressData['countrySubdivision'] as String? ?? '';
        final distance = _calculateDistance(lat, lon, lat2, lon2);
        hospitals.add(Hospital(
          id: 'tomtom_${r['id']}',
          name: name,
          address: addr,
          city: city,
          state: state,
          latitude: lat2,
          longitude: lon2,
          distance: distance,
          rating: 4.0,
          phone: (r['poi'] as Map<String, dynamic>?)?['phone'] as String? ?? '',
          website: (r['poi'] as Map<String, dynamic>?)?['url'] as String? ?? '',
          specialties: ['Emergency Medicine'],
          imageUrl: '',
          estimatedWaitTimeMinutes: null,
        ));
      }
      hospitals.sort((a, b) => a.distance.compareTo(b.distance));
      return hospitals;
    } catch (e) {
      print('TomTom hospital search error: $e');
      return null;
    }
  }

  /// Google Places Nearby Search - requires Google Maps API key (Settings or Django).
  Future<List<Hospital>?> _searchHospitalsGoogle(double lat, double lon, double radiusKm) async {
    try {
      final key = await ApiKeyManager.getActiveGoogleMapsApiKey();
      if (key == null || key.isEmpty) return null;
      final radiusM = (radiusKm * 1000).round().clamp(1, 50000);
      final uri = Uri.parse('https://maps.googleapis.com/maps/api/place/nearbysearch/json').replace(
        queryParameters: {'location': '$lat,$lon', 'radius': '$radiusM', 'type': 'hospital', 'key': key},
      );
      final response = await http.get(uri, headers: headers).timeout(Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>?;
      if (data?['status'] != 'OK' && data?['status'] != 'ZERO_RESULTS') return null;
      final results = data?['results'] as List<dynamic>? ?? [];
      final hospitals = <Hospital>[];
      for (final r in results) {
        final geo = r['geometry'] as Map<String, dynamic>?;
        final loc = geo?['location'] as Map<String, dynamic>?;
        final lat2 = _safeParseDouble(loc?['lat']);
        final lng2 = _safeParseDouble(loc?['lng']);
        if (lat2 == null || lng2 == null) continue;
        final name = r['name'] as String? ?? 'Hospital';
        final vicinity = r['vicinity'] as String? ?? '';
        final cityState = Hospital._extractCityState(vicinity);
        final distance = _calculateDistance(lat, lon, lat2, lng2);
        hospitals.add(Hospital(
          id: 'google_${r['place_id']}',
          name: name,
          address: vicinity,
          city: cityState['city'] ?? '',
          state: cityState['state'] ?? '',
          latitude: lat2,
          longitude: lng2,
          distance: distance,
          rating: 4.0,
          phone: '',
          website: '',
          specialties: ['Emergency Medicine'],
          imageUrl: '',
          estimatedWaitTimeMinutes: null,
        ));
      }
      hospitals.sort((a, b) => a.distance.compareTo(b.distance));
      return hospitals;
    } catch (e) {
      print('Google Places hospital search error: $e');
      return null;
    }
  }

  List<Hospital> _parseHospitalList(
    List<dynamic> hospitalsList,
    double userLat,
    double userLng,
  ) {
    return hospitalsList.map((hospitalJson) {
      try {
        final lat = _safeParseDouble(hospitalJson['latitude']) ?? 0.0;
        final lng = _safeParseDouble(hospitalJson['longitude']) ?? 0.0;
        final rating = _safeParseDouble(hospitalJson['ai_rating']) ?? 4.0;
        final distance = _calculateDistance(userLat, userLng, lat, lng);
        
        // Debug: Log rating to verify backend data
        print('🏥 Hospital: ${hospitalJson['name']}, Rating: $rating (from backend ai_rating: ${hospitalJson['ai_rating']})');
        
        final wait = hospitalJson['smart_wait_time'] ?? hospitalJson['current_wait_time'] ??
            hospitalJson['estimated_wait_time'] ?? hospitalJson['ai_estimated_wait'] ?? hospitalJson['predicted_wait_time'];
        int? waitMinutes;
        if (wait != null) {
          if (wait is int) waitMinutes = wait;
          if (wait is double) waitMinutes = wait.round();
          if (wait is String) waitMinutes = int.tryParse(wait);
        }
        return Hospital(
          id: hospitalJson['id']?.toString() ?? '',
          name: hospitalJson['name'] ?? 'Unknown Hospital',
          address: hospitalJson['address'] ?? '',
          city: hospitalJson['city'] ?? '',
          state: hospitalJson['state'] ?? '',
          latitude: lat,
          longitude: lng,
          distance: distance,
          rating: rating,
          phone: hospitalJson['phone'] ?? '',
          website: hospitalJson['website'] ?? '',
          specialties: List<String>.from(hospitalJson['specialties'] ?? []),
          imageUrl: hospitalJson['image_url'] ?? hospitalJson['website'] ?? '',
          estimatedWaitTimeMinutes: waitMinutes,
        );
      } catch (e) {
        print('Error parsing hospital: $e');
        return null;
      }
    }).where((h) => h != null).cast<Hospital>().toList();
  }
  
  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Remove duplicates: same location (<100m) or very similar name (Levenshtein < 3).
  List<Hospital> _deduplicateHospitals(List<Hospital> hospitals) {
    final keep = <Hospital>[];
    for (final h in hospitals) {
      bool isDupe = false;
      for (final existing in keep) {
        final dist = _calculateDistance(h.latitude, h.longitude, existing.latitude, existing.longitude);
        if (dist < 0.1) {
          isDupe = true;
          break;
        }
        if (_similarName(h.name, existing.name)) {
          isDupe = true;
          break;
        }
      }
      if (!isDupe) keep.add(h);
    }
    return keep;
  }

  bool _similarName(String a, String b) {
    final a2 = a.toLowerCase().replaceAll(RegExp(r'\W+'), '');
    final b2 = b.toLowerCase().replaceAll(RegExp(r'\W+'), '');
    if (a2 == b2) return true;
    if (a2.length < 5 || b2.length < 5) return false;
    return _levenshtein(a2, b2) <= 2;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    final v0 = List<int>.filled(t.length + 1, 0);
    final v1 = List<int>.filled(t.length + 1, 0);
    for (int i = 0; i <= t.length; i++) v0[i] = i;
    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) v0[j] = v1[j];
    }
    return v1[t.length];
  }

  /// Safely parse any type to double
  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
  
  /// Get wait times for a specific hospital
  Future<WaitTime?> getWaitTimes(String hospitalId) async {
    try {
      final uri = Uri.parse(waitTimesEndpoint).replace(
        queryParameters: {'hospital_id': hospitalId},
      );
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        return WaitTime.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error getting wait times: $e');
      return null;
    }
  }
  
  /// Submit feedback for a hospital
  Future<bool> submitFeedback({
    required String hospitalId,
    required int rating,
    required String comment,
    required int waitTime,
  }) async {
    try {
      // Backend expects these fields (see /api/feedback/submit/)
      final normalized = _normalizeRatingToInt1to5(rating);
      final response = await http.post(
        Uri.parse(feedbackEndpoint),
        headers: headers,
        body: json.encode({
          'hospital_id': hospitalId,
          'rating': rating,
          'comment': comment,
          'wait_time': waitTime,
          'care_quality': normalized,
          'staff_friendliness': normalized,
          'cleanliness': normalized,
          'facility_modernity': normalized,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }
  
  /// Submit review + wait time to backend (AI-enhanced processing happens server-side).
  /// Returns SubmitReviewResult with success and aiUpdated (true when backend used feedback for predictions).
  Future<SubmitReviewResult> submitEnhancedReview({
    required String hospitalId,
    required double rating,
    required String comment,
    required int waitTimeMinutes,
    required String userLocation,
    Hospital? hospitalDetails, // Add full hospital details for external API hospitals
  }) async {
    try {
      final normalized = _normalizeRatingToInt1to5(rating);
      
      // Build request payload
      final payload = <String, dynamic>{
        'hospital_id': hospitalId,
        'rating': rating,
        'comment': comment,
        'wait_time': waitTimeMinutes,
        'user_location': userLocation,
        'care_quality': normalized,
        'staff_friendliness': normalized,
        'cleanliness': normalized,
        'facility_modernity': normalized,
        'visit_date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': AppConfig.version,
        'platform': 'flutter',
      };
      
      // If hospital details provided (e.g., from OSM/TomTom/Google), include them so backend can create if needed
      if (hospitalDetails != null) {
        payload['hospital'] = {
          'id': hospitalDetails.id,
          'name': hospitalDetails.name,
          'address': hospitalDetails.address,
          'city': hospitalDetails.city,
          'state': hospitalDetails.state,
          'latitude': hospitalDetails.latitude,
          'longitude': hospitalDetails.longitude,
          'phone': hospitalDetails.phone,
          'website': hospitalDetails.website,
        };
      }
      
      final response = await http.post(
        Uri.parse(feedbackEndpoint),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body) as Map<String, dynamic>?;
        final data = responseData != null && responseData['data'] is Map
            ? responseData['data'] as Map<String, dynamic>
            : responseData;
        final aiUpdated = data != null && (data['ai_updated'] == true || data['ai_updated'] == 'true');
        print('AI Review Response: $responseData, ai_updated: $aiUpdated');
        return SubmitReviewResult(success: true, aiUpdated: aiUpdated);
      }
      print('Failed to submit enhanced review: ${response.statusCode} - ${response.body}');
      return SubmitReviewResult(success: false, aiUpdated: false);
    } catch (e) {
      print('Error submitting enhanced review: $e');
      return SubmitReviewResult(success: false, aiUpdated: false);
    }
  }

  static int _normalizeRatingToInt1to5(num rating) {
    // Accept common scales and coerce safely into 1..5.
    final double r = rating.toDouble();
    if (r.isNaN || r.isInfinite) return 3;
    if (r <= 5.0) {
      return r.round().clamp(1, 5);
    }
    // If the caller passes 1..10, map to 1..5.
    final scaled = (r / 2.0);
    return scaled.round().clamp(1, 5);
  }
  
  /// Get Google Maps API key from Django backend
  Future<String?> getGoogleMapsApiKey() async {
    try {
      final response = await http.get(
        Uri.parse(mapConfigEndpoint),
        headers: headers,
      );
       
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['google_maps_api_key'];
      } else {
        print('Failed to get Google Maps API key: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting Google Maps API key: $e');
      return null;
    }
  }

  Future<String?> getTomTomApiKey() async {
    try {
      final response = await http.get(
        Uri.parse(mapConfigEndpoint),
        headers: headers,
      );
       
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['tomtom_api_key'];
      } else {
        print('Failed to get TomTom API key: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting TomTom API key: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAllMapConfigs() async {
    try {
      final response = await http.get(
        Uri.parse(mapConfigEndpoint),
        headers: headers,
      );
       
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'google_maps_api_key': data['google_maps_api_key'],
          'tomtom_api_key': data['tomtom_api_key'],
          'preferred_map_provider': data['preferred_map_provider'] ?? 'google',
          'enable_google_maps': data['enable_google_maps'] ?? true,
          'enable_tomtom_maps': data['enable_tomtom_maps'] ?? false,
          'fallback_to_google': data['fallback_to_google'] ?? true,
        };
      } else {
        print('Failed to get map configurations: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting map configurations: $e');
      return null;
    }
  }
  
  /// Get all API keys configuration from Django backend
  Future<Map<String, String>?> getApiKeys() async {
    try {
      final response = await http.get(
        Uri.parse(apiKeysEndpoint),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, String>.from(data);
      } else {
        print('Failed to get API keys: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting API keys: $e');
      return null;
    }
  }
  
  /// Login and return auth token from Django backend
  Future<String?> loginAndGetToken(String email, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login/');
      
      // Try with full email first (some backends store email as username)
      var response = await http.post(
        uri,
        headers: headers,
        body: json.encode({
          'username': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 10));

      // If that fails, try with derived username (email prefix)
      if (response.statusCode != 200) {
        final username = email.contains('@') 
            ? email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')
            : email;
        
        response = await http.post(
          uri,
          headers: headers,
          body: json.encode({
            'username': username,
            'password': password,
          }),
        ).timeout(Duration(seconds: 10));
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] ?? data['access'] ?? data['key'] ?? 
                      (data['data'] != null ? data['data']['token'] : null);
        return token?.toString();
      } else {
        print('Login failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Request account deletion on backend (DELETE /api/auth/delete-account/).
  /// Returns true if backend accepted, false otherwise. Caller should clear local data either way.
  Future<bool> deleteAccount() async {
    try {
      final uri = Uri.parse('$baseUrl/auth/delete-account/');
      final response = await http.delete(
        uri,
        headers: headers,
      ).timeout(Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Delete account request error: $e');
      return false;
    }
  }

  /// Register new user on Django backend (POST /api/auth/register/)
  /// Returns error message on failure, null on success.
  Future<String?> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/register/');
      // Generate unique username from email (consistent with login)
      final username = email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'username': username,
      };
      if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['status'] == 'error' || data['error'] != null) {
          return data['message'] ?? data['error'] ?? 'Registration failed';
        }
        return null;
      }
      final bodyStr = response.body;
      try {
        final data = json.decode(bodyStr);
        return data['message'] ?? data['detail'] ?? data['error'] ?? 'Registration failed';
      } catch (_) {
        return bodyStr.isNotEmpty ? bodyStr : 'Registration failed (${response.statusCode})';
      }
    } catch (e) {
      print('Register error: $e');
      return 'Network error. Please try again.';
    }
  }
}

/// Result of submitting a review; aiUpdated is true when backend used feedback for AI predictions.
class SubmitReviewResult {
  final bool success;
  final bool aiUpdated;
  SubmitReviewResult({required this.success, required this.aiUpdated});
}

// Models
class Hospital {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final double distance;
  final double rating;
  final String phone;
  final String website;
  final List<String> specialties;
  final String imageUrl;
  /// AI-enhanced estimate from backend (reviews, traffic, weather, etc.) when available.
  final int? estimatedWaitTimeMinutes;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    this.city = '',
    this.state = '',
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.rating,
    required this.phone,
    this.website = '',
    required this.specialties,
    required this.imageUrl,
    this.estimatedWaitTimeMinutes,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    final wait = json['smart_wait_time'] ?? json['current_wait_time'] ??
        json['estimated_wait_time'] ?? json['ai_estimated_wait'] ?? json['predicted_wait_time'];
    int? waitMinutes;
    if (wait != null) {
      if (wait is int) waitMinutes = wait;
      if (wait is double) waitMinutes = wait.round();
      if (wait is String) waitMinutes = int.tryParse(wait);
    }
    return Hospital(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Hospital',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
      distance: _parseDouble(json['distance']) ?? 0.0,
      rating: _parseDouble(json['ai_rating']) ?? 4.0,
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      specialties: List<String>.from(json['specialties'] ?? []),
      imageUrl: json['image_url'] ?? json['website'] ?? '',
      estimatedWaitTimeMinutes: waitMinutes,
    );
  }
          
          static double? _parseDouble(dynamic value) {
            if (value == null) return null;
            if (value is double) return value;
            if (value is int) return value.toDouble();
            if (value is String) {
              return double.tryParse(value);
            }
            return null;
          }
          
          /// Extract city and state from address string.
          /// Examples:
          /// - "2105 Forest Avenue, San Jose, CA 95128" -> ("San Jose", "CA")
          /// - "1600 Amphitheatre Parkway, Mountain View, California" -> ("Mountain View", "California")
          static Map<String, String> _extractCityState(String address) {
            if (address.isEmpty) return {'city': '', 'state': ''};
            
            // Remove ZIP code (5 digits)
            address = address.replaceAll(RegExp(r'\s*\d{5}(-\d{4})?\s*$'), '');
            
            // Split by comma
            final parts = address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            
            // US state abbreviations and full names
            const usStates = [
              'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
              'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
              'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
              'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
              'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
              'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
              'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
              'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
              'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
              'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
              'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
              'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
              'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
              'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
              'West Virginia', 'Wisconsin', 'Wyoming'
            ];
            
            // Find state (last part if it's a known state)
            String state = '';
            String city = '';
            
            if (parts.length >= 2) {
              final lastPart = parts.last;
              if (usStates.contains(lastPart)) {
                state = lastPart;
                if (parts.length >= 3) {
                  city = parts[parts.length - 2];
                }
              } else if (parts.length >= 3) {
                // Assume last part is state, second-to-last is city
                state = lastPart;
                city = parts[parts.length - 2];
              } else {
                // Only 2 parts, assume last is city
                city = lastPart;
              }
            } else if (parts.length == 1) {
              // Single part, might be just city
              city = parts.first;
            }
            
            return {'city': city, 'state': state};
          }
}

class WaitTime {
  final String hospitalId;
  final int currentWaitTime;
  final int averageWaitTime;
  final String lastUpdated;
  final String status;
  
  WaitTime({
    required this.hospitalId,
    required this.currentWaitTime,
    required this.averageWaitTime,
    required this.lastUpdated,
    required this.status,
  });
  
  factory WaitTime.fromJson(Map<String, dynamic> json) {
    return WaitTime(
      hospitalId: json['hospital_id']?.toString() ?? '',
      currentWaitTime: json['current_wait_time'] ?? 0,
      averageWaitTime: json['average_wait_time'] ?? 0,
      lastUpdated: json['last_updated'] ?? '',
      status: json['status'] ?? 'unknown',
    );
  }
}
