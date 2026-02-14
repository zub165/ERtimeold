# Frontend-Backend Feature Alignment

**Last Updated:** January 28, 2026  
**Backend:** Django @ `https://api.mywaitime.com/api`  
**Frontend:** Flutter Mobile App

---

## 🎯 Critical Alignment Items

### ✅ Duplicate Email Handling
**Frontend Status:** 🔴 Critical - Needs implementation  
**Backend Status:** ✅ Ready

**Backend Response:**
```json
{
  "status": "error",
  "message": "An account with this email already exists. Please try logging in instead.",
  "code": "email_exists",
  "suggestion": "Try logging in with your existing credentials or use a different email address."
}
```

**Flutter Implementation (add to registration handler):**
```dart
final response = await registerUser(...);
if (response['code'] == 'email_exists') {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Account Already Exists'),
      content: Text(response['suggestion'] ?? 
        'This email is already registered. Would you like to log in instead?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login', 
              arguments: {'email': email});
          },
          child: Text('Go to Login'),
        ),
      ],
    ),
  );
}
```

---

## 🔐 Authentication Features

| Feature | Frontend Status | Backend Status | Notes |
|---------|----------------|----------------|-------|
| Email/Username Login | ✅ Implemented | ✅ Ready | Backend accepts username only |
| Email Format Validation | 🟡 Basic | ✅ Enhanced | Backend validates on submit |
| Password Strength | 🟡 Basic | ✅ Enforced | Backend requires 8+ chars, mixed case, numbers, symbols |
| Token Management | ✅ Implemented | ✅ Ready | Backend returns DRF Token + Session |
| Duplicate Email Check | 🔴 Needs Handler | ✅ Returns `code` | Use code snippet above |

**Password Requirements (Backend enforces):**
- ✅ Minimum 8 characters
- ✅ At least one uppercase letter
- ✅ At least one lowercase letter
- ✅ At least one number
- ✅ At least one special character
- ✅ Not in common weak passwords list

**Frontend Action:** Add client-side password validation to match backend requirements before submission.

---

## 🏥 Hospital Search & Display

| Feature | Frontend Status | Backend Status | API Endpoint |
|---------|----------------|----------------|--------------|
| Basic Search | ✅ Implemented | ✅ Ready | `GET /api/hospitals/search/` |
| Distance Calculation | ✅ Implemented | ✅ Ready | Returns `distance_miles` + `distance_km` |
| Pagination | 🟡 Medium Priority | ✅ Ready | `?page=1&page_size=20` |
| Sort Options | 🟡 Medium Priority | ✅ Ready | `?sort_by=rating&sort_order=desc` |
| AI Rating (1-10) | ✅ Implemented | ✅ Ready | Returns `ai_rating` (1-10) |
| AI Rating (1-5) | 🟡 Needs Display | ✅ Ready | Returns `ai_rating_5` (derived) |
| Hospital Types Filter | 🟡 Nice-to-Have | ✅ Ready | Returns `hospital_type` field |

**Backend Sorting Options:**
- `sort_by=rating` - AI rating (high to low)
- `sort_by=wait_time` - Wait time prediction (low to high)
- `sort_by=name` - Alphabetical
- `sort_by=distance` - Nearest first (requires user lat/lon in query)

**Sample Request:**
```
GET /api/hospitals/?page=1&page_size=20&sort_by=rating&sort_order=desc&lat=28.5383&lon=-81.3792
```

---

## ⭐ Feedback & Reviews

| Feature | Frontend Status | Backend Status | API Endpoint |
|---------|----------------|----------------|--------------|
| Submit Review | ✅ Implemented | ✅ Ready | `POST /api/feedback/submit/` |
| Category Ratings | ✅ Implemented | ✅ Ready | 5 categories required |
| Rating Scale | ✅ 1-10 | ✅ Accepts both | Backend normalizes 1-5 or 1-10 |
| AI Learning Feedback | 🟡 Show Confirmation | ✅ Active | Backend returns `ai_updated: true` |

**Required Fields (Backend):**
```json
{
  "hospital_id": "uuid",
  "care_quality": 1-10,
  "staff_friendliness": 1-10,
  "cleanliness": 1-10,
  "wait_time": 1-10,  // rating of wait experience, not minutes
  "facility_modernity": 1-10,
  "comment": "optional",
  "visit_date": "2026-01-28"  // optional
}
```

**Frontend Enhancement:** Show "✅ Your feedback is improving predictions" message when backend returns `ai_updated: true`.

---

## ⏱️ ER Wait Time

| Feature | Frontend Status | Backend Status | API Endpoint |
|---------|----------------|----------------|--------------|
| Report Wait Time | ✅ Implemented | ✅ Ready | `POST /api/hospitals/wait-times/update/` |
| Smart Wait Prediction | 🟡 Display Enhancement | ✅ Ready | `GET /api/hospitals/{id}/smart-wait-time/` |
| AI Wait Prediction | 🟡 Nice-to-Have | ✅ Ready | `GET /api/hospitals/{id}/ai-wait-time/` |
| Quick Report Button | 🟡 UX Enhancement | ✅ Backend Ready | Use same endpoint |

**Report Wait Time Request:**
```json
{
  "hospital_id": "uuid",
  "reported_minutes": 45,
  "severity_level": "medium",  // low|medium|high
  "user_comment": "optional",
  "user_rating": 3  // 1-5, optional
}
```

**Smart Wait Time Response:**
```json
{
  "status": "success",
  "data": {
    "hospital_id": "uuid",
    "hospital_name": "ER Name",
    "base_wait_time": 30,
    "smart_wait_time": 42,
    "capacity_status": "medium",
    "ai_rating": 8.5,
    "factors": {
      "capacity_multiplier": 1.5,
      "time_multiplier": 0.9,
      "current_hour": 21
    }
  }
}
```

**Frontend Enhancement:** After user reports wait time, refresh smart wait time to show "Your report updated the estimate from X to Y minutes."

---

## 🎨 UX & Performance

| Feature | Frontend Status | Backend Status | Notes |
|---------|----------------|----------------|-------|
| Loading States | ✅ Implemented | N/A | Client-side |
| Error Handling | ✅ Implemented | ✅ Standard Format | Backend returns `status: error` |
| Retry on Failure | ✅ Implemented | N/A | Client-side |
| Pull-to-Refresh | ✅ Implemented | N/A | Client-side |
| Offline Caching | 🟡 Hive Integration | N/A | Client-side with Hive |
| Pagination | 🟡 Medium Priority | ✅ Ready | Backend supports |

---

## 🔒 Security

| Feature | Frontend Status | Backend Status | Notes |
|---------|----------------|----------------|-------|
| HTTPS Connection | ✅ Implemented | ✅ Nginx SSL | `https://api.mywaitime.com` |
| Auth Headers | ✅ Implemented | ✅ Validated | `Authorization: Token <token>` |
| Token Storage | ✅ Secure | N/A | Use `flutter_secure_storage` |
| Certificate Pinning | 🟢 Nice-to-Have | N/A | Optional enhancement |
| Biometric Auth | 🟢 Nice-to-Have | N/A | Client-side feature |

---

## 📊 AI Learning & Analytics

| Feature | Frontend Status | Backend Status | Notes |
|---------|----------------|----------------|-------|
| Feedback → AI Update | 🟡 Show Confirmation | ✅ Active | Django signals trigger learning |
| Wait Time → AI Update | 🟡 Show Confirmation | ✅ Active | Updates predictions automatically |
| Learning Status Display | 🟡 Enhancement | ✅ Available | `GET /api/ai/learn/status/` |
| AI Confidence Score | 🟡 Enhancement | ✅ Returns | Included in wait time predictions |

**Backend Auto-Learning:**
- ✅ Every feedback submission triggers AI update (Django signal)
- ✅ Every wait time report adjusts predictions (signal)
- ✅ Batch learning runs periodically (management command)

**Frontend Enhancement:** Add "AI Learning" badge that shows:
```dart
// After successful feedback
if (response['ai_updated'] == true) {
  showSnackBar(
    '✅ Thank you! AI predictions improved',
    backgroundColor: Colors.green,
  );
}
```

---

## 🚀 Priority Implementation Order

### Week 1: Critical Fixes
1. **Duplicate Email Handler** (code provided above) - 30 min
2. **Password Strength UI** - Show requirements before submission - 1 hour
3. **AI Learning Confirmation** - Show success messages - 30 min

### Week 2: High-Value Features
4. **Pagination** - Implement infinite scroll - 2 hours
5. **Sort Controls** - Add sort dropdown (rating/distance/wait) - 2 hours
6. **Smart Wait Time Display** - Fetch and show AI predictions - 2 hours

### Week 3: Enhanced UX
7. **Quick Report Wait Time** - Add FAB button - 1 hour
8. **Distance Unit Toggle** - Miles ↔ Kilometers - 30 min
9. **Rating Scale Toggle** - 1-5 ★ ↔ 1-10 - 1 hour

### Week 4: Polish & Testing
10. **Offline Caching** - Implement Hive - 3 hours
11. **Error Retry Logic** - Enhanced with exponential backoff - 1 hour
12. **End-to-End Testing** - All flows - 4 hours

---

## 📋 Quick Reference: API Endpoints

### Authentication
```
POST /api/auth/register/          # Register (email, username, password)
POST /api/auth/login/             # Login (username, password)
GET  /api/auth/profile/           # Get user profile (requires auth)
```

### Hospitals
```
GET  /api/hospitals/              # List all hospitals (paginated)
GET  /api/hospitals/search/       # Search hospitals (?q=name&lat=&lon=&radius=)
GET  /api/hospitals/{id}/         # Get hospital details
GET  /api/hospitals/{id}/smart-wait-time/   # AI wait prediction
```

### Feedback & Wait Time
```
POST /api/feedback/submit/        # Submit review (5 category ratings)
POST /api/hospitals/wait-times/update/  # Report wait time (minutes)
```

### System
```
GET  /api/health/                 # Health check
GET  /api/docs/                   # Swagger documentation
```

---

## 🔧 Backend Cleanup Tasks (User Action Required)

Before going to production, the user should run:

```bash
cd /home/newgen/hospitalfinder/django-backend
source venv/bin/activate

# 1. Clean duplicate users
python manage.py cleanup_duplicate_users
# Review, then type 'yes' to proceed

# 2. Verify cleanup
python manage.py list_duplicate_users

# 3. Disable CORS wildcard (production hardening)
# Edit settings.py line 572:
# CORS_ALLOW_ALL_ORIGINS = False
```

---

## 📱 Flutter API Service Template

**Complete service class for your Flutter app:**

```dart
// lib/services/hospital_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class HospitalApiService {
  static const String baseUrl = 'https://api.mywaitime.com';
  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Token $_authToken',
  };

  // Register
  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register/'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login/'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    final data = jsonDecode(response.body);
    if (data['status'] == 'success' && data['data']?['token'] != null) {
      setAuthToken(data['data']['token']);
    }
    return data;
  }

  // Search Hospitals
  static Future<Map<String, dynamic>> searchHospitals({
    String? query,
    double? lat,
    double? lon,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'rating',
  }) async {
    final queryParams = {
      if (query != null) 'q': query,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort_by': sortBy,
    };
    final uri = Uri.parse('$baseUrl/api/hospitals/search/')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  // Submit Feedback
  static Future<Map<String, dynamic>> submitFeedback({
    required String hospitalId,
    required Map<String, int> ratings,
    String? comment,
    String? visitDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/feedback/submit/'),
      headers: _headers,
      body: jsonEncode({
        'hospital_id': hospitalId,
        'care_quality': ratings['care_quality'],
        'staff_friendliness': ratings['staff_friendliness'],
        'cleanliness': ratings['cleanliness'],
        'wait_time': ratings['wait_time'],
        'facility_modernity': ratings['facility_modernity'],
        if (comment != null) 'comment': comment,
        if (visitDate != null) 'visit_date': visitDate,
      }),
    );
    return jsonDecode(response.body);
  }

  // Report Wait Time
  static Future<Map<String, dynamic>> reportWaitTime({
    required String hospitalId,
    required int reportedMinutes,
    String severityLevel = 'medium',
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/hospitals/wait-times/update/'),
      headers: _headers,
      body: jsonEncode({
        'hospital_id': hospitalId,
        'reported_minutes': reportedMinutes,
        'severity_level': severityLevel,
        if (comment != null) 'user_comment': comment,
      }),
    );
    return jsonDecode(response.body);
  }

  // Get Smart Wait Time
  static Future<Map<String, dynamic>> getSmartWaitTime(String hospitalId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/hospitals/$hospitalId/smart-wait-time/'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }
}
```

---

## ✅ Alignment Checklist

- [x] Backend duplicates identified (2 email groups)
- [x] Cleanup command ready to run
- [x] Password validation enforced (backend)
- [x] Email validation enforced (backend)
- [x] Rate limiting active (100/hr anon, 1000/hr auth)
- [x] CORS configured (needs prod hardening)
- [x] AI learning active for feedback & wait times
- [x] All API endpoints documented
- [x] Flutter code examples provided
- [x] 4-week sprint plan created

**Next Action:** Run `cleanup_duplicate_users` command on backend, then proceed with Flutter Week 1 critical fixes.
