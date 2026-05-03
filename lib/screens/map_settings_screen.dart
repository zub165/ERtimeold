import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_key_manager.dart';
import '../services/django_api_service.dart';

class MapSettingsScreen extends StatefulWidget {
  @override
  _MapSettingsScreenState createState() => _MapSettingsScreenState();
}

class _MapSettingsScreenState extends State<MapSettingsScreen> {
  final DjangoApiService _apiService = DjangoApiService();
  bool _loading = false;
  
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Settings'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Map Provider Configuration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Choose your preferred map provider. Configuration is managed by Django backend.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 30),

            // TomTom first (default path — avoids Google native SDK crashes when misconfigured)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConfig.useTomTomMaps ? primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: AppConfig.useTomTomMaps ? Colors.white : Colors.grey[600],
                  ),
                ),
                title: Text(
                  'TomTom Maps',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  AppConfig.tomtomApiKey != null
                    ? 'API key managed securely by Django backend'
                    : 'Awaiting key from Django backend',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Switch(
                  value: AppConfig.useTomTomMaps,
                  onChanged: (value) async {
                    final tomtomKey = (AppConfig.tomtomApiKey ?? '').trim();
                    final tomtomKeyValid = tomtomKey.isNotEmpty;
                    if (value && !tomtomKeyValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('TomTom requires an API key. Using OpenStreetMap instead.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      setState(() {
                        AppConfig.useTomTomMaps = false;
                        AppConfig.useGoogleMaps = false;
                        AppConfig.useOpenStreetMap = true;
                      });
                      await ApiKeyManager.savePreferredMapProvider('osm');
                      return;
                    }
                    setState(() {
                      AppConfig.useTomTomMaps = value;
                      if (value) {
                        AppConfig.useGoogleMaps = false;
                        AppConfig.useOpenStreetMap = false;
                      } else {
                        AppConfig.useOpenStreetMap = true;
                      }
                    });
                    if (value) {
                      await ApiKeyManager.savePreferredMapProvider('tomtom');
                    } else {
                      await ApiKeyManager.savePreferredMapProvider('osm');
                    }
                  },
                  activeColor: primary,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Google Maps (strict key format — prevents selecting Google with a bad key)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConfig.useGoogleMaps ? primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.map,
                    color: AppConfig.useGoogleMaps ? Colors.white : Colors.grey[600],
                  ),
                ),
                title: Text(
                  'Google Maps',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  AppConfig.googleMapsApiKey != null
                    ? 'Requires a Maps API key starting with AIza…'
                    : 'Awaiting key from Django backend',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Switch(
                  value: AppConfig.useGoogleMaps,
                  onChanged: (value) async {
                    final googleKey = (AppConfig.googleMapsApiKey ?? '').trim();
                    final googleKeyValid =
                        ApiKeyManager.isValidGoogleMapsApiKey(googleKey);
                    if (value && !googleKeyValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Google Maps needs a valid key (AIza…, 35+ chars). Using TomTom or OpenStreetMap instead.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      setState(() {
                        AppConfig.useGoogleMaps = false;
                        AppConfig.useTomTomMaps =
                            (AppConfig.tomtomApiKey ?? '').trim().isNotEmpty;
                        AppConfig.useOpenStreetMap = !AppConfig.useTomTomMaps;
                      });
                      await ApiKeyManager.savePreferredMapProvider(
                        AppConfig.useTomTomMaps ? 'tomtom' : 'osm',
                      );
                      return;
                    }
                    setState(() {
                      AppConfig.useGoogleMaps = value;
                      if (value) {
                        AppConfig.useTomTomMaps = false;
                        AppConfig.useOpenStreetMap = false;
                      } else {
                        if (!AppConfig.useTomTomMaps) {
                          AppConfig.useOpenStreetMap = true;
                        }
                      }
                    });
                    if (value) {
                      await ApiKeyManager.savePreferredMapProvider('google');
                    } else {
                      await ApiKeyManager.savePreferredMapProvider(
                        AppConfig.useTomTomMaps ? 'tomtom' : 'osm',
                      );
                    }
                  },
                  activeColor: primary,
                ),
              ),
            ),
            SizedBox(height: 16),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConfig.useOpenStreetMap ? primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.public,
                    color: AppConfig.useOpenStreetMap ? Colors.white : Colors.grey[600],
                  ),
                ),
                title: Text(
                  'OpenStreetMap (Free)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Open-source map tiles (no API key required)',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Switch(
                  value: AppConfig.useOpenStreetMap,
                  onChanged: (value) async {
                    setState(() {
                      AppConfig.useOpenStreetMap = value;
                      if (value) {
                        AppConfig.useGoogleMaps = false;
                        AppConfig.useTomTomMaps = false;
                      } else if (!AppConfig.useGoogleMaps &&
                          !AppConfig.useTomTomMaps) {
                        AppConfig.useOpenStreetMap = true;
                      }
                    });
                    if (AppConfig.useOpenStreetMap) {
                      await ApiKeyManager.savePreferredMapProvider('osm');
                    } else if (AppConfig.useTomTomMaps) {
                      await ApiKeyManager.savePreferredMapProvider('tomtom');
                    } else if (AppConfig.useGoogleMaps) {
                      await ApiKeyManager.savePreferredMapProvider('google');
                    }
                  },
                  activeColor: primary,
                ),
              ),
            ),
            SizedBox(height: 30),
            
            // Refresh Configuration Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _refreshMapConfigs,
                icon: _loading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.refresh),
                label: Text(
                  _loading ? 'Refreshing...' : 'Refresh from Django Backend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Current Configuration Info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Configuration:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Active Provider: ${AppConfig.useGoogleMaps ? "Google Maps" : AppConfig.useTomTomMaps ? "TomTom Maps" : AppConfig.useOpenStreetMap ? "OpenStreetMap" : "None"}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• Django Backend: ${AppConfig.djangoBaseUrl}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• Google Maps Enabled: ${AppConfig.useGoogleMaps ? "Yes" : "No"}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• TomTom Maps Enabled: ${AppConfig.useTomTomMaps ? "Yes" : "No"}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• OpenStreetMap Enabled: ${AppConfig.useOpenStreetMap ? "Yes" : "No"}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _refreshMapConfigs() async {
    setState(() {
      _loading = true;
    });
    
    try {
      Map<String, dynamic>? mapConfigs = await _apiService.getAllMapConfigs();
      if (!mounted) return;
      if (mapConfigs != null) {
        setState(() {
          AppConfig.googleMapsApiKey = mapConfigs['google_maps_api_key'];
          AppConfig.tomtomApiKey = mapConfigs['tomtom_api_key'];

          final preferred = (mapConfigs['preferred_map_provider'] ?? '').toString().toLowerCase();
          final enableGoogle = mapConfigs['enable_google_maps'] ?? true;
          final enableTomTom = mapConfigs['enable_tomtom_maps'] ?? true;
          final enableOsmFlag = mapConfigs['enable_openstreet_map'] ?? false;

          final gKey = (AppConfig.googleMapsApiKey ?? '').trim();
          final gOk = ApiKeyManager.isValidGoogleMapsApiKey(gKey);
          final tKey = (AppConfig.tomtomApiKey ?? '').trim();
          final tOk = tKey.isNotEmpty;

          if (preferred == 'openstreetmap' || preferred == 'osm') {
            AppConfig.useOpenStreetMap = true;
            AppConfig.useGoogleMaps = false;
            AppConfig.useTomTomMaps = false;
          } else if (preferred == 'tomtom') {
            AppConfig.useTomTomMaps = enableTomTom && tOk;
            AppConfig.useGoogleMaps = false;
            AppConfig.useOpenStreetMap = !AppConfig.useTomTomMaps;
          } else if (preferred == 'google') {
            AppConfig.useGoogleMaps = enableGoogle && gOk;
            AppConfig.useTomTomMaps = false;
            AppConfig.useOpenStreetMap =
                enableOsmFlag && !AppConfig.useGoogleMaps;
            if (!AppConfig.useGoogleMaps && !AppConfig.useOpenStreetMap && tOk) {
              AppConfig.useTomTomMaps = true;
              AppConfig.useOpenStreetMap = false;
            }
            if (!AppConfig.useGoogleMaps && !AppConfig.useTomTomMaps) {
              AppConfig.useOpenStreetMap = true;
            }
          } else {
            if (enableGoogle && gOk) {
              AppConfig.useGoogleMaps = true;
              AppConfig.useTomTomMaps = false;
              AppConfig.useOpenStreetMap = enableOsmFlag;
            } else if (enableTomTom && tOk) {
              AppConfig.useGoogleMaps = false;
              AppConfig.useTomTomMaps = true;
              AppConfig.useOpenStreetMap = false;
            } else {
              AppConfig.useGoogleMaps = false;
              AppConfig.useTomTomMaps = false;
              AppConfig.useOpenStreetMap = true;
            }
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Map configurations updated from Django backend'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update map configurations'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
