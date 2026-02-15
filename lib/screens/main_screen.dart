import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/hospital_provider.dart';
import '../providers/auth_provider.dart';
import '../services/django_api_service.dart';
import '../services/mock_data_service.dart';
import '../services/ad_manager.dart';
import '../widgets/hospital_card.dart';
import '../widgets/banner_ad_widget.dart';
import '../config/units_config.dart';
import 'maps_screen.dart';
import 'debug_screen.dart';
import 'map_settings_screen.dart';
import 'api_key_settings_screen.dart';
import 'login_screen.dart';

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
  bool _hasSearchedOnce = false;
  DistanceUnit _currentUnit = DistanceUnit.kilometers;
  late bool _backendConnected;
  bool _recheckingConnection = false;
  static const int _pageSize = 20;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  String? _sortBy;
  String _sortOrder = 'asc';

  @override
  void initState() {
    super.initState();
    _backendConnected = widget.backendConnected;
    _loadUnitPreference();
    _getCurrentLocation();
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backendConnected != widget.backendConnected) {
      _backendConnected = widget.backendConnected;
    }
  }

  Future<void> _recheckBackendConnection() async {
    if (_recheckingConnection) return;
    setState(() => _recheckingConnection = true);
    final ok = await _apiService.testConnection();
    if (mounted) setState(() {
      _backendConnected = ok;
      _recheckingConnection = false;
    });
  }

  /// Fetches wait times from backend (AI-enhanced) and updates provider so cards show real estimates.
  void _loadWaitTimesInBackground(List<Hospital> hospitals, HospitalProvider hospitalProvider) {
    final toLoad = hospitals.take(15).toList();
    for (final h in toLoad) {
      _apiService.getWaitTimes(h.id).then((wt) {
        if (wt != null && mounted) hospitalProvider.setWaitTime(h.id, wt);
      });
    }
  }

  Future<void> _loadMoreHospitals() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
    if (locationProvider.currentPosition == null || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final searchRadiusKm = UnitsConfig.convertFromDisplayUnit(_radiusValue);
      final more = await _apiService.searchHospitals(
        latitude: locationProvider.currentPosition!.latitude,
        longitude: locationProvider.currentPosition!.longitude,
        radius: searchRadiusKm,
        page: _currentPage + 1,
        pageSize: _pageSize,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (!mounted) return;
      hospitalProvider.appendHospitals(more);
      _currentPage++;
      _hasMore = more.length >= _pageSize;
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _applySort(String? sortBy, String order) {
    setState(() {
      _sortBy = sortBy;
      _sortOrder = order;
    });
    _searchHospitals();
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
      
      try {
        double searchRadiusKm = UnitsConfig.convertFromDisplayUnit(_radiusValue);
        hospitals = await _apiService.searchHospitals(
          latitude: locationProvider.currentPosition!.latitude,
          longitude: locationProvider.currentPosition!.longitude,
          radius: searchRadiusKm,
          page: 1,
          pageSize: _pageSize,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
        if (!mounted) return;
        _currentPage = 1;
        _hasMore = hospitals.length >= _pageSize;
        
        // Track search action for ad display (Android only)
        AdManager().incrementAction(actionName: 'searched_hospitals');
      } catch (e) {
        if (!mounted) return;
        hospitals = [];
        _hasMore = false;
      }

      if (hospitals.isEmpty) {
        double searchRadiusKm = UnitsConfig.convertFromDisplayUnit(_radiusValue);
        hospitals = MockDataService.generateMockHospitals(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
          searchRadiusKm,
        );
        if (!mounted) return;
        _hasMore = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using demo data - Django backend offline'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (!mounted) return;
        String backendStatus = _backendConnected ? 'Django Backend Connected' : 'Using Demo Data';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$backendStatus: ${hospitals.length} hospitals found'),
            backgroundColor: _backendConnected ? Colors.green : Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      hospitalProvider.setHospitals(hospitals);
      if (hospitals.isNotEmpty) _loadWaitTimesInBackground(hospitals, hospitalProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load hospitals. Check connection and try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _searchHospitals(),
          ),
        ),
      );
      hospitalProvider.setHospitals([]);
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearchedOnce = true;
        });
      }
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
            onSelected: (value) async {
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
                case 'logout':
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(
                        onLoggedIn: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MainScreen(backendConnected: widget.backendConnected),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                  break;
                case 'delete_account':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete account'),
                      content: const Text(
                        'This will permanently delete your account and associated data. You will need to sign up again to use the app. This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete account'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await context.read<AuthProvider>().deleteAccount();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(
                          onLoggedIn: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MainScreen(backendConnected: widget.backendConnected),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
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
              PopupMenuItem(
                value: 'delete_account',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete account', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFF5DADE2)),
                    SizedBox(width: 8),
                    Text('Log out'),
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
                        
                        // Backend Connection Status (tap to recheck)
                        Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: GestureDetector(
                            onTap: _recheckBackendConnection,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_recheckingConnection)
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _backendConnected ? Colors.green : Colors.red,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _backendConnected
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
                                  _recheckingConnection
                                      ? 'Checking...'
                                      : (_backendConnected
                                          ? 'Django Backend: Connected'
                                          : 'Django Backend: Offline (tap to recheck)'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _recheckingConnection
                                        ? Colors.grey
                                        : (_backendConnected ? Colors.green : Colors.red),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!_recheckingConnection) ...[
                                  SizedBox(width: 4),
                                  Icon(
                                    _backendConnected ? Icons.cloud_done : Icons.cloud_off,
                                    size: 16,
                                    color: _backendConnected ? Colors.green : Colors.red,
                                  ),
                                ],
                              ],
                            ),
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
                    final isAfterSearch = _hasSearchedOnce && !_isSearching;
                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                isAfterSearch ? Icons.search_off : Icons.local_hospital,
                                size: 80,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              isAfterSearch ? 'No hospitals found' : 'Find Nearby Hospitals',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              isAfterSearch
                                  ? 'Try increasing the radius or moving to another location, then search again.'
                                  : 'Tap the search button to find emergency rooms and hospitals in your area.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            if (isAfterSearch) ...[
                              SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _isSearching ? null : _searchHospitals,
                                icon: Icon(Icons.refresh, size: 20),
                                label: Text('Search again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFF5DADE2),
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: [
                      // Results header + sort
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
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _sortBy ?? DjangoApiService.sortByDistance,
                                      isDense: true,
                                      dropdownColor: Color(0xFF5DADE2),
                                      style: TextStyle(color: Colors.white, fontSize: 13),
                                      items: [
                                        DropdownMenuItem(value: DjangoApiService.sortByDistance, child: Text('Distance')),
                                        DropdownMenuItem(value: DjangoApiService.sortByRating, child: Text('Rating')),
                                        DropdownMenuItem(value: DjangoApiService.sortByWaitTime, child: Text('Wait time')),
                                        DropdownMenuItem(value: DjangoApiService.sortByName, child: Text('Name')),
                                      ],
                                      onChanged: (v) {
                                        if (v == null) return;
                                        _applySort(v, v == DjangoApiService.sortByRating ? 'desc' : 'asc');
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => hospitalProvider.clearHospitals(),
                                  icon: Icon(Icons.clear, color: Colors.white70, size: 16),
                                  label: Text('Clear', style: TextStyle(color: Colors.white70)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async => await _searchHospitals(),
                          color: Color(0xFF5DADE2),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            itemCount: hospitalProvider.hospitals.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == hospitalProvider.hospitals.length) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: _isLoadingMore
                                        ? CircularProgressIndicator(color: Colors.white)
                                        : TextButton.icon(
                                            onPressed: _loadMoreHospitals,
                                            icon: Icon(Icons.add_circle_outline, color: Colors.white),
                                            label: Text('Load more', style: TextStyle(color: Colors.white)),
                                          ),
                                  ),
                                );
                              }
                              return HospitalCard(hospital: hospitalProvider.hospitals[index]);
                            },
                          ),
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
