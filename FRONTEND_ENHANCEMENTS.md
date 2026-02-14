# Frontend Enhancements - ER Wait Time Flutter App

**App Version:** 2.0.7  
**Backend URL:** `https://api.mywaitime.com/api`  
**Last Updated:** January 28, 2026

---

## 📋 Table of Contents

1. [API & Configuration](#1-api--configuration)
2. [Authentication & User Management](#2-authentication--user-management)
3. [Hospital Search & Display](#3-hospital-search--display)
4. [Feedback Submission](#4-feedback-submission)
5. [ER Wait Time Reporting](#5-er-wait-time-reporting)
6. [UX & Performance](#6-ux--performance)
7. [Learning & Analytics](#7-learning--analytics)
8. [Security & Privacy](#8-security--privacy)
9. [Testing Checklist](#9-testing-checklist)

---

## 1. API & Configuration

### ✅ COMPLETED

#### 1.1 Single Base URL Configuration
**Status:** ✅ Done  
**Location:** `lib/config/app_config.dart`

```dart
class AppConfig {
  static const String djangoBaseUrl = 'https://api.mywaitime.com/api';
  static const String version = '2.0.7';
  static const int versionCode = 7;
}
```

#### 1.2 HTTPS-First with HTTP Fallback
**Status:** ✅ Done  
**Location:** `lib/services/django_api_service.dart`

- Primary: `https://api.mywaitime.com/api`
- Fallback: Handled via try-catch with timeout
- Connection test on app startup validates backend availability

#### 1.3 Consistent Auth Headers
**Status:** ✅ Done  
**Implementation:**

```dart
Map<String, String> get headers => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'User-Agent': 'ERTime-Flutter-App/${AppConfig.version}',
  'X-App-Type': 'flutter',
  if (authToken != null) 'Authorization': 'Token $authToken',
};
```

**Key Points:**
- Uses `Token` prefix (not `Bearer`)
- Token automatically included when available
- Version tracking via User-Agent

### 🟡 IN PROGRESS

#### 1.4 Enhanced Error Handling
**Status:** Partial  
**TODO:**

```dart
// Add to django_api_service.dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  
  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });
  
  factory ApiException.fromResponse(http.Response response) {
    final data = json.decode(response.body);
    return ApiException(
      statusCode: response.statusCode,
      message: data['message'] ?? 'An error occurred',
      errors: data['errors'],
    );
  }
}

// Use in API calls:
if (response.statusCode != 200) {
  throw ApiException.fromResponse(response);
}
```

**Handle in UI:**

```dart
try {
  await apiService.someMethod();
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Redirect to login
  } else if (e.statusCode == 429) {
    // Show rate limit message
  } else {
    // Show generic error
    _showError(e.message);
  }
}
```

---

## 2. Authentication & User Management

### ✅ COMPLETED

#### 2.1 Registration Flow
**Status:** ✅ Done  
**Location:** `lib/screens/register_screen.dart`, `lib/services/django_api_service.dart`

**Current Implementation:**
- Username derived from email prefix
- Name field optional
- Password validation (min 6 chars)
- Email format validation
- Duplicate username check handled

#### 2.2 Login with Flexible Username
**Status:** ✅ Done  
**Implementation:**

```dart
Future<String?> loginAndGetToken(String email, String password) async {
  // Try with full email first
  var response = await http.post(uri, body: {'username': email, 'password': password});
  
  // If fails, try with derived username
  if (response.statusCode != 200) {
    final username = email.split('@').first.toLowerCase()...;
    response = await http.post(uri, body: {'username': username, 'password': password});
  }
  
  // Extract token from response
  return extractToken(response);
}
```

#### 2.3 Token Validation
**Status:** ✅ Done  
**Location:** `lib/providers/auth_provider.dart`

- Validates stored token on app startup
- Automatically clears invalid tokens
- Redirects to login when token expires

### 🔴 CRITICAL TODO

#### 2.4 Handle Duplicate Email Response
**Status:** ❌ Not Implemented  
**Priority:** CRITICAL

**Backend Returns:**
```json
{
  "status": "error",
  "code": "email_exists",
  "message": "Email already registered"
}
```

**Implementation Needed:**

```dart
// In lib/providers/auth_provider.dart
Future<String?> register({
  required String email,
  required String password,
  String? name,
}) async {
  try {
    final error = await _apiService.register(
      email: email,
      password: password,
      name: name,
    );
    
    // ✅ Parse error code
    if (error != null) {
      // Check if it's a duplicate email error
      if (error.contains('email_exists') || 
          error.contains('Email already registered')) {
        return 'This email is already registered. Please login instead.';
      }
      return error;
    }
    
    return null;
  } catch (e) {
    return 'Registration failed: $e';
  }
}
```

**UI Update in register_screen.dart:**

```dart
final error = await context.read<AuthProvider>().register(...);

if (error != null) {
  if (error.contains('already registered')) {
    // Show option to navigate to login
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email Already Registered'),
        content: Text('This email is already in use. Would you like to login instead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go to login
            },
            child: Text('Go to Login'),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
  }
}
```

#### 2.5 Profile Fields Handling
**Status:** ✅ Done (Backend Fixed)

Backend now returns:
```json
{
  "status": "success",
  "data": {
    "user_id": 123,
    "username": "user_123",
    "email": "user@example.com",
    "role": "user",
    "is_verified": false
  }
}
```

**Frontend can now safely use:**
```dart
final role = data['data']['role'] ?? 'user';
final isVerified = data['data']['is_verified'] ?? false;
```

---

## 3. Hospital Search & Display

### ✅ COMPLETED

#### 3.1 Search API Integration
**Status:** ✅ Done  
**Endpoint:** `GET /api/hospitals/search/`

**Query Parameters:**
- `lat` (required): Latitude
- `lon` (required): Longitude
- `radius_m` (required): Radius in meters
- `limit` (optional): Max results (default: 50)

**Current Implementation:**
```dart
Future<List<Hospital>> searchHospitals({
  required double latitude,
  required double longitude,
  double radius = 10.0, // km
}) async {
  final radiusM = (radius * 1000).round();
  final searchUri = Uri.parse(hospitalsSearchEndpoint).replace(
    queryParameters: {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'radius_m': radiusM.toString(),
      'limit': '50',
    },
  );
  // ... fetch and parse
}
```

#### 3.2 Distance Display
**Status:** ✅ Done  
**Location:** `lib/widgets/hospital_card.dart`

Currently shows distance in either miles or kilometers based on user preference stored in `SharedPreferences`.

### 🟡 TODO

#### 3.3 Add Pagination
**Status:** ❌ Not Implemented  
**Priority:** MEDIUM

**Backend Response Expected:**
```json
{
  "status": "success",
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 50,
    "total": 150,
    "has_next": true
  }
}
```

**Implementation:**

```dart
class HospitalProvider with ChangeNotifier {
  List<Hospital> _hospitals = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    final nextPage = await apiService.searchHospitals(
      page: _currentPage + 1,
      ...
    );
    
    _hospitals.addAll(nextPage);
    _currentPage++;
    _hasMore = nextPage.isNotEmpty;
    _isLoadingMore = false;
    notifyListeners();
  }
}

// In UI (main_screen.dart):
ListView.builder(
  controller: _scrollController,
  itemBuilder: (context, index) {
    if (index == hospitals.length - 1) {
      // Load more when reaching end
      Provider.of<HospitalProvider>(context, listen: false).loadMore();
    }
    return HospitalCard(hospital: hospitals[index]);
  },
)
```

#### 3.4 Sort Options
**Status:** ❌ Not Implemented  
**Priority:** MEDIUM

**Add Sort Controls:**

```dart
enum HospitalSortOption {
  distance,
  rating,
  name,
}

// In main_screen.dart
PopupMenuButton<HospitalSortOption>(
  icon: Icon(Icons.sort),
  onSelected: (option) {
    setState(() {
      _sortOption = option;
      _sortHospitals();
    });
  },
  itemBuilder: (context) => [
    PopupMenuItem(
      value: HospitalSortOption.distance,
      child: Text('Sort by Distance'),
    ),
    PopupMenuItem(
      value: HospitalSortOption.rating,
      child: Text('Sort by Rating'),
    ),
    PopupMenuItem(
      value: HospitalSortOption.name,
      child: Text('Sort by Name'),
    ),
  ],
);

void _sortHospitals() {
  switch (_sortOption) {
    case HospitalSortOption.distance:
      _hospitals.sort((a, b) => a.distance.compareTo(b.distance));
      break;
    case HospitalSortOption.rating:
      _hospitals.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case HospitalSortOption.name:
      _hospitals.sort((a, b) => a.name.compareTo(b.name));
      break;
  }
}
```

#### 3.5 Rating Display Enhancement
**Status:** Partial  
**Current:** Shows numeric rating (e.g., 4.5)  
**TODO:** Add visual rating bar with color coding

```dart
// In hospital_card.dart
Widget _buildRatingDisplay(double rating) {
  Color ratingColor;
  if (rating >= 4.0) {
    ratingColor = Colors.green;
  } else if (rating >= 3.0) {
    ratingColor = Colors.orange;
  } else {
    ratingColor = Colors.red;
  }
  
  return Row(
    children: [
      Icon(Icons.star, color: ratingColor, size: 16),
      SizedBox(width: 4),
      Text(
        rating.toStringAsFixed(1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: ratingColor,
        ),
      ),
      Text(' / 5.0', style: TextStyle(color: Colors.grey)),
    ],
  );
}
```

---

## 4. Feedback Submission

### ✅ COMPLETED

#### 4.1 Basic Feedback API
**Status:** ✅ Done  
**Endpoint:** `POST /api/feedback/submit/`

**Current Implementation:**
```dart
Future<bool> submitEnhancedReview({
  required String hospitalId,
  required double rating,
  required String comment,
  int? waitTimeMinutes,
  String? userLocation,
}) async {
  final normalized = _normalizeRatingToInt1to5(rating);
  final body = {
    'hospital_id': hospitalId,
    'rating': rating,
    'comment': comment,
    'wait_time': waitTimeMinutes,
    'care_quality': normalized,
    'staff_friendliness': normalized,
    'cleanliness': normalized,
    'facility_modernity': normalized,
    'user_location': userLocation,
    'timestamp': DateTime.now().toIso8601String(),
    'app_version': AppConfig.version,
    'platform': 'flutter',
  };
  
  final response = await http.post(feedbackEndpoint, body: json.encode(body));
  return response.statusCode == 200;
}
```

### 🟡 TODO

#### 4.2 Enhanced Rating Categories
**Status:** ❌ Not Implemented  
**Priority:** MEDIUM

**Allow users to rate each category separately:**

```dart
// In hospital_detail_screen.dart
class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  double _careQuality = 3.0;
  double _staffFriendliness = 3.0;
  double _cleanliness = 3.0;
  double _facilityModernity = 3.0;
  
  Widget _buildCategoryRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rate Your Experience:', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildCategorySlider('Care Quality', _careQuality, (val) => setState(() => _careQuality = val)),
        _buildCategorySlider('Staff Friendliness', _staffFriendliness, (val) => setState(() => _staffFriendliness = val)),
        _buildCategorySlider('Cleanliness', _cleanliness, (val) => setState(() => _cleanliness = val)),
        _buildCategorySlider('Facility Modernity', _facilityModernity, (val) => setState(() => _facilityModernity = val)),
      ],
    );
  }
  
  Widget _buildCategorySlider(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
```

#### 4.3 Optional Fields Handling
**Status:** ✅ Done

Backend accepts optional fields:
- `visit_date`
- `reviewer_name`
- `reviewer_email`
- `reviewer_phone`

**Add to UI if needed:**

```dart
// Add optional fields to form
TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: 'Your Name (optional)',
    hintText: 'Anonymous',
  ),
),
```

#### 4.4 Success UX with AI Feedback
**Status:** Partial  
**Current:** Shows generic success dialog  
**TODO:** Display backend AI response

```dart
// Backend returns:
{
  "status": "success",
  "message": "Thank you for your feedback!",
  "feedback_id": "uuid",
  "overall_rating": 4.2,
  "ai_updated": true
}

// Display in UI:
void _showSuccessDialog(Map<String, dynamic> response) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
      title: Text('Thank You!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(response['message'] ?? 'Your feedback has been submitted.'),
          if (response['ai_updated'] == true)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '🤖 AI has learned from your feedback',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          Text(
            'Overall rating: ${response['overall_rating']}/5',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
```

---

## 5. ER Wait Time Reporting

### ✅ COMPLETED

#### 5.1 Basic Wait Time Submission
**Status:** ✅ Done  
**Location:** `lib/screens/hospital_detail_screen.dart`

Wait time included in feedback submission as `wait_time` field.

### 🟡 TODO

#### 5.2 Dedicated Wait Time Report Flow
**Status:** ❌ Not Implemented  
**Priority:** MEDIUM

**Add quick "Report Wait Time Only" option:**

```dart
// In hospital_card.dart or hospital_detail_screen.dart
ElevatedButton.icon(
  icon: Icon(Icons.access_time),
  label: Text('Quick Report Wait Time'),
  onPressed: () => _showQuickWaitTimeDialog(),
);

void _showQuickWaitTimeDialog() {
  int waitMinutes = 30;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Report Current Wait Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('How long are you waiting?'),
          Slider(
            value: waitMinutes.toDouble(),
            min: 0,
            max: 240,
            divisions: 24,
            label: '$waitMinutes min',
            onChanged: (val) => setState(() => waitMinutes = val.round()),
          ),
          Text('$waitMinutes minutes'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _apiService.submitWaitTime(
              hospitalId: widget.hospital.id,
              waitMinutes: waitMinutes,
            );
            Navigator.pop(context);
            _showSuccessSnackBar('Wait time reported!');
          },
          child: Text('Submit'),
        ),
      ],
    ),
  );
}
```

#### 5.3 Display Smart Wait Time
**Status:** ❌ Not Implemented  
**Priority:** HIGH

**Backend Endpoint:** `GET /api/hospitals/{hospital_id}/smart-wait-time/`

**Response:**
```json
{
  "status": "success",
  "data": {
    "hospital_id": "uuid",
    "base_wait_time": 30,
    "smart_wait_time": 42,
    "capacity_status": "medium",
    "ai_rating": 8.7,
    "last_updated": "2026-01-28T10:30:00Z"
  }
}
```

**Implementation:**

```dart
// In django_api_service.dart
Future<Map<String, dynamic>?> getSmartWaitTime(String hospitalId) async {
  try {
    final uri = Uri.parse('$baseUrl/hospitals/$hospitalId/smart-wait-time/');
    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
    }
    return null;
  } catch (e) {
    print('Error fetching smart wait time: $e');
    return null;
  }
}

// In hospital_detail_screen.dart
Widget _buildWaitTimeDisplay() {
  return FutureBuilder<Map<String, dynamic>?>(
    future: _apiService.getSmartWaitTime(widget.hospital.id),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return CircularProgressIndicator();
      }
      
      final data = snapshot.data!;
      final smartWait = data['smart_wait_time'] ?? 0;
      final capacity = data['capacity_status'] ?? 'unknown';
      
      Color statusColor;
      if (capacity == 'low') {
        statusColor = Colors.green;
      } else if (capacity == 'medium') {
        statusColor = Colors.orange;
      } else {
        statusColor = Colors.red;
      }
      
      return Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: statusColor),
                  SizedBox(width: 8),
                  Text(
                    'Estimated Wait Time',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '$smartWait minutes',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                'Capacity: ${capacity.toUpperCase()}',
                style: TextStyle(color: statusColor),
              ),
              SizedBox(height: 4),
              Text(
                'Updated: ${_formatTime(data['last_updated'])}',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

#### 5.4 Auto-Refresh After Wait Time Submit
**Status:** ❌ Not Implemented  
**Priority:** LOW

After user submits wait time, automatically refresh the smart wait time display:

```dart
Future<void> _submitWaitTime() async {
  await _apiService.submitWaitTime(...);
  
  // Refresh smart wait time
  setState(() {
    // This will trigger FutureBuilder to refresh
  });
  
  _showSuccessSnackBar('Wait time reported! Updated estimate coming...');
}
```

---

## 6. UX & Performance

### ✅ COMPLETED

#### 6.1 Loading States
**Status:** ✅ Done

- Splash screen with loading spinner
- CircularProgressIndicator during API calls
- Loading state in buttons during form submission

#### 6.2 Error Handling with Retry
**Status:** ✅ Done  
**Location:** `lib/screens/main_screen.dart`

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(_lastSearchError ?? 'Failed to load hospitals'),
    backgroundColor: Colors.red,
    action: SnackBarAction(
      label: 'Retry',
      textColor: Colors.white,
      onPressed: _searchHospitals,
    ),
  ),
);
```

#### 6.3 Pull to Refresh
**Status:** ✅ Done  
**Location:** Hospital list uses `RefreshIndicator`

### 🟡 TODO

#### 6.4 Offline Mode & Caching
**Status:** ❌ Not Implemented  
**Priority:** HIGH

**Use Hive or SQLite for local caching:**

```dart
// Add dependencies in pubspec.yaml:
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0

// Initialize in main.dart:
await Hive.initFlutter();
await Hive.openBox<Hospital>('hospitals_cache');

// Cache hospitals after fetch:
Future<List<Hospital>> searchHospitals(...) async {
  final box = Hive.box<Hospital>('hospitals_cache');
  
  try {
    // Fetch from API
    final hospitals = await _fetchFromApi();
    
    // Cache results
    await box.clear();
    await box.addAll(hospitals);
    
    return hospitals;
  } catch (e) {
    // If offline, return cached data
    print('Offline mode: using cached data');
    return box.values.toList();
  }
}

// Show offline indicator in UI:
if (!_isOnline) {
  Container(
    color: Colors.orange,
    padding: EdgeInsets.all(8),
    child: Row(
      children: [
        Icon(Icons.offline_bolt, color: Colors.white),
        SizedBox(width: 8),
        Text('Offline - Showing cached data', style: TextStyle(color: Colors.white)),
      ],
    ),
  ),
}
```

#### 6.5 Deep Links
**Status:** ❌ Not Implemented  
**Priority:** LOW

**Allow opening specific hospital from notification or web:**

```dart
// Add to pubspec.yaml:
dependencies:
  uni_links: ^0.5.1

// In main.dart:
Future<void> _handleDeepLink() async {
  final initialLink = await getInitialLink();
  if (initialLink != null) {
    final uri = Uri.parse(initialLink);
    if (uri.path.contains('/hospital/')) {
      final hospitalId = uri.pathSegments.last;
      _navigateToHospital(hospitalId);
    }
  }
}

// Example deep links:
// erwaittime://hospital/abc-123
// https://mywaitime.com/hospital/abc-123
```

#### 6.6 Image Caching
**Status:** ✅ Done  
**Location:** Using `cached_network_image` package

#### 6.7 Debounce Search Input
**Status:** ❌ Not Implemented  
**Priority:** LOW

If adding search by name:

```dart
import 'dart:async';

Timer? _debounce;

void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  
  _debounce = Timer(Duration(milliseconds: 500), () {
    _performSearch(query);
  });
}

@override
void dispose() {
  _debounce?.cancel();
  super.dispose();
}
```

---

## 7. Learning & Analytics

### 🟡 TODO

#### 7.1 Display AI Learning Indicators
**Status:** ❌ Not Implemented  
**Priority:** MEDIUM

**Show when AI has updated based on user feedback:**

```dart
// Backend returns ai_updated: true
// Display badge in hospital card:
if (hospital.aiUpdated) {
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.psychology, size: 12, color: Colors.white),
        SizedBox(width: 4),
        Text('AI Updated', style: TextStyle(color: Colors.white, fontSize: 10)),
      ],
    ),
  ),
}
```

#### 7.2 Wait Time Confirmation
**Status:** ❌ Not Implemented  
**Priority:** LOW

**After visit, ask user to confirm actual wait time:**

```dart
// After user views hospital details, schedule notification for later
// Using flutter_local_notifications

Future<void> scheduleWaitTimeConfirmation(Hospital hospital) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'How was your visit?',
    'Please confirm your actual wait time at ${hospital.name}',
    tz.TZDateTime.now(tz.local).add(Duration(hours: 2)),
    NotificationDetails(...),
    uiLocalNotificationDateInterpretation: ...,
  );
}

// On notification tap, show confirmation dialog:
void _confirmWaitTime(Hospital hospital) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Wait Time'),
      content: Text('How long did you actually wait at ${hospital.name}?'),
      // ... slider to confirm actual wait
    ),
  );
}
```

#### 7.3 Analytics Events
**Status:** ❌ Not Implemented  
**Priority:** LOW

**Track user interactions for analytics:**

```dart
// Add firebase_analytics or custom analytics
Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
  // Send to backend analytics endpoint
  await http.post(
    Uri.parse('$baseUrl/analytics/event/'),
    body: json.encode({
      'event_name': name,
      'parameters': parameters,
      'timestamp': DateTime.now().toIso8601String(),
    }),
  );
}

// Use throughout app:
logEvent('hospital_viewed', {'hospital_id': hospital.id});
logEvent('feedback_submitted', {'rating': rating});
logEvent('search_performed', {'radius': radius});
```

---

## 8. Security & Privacy

### ✅ COMPLETED

#### 8.1 No Sensitive Data in Logs
**Status:** ✅ Partial

Current `print()` statements don't log passwords or tokens.

**TODO: Remove all print statements in production:**

```dart
// Create debug helper:
void debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

// Replace all print() with debugLog():
debugLog('Token validated successfully');
```

#### 8.2 HTTPS in Production
**Status:** ✅ Done

Base URL uses HTTPS: `https://api.mywaitime.com/api`

### 🟡 TODO

#### 8.3 Secure Token Storage
**Status:** ⚠️ Review Needed  
**Current:** Using `SharedPreferences` (not encrypted)  
**Recommendation:** Use `flutter_secure_storage` for sensitive data

```dart
// Replace in auth_provider.dart:
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Save token securely:
await storage.write(key: 'auth_token', value: token);

// Read token:
final token = await storage.read(key: 'auth_token');

// Delete token:
await storage.delete(key: 'auth_token');
```

#### 8.4 Biometric Authentication
**Status:** ❌ Not Implemented  
**Priority:** LOW

**Add fingerprint/Face ID for login:**

```dart
// Add dependency:
dependencies:
  local_auth: ^2.1.6

// Implementation:
import 'package:local_auth/local_auth.dart';

final LocalAuthentication auth = LocalAuthentication();

Future<bool> authenticateWithBiometrics() async {
  try {
    return await auth.authenticate(
      localizedReason: 'Please authenticate to access ER Wait Time',
      options: AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  } catch (e) {
    return false;
  }
}

// Use before showing sensitive data or login
if (await authenticateWithBiometrics()) {
  // Proceed
}
```

#### 8.5 Certificate Pinning
**Status:** ❌ Not Implemented  
**Priority:** LOW (for high security apps)

```dart
// For HTTPS certificate pinning:
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

// Pin mywaitime.com certificate
```

---

## 9. Testing Checklist

### Manual Testing

- [ ] **Registration Flow**
  - [ ] New user can register
  - [ ] Duplicate email shows proper error
  - [ ] Form validation works (email format, password length)
  - [ ] Success redirects to login

- [ ] **Login Flow**
  - [ ] User can login with email
  - [ ] Invalid credentials show error
  - [ ] Token persists across app restarts
  - [ ] Logout clears credentials

- [ ] **Hospital Search**
  - [ ] Location permission requested
  - [ ] Search returns nearby hospitals
  - [ ] Distance displayed correctly (mi/km)
  - [ ] Pull-to-refresh works
  - [ ] Empty state shows when no results

- [ ] **Hospital Details**
  - [ ] Card shows all info (name, address, rating, phone)
  - [ ] Tap card opens detail screen
  - [ ] Directions button works
  - [ ] Call button works (if phone available)

- [ ] **Feedback Submission**
  - [ ] Rating can be set (1-5 stars)
  - [ ] Comment validation (min 10 chars)
  - [ ] Wait time input works
  - [ ] Success shows confirmation
  - [ ] Error shows with retry option
  - [ ] Requires authentication

- [ ] **UX/UI**
  - [ ] Loading indicators show during async operations
  - [ ] Error messages are clear and actionable
  - [ ] Navigation works (back buttons, bottom nav)
  - [ ] App looks good on different screen sizes
  - [ ] Orientation changes handled

- [ ] **Offline Mode** (if implemented)
  - [ ] Cached data shown when offline
  - [ ] Offline indicator visible
  - [ ] Data syncs when back online

### Automated Testing

#### Unit Tests
```dart
// test/services/django_api_service_test.dart
testWidgets('searchHospitals returns list', (WidgetTester tester) async {
  final service = DjangoApiService();
  final hospitals = await service.searchHospitals(
    latitude: 37.7749,
    longitude: -122.4194,
  );
  expect(hospitals, isNotEmpty);
});
```

#### Widget Tests
```dart
// test/widgets/hospital_card_test.dart
testWidgets('HospitalCard displays hospital info', (WidgetTester tester) async {
  final hospital = Hospital(...);
  await tester.pumpWidget(
    MaterialApp(home: HospitalCard(hospital: hospital)),
  );
  expect(find.text(hospital.name), findsOneWidget);
});
```

#### Integration Tests
```dart
// integration_test/app_test.dart
testWidgets('Complete user flow', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Test splash screen
  expect(find.text('ER Wait Time'), findsOneWidget);
  
  // Navigate to login
  await tester.pumpAndSettle();
  expect(find.text('Sign In'), findsOneWidget);
  
  // Test registration
  await tester.tap(find.text('Don\'t have an account? Sign up'));
  await tester.pumpAndSettle();
  
  // ... complete flow test
});
```

---

## 📊 Priority Summary

| Priority | Count | Focus Area |
|----------|-------|------------|
| 🔴 CRITICAL | 1 | Duplicate email error handling |
| 🟠 HIGH | 2 | Smart wait time display, Offline caching |
| 🟡 MEDIUM | 6 | Pagination, Sort, Category ratings, Quick wait report |
| 🟢 LOW | 8 | Deep links, Biometrics, Analytics, Notifications |

---

## 🚀 Implementation Roadmap

### Sprint 1 (Week 1)
- ✅ Fix duplicate email error handling
- ✅ Implement smart wait time display
- ✅ Add enhanced error response parsing

### Sprint 2 (Week 2)
- ✅ Add pagination to hospital list
- ✅ Implement sort controls
- ✅ Add category-specific ratings

### Sprint 3 (Week 3)
- ✅ Implement offline caching with Hive
- ✅ Add quick wait time report button
- ✅ Display AI learning indicators

### Sprint 4 (Week 4)
- ✅ Implement deep linking
- ✅ Add analytics tracking
- ✅ Secure storage migration
- ✅ Write automated tests

---

## 📝 Notes

- **Backend Alignment:** This document is synchronized with `BACKEND_ENHANCEMENTS_GODADDY.md`
- **Duplicate Users:** Known issue documented in `DUPLICATE_USERS_REPORT.md` - backend fix in progress
- **Version:** Keep `AppConfig.version` in sync with `pubspec.yaml`
- **Testing:** Test all features on both iOS and Android before production release

---

**Last Updated:** January 28, 2026  
**Next Review:** Before version 2.1.0 release
