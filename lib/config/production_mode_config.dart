/// Production Mode Configuration for ER Time App
class ProductionModeConfig {
  // Backend Configuration
  static const String primaryBackendUrl = 'https://api.mywaitime.com/api';
  static const String fallbackBackendUrl = 'https://api.mywaitime.com/api';
  
  // Timeout Configuration
  static const int connectionTimeoutSeconds = 30;
  static const int readTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;
  
  // Production Features
  static const bool enableOfflineMode = true;
  static const bool enableMockDataFallback = true;
  static const bool enableLocationFallback = true;
  static const bool enableAnalytics = true;
  static const bool enableErrorReporting = true;
  
  // API Keys (Production)
  static const String googleMapsApiKey = 'AIzaSyC5ku3HcZ7Rc_Tlpi2roWgDoX5XYiQ8Aro';
  static const String tomtomApiKey = 'TN96UVRijrAr9LJwUqL7Scbfqf9syviD';
  
  // Demo Account (Production)
  static const String demoUsername = 'demo@ertime.app';
  static const String demoPassword = 'demo123';
  
  // App Configuration
  static const String appVersion = '2.1.11';
  static const int buildNumber = 21;
  static const String appName = 'ER Wait Time';
  static const String bundleId = 'com.erwwaittime.com';
  
  // Production URLs
  static const String privacyPolicyUrl = 'https://api.mywaitime.com/privacy.html';
  static const String termsOfServiceUrl = 'https://api.mywaitime.com/terms.html';
  static const String supportEmail = 'zub165@yahoo.com';
  
  // Feature Flags
  static const bool enableAiPredictions = true;
  static const bool enableWeatherData = true;
  static const bool enableTrafficData = true;
  static const bool enableFeedbackSystem = true;
  static const bool enableUserRegistration = true;
  static const bool enablePasswordReset = true;
  
  // Performance Settings
  static const int maxHospitalsPerSearch = 50;
  static const double defaultSearchRadiusKm = 10.0;
  static const int cacheExpirationHours = 1;
  static const int maxCacheSizeMB = 100;
  
  // Error Handling
  static const bool showDetailedErrors = false; // Set to false in production
  static const bool logNetworkErrors = true;
  static const bool enableCrashReporting = true;
  
  // Ad Configuration
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static const bool enableBannerAds = true;
  static const bool enableInterstitialAds = true;
  // Android interstitial (Hospital View Interstitial)
  static const String androidInterstitialAdUnitId =
      'ca-app-pub-2497524301046342/4743268477';
  
  /// Check if app is in production mode
  static bool get isProductionMode => true;
  
  /// Get the current backend URL (with fallback)
  static String get currentBackendUrl {
    // In production, always use the working backend
    return primaryBackendUrl;
  }
  
  /// Get timeout duration for API calls
  static Duration get connectionTimeout => Duration(seconds: connectionTimeoutSeconds);
  
  /// Get read timeout duration
  static Duration get readTimeout => Duration(seconds: readTimeoutSeconds);
  
  /// Check if feature is enabled
  static bool isFeatureEnabled(String feature) {
    switch (feature) {
      case 'ai_predictions':
        return enableAiPredictions;
      case 'weather_data':
        return enableWeatherData;
      case 'traffic_data':
        return enableTrafficData;
      case 'feedback_system':
        return enableFeedbackSystem;
      case 'user_registration':
        return enableUserRegistration;
      case 'password_reset':
        return enablePasswordReset;
      case 'offline_mode':
        return enableOfflineMode;
      case 'mock_data_fallback':
        return enableMockDataFallback;
      case 'analytics':
        return enableAnalytics;
      default:
        return false;
    }
  }
  
  /// Get production status message
  static String get productionStatusMessage {
    return '''
🚀 ER TIME APP - PRODUCTION MODE ACTIVE

✅ Backend: $currentBackendUrl
✅ Version: $appVersion (Build $buildNumber)
✅ Demo Account: $demoUsername / $demoPassword
✅ Features: AI Predictions, Weather Data, Traffic Data
✅ Offline Mode: Enabled
✅ Error Handling: Production Ready

📱 Ready for App Store Submission!
''';
  }
}
