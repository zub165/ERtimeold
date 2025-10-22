import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiKeyManager {
  static const String _googleMapsKeyPref = 'user_google_maps_api_key';
  static const String _tomtomKeyPref = 'user_tomtom_api_key';
  static const String _preferredMapProviderPref = 'preferred_map_provider';
  static const String _useUserKeysOnlyPref = 'use_user_keys_only';
  
  /// Save user's Google Maps API key
  static Future<void> saveGoogleMapsApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleMapsKeyPref, apiKey);
    AppConfig.googleMapsApiKey = apiKey;
  }
  
  /// Save user's TomTom API key
  static Future<void> saveTomTomApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tomtomKeyPref, apiKey);
    AppConfig.tomtomApiKey = apiKey;
  }
  
  /// Get user's Google Maps API key
  static Future<String?> getUserGoogleMapsApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googleMapsKeyPref);
  }
  
  /// Get user's TomTom API key
  static Future<String?> getUserTomTomApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tomtomKeyPref);
  }
  
  /// Save preferred map provider
  static Future<void> savePreferredMapProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredMapProviderPref, provider);
    
    if (provider == 'google') {
      AppConfig.useGoogleMaps = true;
      AppConfig.useTomTomMaps = false;
    } else if (provider == 'tomtom') {
      AppConfig.useGoogleMaps = false;
      AppConfig.useTomTomMaps = true;
    }
  }
  
  /// Get preferred map provider
  static Future<String> getPreferredMapProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredMapProviderPref) ?? 'google';
  }
  
  /// Set whether to use only user-provided keys (ignore Django/fallback)
  static Future<void> setUseUserKeysOnly(bool useUserKeysOnly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useUserKeysOnlyPref, useUserKeysOnly);
  }
  
  /// Check if should use only user-provided keys
  static Future<bool> shouldUseUserKeysOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useUserKeysOnlyPref) ?? false;
  }
  
  /// Load all user API configurations
  static Future<void> loadUserApiConfigurations() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load user API keys
    final userGoogleKey = prefs.getString(_googleMapsKeyPref);
    final userTomTomKey = prefs.getString(_tomtomKeyPref);
    final preferredProvider = prefs.getString(_preferredMapProviderPref) ?? 'google';
    final useUserKeysOnly = prefs.getBool(_useUserKeysOnlyPref) ?? false;
    
    // Apply user API keys if available
    if (userGoogleKey != null && userGoogleKey.isNotEmpty) {
      AppConfig.googleMapsApiKey = userGoogleKey;
      print('Loaded user Google Maps API key: ${userGoogleKey.substring(0, 10)}...');
    }
    
    if (userTomTomKey != null && userTomTomKey.isNotEmpty) {
      AppConfig.tomtomApiKey = userTomTomKey;
      print('Loaded user TomTom API key: ${userTomTomKey.substring(0, 10)}...');
    }
    
    // Set preferred map provider
    if (preferredProvider == 'google') {
      AppConfig.useGoogleMaps = true;
      AppConfig.useTomTomMaps = false;
    } else if (preferredProvider == 'tomtom') {
      AppConfig.useGoogleMaps = false;
      AppConfig.useTomTomMaps = true;
    }
    
    print('Map provider preference: $preferredProvider');
    print('Use user keys only: $useUserKeysOnly');
  }
  
  /// Get current active Google Maps API key (user > Django > fallback)
  static Future<String?> getActiveGoogleMapsApiKey() async {
    final useUserKeysOnly = await shouldUseUserKeysOnly();
    
    if (useUserKeysOnly) {
      // Only use user-provided key
      final userKey = await getUserGoogleMapsApiKey();
      return userKey?.isNotEmpty == true ? userKey : null;
    } else {
      // Priority: User > Django > Fallback
      final userKey = await getUserGoogleMapsApiKey();
      if (userKey != null && userKey.isNotEmpty) {
        return userKey;
      }
      
      if (AppConfig.googleMapsApiKey != null && AppConfig.googleMapsApiKey!.isNotEmpty) {
        return AppConfig.googleMapsApiKey;
      }
      
      // No fallback API key - return null for demo mode
      return null;
    }
  }
  
  /// Get current active TomTom API key (user > Django > fallback)
  static Future<String?> getActiveTomTomApiKey() async {
    final useUserKeysOnly = await shouldUseUserKeysOnly();
    
    if (useUserKeysOnly) {
      // Only use user-provided key
      final userKey = await getUserTomTomApiKey();
      return userKey?.isNotEmpty == true ? userKey : null;
    } else {
      // Priority: User > Django > Fallback
      final userKey = await getUserTomTomApiKey();
      if (userKey != null && userKey.isNotEmpty) {
        return userKey;
      }
      
      if (AppConfig.tomtomApiKey != null && AppConfig.tomtomApiKey!.isNotEmpty) {
        return AppConfig.tomtomApiKey;
      }
      
      // No fallback API key - return null for demo mode
      return null;
    }
  }
  
  /// Validate Google Maps API key format
  static bool isValidGoogleMapsApiKey(String apiKey) {
    return apiKey.startsWith('AIza') && apiKey.length >= 35;
  }
  
  /// Validate TomTom API key format  
  static bool isValidTomTomApiKey(String apiKey) {
    return apiKey.length >= 20; // TomTom keys are typically longer
  }
  
  /// Clear all user API keys
  static Future<void> clearAllUserApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_googleMapsKeyPref);
    await prefs.remove(_tomtomKeyPref);
    await prefs.remove(_preferredMapProviderPref);
    await prefs.remove(_useUserKeysOnlyPref);
  }
  
  /// Get API key source information
  static Future<Map<String, String>> getApiKeySourceInfo() async {
    final userGoogleKey = await getUserGoogleMapsApiKey();
    final userTomTomKey = await getUserTomTomApiKey();
    final useUserKeysOnly = await shouldUseUserKeysOnly();
    
    String googleSource = 'None';
    String tomtomSource = 'None';
    
    if (useUserKeysOnly) {
      googleSource = userGoogleKey?.isNotEmpty == true ? 'User Provided' : 'None';
      tomtomSource = userTomTomKey?.isNotEmpty == true ? 'User Provided' : 'None';
    } else {
      if (userGoogleKey?.isNotEmpty == true) {
        googleSource = 'User Provided';
      } else if (AppConfig.googleMapsApiKey?.isNotEmpty == true) {
        googleSource = 'Django Backend';
      } else {
        googleSource = 'Not Available';
      }
      
      if (userTomTomKey?.isNotEmpty == true) {
        tomtomSource = 'User Provided';
      } else if (AppConfig.tomtomApiKey?.isNotEmpty == true) {
        tomtomSource = 'Django Backend';
      } else {
        tomtomSource = 'Not Available';
      }
    }
    
    return {
      'google_source': googleSource,
      'tomtom_source': tomtomSource,
    };
  }
}
