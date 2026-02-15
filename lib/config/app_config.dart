// lib/config/app_config.dart

class AppConfig {
  // App Information
  static const String appName = 'ER Wait Time';
  static const String packageName = 'com.easytechnologiez.ERTime';
  static const String version = '2.0.9';
  static const int versionCode = 9;
  
  // PLATFORM-SPECIFIC PRICING
  // iOS: Paid app ($6.99) - NO ADS
  // Android: Free with ads OR Premium IAP
  static const bool isIOSPaidApp = true;  // iOS is $6.99 paid
  static const bool isAndroidFreeApp = true;  // Android is free with ads
  
  // IN-APP PURCHASE IDs
  // iOS: Additional premium features
  static const String iosPremiumPlus = 'premium_plus_monthly_299';  // $2.99/month for advanced features
  static const String iosPremiumPlusYearly = 'premium_plus_yearly_2999';  // $29.99/year
  
  // Android: Full premium (removes ads + features)
  static const String androidPremiumMonthly = 'premium_monthly_499';  // $4.99/month
  static const String androidPremiumYearly = 'premium_yearly_3999';  // $39.99/year
  
  // Map API Keys - Retrieved dynamically from Django backend or user input
  static String? googleMapsApiKey;
  static String? tomtomApiKey;

  // NO HARDCODED API KEYS - Security Best Practice
  // Keys are loaded from:
  // 1. User-provided keys (via API Key Settings)
  // 2. Django backend (securely fetched at runtime)
  // 3. Demo/fallback mode (limited functionality)
  
  // Map Provider Settings
  static bool useGoogleMaps = true;
  static bool useTomTomMaps = false;
  
  // Django Backend Configuration (Primary Database)
  // Production behind Nginx (HTTPS)
  static const String djangoBaseUrl = 'https://api.mywaitime.com/api';
  static const String djangoPassword = 'Bismilah165\$';
  
  // Database Configuration - Using Django PostgreSQL/MySQL Backend
  static const bool useDjangoDatabase = true;
  static const bool useFirebase = false; // Disabled - using Django only
  
  // App Settings
  static const double defaultSearchRadius = 10.0; // kilometers
  static const int maxSearchRadius = 50;
  static const int minSearchRadius = 1;
  
  // Contact Information
  static const String supportEmail = 'support@easytechnologiez.com';
  
  // FEATURE FLAGS
  static bool shouldShowAds() {
    // iOS paid app: NO ADS
    // Android free app: SHOW ADS (unless premium)
    if (isIOSPaidApp) return false;
    return isAndroidFreeApp;
  }
  
  static bool hasPremiumPlusFeatures() {
    // Check if user has subscribed to Premium Plus
    // Will be implemented in SubscriptionService
    return false; // Default
  }
  
  // Privacy Policy Text (from existing Android project)
  static const String privacyPolicyText = '''
ER Wait Time Privacy Policy

This app provides estimated ER wait times at nearby hospitals. We do not collect or store any personal information from users.

DATA WE COLLECT:
• Location data: We access your location only to show nearby hospitals. This data is used only within the app and is never stored on our servers.
• App usage data: Google may collect anonymous usage statistics to help improve the app experience.

DATA WE DO NOT COLLECT:
• Personal information: We do not require login or collect any personal information like names, emails, or health data.
• Photos or media: We do not access or collect photos or media files.

THIRD-PARTY SERVICES:
• Google Maps: Used to display maps and location information according to Google's privacy policy.

CONTACT:
For questions about privacy, contact us at support@easytechnologiez.com
  ''';
}
