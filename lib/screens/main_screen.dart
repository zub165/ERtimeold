import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/location_provider.dart';
import '../providers/hospital_provider.dart';
import '../providers/auth_provider.dart';
import '../services/django_api_service.dart';
import '../services/enhanced_hospital_search_service.dart';
import '../services/mock_data_service.dart';
import '../widgets/hospital_card.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/sync_status_widget.dart';
import '../config/units_config.dart';
import '../models/hospital.dart';
import '../config/production_config.dart';
import '../app_settings.dart';
import 'maps_screen.dart';
import 'debug_screen.dart';
import 'map_settings_screen.dart';
import 'api_key_settings_screen.dart';
import 'profile_screen.dart';
import 'app_settings_screen.dart';
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
  final EnhancedHospitalSearchService _enhancedSearchService = EnhancedHospitalSearchService();
  bool _isSearching = false;
  DistanceUnit _currentUnit = DistanceUnit.kilometers;
  bool _controlsExpanded = false;
  _SortOption _sortOption = _SortOption.priorityDistance;
  _FilterOption _filterOption = _FilterOption.all;
  List<Hospital> _lastResults = const [];
  
  @override
  void initState() {
    super.initState();
    _loadUnitPreference();
    _loadApiKeysAndLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalProvider>().loadFavorites();
    });
  }
  
  Future<void> _loadApiKeysAndLocation() async {
    // Load API keys from backend environment first
    await ProductionConfig.loadApiKeysFromBackend();
    // Then get current location
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

  /// Store search analytics to Django backend
  Future<void> _storeSearchAnalytics(double latitude, double longitude, double radius, int hospitalCount) async {
    if (!mounted) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && !authProvider.isOfflineMode) {
        await _apiService.submitSearchAnalytics(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          hospitalCount: hospitalCount,
          userId: authProvider.userId,
        );
        print('✅ Search analytics stored to backend');
      }
    } catch (e) {
      print('⚠️ Failed to store search analytics: $e');
    }
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
      
              // Use enhanced search service with GPS coordinate enforcement
              try {
                double searchRadiusKm = UnitsConfig.convertFromDisplayUnit(_radiusValue);
                // Ensure radius is an integer to avoid backend float errors
                searchRadiusKm = searchRadiusKm.round().toDouble();
                print('🔗 Starting enhanced hospital search with GPS enforcement...');
                
                // Validate GPS coordinates
                if (locationProvider.currentPosition == null) {
                  throw Exception('MISSING_COORDINATES: GPS location not available');
                }
                
                double lat = locationProvider.currentPosition!.latitude;
                double lon = locationProvider.currentPosition!.longitude;
                
                print('📍 Using GPS coordinates: $lat, $lon');
                
                // Use enhanced search service that enforces client coordinates
                final type = _filterOption.backendType;
                List<Hospital> enhancedHospitals = await _enhancedSearchService.searchHospitalsEnhanced(
                  latitude: lat,
                  longitude: lon,
                  radius: searchRadiusKm,
                  type: type,
                );
                
                hospitals = enhancedHospitals;
                print('✅ Enhanced search: Found ${hospitals.length} hospitals with GPS-level precision');
                
                // Store search data to backend for analytics
                if (hospitals.isNotEmpty) {
                  try {
                    await _storeSearchAnalytics(
                      lat,
                      lon,
                      searchRadiusKm,
                      hospitals.length,
                    );
                  } catch (e) {
                    print('⚠️ Could not store search analytics: $e');
                  }
                }
              } catch (e) {
                print('❌ Enhanced search error: $e');
                if (mounted && e.toString().contains('MISSING_COORDINATES')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('GPS location required. Please enable location services or enter address manually.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
                hospitals = []; // Ensure it's empty to trigger mock data
              }
      
      if (!mounted) return;

      // If no hospitals from Django or backend not connected, use mock data
      if (hospitals.isEmpty) {
        // Ensure we have a valid location before generating mock data
        if (locationProvider.currentPosition == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location not available. Please enable location services.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        double searchRadiusKm = UnitsConfig.convertFromDisplayUnit(_radiusValue);
        // Ensure radius is an integer to avoid backend float errors
        searchRadiusKm = searchRadiusKm.round().toDouble();
        hospitals = MockDataService.generateMockHospitals(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
          searchRadiusKm,
        );
        print('Using mock data: Generated ${hospitals.length} hospitals');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo Mode: Full offline functionality available for Apple review'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
              } else {
                // Show enhanced search results
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🏥 Enhanced Search: ${hospitals.length} hospitals found with GPS-level precision! Sources: Django + TomTom + Google Places'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
      
      _lastResults = hospitals;
      hospitalProvider.setHospitals(_applyFilter(_lastResults, hospitalProvider));
      // Fetch predicted wait times for the top facilities (non-blocking).
      // ignore: discarded_futures
      hospitalProvider.prefetchSmartWaitTimes();
      _applySort(hospitalProvider);
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching hospitals'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _applySort(HospitalProvider hospitalProvider) {
    switch (_sortOption) {
      case _SortOption.priorityDistance:
        hospitalProvider.sortByDistance();
        break;
      case _SortOption.rating:
        hospitalProvider.sortByRating();
        break;
      case _SortOption.waitTime:
        final sorted = [...hospitalProvider.hospitals]
          ..sort((a, b) {
            final aw = a.waitTimeMinutes ?? 1 << 30;
            final bw = b.waitTimeMinutes ?? 1 << 30;
            final c = aw.compareTo(bw);
            return c != 0 ? c : a.distance.compareTo(b.distance);
          });
        hospitalProvider.setHospitals(sorted);
        break;
      case _SortOption.name:
        final sorted = [...hospitalProvider.hospitals]
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        hospitalProvider.setHospitals(sorted);
        break;
    }
  }

  List<Hospital> _applyFilter(List<Hospital> input, HospitalProvider hospitalProvider) {
    switch (_filterOption) {
      case _FilterOption.all:
        return input;
      case _FilterOption.er:
        return input.where((h) => h.facilityPriority == 2).toList();
      case _FilterOption.urgent:
        return input.where((h) => h.facilityPriority == 1).toList();
      case _FilterOption.walkIn:
        return input.where((h) => h.facilityPriority == 3).toList();
      case _FilterOption.clinic:
        return input.where((h) => h.name.toLowerCase().contains('clinic') || h.facilityPriority == 3).toList();
      case _FilterOption.favorites:
        return input.where((h) => hospitalProvider.isFavorite(h.id)).toList();
    }
  }

  Future<void> _confirmAndCall911() async {
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call 911?'),
        content: const Text(
          'Only call 911 for emergencies. Do you want to place a call now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Call 911'),
          ),
        ],
      ),
    );

    if (shouldCall != true) return;
    try {
      // ignore: deprecated_member_use
      await launchUrl(
        Uri.parse('tel:911'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start the phone dialer.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildCollapsedControls(Color primary, Locale locale) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return Expanded(
                  child: Text(
                    locationProvider.hasPermission
                        ? AppI18n.t(locale, 'location_permission_granted')
                        : AppI18n.t(locale, 'click_for_permission'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary, width: 1),
              ),
              child: Text(
                '${_radiusValue.round()} ${UnitsConfig.getDistanceUnitAbbr()}',
                style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isSearching ? null : _searchHospitals,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSearching
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    AppI18n.t(locale, 'search'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              widget.backendConnected ? Icons.cloud_done : Icons.cloud_off,
              size: 16,
              color: widget.backendConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.backendConnected ? 'Backend connected' : 'Backend offline',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.backendConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const SyncStatusWidget(showDetails: false),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedControls(Color primary, Locale locale) {
    return Column(
      children: [
        Consumer<LocationProvider>(
          builder: (context, locationProvider, child) {
            return Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locationProvider.hasPermission
                        ? AppI18n.t(locale, 'location_permission_granted')
                        : AppI18n.t(locale, 'click_for_permission'),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
                if (!locationProvider.hasPermission)
                  IconButton(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppI18n.t(locale, 'search_radius'),
                style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w600),
              ),
            ),
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
                          _radiusValue = _radiusValue / 0.621371;
                        }
                        _currentUnit = DistanceUnit.kilometers;
                        UnitsConfig.setDistanceUnit(_currentUnit);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentUnit == DistanceUnit.kilometers ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'km',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentUnit == DistanceUnit.kilometers ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_currentUnit == DistanceUnit.kilometers) {
                          _radiusValue = _radiusValue * 0.621371;
                        }
                        _currentUnit = DistanceUnit.miles;
                        UnitsConfig.setDistanceUnit(_currentUnit);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentUnit == DistanceUnit.miles ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'mi',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentUnit == DistanceUnit.miles ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _radiusValue,
                min: _currentUnit == DistanceUnit.miles ? 0.6 : 1.0,
                max: _currentUnit == DistanceUnit.miles ? 31.0 : 50.0,
                divisions: _currentUnit == DistanceUnit.miles ? 30 : 49,
                activeColor: primary,
                label: '${_radiusValue.round()} ${UnitsConfig.getDistanceUnitAbbr()}',
                onChanged: (value) => setState(() => _radiusValue = value),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary, width: 1),
              ),
              child: Text(
                '${_radiusValue.round()} ${UnitsConfig.getDistanceUnitAbbr()}',
                style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isSearching ? null : _searchHospitals,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSearching
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    AppI18n.t(locale, 'search'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.backendConnected ? Icons.cloud_done : Icons.cloud_off,
              size: 16,
              color: widget.backendConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 6),
            Text(
              widget.backendConnected ? 'Backend connected' : 'Backend offline',
              style: TextStyle(
                fontSize: 12,
                color: widget.backendConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            const SyncStatusWidget(showDetails: false),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().locale;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        title: Text(AppI18n.t(locale, 'app_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: AppI18n.t(locale, 'call_911'),
            onPressed: _confirmAndCall911,
          ),
          // Profile Button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return IconButton(
                icon: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Text(
                    (authProvider.fullName != null && authProvider.fullName!.isNotEmpty)
                        ? authProvider.fullName![0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onPressed: () {
                  final parentContext = context;
                  if (authProvider.isAuthenticated) {
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(
                        successRouteBuilder: (_) => const ProfileScreen(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
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
                case 'app_settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppSettingsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'app_settings',
                child: Row(
                  children: [
                    Icon(Icons.palette, color: primary),
                    SizedBox(width: 8),
                    Text(AppI18n.t(locale, 'settings')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'api_keys',
                child: Row(
                  children: [
                    Icon(Icons.vpn_key, color: primary),
                    SizedBox(width: 8),
                    Text('API Key Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'map_settings',
                child: Row(
                  children: [
                    Icon(Icons.map, color: primary),
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
              padding: const EdgeInsets.all(12),
              child: Column(
              children: [
                const SizedBox(height: 6),
                  
                  // Search Card
                  Container(
                    padding: const EdgeInsets.all(12),
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
                        Row(
                          children: [
                            Icon(Icons.tune, color: primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Search Controls',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _controlsExpanded = !_controlsExpanded),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                _controlsExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey[700],
                              ),
                              tooltip: _controlsExpanded ? 'Collapse' : 'Expand',
                            ),
                          ],
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 180),
                          crossFadeState: _controlsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: _buildCollapsedControls(primary, locale),
                          secondChild: _buildExpandedControls(primary, locale),
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
                    // If we have results but the current filter produced none, show a clearer state.
                    if (_lastResults.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(26),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.filter_alt_off,
                                size: 70,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No results for this filter',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try switching filters or show all hospitals.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _filterOption = _FilterOption.all);
                                hospitalProvider.setHospitals(_applyFilter(_lastResults, hospitalProvider));
                                _applySort(hospitalProvider);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                              icon: Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                              label: Text(
                                'Show All',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${hospitalProvider.hospitals.length} hospitals found',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(38),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withAlpha(80)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sort, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    _sortOption.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                                    color: const Color(0xFF3498DB),
                                    onSelected: (value) async {
                                      if (value == 'clear') {
                                        hospitalProvider.clearHospitals();
                                        _lastResults = const [];
                                        return;
                                      }
                                      final next = _SortOptionX.fromId(value);
                                      if (next == null) return;
                                      setState(() => _sortOption = next);
                                      _applySort(hospitalProvider);
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'priorityDistance', child: Text('Priority + distance')),
                                      PopupMenuItem(value: 'rating', child: Text('Rating')),
                                      PopupMenuItem(value: 'waitTime', child: Text('Wait time')),
                                      PopupMenuItem(value: 'name', child: Text('Name')),
                                      PopupMenuDivider(),
                                      PopupMenuItem(value: 'clear', child: Text('Clear results')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hospital list
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(hospitalProvider, _FilterOption.all, AppI18n.t(locale, 'filter_all')),
                              const SizedBox(width: 8),
                              _buildFilterChip(hospitalProvider, _FilterOption.er, AppI18n.t(locale, 'filter_er')),
                              const SizedBox(width: 8),
                              _buildFilterChip(hospitalProvider, _FilterOption.urgent, AppI18n.t(locale, 'filter_urgent')),
                              const SizedBox(width: 8),
                              _buildFilterChip(hospitalProvider, _FilterOption.walkIn, AppI18n.t(locale, 'filter_walk_in')),
                              const SizedBox(width: 8),
                              _buildFilterChip(hospitalProvider, _FilterOption.clinic, AppI18n.t(locale, 'filter_clinic')),
                              const SizedBox(width: 8),
                              _buildFilterChip(hospitalProvider, _FilterOption.favorites, AppI18n.t(locale, 'filter_favorites')),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildFilterChip(HospitalProvider hospitalProvider, _FilterOption option, String label) {
    final selected = _filterOption == option;
    final primary = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: primary,
      backgroundColor: Colors.white.withAlpha(235),
      side: BorderSide(color: Colors.white.withAlpha(200)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      labelStyle: TextStyle(
        color: selected ? Colors.white : primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (v) async {
        if (!v) return;
        setState(() => _filterOption = option);
        if (option == _FilterOption.favorites) {
          hospitalProvider.setHospitals(_applyFilter(_lastResults, hospitalProvider));
          _applySort(hospitalProvider);
          return;
        }
        // Re-filter locally on the last full result set. Do **not** hit the
        // network on every chip tap — that can return a different merge set
        // (or an over-narrow backend `type` response) and look like “sometimes
        // nothing shows”.
        if (_lastResults.isEmpty) {
          await _searchHospitals();
          return;
        }
        hospitalProvider.setHospitals(_applyFilter(_lastResults, hospitalProvider));
        _applySort(hospitalProvider);
      },
    );
  }
}

enum _SortOption {
  priorityDistance,
  rating,
  waitTime,
  name,
}

extension _SortOptionLabel on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.priorityDistance:
        return 'Priority';
      case _SortOption.rating:
        return 'Rating';
      case _SortOption.waitTime:
        return 'Wait';
      case _SortOption.name:
        return 'Name';
    }
  }
}

class _SortOptionX {
  static _SortOption? fromId(String id) {
    switch (id) {
      case 'priorityDistance':
        return _SortOption.priorityDistance;
      case 'rating':
        return _SortOption.rating;
      case 'waitTime':
        return _SortOption.waitTime;
      case 'name':
        return _SortOption.name;
      default:
        return null;
    }
  }
}

enum _FilterOption {
  all,
  er,
  urgent,
  walkIn,
  clinic,
  favorites,
}

extension on _FilterOption {
  /// Always fetch the broad hospital set from the backend, then classify with
  /// [Hospital.facilityPriority] + [_applyFilter]. Passing a narrow `type`
  /// (e.g. `walk_in`) often returns **zero** rows while the same area still has
  /// walk‑in clinics that only match client-side heuristics — looks like a
  /// random “empty list” bug when switching chips.
  String? get backendType => null;
}
