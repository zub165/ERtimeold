import 'package:flutter/material.dart';
import '../config/app_config.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Settings'),
        backgroundColor: Color(0xFF5DADE2),
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
                color: Color(0xFF5DADE2),
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
            
            // Google Maps Option
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConfig.useGoogleMaps ? Color(0xFF5DADE2) : Colors.grey[300],
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
                    ? 'API Key: ${AppConfig.googleMapsApiKey!.substring(0, 10)}...'
                    : 'No API key available',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Switch(
                  value: AppConfig.useGoogleMaps,
                  onChanged: (value) {
                    setState(() {
                      AppConfig.useGoogleMaps = value;
                      if (value) AppConfig.useTomTomMaps = false;
                    });
                  },
                  activeColor: Color(0xFF5DADE2),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // TomTom Maps Option
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConfig.useTomTomMaps ? Color(0xFF5DADE2) : Colors.grey[300],
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
                    ? 'API Key: ${AppConfig.tomtomApiKey!.substring(0, 10)}...'
                    : 'API key will be provided by Django backend',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Switch(
                  value: AppConfig.useTomTomMaps,
                  onChanged: (value) {
                    setState(() {
                      AppConfig.useTomTomMaps = value;
                      if (value) AppConfig.useGoogleMaps = false;
                    });
                  },
                  activeColor: Color(0xFF5DADE2),
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
                  backgroundColor: Color(0xFF5DADE2),
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
                      color: Color(0xFF5DADE2),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Active Provider: ${AppConfig.useGoogleMaps ? "Google Maps" : AppConfig.useTomTomMaps ? "TomTom Maps" : "None"}',
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
      if (mapConfigs != null) {
        setState(() {
          AppConfig.googleMapsApiKey = mapConfigs['google_maps_api_key'];
          AppConfig.tomtomApiKey = mapConfigs['tomtom_api_key'];
          AppConfig.useGoogleMaps = mapConfigs['enable_google_maps'] ?? true;
          AppConfig.useTomTomMaps = mapConfigs['enable_tomtom_maps'] ?? false;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
