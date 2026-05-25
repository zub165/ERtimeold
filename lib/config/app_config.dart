class AppConfig {
  // App Information
  static const String appName = 'ER Wait Time';
  static const String packageName = 'com.easytechnologiez.ERTime';
  static const String version = '5.1.6';
  static const int versionCode = 73;

  /// Free hospital searches before premium subscription is required (iOS + Android).
  static const int freeSearchLimit = 30;

  /// Same product ID in Google Play Console and App Store Connect ($3.99/month).
  ///
  /// **Google Play:** Monetize → Subscriptions → Create subscription
  /// `er_premium_monthly` → base plan $3.99/month → activate.
  ///
  /// **App Store Connect:** Subscriptions → group (e.g. ER Premium) →
  /// `er_premium_monthly` → $3.99/month → submit with app version.
  static const String premiumMonthlyProductId = 'er_premium_monthly';
  static const String premiumMonthlyPriceHint = '\$3.99';

  /// Legal / subscription management (required for App Store & Google Play).
  ///
  /// **App Store Connect (required for auto-renewable subscriptions):**
  /// 1. App Information → Privacy Policy URL → [privacyPolicyUrl]
  /// 2. App Description must include a line with [termsOfUseEulaUrl] (or use
  ///    [appleStandardEulaUrl] if you rely on Apple's standard EULA only).
  /// 3. Or upload a custom EULA under App Information → License Agreement.
  static const String privacyPolicyUrl = 'https://api.mywaitime.com/privacy-policy/';
  static const String termsOfServiceUrl = 'https://api.mywaitime.com/terms/';

  /// Same as [termsOfServiceUrl] — label as "Terms of Use (EULA)" for Apple review.
  static const String termsOfUseEulaUrl = termsOfServiceUrl;

  /// Apple's standard licensed-application EULA (if you do not use a custom EULA).
  static const String appleStandardEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String privacyContactEmail = 'privacy@mywaittime.com';
  static const String appleManageSubscriptionsUrl =
      'https://apps.apple.com/account/subscriptions';
  static const String googlePlayManageSubscriptionsUrl =
      'https://play.google.com/store/account/subscriptions';

  /// Mailto links for data-rights requests (API POST endpoints are not browser pages).
  static String get accountDeletionRequestMailto => _mailto(
        subject: 'Account Deletion Request - ER Wait Time',
        body:
            'Please delete my account and all associated personal data.\n\n'
            'Registered email in app:\n',
      );

  static String get dataExportRequestMailto => _mailto(
        subject: 'Data Export Request - ER Wait Time',
        body:
            'Please send me a copy of my personal data held by ER Wait Time.\n\n'
            'Registered email in app:\n',
      );

  static String _mailto({required String subject, required String body}) =>
      'mailto:$privacyContactEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
  
  // Map API Keys - Retrieved dynamically from Django backend or user input
  static String? googleMapsApiKey;
  static String? tomtomApiKey;

  // NO HARDCODED API KEYS - Security Best Practice
  // Keys are loaded from:
  // 1. User-provided keys (via API Key Settings)
  // 2. Django backend (securely fetched at runtime)
  // 3. Demo/fallback mode (limited functionality)
  
  // Map Provider Settings
  // IMPORTANT: Google Maps is disabled by default to prevent crashes if API key is missing
  // It will be enabled only if a valid API key is provided
  static bool useGoogleMaps = false; // Changed to false - will be enabled if key is available
  static bool useTomTomMaps = false;
  static bool useOpenStreetMap = true; // Enable OSM as default fallback
  
  // Django Backend Configuration (Primary Database)
  static const String djangoBaseUrl = 'https://api.mywaitime.com/api';
  
  // Database Configuration - Using Django PostgreSQL/MySQL Backend
  static const bool useDjangoDatabase = true;
  static const bool useFirebase = false; // Disabled - using Django only
  
  // App Settings
  static const double defaultSearchRadius = 10.0; // kilometers
  static const int maxSearchRadius = 50;
  static const int minSearchRadius = 1;
  
  // Contact Information
  static const String supportEmail = 'zub165@yahoo.com';
  
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
For questions about privacy, contact us at zub165@yahoo.com
  ''';
}
