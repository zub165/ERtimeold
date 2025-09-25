import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_key_manager.dart';
import '../services/django_api_service.dart';
import '../config/app_config.dart';

class ApiKeySettingsScreen extends StatefulWidget {
  @override
  _ApiKeySettingsScreenState createState() => _ApiKeySettingsScreenState();
}

class _ApiKeySettingsScreenState extends State<ApiKeySettingsScreen> {
  final _googleMapsController = TextEditingController();
  final _tomtomController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _loading = false;
  bool _useUserKeysOnly = false;
  String _preferredProvider = 'google';
  Map<String, String> _sourceInfo = {};
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }
  
  @override
  void dispose() {
    _googleMapsController.dispose();
    _tomtomController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCurrentSettings() async {
    setState(() {
      _loading = true;
    });
    
    try {
      // Load current user keys
      final userGoogleKey = await ApiKeyManager.getUserGoogleMapsApiKey();
      final userTomTomKey = await ApiKeyManager.getUserTomTomApiKey();
      final preferredProvider = await ApiKeyManager.getPreferredMapProvider();
      final useUserKeysOnly = await ApiKeyManager.shouldUseUserKeysOnly();
      final sourceInfo = await ApiKeyManager.getApiKeySourceInfo();
      
      setState(() {
        _googleMapsController.text = userGoogleKey ?? '';
        _tomtomController.text = userTomTomKey ?? '';
        _preferredProvider = preferredProvider;
        _useUserKeysOnly = useUserKeysOnly;
        _sourceInfo = sourceInfo;
      });
    } catch (e) {
      _showSnackBar('Error loading settings: $e', Colors.red);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _loading = true;
    });
    
    try {
      // Save API keys
      if (_googleMapsController.text.isNotEmpty) {
        await ApiKeyManager.saveGoogleMapsApiKey(_googleMapsController.text.trim());
      }
      
      if (_tomtomController.text.isNotEmpty) {
        await ApiKeyManager.saveTomTomApiKey(_tomtomController.text.trim());
      }
      
      // Save preferences
      await ApiKeyManager.savePreferredMapProvider(_preferredProvider);
      await ApiKeyManager.setUseUserKeysOnly(_useUserKeysOnly);
      
      // Refresh source info
      final sourceInfo = await ApiKeyManager.getApiKeySourceInfo();
      setState(() {
        _sourceInfo = sourceInfo;
      });
      
      _showSnackBar('API key settings saved successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error saving settings: $e', Colors.red);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  Future<void> _testGoogleMapsKey() async {
    if (_googleMapsController.text.isEmpty) {
      _showSnackBar('Please enter a Google Maps API key', Colors.orange);
      return;
    }
    
    setState(() {
      _loading = true;
    });
    
    try {
      // Test the key by making a simple geocoding request
      // This is a basic validation - in production you'd make an actual API call
      if (ApiKeyManager.isValidGoogleMapsApiKey(_googleMapsController.text.trim())) {
        _showSnackBar('Google Maps API key format is valid!', Colors.green);
      } else {
        _showSnackBar('Invalid Google Maps API key format', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error testing Google Maps key: $e', Colors.red);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  Future<void> _testTomTomKey() async {
    if (_tomtomController.text.isEmpty) {
      _showSnackBar('Please enter a TomTom API key', Colors.orange);
      return;
    }
    
    setState(() {
      _loading = true;
    });
    
    try {
      // Test the key format
      if (ApiKeyManager.isValidTomTomApiKey(_tomtomController.text.trim())) {
        _showSnackBar('TomTom API key format is valid!', Colors.green);
      } else {
        _showSnackBar('Invalid TomTom API key format', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error testing TomTom key: $e', Colors.red);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  Future<void> _clearAllKeys() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All API Keys'),
        content: Text('Are you sure you want to clear all user-provided API keys? This will revert to Django backend or fallback keys.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ApiKeyManager.clearAllUserApiKeys();
      await _loadCurrentSettings();
      _showSnackBar('All user API keys cleared', Colors.blue);
    }
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Key Settings'),
        backgroundColor: Color(0xFF5DADE2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    SizedBox(height: 30),
                    
                    // Settings Toggle
                    _buildUserKeysOnlyToggle(),
                    SizedBox(height: 20),
                    
                    // Google Maps API Key Section
                    _buildGoogleMapsSection(),
                    SizedBox(height: 30),
                    
                    // TomTom API Key Section
                    _buildTomTomSection(),
                    SizedBox(height: 30),
                    
                    // Map Provider Selection
                    _buildMapProviderSelection(),
                    SizedBox(height: 30),
                    
                    // Current Configuration Info
                    _buildConfigurationInfo(),
                    SizedBox(height: 30),
                    
                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.vpn_key, color: Color(0xFF5DADE2), size: 28),
            SizedBox(width: 10),
            Text(
              'API Key Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5DADE2),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Secure API Key Management: Provide your own API keys or connect to Django backend. No keys are hardcoded in the app for security.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildUserKeysOnlyToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.security, color: Color(0xFF5DADE2)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use Only User-Provided Keys',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Ignore Django backend and fallback keys',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _useUserKeysOnly,
              onChanged: (value) {
                setState(() {
                  _useUserKeysOnly = value;
                });
              },
              activeColor: Color(0xFF5DADE2),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGoogleMapsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  'Google Maps API Key',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _googleMapsController,
              decoration: InputDecoration(
                labelText: 'Google Maps API Key',
                hintText: 'AIza...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _googleMapsController.text = data!.text!;
                    }
                  },
                ),
              ),
              validator: (value) {
                if (_useUserKeysOnly && (value == null || value.isEmpty)) {
                  return 'Google Maps API key is required when using user keys only';
                }
                if (value != null && value.isNotEmpty && !ApiKeyManager.isValidGoogleMapsApiKey(value)) {
                  return 'Invalid Google Maps API key format';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testGoogleMapsKey,
                    icon: Icon(Icons.check_circle),
                    label: Text('Test Key'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () => _googleMapsController.clear(),
                  child: Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTomTomSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.navigation, color: Colors.orange),
                SizedBox(width: 10),
                Text(
                  'TomTom Maps API Key',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _tomtomController,
              decoration: InputDecoration(
                labelText: 'TomTom API Key',
                hintText: 'Enter your TomTom API key...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _tomtomController.text = data!.text!;
                    }
                  },
                ),
              ),
              validator: (value) {
                if (_preferredProvider == 'tomtom' && _useUserKeysOnly && (value == null || value.isEmpty)) {
                  return 'TomTom API key is required when TomTom is preferred and using user keys only';
                }
                if (value != null && value.isNotEmpty && !ApiKeyManager.isValidTomTomApiKey(value)) {
                  return 'Invalid TomTom API key format';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testTomTomKey,
                    icon: Icon(Icons.check_circle),
                    label: Text('Test Key'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () => _tomtomController.clear(),
                  child: Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMapProviderSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferred Map Provider',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Google Maps'),
                    value: 'google',
                    groupValue: _preferredProvider,
                    onChanged: (value) {
                      setState(() {
                        _preferredProvider = value!;
                      });
                    },
                    activeColor: Color(0xFF5DADE2),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('TomTom Maps'),
                    value: 'tomtom',
                    groupValue: _preferredProvider,
                    onChanged: (value) {
                      setState(() {
                        _preferredProvider = value!;
                      });
                    },
                    activeColor: Color(0xFF5DADE2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfigurationInfo() {
    return Container(
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
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow('Google Maps Source:', _sourceInfo['google_source'] ?? 'Unknown'),
          _buildInfoRow('TomTom Maps Source:', _sourceInfo['tomtom_source'] ?? 'Unknown'),
          _buildInfoRow('Preferred Provider:', _preferredProvider.toUpperCase()),
          _buildInfoRow('User Keys Only:', _useUserKeysOnly ? 'Yes' : 'No'),
          _buildInfoRow('Django Backend:', AppConfig.djangoBaseUrl),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _saveSettings,
            icon: Icon(Icons.save),
            label: Text(
              'Save Settings',
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
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _clearAllKeys,
            icon: Icon(Icons.clear_all, color: Colors.red),
            label: Text(
              'Clear All User Keys',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help, color: Color(0xFF5DADE2)),
            SizedBox(width: 8),
            Text('API Key Help'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to get API Keys:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Google Maps: Visit Google Cloud Console → APIs & Services → Credentials'),
              Text('• TomTom Maps: Visit TomTom Developer Portal → My Dashboard → API Keys'),
              SizedBox(height: 16),
              Text(
                'Key Priority Order:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Your API Keys (if provided)'),
              Text('2. Django Backend Keys'),
              Text('3. Fallback Default Keys'),
              SizedBox(height: 16),
              Text(
                'User Keys Only Mode:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('When enabled, only your provided keys will be used. Backend and fallback keys will be ignored.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: TextStyle(color: Color(0xFF5DADE2))),
          ),
        ],
      ),
    );
  }
}
