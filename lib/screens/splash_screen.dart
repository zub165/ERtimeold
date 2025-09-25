import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main_screen.dart';
import 'login_screen.dart';
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
    await context.read<AuthProvider>().loadFromStorage();
    // Load user API configurations first
    await ApiKeyManager.loadUserApiConfigurations();
    
    // Test Django backend connection
    bool isConnected = await _apiService.testConnection();

    setState(() {
      _connectionTested = true;
    });
    
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
            AppConfig.useGoogleMaps = mapConfigs['enable_google_maps'] ?? true;
            AppConfig.useTomTomMaps = mapConfigs['enable_tomtom_maps'] ?? false;
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
    
    print('Final API key configuration:');
    print('- Google Maps: ${AppConfig.googleMapsApiKey?.substring(0, 10)}...');
    print('- TomTom: ${AppConfig.tomtomApiKey?.substring(0, 10)}...');
    print('- Preferred: ${AppConfig.useGoogleMaps ? "Google" : "TomTom"}');
    
    setState(() {
      _apiKeysLoaded = true;
    });
    
    // Request permissions
    await _requestPermissions();
    
    // Wait for splash screen effect
    await Future.delayed(Duration(seconds: 2));
    
    final auth = context.read<AuthProvider>();
    // Navigate to login quickly if not authenticated, else to main screen
    if (!auth.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoggedIn: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MainScreen(backendConnected: isConnected),
                ),
              );
            },
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(backendConnected: isConnected),
        ),
      );
    }
  }
  
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
    
    // Handle permission results if needed
    if (statuses[Permission.location] != PermissionStatus.granted) {
      print('Location permission not granted');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5DADE2), // Light blue matching the design
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
                color: Color(0xFF5DADE2),
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
    AppConfig.useGoogleMaps = true;
    AppConfig.useTomTomMaps = false;
    print('No API keys available - will use demo mode or user-provided keys');
  }
}
