import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/django_api_service.dart';
import '../services/api_key_manager.dart';
import '../config/app_config.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final DjangoApiService _apiService = DjangoApiService();
  bool _connectionTested = false;
  bool _apiKeysLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    await context.read<AuthProvider>().checkAuthStatus();
    // Load user API configurations first
    await ApiKeyManager.loadUserApiConfigurations();
    
    // Test Django backend connection
    final connectionResult = await _apiService.testConnection();
    bool isConnected = connectionResult.isSuccess;

    if (mounted) {
      setState(() {
        _connectionTested = true;
      });
    }
    
    // Fetch map configurations from Django backend (only if user hasn't set "user keys only")
    final useUserKeysOnly = await ApiKeyManager.shouldUseUserKeysOnly();
    
    if (isConnected && !useUserKeysOnly) {
      try {
        Map<String, dynamic>? mapConfigs = await _apiService.getAllMapConfigs();
        if (mapConfigs != null) {
          // Only update if user hasn't provided their own keys
          final userGoogleKey = await ApiKeyManager.getUserGoogleMapsApiKey();
          final userTomTomKey = await ApiKeyManager.getUserTomTomApiKey();
          
          if (userGoogleKey == null || userGoogleKey.isEmpty) {
            AppConfig.googleMapsApiKey = mapConfigs['google_maps_api_key'];
          }
          
          if (userTomTomKey == null || userTomTomKey.isEmpty) {
            AppConfig.tomtomApiKey = mapConfigs['tomtom_api_key'];
          }
          
          // Update preferences if not set by user
          final preferredProvider = await ApiKeyManager.getPreferredMapProvider();
          if (preferredProvider == 'google') {
            final googleKey = (AppConfig.googleMapsApiKey ?? '').trim();
            final googleKeyValid = ApiKeyManager.isValidGoogleMapsApiKey(googleKey);
            // Only allow Google Maps with a real browser/mobile Maps key shape (avoids native crashes).
            AppConfig.useGoogleMaps = (mapConfigs['enable_google_maps'] ?? true) && googleKeyValid;
            AppConfig.useTomTomMaps = mapConfigs['enable_tomtom_maps'] ?? false;
            AppConfig.useOpenStreetMap = !AppConfig.useGoogleMaps && !AppConfig.useTomTomMaps;
          } else if (preferredProvider == 'tomtom') {
            final tomtomKey = (AppConfig.tomtomApiKey ?? '').trim();
            final tomtomKeyValid = tomtomKey.isNotEmpty;
            // When user prefers TomTom, default backend flag to on so TomTom is used when a key exists.
            AppConfig.useTomTomMaps =
                (mapConfigs['enable_tomtom_maps'] ?? true) && tomtomKeyValid;
            AppConfig.useGoogleMaps = false;
            AppConfig.useOpenStreetMap = !AppConfig.useTomTomMaps;
          } else if (preferredProvider == 'osm' ||
              preferredProvider == 'openstreetmap') {
            AppConfig.useGoogleMaps = false;
            AppConfig.useTomTomMaps = false;
            AppConfig.useOpenStreetMap = true;
          }
          
          print('Map configurations loaded from Django backend');
        } else {
          print('Failed to load map configurations from Django backend');
          _setFallbackConfigurations();
        }
      } catch (e) {
        print('Error loading map configurations: $e');
        _setFallbackConfigurations();
      }
    } else if (!isConnected && !useUserKeysOnly) {
      // Django backend not connected and not using user keys only
      _setFallbackConfigurations();
    }
    
    // Ensure we have working API keys
    final activeGoogleKey = await ApiKeyManager.getActiveGoogleMapsApiKey();
    final activeTomTomKey = await ApiKeyManager.getActiveTomTomApiKey();
    
    if (activeGoogleKey != null) {
      AppConfig.googleMapsApiKey = activeGoogleKey;
    }
    
    if (activeTomTomKey != null) {
      AppConfig.tomtomApiKey = activeTomTomKey;
    }

    // Re-apply saved provider against the final resolved keys (Django + user + active).
    final resolvedPref = await ApiKeyManager.getPreferredMapProvider();
    await ApiKeyManager.savePreferredMapProvider(resolvedPref);
    
    print('Final API key configuration:');
    final googlePreview = AppConfig.googleMapsApiKey != null && AppConfig.googleMapsApiKey!.length >= 10
        ? '${AppConfig.googleMapsApiKey!.substring(0, 10)}...'
        : AppConfig.googleMapsApiKey ?? 'null';
    final tomtomPreview = AppConfig.tomtomApiKey != null && AppConfig.tomtomApiKey!.length >= 10
        ? '${AppConfig.tomtomApiKey!.substring(0, 10)}...'
        : AppConfig.tomtomApiKey ?? 'null';
    print('- Google Maps: $googlePreview');
    print('- TomTom: $tomtomPreview');
    print(
        '- Active map: ${AppConfig.useGoogleMaps ? "Google" : AppConfig.useTomTomMaps ? "TomTom" : "OpenStreetMap"}');
    
    if (mounted) {
      setState(() {
        _apiKeysLoaded = true;
      });
    }
    
    // Request permissions
    await _requestPermissions();
    
    // Wait for splash screen effect
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    // Guest mode: Always allow access to non-account features.
    // Login remains available from Profile/Settings when needed.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(backendConnected: isConnected),
      ),
    );
  }
  
  Future<void> _requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.locationWhenInUse,
      ].request();
      
      // Handle permission results
      if (statuses[Permission.location] == PermissionStatus.granted) {
        print('✅ Location permission granted');
      } else if (statuses[Permission.location] == PermissionStatus.denied) {
        print('⚠️ Location permission denied - app will use default location');
      } else if (statuses[Permission.location] == PermissionStatus.permanentlyDenied) {
        print('❌ Location permission permanently denied - app will use default location');
      } else {
        print('⚠️ Location permission status: ${statuses[Permission.location]}');
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ER Wait Time Logo
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_hospital,
                size: 80,
                color: primary,
              ),
            ),
            SizedBox(height: 30),
            
            // App Title
            Text(
              'ER Wait Time',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 10),
            
            Text(
              'Emergency Wait Time Tracker',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 50),
            
            // Loading indicator
            SpinKitWave(
              color: Colors.white,
              size: 50.0,
            ),
            SizedBox(height: 20),
            
            // Status text
            Text(
              !_connectionTested 
                ? 'Testing Django Backend...'
                : !_apiKeysLoaded
                  ? 'Loading Map API Keys...'
                  : 'Connecting to Hospital Finder...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _setFallbackConfigurations() {
    // No hardcoded fallback keys - use demo mode
    AppConfig.googleMapsApiKey = null;
    AppConfig.tomtomApiKey = null;
    // Prefer non-Google providers by default to avoid crashes when Google keys/SDK
    // are not available (especially on iOS without proper setup).
    AppConfig.useGoogleMaps = false;
    AppConfig.useTomTomMaps = false;
    AppConfig.useOpenStreetMap = true;
    print('No API keys available - will use demo mode or user-provided keys');
  }
}
