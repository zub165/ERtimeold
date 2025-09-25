import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class DjangoApiService {
  static const String baseUrl = 'http://208.109.215.53:3015/api';
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
    'User-Agent': 'ERTime-Flutter-App/1.0.3',
    if (authToken != null) 'Authorization': 'Bearer \$authToken',
  };
  
  /// Test connection to Django backend
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: headers,
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: \$e');
      return false;
    }
  }
  
  /// Search for hospitals near location
  Future<List<Hospital>> searchHospitals({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {
    try {
      // Use the main hospitals endpoint that works  
      final uri = Uri.parse('$baseUrl/hospitals/');
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('Django response: $responseData');
        
        // Check if response has 'data' field with hospitals array
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final List<dynamic> hospitalsList = responseData['data'];
          print('Found ${hospitalsList.length} hospitals in Django response');
          
          List<Hospital> hospitals = hospitalsList.map((hospitalJson) {
                    try {
                      // Direct parsing with robust type conversion
                      double lat = _safeParseDouble(hospitalJson['latitude']) ?? 0.0;
                      double lng = _safeParseDouble(hospitalJson['longitude']) ?? 0.0;
                      double rating = _safeParseDouble(hospitalJson['ai_rating']) ?? 4.0;
                      
                      // Calculate distance to user location
                      double distance = _calculateDistance(latitude, longitude, lat, lng);
                      
                      // Create hospital with parsed values
                      return Hospital(
                        id: hospitalJson['id']?.toString() ?? '',
                        name: hospitalJson['name'] ?? 'Unknown Hospital',
                        address: hospitalJson['address'] ?? '',
                        latitude: lat,
                        longitude: lng,
                        distance: distance,
                        rating: rating,
                        phone: hospitalJson['phone'] ?? '',
                        specialties: List<String>.from(hospitalJson['specialties'] ?? []),
                        imageUrl: hospitalJson['image_url'] ?? hospitalJson['website'] ?? '',
                      );
                    } catch (e) {
                      print('Error parsing hospital: $e');
                      print('Hospital JSON: $hospitalJson');
                      return null;
                    }
          }).where((hospital) => hospital != null).cast<Hospital>().toList();
          
                  // Filter hospitals by distance - but if none found within radius, show closest 20
                  List<Hospital> nearbyHospitals = hospitals.where((hospital) {
                    return hospital.distance <= radius;
                  }).toList();
                  
                  // If no hospitals within radius, show closest 20 for demo
                  if (nearbyHospitals.isEmpty && hospitals.isNotEmpty) {
                    hospitals.sort((a, b) => a.distance.compareTo(b.distance));
                    nearbyHospitals = hospitals.take(20).toList();
                    print('No hospitals within ${radius}km, showing closest 20 hospitals');
                  }
          
          // Sort by distance
          nearbyHospitals.sort((a, b) => a.distance.compareTo(b.distance));
          
          print('Filtered to ${nearbyHospitals.length} hospitals within ${radius}km');
          return nearbyHospitals;
        } else {
          print('Invalid response structure: $responseData');
          throw Exception('Invalid response structure from Django');
        }
      } else {
        print('Failed to load hospitals: ${response.statusCode} - ${response.body}');
        throw Exception('Django backend returned ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching hospitals: $e');
      return [];
    }
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
      final response = await http.post(
        Uri.parse(feedbackEndpoint),
        headers: headers,
        body: json.encode({
          'hospital_id': hospitalId,
          'rating': rating,
          'comment': comment,
          'wait_time': waitTime,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }
  
  /// Submit enhanced review to AI-powered Django backend
  Future<bool> submitEnhancedReview({
    required String hospitalId,
    required double rating,
    required String comment,
    required int waitTimeMinutes,
    required String userLocation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai-enhanced-review/'),
        headers: headers,
        body: json.encode({
          'hospital_id': hospitalId,
          'user_rating': rating,
          'review_comment': comment,
          'wait_time_minutes': waitTimeMinutes,
          'user_location': userLocation,
          'submission_timestamp': DateTime.now().toIso8601String(),
          'app_version': '1.0.3',
          'platform': 'flutter',
          'ai_analysis_requested': true,
          'sentiment_analysis': true,
          'wait_time_prediction': true,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('AI Review Response: $responseData');
        return true;
      } else {
        print('Failed to submit enhanced review: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error submitting enhanced review: $e');
      return false;
    }
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
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({'email': email, 'password': password}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] ?? data['access'] ?? data['key'];
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
}

// Models
class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final double rating;
  final String phone;
  final List<String> specialties;
  final String imageUrl;
  
  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.rating,
    required this.phone,
    required this.specialties,
    required this.imageUrl,
  });
  
          factory Hospital.fromJson(Map<String, dynamic> json) {
            return Hospital(
              id: json['id']?.toString() ?? '',
              name: json['name'] ?? 'Unknown Hospital',
              address: json['address'] ?? '',
              latitude: _parseDouble(json['latitude']) ?? 0.0,
              longitude: _parseDouble(json['longitude']) ?? 0.0,
              distance: _parseDouble(json['distance']) ?? 0.0,
              rating: _parseDouble(json['ai_rating']) ?? 4.0,
              phone: json['phone'] ?? '',
              specialties: List<String>.from(json['specialties'] ?? []),
              imageUrl: json['image_url'] ?? json['website'] ?? '',
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
