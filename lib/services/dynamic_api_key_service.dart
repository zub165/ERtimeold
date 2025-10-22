import 'package:flutter/services.dart';
import '../config/app_config.dart';

class DynamicApiKeyService {
  static const MethodChannel _channel = MethodChannel('api_key_manager');
  
  /// Update Android Manifest API key at runtime (if possible)
  static Future<bool> updateAndroidManifestApiKey(String apiKey) async {
    try {
      // This would require platform-specific implementation
      // For now, we'll just store it in memory
      AppConfig.googleMapsApiKey = apiKey;
      print('Updated Google Maps API key in memory');
      return true;
    } catch (e) {
      print('Error updating Android Manifest API key: $e');
      return false;
    }
  }
  
  /// Check if Google Maps is functional with current API key
  static Future<bool> validateGoogleMapsConnection() async {
    try {
      if (AppConfig.googleMapsApiKey == null || AppConfig.googleMapsApiKey!.isEmpty) {
        return false;
      }
      
      // This would make a test API call to validate the key
      // For now, just check if key format is correct
      return AppConfig.googleMapsApiKey!.startsWith('AIza') && 
             AppConfig.googleMapsApiKey!.length >= 35;
    } catch (e) {
      print('Error validating Google Maps connection: $e');
      return false;
    }
  }
  
  /// Get API key status and source
  static Map<String, dynamic> getApiKeyStatus() {
    return {
      'google_maps_available': AppConfig.googleMapsApiKey?.isNotEmpty == true,
      'tomtom_available': AppConfig.tomtomApiKey?.isNotEmpty == true,
      'google_maps_source': AppConfig.googleMapsApiKey?.isNotEmpty == true ? 
                           (AppConfig.googleMapsApiKey!.startsWith('AIza') ? 'Valid Format' : 'Invalid Format') : 
                           'Not Set',
      'security_mode': 'Dynamic Keys Only',
      'hardcoded_keys': false,
    };
  }
  
  /// Generate instructions for users to get API keys
  static Map<String, String> getApiKeyInstructions() {
    return {
      'google_maps': '''
1. Go to Google Cloud Console (console.cloud.google.com)
2. Enable the Maps SDK for Android and iOS
3. Create credentials → API Key
4. Restrict the key to your app package
5. Copy the API key and paste it in the app settings''',
      
      'tomtom': '''
1. Go to TomTom Developer Portal (developer.tomtom.com)
2. Create a free account
3. Go to My Dashboard → API Keys
4. Create a new API key
5. Copy the key and paste it in the app settings''',
    };
  }
  
  /// Check if app can function without API keys (demo mode)
  static bool canRunInDemoMode() {
    // App can show hospital list without maps
    return true;
  }
  
  /// Get demo mode limitations
  static List<String> getDemoModeLimitations() {
    return [
      'Map view will not be available',
      'Directions will open in external apps only',
      'Distance calculations may be less accurate',
      'Some location features may be limited',
    ];
  }
}
