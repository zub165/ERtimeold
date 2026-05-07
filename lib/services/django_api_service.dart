import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/hospital.dart';
import 'error_handler_service.dart';

class DjangoApiService {
  static const String baseUrl = 'https://api.mywaitime.com/api';
  
  // API Endpoints - Updated to match Django backend structure
  static const String hospitalFinderEndpoint = '$baseUrl/hospitals/search/';
  static const String analyticsEndpoint = '$baseUrl/analytics/search/';
  static const String hospitalsSearchEndpoint = '$baseUrl/hospitals/search/';
  static const String hospitalDetailsEndpoint = '$baseUrl/hospitals/';
  static const String waitTimesEndpoint = '$baseUrl/hospitals/wait-times/update/';
  static const String ratingsEndpoint = '$baseUrl/hospitals/';
  static const String feedbackEndpoint = '$baseUrl/feedback/submit/';
  static const String healthCheckEndpoint = '$baseUrl/health/';
  static const String mapConfigEndpoint = '$baseUrl/map-config/';
  static const String apiKeysEndpoint = '$baseUrl/config/api-keys/';
  static const String dedupPreviewEndpoint = '$baseUrl/hospitals/dedup/preview/';
  
  // New AI and Data Endpoints
  static const String aiWaitTimeEndpoint = '$baseUrl/hospitals/{id}/ai-wait-time/';
  static const String smartWaitTimeEndpoint = '$baseUrl/hospitals/{id}/smart-wait-time/';
  static const String trafficDataEndpoint = '$baseUrl/hospitals/{id}/traffic/';
  static const String weatherDataEndpoint = '$baseUrl/hospitals/{id}/weather/';
  static const String waitTimeUpdateEndpoint = '$baseUrl/hospitals/wait-times/update/';
  static const String hospitalPerformanceEndpoint = '$baseUrl/hospitals/{id}/performance/';
  static const String userProfileEndpoint = '$baseUrl/auth/profile/';
  static const String userRegisterEndpoint = '$baseUrl/auth/register/';
  static const String userLoginEndpoint = '$baseUrl/auth/login/';
  static const String passwordPolicyEndpoint = '$baseUrl/auth/password-policy/';
  
  String? authToken;
  String? lastRegisterError;
  String? lastLoginError;
  
  // Headers
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ERTime-Flutter-App/${AppConfig.version}',
    'X-App-Type': 'flutter',  // ✅ ADD THIS HEADER
    // Backend expects DRF TokenAuth format: Authorization: Token <token>
    if (authToken != null && authToken != 'demo_token') 'Authorization': 'Token $authToken',
  };

  /// Fetch AI smart wait time for a hospital.
  ///
  /// Expected backend shape includes `predicted_wait_minutes` (int).
  Future<int?> getSmartWaitTimeMinutes(String hospitalId) async {
    try {
      final uri = Uri.parse(
        smartWaitTimeEndpoint.replaceFirst('{id}', hospitalId.toString()),
      );
      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 15),
          );
      if (response.statusCode != 200) return null;
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        // Backend may wrap payload in { status, data: { ... } }
        final Map<String, dynamic> payload =
            (decoded['data'] is Map<String, dynamic>)
                ? (decoded['data'] as Map<String, dynamic>)
                : decoded;
        final v = payload['predicted_wait_minutes'] ??
            payload['wait_time_minutes'] ??
            payload['predicted_wait_time_minutes'] ??
            // Fallbacks if backend still sends fields at top-level
            decoded['predicted_wait_minutes'] ??
            decoded['wait_time_minutes'] ??
            decoded['predicted_wait_time_minutes'];
        if (v is int) return v;
        if (v is double) return v.round();
        if (v is String) return int.tryParse(v);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  /// Test connection to Django backend with comprehensive error handling
  Future<ApiResponse<bool>> testConnection() async {
    try {
      print('🔍 Testing backend connection to: $baseUrl/health/');
      final response = await http.get(
        Uri.parse('$baseUrl/health/'),
        headers: headers,
        ).timeout(Duration(seconds: 30));
      
      print('🔍 Backend health response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final error = ErrorHandlerService.handleApiError(response, '$baseUrl/health/');
        return ApiResponse.error(error);
      }
    } catch (e) {
      final error = ErrorHandlerService.handleNetworkError(e, '$baseUrl/health/');
      print('❌ Backend connection test failed: ${error.message}');
      return ApiResponse.error(error);
    }
  }
  
  /// Search for hospitals near location
  Future<List<Hospital>> searchHospitals({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    String? type,
  }) async {
    try {
      // Ensure radius is an integer to avoid backend float errors
      radius = radius.round().toDouble();
      
      // Validate coordinates - reject if invalid
      if (latitude == 0.0 && longitude == 0.0) {
        throw Exception('MISSING_COORDINATES: Client must provide valid GPS coordinates');
      }
      
      if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        throw Exception('INVALID_COORDINATES: GPS coordinates out of valid range');
      }
      
      print('🌐 Django search with enforced coordinates: $latitude, $longitude');
      
      // Use the new hospitals/search endpoint with coordinate parameters
      final normalizedType = (type ?? '').trim();
      final uri = Uri.parse('$baseUrl/hospitals/search/').replace(queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'radius_m': (radius * 1000).round().toString(), // Convert km to meters and ensure integer
        'limit': '20',
        if (normalizedType.isNotEmpty) 'type': normalizedType,
      });
      
      print('🌐 Django request: $uri');
      
      final response = await http.get(uri, headers: headers).timeout(Duration(seconds: 10));
      
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
              final double? rating = _safeParseDouble(
                hospitalJson['ai_rating_stars'] ??
                    hospitalJson['ai_rating'] ??
                    hospitalJson['rating'],
              );
              
              // Calculate distance to user location
              double distance = _calculateDistance(latitude, longitude, lat, lng);
              
              String phone = hospitalJson['phone'] ?? '';
              
              // Debug phone number
              if (phone.isNotEmpty) {
                print('📞 Django phone found: $phone for ${hospitalJson['name']}');
              } else {
                print('⚠️ No phone number found for Django hospital: ${hospitalJson['name']}');
              }
              
              final dynamic waitTimeRaw = hospitalJson['wait_time_minutes'] ??
                  hospitalJson['wait_time_prediction'] ??
                  hospitalJson['current_wait_time'] ??
                  hospitalJson['wait_time'];
              final int? waitTimeMinutes = waitTimeRaw is int
                  ? waitTimeRaw
                  : waitTimeRaw is double
                      ? waitTimeRaw.round()
                      : waitTimeRaw is String
                          ? int.tryParse(waitTimeRaw)
                          : null;

              // Create hospital with parsed values
              return Hospital(
                id: hospitalJson['id']?.toString() ?? '',
                name: hospitalJson['name'] ?? 'Unknown Hospital',
                address: hospitalJson['address'] ?? '',
                latitude: lat,
                longitude: lng,
                distance: distance,
                rating: rating,
                waitTimeMinutes: waitTimeMinutes,
                phone: phone,
                specialties: List<String>.from(hospitalJson['specialties'] ?? []),
                imageUrl: hospitalJson['image_url'] ?? hospitalJson['website'] ?? '',
                source: 'django_backend',
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
                    Hospital.sortByPriorityAndDistance(hospitals);
                    nearbyHospitals = hospitals.take(20).toList();
                    print('No hospitals within ${radius}km, showing closest 20 hospitals (sorted by priority)');
                  }
          
          // Sort by priority (Urgent Care > Emergency > Walk-in > Others), then by distance
          Hospital.sortByPriorityAndDistance(nearbyHospitals);
          print('📋 Sorted hospitals by priority: Urgent Care → Emergency → Walk-in → Others');
          
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
      
      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
      
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
      ).timeout(const Duration(seconds: 30));
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }
  
  /// Submit enhanced review to Django backend
  Future<bool> submitEnhancedReview({
    required String hospitalId,
    required double rating,
    required String comment,
    required int waitTimeMinutes,
    required String userLocation,
    Map<String, String>? externalIds,
    int careQuality = 3,
    int staffFriendliness = 3,
    int cleanliness = 3,
    int facilityModernity = 3,
  }) async {
    try {
      print('🔄 Submitting review to backend: $baseUrl/feedback/submit/');
      print('🔄 Hospital ID: $hospitalId, Rating: $rating, Comment: $comment');
      
      final response = await http.post(
        Uri.parse('$baseUrl/feedback/submit/'),
        headers: headers,
        body: json.encode({
          'hospital_id': hospitalId,
          'rating': rating,
          'comment': comment,
          'wait_time': waitTimeMinutes,
          'user_location': userLocation,
          'care_quality': careQuality,
          'staff_friendliness': staffFriendliness,
          'cleanliness': cleanliness,
          'facility_modernity': facilityModernity,
          'visit_date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': AppConfig.version,
          'platform': 'flutter',
          if (externalIds != null && externalIds.isNotEmpty) 'external_ids': externalIds,
        }),
        ).timeout(Duration(seconds: 30));
      
      print('🔄 Review response status: ${response.statusCode}');
      print('🔄 Review response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('✅ Review submitted successfully: $responseData');
        return true;
      } else {
        print('❌ Failed to submit review: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error submitting review: $e');
      return false;
    }
  }

  /// Optional: Call hospital dedup preview to get best match and candidates
  Future<Map<String, dynamic>?> dedupPreview({
    required String name,
    String? city,
    String? state,
    required double latitude,
    required double longitude,
    String? address,
    Map<String, String>? externalIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(dedupPreviewEndpoint),
        headers: headers,
        body: json.encode({
          'name': name,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
          if (externalIds != null && externalIds.isNotEmpty) 'external_ids': externalIds,
        }),
      ).timeout(Duration(seconds: 20));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Dedup preview error: $e');
      return null;
    }
  }
  
  // In-memory cache so all three map-config accessors share one network call per session.
  Map<String, dynamic>? _mapConfigCache;

  /// Fetch map configuration once and cache the result for the session.
  Future<Map<String, dynamic>?> _fetchMapConfig() async {
    if (_mapConfigCache != null) return _mapConfigCache;
    try {
      final response = await http.get(
        Uri.parse(mapConfigEndpoint),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        _mapConfigCache = json.decode(response.body) as Map<String, dynamic>;
        return _mapConfigCache;
      }
      print('Failed to get map config: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching map config: $e');
      return null;
    }
  }

  /// Get Google Maps API key from Django backend
  Future<String?> getGoogleMapsApiKey() async {
    final data = await _fetchMapConfig();
    return data?['google_maps_api_key'] as String?;
  }

  Future<String?> getTomTomApiKey() async {
    final data = await _fetchMapConfig();
    return data?['tomtom_api_key'] as String?;
  }

  Future<Map<String, dynamic>?> getAllMapConfigs() async {
    final data = await _fetchMapConfig();
    if (data == null) return null;
    return {
      'google_maps_api_key': data['google_maps_api_key'],
      'tomtom_api_key': data['tomtom_api_key'],
      'preferred_map_provider': data['preferred_map_provider'] ?? 'google',
      'enable_google_maps': data['enable_google_maps'] ?? true,
      'enable_tomtom_maps': data['enable_tomtom_maps'] ?? false,
      'enable_openstreet_map': data['enable_openstreet_map'] ?? false,
      'fallback_to_google': data['fallback_to_google'] ?? true,
    };
  }
  
  /// Get all API keys configuration from Django backend
  Future<Map<String, String>?> getApiKeys() async {
    try {
      final response = await http.get(
        Uri.parse(apiKeysEndpoint),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! Map) {
          print('Unexpected API keys response shape: ${decoded.runtimeType}');
          return null;
        }
        // Safely convert — values that are not strings are coerced via toString()
        return Map<String, String>.fromEntries(
          decoded.entries
              .where((e) => e.key is String && e.value != null)
              .map((e) => MapEntry(e.key as String, e.value.toString())),
        );
      } else {
        print('Failed to get API keys: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting API keys: $e');
      return null;
    }
  }
  
  /// Register new user with Django backend
  Future<bool> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      lastRegisterError = null;
      print('🔄 Attempting to register user: $email');
      final uri = Uri.parse('$baseUrl/auth/register/');
      print('🔄 Registration URL: $uri');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'username': email, // Use email as username
        }),
        ).timeout(Duration(seconds: 30));

      print('🔄 Registration response status: ${response.statusCode}');
      // SECURITY: do not log response body (may contain PII)

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Registration successful: $data');
        return true;
      } else {
        String errorMessage = 'Registration failed';
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map) {
            // Prefer the backend's message, but also support the new consistent "errors" map.
            errorMessage = (decoded['message'] ??
                    decoded['detail'] ??
                    decoded['error'] ??
                    decoded['non_field_errors'] ??
                    'Registration failed')
                .toString();

            // New backend shape:
            // { status: "error", message: "...", errors: { field: ["..."] } }
            final errors = decoded['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final parts = <String>[];
              for (final entry in errors.entries) {
                final v = entry.value;
                if (v is List) {
                  parts.add(v.join(' '));
                } else if (v != null) {
                  parts.add(v.toString());
                }
              }
              if (parts.isNotEmpty) {
                errorMessage = parts.join('\n');
              }
            } else if (errorMessage == 'Registration failed') {
              // Older field-level errors like { "password": ["..."] }
              final passwordErr = decoded['password'];
              final emailErr = decoded['email'];
              final usernameErr = decoded['username'];
              final firstNameErr = decoded['first_name'];
              final lastNameErr = decoded['last_name'];
              final fieldErr = passwordErr ?? emailErr ?? usernameErr ?? firstNameErr ?? lastNameErr;
              if (fieldErr != null) {
                errorMessage = fieldErr is List ? fieldErr.join(' ') : fieldErr.toString();
              }
            }
          } else {
            errorMessage = decoded.toString();
          }
        } catch (_) {
          // Non-JSON error bodies can happen (proxy/html). Keep default message.
        }

        lastRegisterError = errorMessage;
        print('❌ Registration failed: ${response.statusCode} - $errorMessage');

        return false;
      }
    } catch (e) {
      print('❌ Registration error: $e');
      lastRegisterError = 'Registration error: ${e.toString()}';
      return false;
    }
  }

  /// Fetch password policy so the UI can validate before submit.
  /// Returns a map like:
  /// { minLength: int, helpText: List<String>, customRules: List<String> }
  Future<Map<String, dynamic>?> getPasswordPolicy() async {
    try {
      final response = await http
          .get(Uri.parse(passwordPolicyEndpoint), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final data = decoded['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      print('🔄 Requesting password reset for: $email');
      final uri = Uri.parse('$baseUrl/auth/password-reset/');
      print('🔄 Reset URL: $uri');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({'email': email}),
        ).timeout(Duration(seconds: 30));

      print('🔄 Reset response status: ${response.statusCode}');
      print('🔄 Reset response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Password reset email sent successfully');
        return true;
      } else {
        print('❌ Password reset request failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Password reset request error: $e');
      return false;
    }
  }

  /// Reset password with token
  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/password-reset-confirm/');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({
          'token': token,
          'new_password': newPassword,
        }),
        ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Password reset successful');
        return true;
      } else {
        print('Password reset failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Password reset error: $e');
      return false;
    }
  }

  /// Reset password directly (admin method)
  Future<bool> resetPasswordDirect({
    required String email,
    required String newPassword,
  }) async {
    try {
      print('🔄 Attempting direct password reset for: $email');
      
      // For now, we'll use the existing password reset endpoint
      // In the future, you can implement a dedicated admin endpoint
      final uri = Uri.parse('$baseUrl/auth/password-reset/');
      print('🔄 Reset URL: $uri');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({
          'email': email,
          'new_password': newPassword,
          'admin_reset': true, // Flag to indicate admin reset
        }),
        ).timeout(Duration(seconds: 30));

      print('🔄 Reset response status: ${response.statusCode}');
      print('🔄 Reset response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Direct password reset successful');
        return true;
      } else {
        print('❌ Direct password reset failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Direct password reset error: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/profile/');
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode({
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (email != null) 'email': email,
        }),
        ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Profile updated successfully');
        return true;
      } else {
        print('Profile update failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Profile update error: $e');
      return false;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final uri = Uri.parse('$baseUrl/auth/profile/');
      final response = await http.get(
        uri,
        headers: headers,
        ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('User profile loaded: $data');
        return data;
      } else {
        print('Failed to load user profile: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/change-password/');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
        ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Password changed successfully');
        return true;
      } else {
        print('Password change failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Password change error: $e');
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount({required String password}) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/delete-account/');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({'password': password}),
        ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Account deleted successfully');
        return true;
      } else {
        print('Account deletion failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Account deletion error: $e');
      return false;
    }
  }

  /// Login and return auth token from Django backend
  Future<String?> loginAndGetToken(String email, String password) async {
    try {
      lastLoginError = null;
      final uri = Uri.parse('$baseUrl/auth/login/');
      print('🌐 Making request to: $uri');
      // SECURITY: never log email or password

      final response = await http.post(
        uri,
        headers: headers,
        // Be compatible with backends that expect either username OR email.
        body: json.encode({
          'username': email,
          'email': email,
          'password': password,
        }),
         ).timeout(Duration(seconds: 30));

      print('🌐 Response status: ${response.statusCode}');
      // SECURITY: do not log response body (contains token)

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        final status = (data['status'] ?? '').toString().toLowerCase();
        final Object? rawNested = data['data'];
        final Map<String, dynamic>? nested =
            rawNested is Map<String, dynamic> ? rawNested : null;

        // Some backends return {status: success} while others return 200 with token only.
        final bool looksSuccessful =
            status == 'success' ||
                status == 'ok' ||
                data.containsKey('token') ||
                data.containsKey('access') ||
                data.containsKey('key') ||
                (nested != null &&
                    (nested.containsKey('token') ||
                        nested.containsKey('access') ||
                        nested.containsKey('key')));

        if (looksSuccessful) {
          final dynamic token = data['token'] ??
              data['access'] ??
              data['key'] ??
              nested?['token'] ??
              nested?['access'] ??
              nested?['key'];
          print('🌐 Token found: ${token != null ? "YES" : "NO"}');
          
          if (token == null) {
            // For successful login without token, return demo token
            print('🌐 No token in response, using demo token for successful login');
            return 'demo_token';
          }
          return token.toString();
        } else {
          lastLoginError = (data['message'] ?? data['detail'] ?? 'Login failed').toString();
          print('❌ Login failed: ${data['message']}');
          return null;
        }
      } else {
        // Try to parse a helpful error message without logging sensitive data.
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map) {
            lastLoginError = (decoded['message'] ??
                    decoded['detail'] ??
                    decoded['error'] ??
                    decoded['non_field_errors'] ??
                    'Login failed (${response.statusCode})')
                .toString();
          } else {
            lastLoginError = 'Login failed (${response.statusCode})';
          }
        } catch (_) {
          lastLoginError = 'Login failed (${response.statusCode})';
        }
        print('❌ Login failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Login error: $e');
      lastLoginError = 'Login error: ${e.toString()}';
      return null;
    }
  }

  /// Submit search analytics to Django backend
  Future<bool> submitSearchAnalytics({
    required double latitude,
    required double longitude,
    required double radius,
    required int hospitalCount,
    String? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analytics/search/'),
        headers: headers,
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
          'hospital_count': hospitalCount,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': AppConfig.version,
          'platform': 'flutter',
        }),
        ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Search analytics submitted successfully');
        return true;
      } else {
        print('Failed to submit search analytics: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error submitting search analytics: $e');
      return false;
    }
  }

  /// Submit user activity to Django backend
  Future<bool> submitUserActivity({
    required String activity,
    required String details,
    String? hospitalId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analytics/activity/'),
        headers: headers,
        body: json.encode({
          'activity': activity,
          'details': details,
          'hospital_id': hospitalId,
          'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': AppConfig.version,
          'platform': 'flutter',
        }),
        ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('User activity submitted successfully');
        return true;
      } else {
        print('Failed to submit user activity: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error submitting user activity: $e');
      return false;
    }
  }
}

// Hospital model is now imported from ../models/hospital.dart

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
