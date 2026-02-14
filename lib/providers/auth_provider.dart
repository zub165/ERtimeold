import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/django_api_service.dart';

class AuthProvider extends ChangeNotifier {
  final DjangoApiService _apiService = DjangoApiService();

  String? _authToken;
  String? _email;
  bool _isLoading = false;

  String? get authToken => _authToken;
  String? get email => _email;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
  bool get isLoading => _isLoading;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _email = prefs.getString('auth_email');
    
    // Set token in API service if available
    if (_authToken != null && _authToken!.isNotEmpty) {
      _apiService.authToken = _authToken;
    }
    
    notifyListeners();
  }
  
  /// Validate stored token and clear if invalid
  Future<bool> validateStoredToken() async {
    if (_authToken == null || _authToken!.isEmpty) {
      return false;
    }
    
    // Set token in API service for validation
    _apiService.authToken = _authToken;
    
    // Try a simple backend call to validate token (hospital search doesn't require auth)
    try {
      final hospitals = await _apiService.searchHospitals(
        latitude: 37.7749,
        longitude: -122.4194,
        radius: 5.0,
      );
      // If we get here without error, token is valid
      print('✅ Stored token validated successfully');
      return true;
    } catch (e) {
      print('⚠️  Stored token invalid or expired, clearing credentials');
      // Clear invalid token
      await logout();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _apiService.loginAndGetToken(email, password);
      if (token != null && token.isNotEmpty) {
        _authToken = token;
        _email = email;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('auth_email', email);
        _apiService.authToken = token;
        return true;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register new user. Returns null on success, error message on failure.
  Future<String?> register({
    required String email,
    required String password,
    String? name,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final error = await _apiService.register(email: email, password: password, name: name);
      return error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _authToken = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_email');
    notifyListeners();
  }

  /// Request account deletion on backend then clear local auth. Always clears local data.
  Future<void> deleteAccount() async {
    await _apiService.deleteAccount();
    await logout();
  }
}


