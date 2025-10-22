import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/location_provider.dart';
import '../providers/hospital_provider.dart';
import '../services/django_api_service.dart';
import '../config/app_config.dart';
import 'api_key_settings_screen.dart';

class MapsScreen extends StatefulWidget {
  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _loadHospitalMarkers();
  }
  
  void _loadHospitalMarkers() {
    final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
    
    setState(() {
      _markers = hospitalProvider.hospitals.map((hospital) {
        return Marker(
          markerId: MarkerId(hospital.id),
          position: LatLng(hospital.latitude, hospital.longitude),
          infoWindow: InfoWindow(
            title: hospital.name,
            snippet: '${hospital.distance.toStringAsFixed(1)} km away',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _showHospitalInfo(hospital),
        );
      }).toSet();
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
                Text('Rating: ${hospital.rating.toStringAsFixed(1)}'),
                Spacer(),
                Text('${hospital.distance.toStringAsFixed(1)} km away'),
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
    
    // Check if we have a working Google Maps API key
    if (AppConfig.googleMapsApiKey == null || AppConfig.googleMapsApiKey!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Hospital Map'),
          backgroundColor: Color(0xFF5DADE2),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.key_off,
                size: 80,
                color: Colors.grey[400],
              ),
              SizedBox(height: 20),
              Text(
                'Google Maps API Key Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'To view the map, please:\n\n1. Add your Google Maps API key in Settings\n2. OR ensure Django backend is configured with API keys',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to API key settings using MaterialPageRoute
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApiKeySettingsScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.settings),
                label: Text('API Key Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5DADE2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Hospital Map'),
        backgroundColor: Color(0xFF5DADE2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              if (locationProvider.currentPosition != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      locationProvider.currentPosition!.latitude,
                      locationProvider.currentPosition!.longitude,
                    ),
                  ),
                );
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
          
          return GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                locationProvider.currentPosition!.latitude,
                locationProvider.currentPosition!.longitude,
              ),
              zoom: 12.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We have our own button
            zoomControlsEnabled: true,
            mapType: MapType.normal,
          );
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
}
