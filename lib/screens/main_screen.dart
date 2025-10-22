import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/location_provider.dart';
import '../providers/hospital_provider.dart';
import '../services/django_api_service.dart';
import '../services/mock_data_service.dart';
import '../widgets/hospital_card.dart';
import '../widgets/banner_ad_widget.dart';
import '../config/units_config.dart';
import 'maps_screen.dart';
import 'debug_screen.dart';
import 'map_settings_screen.dart';
import 'api_key_settings_screen.dart';

class MainScreen extends StatefulWidget {
  final bool backendConnected;
  
  const MainScreen({Key? key, required this.backendConnected}) : super(key: key);
  
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double _radiusValue = 10.0;
  final DjangoApiService _apiService = DjangoApiService();
  bool _isSearching = false;
  DistanceUnit _currentUnit = DistanceUnit.kilometers;
  
  @override
  void initState() {
    super.initState();
    _loadUnitPreference();
    _getCurrentLocation();
  }

  void _loadUnitPreference() {
    _currentUnit = UnitsConfig.distanceUnit;
    setState(() {
      // Adjust radius value if unit changed
      if (_currentUnit == DistanceUnit.miles) {
        _radiusValue = _radiusValue * 0.621371; // Convert km to miles
      }
      _radiusValue = _radiusValue.clamp(
        _currentUnit == DistanceUnit.miles ? 0.6 : 1.0,
        _currentUnit == DistanceUnit.miles ? 31.0 : 50.0,
      );
    });
  }
  
  Future<void> _getCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();
    
    // Auto-search hospitals when location is obtained
    if (locationProvider.currentPosition != null) {
      print('Location obtained: ${locationProvider.currentPosition!.latitude}, ${locationProvider.currentPosition!.longitude}');
      await _searchHospitals();
    } else {
      print('Location not available: ${locationProvider.errorMessage}');
    }
  }
  
  Future<void> _searchHospitals() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
    
    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enable location services'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      List<Hospital> hospitals = [];
      
      // Try Django backend first (always try, even if connection test failed)
      try {
        double searchRadiusKm = UnitsConfig.convertFromDisplayUnit(_radiusValue);
        hospitals = await _apiService.searchHospitals(
          latitude: locationProvider.currentPosition!.latitude,
          longitude: locationProvider.currentPosition!.longitude,
          radius: searchRadiusKm,
        );
        print('Django search: Found ${hospitals.length} hospitals');
      } catch (e) {
        print('Django backend error: $e');
        hospitals = []; // Ensure it's empty to trigger mock data
      }
      
      // If no hospitals from Django or backend not connected, use mock data
      if (hospitals.isEmpty) {
        double searchRadiusKm = UnitsConfig.convertFromDisplayUnit(_radiusValue);
        hospitals = MockDataService.generateMockHospitals(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
          searchRadiusKm,
        );
        print('Using mock data: Generated ${hospitals.length} hospitals');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using demo data - Django backend offline'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
                        String backendStatus = widget.backendConnected ? 'Django Backend Connected' : 'Using Demo Data';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$backendStatus: ${hospitals.length} hospitals found'),
                            backgroundColor: widget.backendConnected ? Colors.green : Colors.blue,
                            duration: Duration(seconds: 2),
                          ),
                        );
      }
      
      hospitalProvider.setHospitals(hospitals);
    } catch (e) {
      print('Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching hospitals'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5DADE2),
      appBar: AppBar(
        title: Text('ER Wait Time'),
        backgroundColor: Color(0xFF5DADE2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.settings),
            onSelected: (value) {
              switch (value) {
                case 'api_keys':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApiKeySettingsScreen(),
                    ),
                  );
                  break;
                case 'map_settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapSettingsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'api_keys',
                child: Row(
                  children: [
                    Icon(Icons.vpn_key, color: Color(0xFF5DADE2)),
                    SizedBox(width: 8),
                    Text('API Key Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'map_settings',
                child: Row(
                  children: [
                    Icon(Icons.map, color: Color(0xFF5DADE2)),
                    SizedBox(width: 8),
                    Text('Map Settings'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DebugScreen(),
                ),
              );
            },
            tooltip: 'Debug Django',
          ),
          Consumer<HospitalProvider>(
            builder: (context, hospitalProvider, child) {
              return IconButton(
                icon: Icon(Icons.map),
                onPressed: hospitalProvider.hospitals.isNotEmpty
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapsScreen(),
                          ),
                        );
                      }
                    : null,
                tooltip: 'View on Map',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner Ad at top
            const BannerAdWidget(
              height: 50,
              margin: EdgeInsets.only(top: 8),
            ),
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
              children: [
                SizedBox(height: 10),
                  
                  // Search Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Location Permission Row
                        Consumer<LocationProvider>(
                          builder: (context, locationProvider, child) {
                            return Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    locationProvider.hasPermission
                                        ? 'Location Permission Granted'
                                        : 'Click for Permission',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                if (!locationProvider.hasPermission)
                                  IconButton(
                                    onPressed: _getCurrentLocation,
                                    icon: Icon(Icons.refresh),
                                  ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        
                        // Radius Slider
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Search Radius',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Units Toggle
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (_currentUnit == DistanceUnit.miles) {
                                              _radiusValue = _radiusValue / 0.621371; // Convert miles to km
                                            }
                                            _currentUnit = DistanceUnit.kilometers;
                                            UnitsConfig.setDistanceUnit(_currentUnit);
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _currentUnit == DistanceUnit.kilometers 
                                                ? Color(0xFF5DADE2) 
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'km',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _currentUnit == DistanceUnit.kilometers 
                                                  ? Colors.white 
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (_currentUnit == DistanceUnit.kilometers) {
                                              _radiusValue = _radiusValue * 0.621371; // Convert km to miles
                                            }
                                            _currentUnit = DistanceUnit.miles;
                                            UnitsConfig.setDistanceUnit(_currentUnit);
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _currentUnit == DistanceUnit.miles 
                                                ? Color(0xFF5DADE2) 
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'mi',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _currentUnit == DistanceUnit.miles 
                                                  ? Colors.white 
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _radiusValue,
                                    min: _currentUnit == DistanceUnit.miles ? 0.6 : 1.0,
                                    max: _currentUnit == DistanceUnit.miles ? 31.0 : 50.0,
                                    divisions: _currentUnit == DistanceUnit.miles ? 30 : 49,
                                    activeColor: Color(0xFF5DADE2),
                                    label: '${_radiusValue.round()} ${UnitsConfig.getDistanceUnitAbbr()}',
                                    onChanged: (value) {
                                      setState(() {
                                        _radiusValue = value;
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF5DADE2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Color(0xFF5DADE2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${_radiusValue.round()} ${UnitsConfig.getDistanceUnitAbbr()}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF5DADE2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        // Search Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _searchHospitals,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5DADE2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSearching
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'SEARCH',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        
                        // Backend Connection Status
                        Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.backendConnected ? Colors.green : Colors.red,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.backendConnected 
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.red.withOpacity(0.3),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                widget.backendConnected 
                                    ? 'Django Backend: Connected'
                                    : 'Django Backend: Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.backendConnected ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                widget.backendConnected ? Icons.cloud_done : Icons.cloud_off,
                                size: 16,
                                color: widget.backendConnected ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Hospital List
            Expanded(
              child: Consumer<HospitalProvider>(
                builder: (context, hospitalProvider, child) {
                  if (_isSearching) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Searching for hospitals...',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (hospitalProvider.hospitals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.local_hospital,
                              size: 80,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Find Nearby Hospitals',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Tap the search button to find emergency rooms\\nand hospitals in your area',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Column(
                    children: [
                      // Results header
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${hospitalProvider.hospitals.length} hospitals found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                hospitalProvider.clearHospitals();
                              },
                              icon: Icon(Icons.clear, color: Colors.white70, size: 16),
                              label: Text(
                                'Clear',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hospital list
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: hospitalProvider.hospitals.length,
                          itemBuilder: (context, index) {
                            return HospitalCard(
                              hospital: hospitalProvider.hospitals[index],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
