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
    notifyListeners();
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

  Future<void> logout() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}


