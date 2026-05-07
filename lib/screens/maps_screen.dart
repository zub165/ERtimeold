import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';
import '../services/api_key_manager.dart';
import '../models/hospital.dart';
import '../providers/hospital_provider.dart';
import '../providers/location_provider.dart';

class MapsScreen extends StatefulWidget {
  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  gmap.GoogleMapController? _googleMapController;
  final fmap.MapController _osmMapController = fmap.MapController();
  bool _googleMapsError = false;

  void _refreshMarkers() {
    setState(() {});
  }

  void _openDirections(Hospital hospital) async {
    try {
      final ok = await openHospitalDirections(hospital);
      if (ok) {
        if (mounted) Navigator.pop(context);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open maps. Try installing Google Maps, or allow your browser to use cellular data.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
                Text(
                  'Rating: ${hospital.rating != null ? hospital.rating!.toStringAsFixed(1) : "No rating"}',
                ),
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
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

  Set<gmap.Marker> _buildGoogleMarkers(List<Hospital> hospitals) {
    return hospitals.map((hospital) {
      return gmap.Marker(
        markerId: gmap.MarkerId(hospital.id),
        position: gmap.LatLng(hospital.latitude, hospital.longitude),
        infoWindow: gmap.InfoWindow(
          title: hospital.name,
          snippet: '${hospital.distance.toStringAsFixed(1)} km away',
        ),
        icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueRed),
        onTap: () => _showHospitalInfo(hospital),
      );
    }).toSet();
  }

  List<fmap.Marker> _buildOsmMarkers(List<Hospital> hospitals) {
    return hospitals.map((hospital) {
      return fmap.Marker(
        point: ll.LatLng(hospital.latitude, hospital.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showHospitalInfo(hospital),
          child: Icon(
            Icons.location_on,
            color: Colors.redAccent,
            size: 36,
          ),
        ),
      );
    }).toList();
  }

  Future<void> _confirmAndCall911() async {
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call 911?'),
        content: const Text('Only call 911 for emergencies. Do you want to place a call now?'),
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
    await launchUrl(Uri.parse('tel:911'), mode: LaunchMode.externalApplication);
  }

  Widget _buildClosestBanner(List<Hospital> hospitals) {
    if (hospitals.isEmpty) return const SizedBox.shrink();
    final sorted = [...hospitals]..sort((a, b) => a.distance.compareTo(b.distance));
    final closest = sorted.first;
    final mins = (closest.distance * 2.2).round().clamp(1, 120); // simple estimate
    return GestureDetector(
      onTap: () => _openDirections(closest),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Closest ER is about $mins mins away. Tap for directions.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String message, {Color color = Colors.blueGrey}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: color),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// Build fallback map (TomTom or OSM) when Google Maps is unavailable
  Widget _buildFallbackMap(
    Position location,
    List<Hospital> hospitals,
    bool useTomTom,
    String? tomtomApiKey,
  ) {
    final useTomTomTiles = useTomTom && tomtomApiKey != null && tomtomApiKey.isNotEmpty;
    // Safe to use tomtomApiKey here because useTomTomTiles guarantees it's not null
    final String safeTomTomKey = tomtomApiKey ?? '';
    
    return fmap.FlutterMap(
      mapController: _osmMapController,
      options: fmap.MapOptions(
        initialCenter: ll.LatLng(location.latitude, location.longitude),
        initialZoom: 13,
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: useTomTomTiles
              ? 'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$safeTomTomKey'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: useTomTomTiles ? const [] : const ['a', 'b', 'c'],
          userAgentPackageName: AppConfig.packageName,
          additionalOptions: useTomTomTiles
              ? {
                  'key': safeTomTomKey,
                }
              : {},
        ),
        fmap.MarkerLayer(markers: _buildOsmMarkers(hospitals)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final locationProvider = Provider.of<LocationProvider>(context);
    final String googleKeyTrimmed =
        (AppConfig.googleMapsApiKey ?? '').trim();
    final bool hasGoogleKey =
        ApiKeyManager.isValidGoogleMapsApiKey(googleKeyTrimmed);
    
    // CRITICAL: Never use Google Maps if key is missing, invalid, or if there was a previous error
    // This prevents GMSServices initialization crash
    final bool useGoogle = !_googleMapsError && 
                          AppConfig.useGoogleMaps && 
                          hasGoogleKey;
    
    final bool useTomTom = AppConfig.useTomTomMaps;
    // Always use OSM as fallback if Google Maps can't be used
    final bool useOsm = AppConfig.useOpenStreetMap || !useGoogle || _googleMapsError || !hasGoogleKey;

    String? fallbackBanner;
    final tomtomApiKey = AppConfig.tomtomApiKey;
    final hasTomTomKey = tomtomApiKey != null && tomtomApiKey.isNotEmpty;
    
    if (_googleMapsError) {
      fallbackBanner = 'Google Maps unavailable. Using ${useTomTom && hasTomTomKey ? "TomTom" : "OpenStreetMap"} instead.';
    } else if (!useGoogle && useTomTom && !hasTomTomKey) {
      fallbackBanner = 'TomTom API key missing. Showing OpenStreetMap instead.';
    } else if (!useGoogle && !hasGoogleKey && AppConfig.useGoogleMaps) {
      fallbackBanner = 'Google Maps API key missing. Falling back to ${useTomTom && hasTomTomKey ? "TomTom" : "OpenStreetMap"}.';
    } else if (!useGoogle && useTomTom && hasTomTomKey) {
      // TomTom is enabled and key is available - no banner needed
      fallbackBanner = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hospital Map'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Call 911',
            onPressed: _confirmAndCall911,
          ),
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              final position = locationProvider.currentPosition;
              if (position == null) return;
              if (useGoogle && _googleMapController != null) {
                _googleMapController!.animateCamera(
                  gmap.CameraUpdate.newLatLng(
                    gmap.LatLng(position.latitude, position.longitude),
                  ),
                );
              } else if (useOsm) {
                _osmMapController.move(
                  ll.LatLng(position.latitude, position.longitude),
                  13,
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshMarkers,
          ),
        ],
      ),
      body: Consumer<HospitalProvider>(
        builder: (context, hospitalProvider, child) {
          final location = locationProvider.currentPosition;
          if (location == null) {
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

          final hospitals = hospitalProvider.hospitals;
          final mapWidgets = <Widget>[];

          if (fallbackBanner != null) {
            mapWidgets.add(_buildInfoBanner(fallbackBanner));
          }
          if (hospitals.isEmpty) {
            mapWidgets.add(_buildInfoBanner(
              'No hospitals loaded yet. Run a search to populate the map.',
              color: Colors.orange,
            ));
          }

          Widget mapContent;
          // CRITICAL SAFETY CHECK: Never create GoogleMap widget if:
          // 1. useGoogle is false (disabled or key missing)
          // 2. There was a previous error
          // 3. Key is null, empty, or too short
          // This prevents GMSServices.checkServicePreconditions crash
          final bool canUseGoogle = useGoogle && 
                                   !_googleMapsError && 
                                   hasGoogleKey &&
                                   AppConfig.useGoogleMaps; // Double-check config
          
          // ABSOLUTE SAFETY: If any condition fails, use fallback
          if (!canUseGoogle) {
            // Use fallback map (TomTom or OSM) - SAFE option
            mapContent = _buildFallbackMap(location, hospitals, useTomTom, tomtomApiKey);
          } else {
            // Only create GoogleMap if ALL safety checks pass
            mapContent = gmap.GoogleMap(
              key: ValueKey(
                'google_map_${googleKeyTrimmed.substring(0, googleKeyTrimmed.length > 10 ? 10 : googleKeyTrimmed.length)}',
              ),
              onMapCreated: (controller) {
                _googleMapController = controller;
                // Reset error flag on successful creation
                if (_googleMapsError) {
                  setState(() {
                    _googleMapsError = false;
                  });
                }
              },
              initialCameraPosition: gmap.CameraPosition(
                target: gmap.LatLng(location.latitude, location.longitude),
                zoom: 12,
              ),
              markers: _buildGoogleMarkers(hospitals),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapType: gmap.MapType.normal,
            );
          }

          // Stack map + closest banner overlay
          return Column(
            children: [
              ...mapWidgets,
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: mapContent),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildClosestBanner(hospitals),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: primary,
        child: Icon(Icons.list, color: Colors.white),
        tooltip: 'Back to List',
      ),
    );
  }
}
