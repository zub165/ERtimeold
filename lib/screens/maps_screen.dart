import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/location_provider.dart';
import '../providers/hospital_provider.dart';
import '../services/django_api_service.dart';
import '../config/app_config.dart';
import '../config/units_config.dart';

enum MapProvider { openStreetMap, googleMaps, tomTomMaps }

class MapsScreen extends StatefulWidget {
  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  google_maps.GoogleMapController? _googleMapController;
  MapController _openStreetMapController = MapController();
  MapController _tomTomMapController = MapController();
  Set<google_maps.Marker> _googleMarkers = {};
  List<Marker> _openStreetMarkers = [];
  List<Marker> _tomTomMarkers = [];
  MapProvider _currentProvider = MapProvider.openStreetMap;
  
  @override
  void initState() {
    super.initState();
    _selectMapProvider();
    _loadHospitalMarkers();
  }
  
  void _selectMapProvider() {
    // Priority: TomTom > Google > OpenStreetMap (default)
    if (AppConfig.tomtomApiKey != null && AppConfig.tomtomApiKey!.isNotEmpty) {
      _currentProvider = MapProvider.tomTomMaps;
    } else if (AppConfig.googleMapsApiKey != null && AppConfig.googleMapsApiKey!.isNotEmpty) {
      _currentProvider = MapProvider.googleMaps;
    } else {
      _currentProvider = MapProvider.openStreetMap;
    }
  }
  
  String get _mapTitle {
    switch (_currentProvider) {
      case MapProvider.googleMaps:
        return 'Hospital Map (Google Maps)';
      case MapProvider.tomTomMaps:
        return 'Hospital Map (TomTom)';
      case MapProvider.openStreetMap:
      default:
        return 'Hospital Map (OpenStreetMap)';
    }
  }
  
  void _loadHospitalMarkers() {
    final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
    
    switch (_currentProvider) {
      case MapProvider.googleMaps:
        _loadGoogleMarkers(hospitalProvider);
        break;
      case MapProvider.tomTomMaps:
        _loadTomTomMarkers(hospitalProvider);
        break;
      case MapProvider.openStreetMap:
      default:
        _loadOpenStreetMarkers(hospitalProvider);
    }
  }
  
  void _loadGoogleMarkers(HospitalProvider hospitalProvider) {
    setState(() {
      _googleMarkers = hospitalProvider.hospitals.map((hospital) {
        return google_maps.Marker(
          markerId: google_maps.MarkerId(hospital.id),
          position: google_maps.LatLng(hospital.latitude, hospital.longitude),
          infoWindow: google_maps.InfoWindow(
            title: hospital.name,
            snippet: '${UnitsConfig.formatDistanceOrNull(hospital.distance)} away • ${hospital.rating != null ? hospital.rating!.toStringAsFixed(1) : "—"}⭐',
          ),
          icon: google_maps.BitmapDescriptor.defaultMarkerWithHue(
              google_maps.BitmapDescriptor.hueRed),
          onTap: () => _showHospitalInfo(hospital),
        );
      }).toSet();
    });
  }
  
  void _loadTomTomMarkers(HospitalProvider hospitalProvider) {
    setState(() {
      _tomTomMarkers = hospitalProvider.hospitals.map((hospital) {
        return Marker(
          point: LatLng(hospital.latitude, hospital.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showHospitalInfo(hospital),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: Color(0xFFD7282C), // TomTom red
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList();
    });
  }
  
  void _loadOpenStreetMarkers(HospitalProvider hospitalProvider) {
    setState(() {
      _openStreetMarkers = hospitalProvider.hospitals.map((hospital) {
        return Marker(
          point: LatLng(hospital.latitude, hospital.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showHospitalInfo(hospital),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList();
    });
  }
  
  void _openDirections(Hospital hospital) async {
    try {
      // Try Google Maps app first
      final String googleMapsAppUrl = 
          'comgooglemaps://?daddr=${hospital.latitude},${hospital.longitude}&directionsmode=driving';
      
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        await launchUrl(
          Uri.parse(googleMapsAppUrl), 
          mode: LaunchMode.externalApplication
        );
        Navigator.pop(context); // Close the bottom sheet
        return;
      }
      
      // Fallback to web Google Maps
      final String webMapsUrl = 
          'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}';
      
      if (await canLaunchUrl(Uri.parse(webMapsUrl))) {
        await launchUrl(
          Uri.parse(webMapsUrl), 
          mode: LaunchMode.externalApplication
        );
        Navigator.pop(context); // Close the bottom sheet
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening directions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHospitalInfo(Hospital hospital) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hospital.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              hospital.address,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 5),
                Text('Rating: ${hospital.rating != null ? hospital.rating!.toStringAsFixed(1) : "—"}'),
                Spacer(),
                Text('${UnitsConfig.formatDistanceOrNull(hospital.distance)} away'),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openDirections(hospital),
                    icon: Icon(Icons.directions),
                    label: Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5DADE2),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                    label: Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_mapTitle),
        backgroundColor: Color(0xFF5DADE2),
        foregroundColor: Colors.white,
        actions: [
          // Map provider selector
          PopupMenuButton<MapProvider>(
            icon: Icon(Icons.map),
            onSelected: (MapProvider provider) {
              setState(() {
                _currentProvider = provider;
                _loadHospitalMarkers();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: MapProvider.openStreetMap,
                child: Row(
                  children: [
                    Icon(Icons.public, color: Colors.green),
                    SizedBox(width: 8),
                    Text('OpenStreetMap (Free)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: MapProvider.googleMaps,
                enabled: AppConfig.googleMapsApiKey != null && 
                        AppConfig.googleMapsApiKey!.isNotEmpty,
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Google Maps'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: MapProvider.tomTomMaps,
                enabled: AppConfig.tomtomApiKey != null && 
                        AppConfig.tomtomApiKey!.isNotEmpty,
                child: Row(
                  children: [
                    Icon(Icons.navigation, color: Color(0xFFD7282C)),
                    SizedBox(width: 8),
                    Text('TomTom Maps'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              if (locationProvider.currentPosition != null) {
                final userLat = locationProvider.currentPosition!.latitude;
                final userLng = locationProvider.currentPosition!.longitude;
                
                switch (_currentProvider) {
                  case MapProvider.googleMaps:
                    if (_googleMapController != null) {
                      _googleMapController!.animateCamera(
                        google_maps.CameraUpdate.newLatLng(
                          google_maps.LatLng(userLat, userLng),
                        ),
                      );
                    }
                    break;
                  case MapProvider.tomTomMaps:
                    _tomTomMapController.move(LatLng(userLat, userLng), 14.0);
                    break;
                  case MapProvider.openStreetMap:
                    _openStreetMapController.move(LatLng(userLat, userLng), 14.0);
                    break;
                }
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHospitalMarkers,
          ),
        ],
      ),
      body: Consumer<HospitalProvider>(
        builder: (context, hospitalProvider, child) {
          if (locationProvider.currentPosition == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Getting your location...'),
                ],
              ),
            );
          }
          
          if (hospitalProvider.hospitals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital, size: 64, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No hospitals found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Search for hospitals first',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          
          switch (_currentProvider) {
            case MapProvider.googleMaps:
              return _buildGoogleMap(locationProvider);
            case MapProvider.tomTomMaps:
              return _buildTomTomMap(locationProvider);
            case MapProvider.openStreetMap:
            default:
              return _buildOpenStreetMap(locationProvider);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: Color(0xFF5DADE2),
        child: Icon(Icons.list, color: Colors.white),
        tooltip: 'Back to List',
      ),
    );
  }
  
  Widget _buildGoogleMap(LocationProvider locationProvider) {
    return google_maps.GoogleMap(
      onMapCreated: (google_maps.GoogleMapController controller) {
        _googleMapController = controller;
      },
      initialCameraPosition: google_maps.CameraPosition(
        target: google_maps.LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        ),
        zoom: 12.0,
      ),
      markers: _googleMarkers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapType: google_maps.MapType.normal,
    );
  }
  
  Widget _buildTomTomMap(LocationProvider locationProvider) {
    final tomTomApiKey = AppConfig.tomtomApiKey ?? '';
    
    return FlutterMap(
      mapController: _tomTomMapController,
      options: MapOptions(
        initialCenter: LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        ),
        initialZoom: 12.0,
        minZoom: 3.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$tomTomApiKey',
          userAgentPackageName: 'com.mywaitime.app',
          tileDisplay: const TileDisplay.fadeIn(),
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers: [
            // User location marker
            Marker(
              point: LatLng(
                locationProvider.currentPosition!.latitude,
                locationProvider.currentPosition!.longitude,
              ),
              width: 40,
              height: 40,
              child: Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 32,
              ),
            ),
            // Hospital markers
            ..._tomTomMarkers,
          ],
        ),
      ],
    );
  }
  
  Widget _buildOpenStreetMap(LocationProvider locationProvider) {
    return FlutterMap(
      mapController: _openStreetMapController,
      options: MapOptions(
        initialCenter: LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        ),
        initialZoom: 12.0,
        minZoom: 3.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.mywaitime.app',
          tileDisplay: const TileDisplay.fadeIn(),
        ),
        MarkerLayer(
          markers: [
            // User location marker
            Marker(
              point: LatLng(
                locationProvider.currentPosition!.latitude,
                locationProvider.currentPosition!.longitude,
              ),
              width: 40,
              height: 40,
              child: Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 32,
              ),
            ),
            // Hospital markers
            ..._openStreetMarkers,
          ],
        ),
      ],
    );
  }
}
