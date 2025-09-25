import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  bool _hasPermission = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  Position? get currentPosition => _currentPosition;
  bool get hasPermission => _hasPermission;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> getCurrentLocation() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    
    _isLoading = true;
    _errorMessage = null;
    
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled';
        _hasPermission = false;
        return;
      }
      
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permission denied';
          _hasPermission = false;
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied';
        _hasPermission = false;
        return;
      }
      
      // Get current position with timeout
      print('Attempting to get current location...');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
        forceAndroidLocationManager: false,
      );
      _hasPermission = true;
      _errorMessage = null;
      print('Location obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    } catch (e) {
      print('Location error: $e');
      _errorMessage = 'Error getting location: ${e.toString()}';
      _hasPermission = false;
      
      // Try to get last known position as fallback
      try {
        _currentPosition = await Geolocator.getLastKnownPosition();
        if (_currentPosition != null) {
          _hasPermission = true;
          _errorMessage = null;
          print('Using last known position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        } else {
          // Use default location (Los Angeles) for emulator/testing
          _currentPosition = Position(
            latitude: 34.0522,
            longitude: -118.2437,
            timestamp: DateTime.now(),
            accuracy: 100.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
          _hasPermission = true;
          _errorMessage = 'Using default location (Los Angeles) for demo';
          print('Using default location for demo: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        }
      } catch (fallbackError) {
        print('Fallback location error: $fallbackError');
        // Last resort: use default location
        _currentPosition = Position(
          latitude: 34.0522,
          longitude: -118.2437,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        _hasPermission = true;
        _errorMessage = 'Using default location (Los Angeles) for demo';
        print('Using default location as last resort');
      }
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
  
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to kilometers
  }
}
