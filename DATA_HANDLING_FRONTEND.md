# How Data Is Handled in the Frontend (Flutter App)

This document describes data flow, storage, and backend sync in the ER Time Flutter app, plus a **to-do list** for testing and releases.

---

## 1. Data Sources and Storage

| Data | Where it lives | Persisted? | Backend sync |
|------|----------------|------------|--------------|
| **Location** | `LocationProvider` (in-memory) | No | No — used only for search and map |
| **Hospital list** | `HospitalProvider.hospitals` (in-memory) | No | Fetched via `GET /api/hospitals/search/` (or list fallback) |
| **Wait times (per hospital)** | `HospitalProvider.waitTimes` (in-memory) | No | Optional `GET /api/hospitals/wait-times/?hospital_id=` |
| **Auth token / email** | `AuthProvider` + SharedPreferences | Yes | Login via `POST /api/auth/login/`; token stored locally |
| **Map API keys & provider** | `ApiKeyManager` → SharedPreferences + `AppConfig` | Yes | Optional fetch from Django map-config; user can override |
| **Distance unit** | `UnitsConfig` (SharedPreferences) | Yes | No |
| **Feedback / ER time** | Not stored locally | No | Sent once via `POST /api/feedback/submit/` |

---

## 2. Data Flow Summary

1. **App start**  
   - `SplashScreen`: `AuthProvider.loadFromStorage()`, `ApiKeyManager.loadUserApiConfigurations()`, then optional Django map config.  
   - Then navigates to `LoginScreen` or `MainScreen` (if already logged in is not enforced in current flow; splash may go to main).

2. **Location**  
   - `MainScreen.initState()` → `_getCurrentLocation()` → `LocationProvider.getCurrentLocation()` (Geolocator).  
   - Result stored only in `LocationProvider` (in-memory). If permission fails, fallback to default (e.g. LA) for demo.

3. **Hospital search**  
   - `MainScreen._searchHospitals()` uses `LocationProvider.currentPosition` and `DjangoApiService.searchHospitals(lat, lng, radius)`.  
   - API: `GET /api/hospitals/search/?lat=&lon=&radius_m=&limit=` (fallback: `GET /api/hospitals/` + client filter).  
   - Result stored in `HospitalProvider.setHospitals(hospitals)` (in-memory). No local DB cache.

4. **Submit review + ER time**  
   - User on `HospitalDetailScreen` fills rating, comment, wait-time slider → "Submit Review & Wait Time".  
   - `_submitReview()` → `DjangoApiService.submitEnhancedReview(...)` → `POST /api/feedback/submit/`.  
   - Payload includes `wait_time` (minutes), rating, comment, and required category fields.  
   - **Not saved locally**; success/error only shown in UI.

5. **Auth**  
   - Login: `AuthProvider.login()` → Django login API → token and email saved in SharedPreferences and in `AuthProvider`.  
   - Logout: token (and should clear email) removed from prefs and memory.

6. **Map / API keys**  
   - Load: `ApiKeyManager.loadUserApiConfigurations()` reads SharedPreferences, sets `AppConfig.googleMapsApiKey`, `AppConfig.tomtomApiKey`, and map provider.  
   - Save: API Key Settings screen writes keys and preferred provider to SharedPreferences and `AppConfig`.

---

## 3. To-Do List (Frontend)

**Step-by-step enhancement tasks:** see **[FRONTEND_ENHANCEMENT_TODO.md](FRONTEND_ENHANCEMENT_TODO.md)** for phased tasks (loading/error UX, empty states, search/list, detail/feedback form, async safety, accessibility, optional features).

- [ ] **Testing**
  - [ ] Run app in Android emulator: `flutter run` (or choose device).
  - [ ] Run app in iOS simulator: `flutter run` (select iOS device).
  - [ ] Test: location → search → open hospital → submit review & wait time → verify success message and backend receives data.
  - [ ] Test: API Key Settings save/load and map provider switch.
  - [ ] Test: logout clears token and email (and UI reflects logged-out state if applicable).
- [ ] **Bugs / Cleanup**
  - [ ] Fix any `flutter analyze` issues.
  - [ ] Ensure `AuthProvider.logout()` clears `auth_email` from SharedPreferences and sets `_email = null`.
  - [ ] Align `AppConfig.version` / `versionCode` with `pubspec.yaml` for store builds.
- [ ] **Release**
  - [ ] Bump version in `pubspec.yaml` (e.g. 2.0.7+7).
  - [ ] Build Android App Bundle: `flutter build appbundle`.
  - [ ] Build iOS IPA: `flutter build ipa` (with signing).
  - [ ] Submit AAB to Google Play and IPA to App Store Connect.

---

## 4. Key Files

| Purpose | File |
|--------|------|
| App entry, providers | `lib/main.dart` |
| Location state | `lib/providers/location_provider.dart` |
| Hospital list state | `lib/providers/hospital_provider.dart` |
| Auth state + persistence | `lib/providers/auth_provider.dart` |
| API keys + map provider persistence | `lib/services/api_key_manager.dart` |
| Backend API (search, feedback, auth) | `lib/services/django_api_service.dart` |
| App constants, version, subscription IDs | `lib/config/app_config.dart` |
| In-app subscription ($3.99/mo after 30 searches) | `lib/services/billing_service.dart`, `lib/providers/subscription_provider.dart` |
| Splash, load storage | `lib/screens/splash_screen.dart` |
| Search, list UI | `lib/screens/main_screen.dart` |
| Review + ER time submit | `lib/screens/hospital_detail_screen.dart` |

---

*Last updated for ER Time Flutter app — data handling and release to-do.*
