# Workflow: ER Time Submission, Hospital Review Feedback & Hospital Search

This document describes how **ER wait time** and **hospital review feedback** are submitted from the Flutter app, how they are saved in the Django backend, and how **hospital search** works—with improvement recommendations for both frontend and backend.

---

## 1. Workflow: Submitting ER Time & Hospital Review Feedback

### 1.1 User flow (frontend)

1. **User opens a hospital**  
   From the main list (or map), user taps a hospital → `HospitalDetailScreen` opens.

2. **User fills the form**
   - **Rating**: 1–5 stars (optional half stars).
   - **Comment**: Free text (required).
   - **Wait time**: Slider 5 min–5+ hours (stored as `_waitTimeMinutes`).

3. **User taps “Submit Review & Wait Time”**  
   → `_submitReview()` runs.

4. **Single API call**  
   The app does **one** POST to the backend that sends both the **review** and the **ER wait time** together (no separate “ER time only” call in the current flow).

### 1.2 API call (Flutter → Django)

- **Endpoint**: `POST /api/feedback/submit/`  
  (Configured in Flutter as `DjangoApiService.feedbackEndpoint` → `AppConfig.djangoBaseUrl` + `feedback/submit/`.)

- **Method**: `submitEnhancedReview()` in `lib/services/django_api_service.dart`.

- **Body (summary)**:

  | Field                  | Source                    | Notes                                      |
  |------------------------|---------------------------|--------------------------------------------|
  | `hospital_id`          | `widget.hospital.id`      | UUID from hospital list/detail             |
  | `rating`               | `_userRating` (1–5)        | Overall rating                             |
  | `comment`              | `_userComment`            | Required                                   |
  | `wait_time`            | `_waitTimeMinutes`        | **ER wait time in minutes** (same payload) |
  | `user_location`        | Hospital lat,lng          | e.g. `"37.77,-122.41"`                     |
  | `care_quality`         | Derived from rating       | 1–5, required by backend                  |
  | `staff_friendliness`   | Derived from rating       | 1–5                                        |
  | `cleanliness`          | Derived from rating       | 1–5                                        |
  | `facility_modernity`   | Derived from rating       | 1–5                                        |
  | `visit_date`           | Today (YYYY-MM-DD)        |                                            |
  | `timestamp`            | ISO 8601                  |                                            |
  | `app_version`          | `AppConfig.version`       |                                            |
  | `platform`             | `"flutter"`               |                                            |

So: **ER time is submitted as part of the same feedback object** (`wait_time` in minutes). There is no separate “ER time only” endpoint used by the app right now.

### 1.3 How it is saved in the Django backend

- **URL**: Django route `submit_feedback` → `POST /api/feedback/submit/`.
- **Typical backend behavior** (what the API is expected to do):
  1. Validate `hospital_id` (UUID), required rating fields, and optionally `wait_time`.
  2. Create or update a **Feedback** (or equivalent) model row linked to the hospital.
  3. Store: hospital_id, ratings (care_quality, staff_friendliness, cleanliness, facility_modernity, wait_time as experience), comment, visit_date, timestamps, etc.
  4. Optionally: run AI/sentiment logic and update hospital aggregates (e.g. `ai_rating`, average wait time).
  5. Return JSON like:  
     `{ "status": "success", "message": "...", "feedback_id": "UUID", "overall_rating": ..., "ai_updated": true }`.

- **Important**: The same submission carries both “review” and “ER wait time” data; the backend should persist both (e.g. in one feedback record or in linked wait-time records, depending on your Django schema).

---

## 2. Workflow: Hospital Search

### 2.1 Current behavior (before improvement)

- **Frontend**: `MainScreen._searchHospitals()` uses `DjangoApiService.searchHospitals(lat, lng, radius)`.
- **API used**: `GET /api/hospitals/` (list endpoint)—**no** query parameters for location or radius.
- **Result**: Backend returns a **full list** of hospitals; the Flutter app then:
  - Parses the list.
  - Computes **distance** for each hospital (Haversine) and **filters by radius** on the client.
  - Sorts by distance and, if none in radius, shows the closest 20.

**Problems**:  
- Fetches more data than needed.  
- Search is not consistent with backend’s **search** API (e.g. `/api/hospitals/search/`), which can return different IDs or ordering.  
- Using list + client-side filter can lead to mismatches with feedback (e.g. hospital IDs from list vs search).

### 2.2 Improved behavior (recommended)

- **Frontend**: Call the **search** endpoint with user location and radius.
- **API**: `GET /api/hospitals/search/?lat=<lat>&lon=<lon>&radius_m=<meters>&limit=<n>`.
- **Backend**: Returns only hospitals within the given radius (or closest N), with consistent UUIDs. The app then just parses and displays; no client-side distance filter needed for correctness (optional display-only distance).

**Benefits**:  
- Less payload, faster and consistent with feedback (same hospital IDs as in search).  
- Backend can use DB/spatial indexing and one source of truth for “nearby”.

---

## 3. Summary: What is saved in Django

| What                | Where it is sent              | How it is saved (expected)                          |
|---------------------|-------------------------------|------------------------------------------------------|
| ER wait time        | `POST /api/feedback/submit/`  | In feedback record as `wait_time` (minutes)          |
| Hospital review     | Same request                  | Ratings + comment in same feedback record           |
| Optional (future)   | `POST /api/hospitals/wait-times/update/` or per-hospital `.../hospitals/<id>/update-wait-time/` | If you add “ER time only” flows, backend can persist to wait-time tables |

Right now, **one feedback submit = one record (or linked set) in Django that includes both ER time and review**.

---

## 4. Improvements: Frontend (Flutter)

- **Hospital search**
  - Use `GET /api/hospitals/search/?lat=&lon=&radius_m=&limit=` instead of `GET /api/hospitals/` + client-side filter.  
  - Pass `radius_m` as integer (e.g. `(radiusKm * 1000).round()`).  
  - Parse the same response shape (`status`, `data` list of hospitals with `id`, `name`, `latitude`, `longitude`, `ai_rating`, etc.).

- **Feedback / ER time**
  - Keep using a single `POST /api/feedback/submit/` with `wait_time` and all required category fields.  
  - Optional: add a dedicated “Report wait time only” flow that calls a wait-time update endpoint if the backend exposes one (e.g. `POST /api/hospitals/wait-times/update/` or `.../hospitals/<id>/update-wait-time/`).

- **UX**
  - Show loading and clear errors when submit or search fails.  
  - Optional: cache last search result and show “Updated at …” for stale data.

---

## 5. Improvements: Backend (Django)

- **Hospital search**
  - Ensure `GET /api/hospitals/search/` accepts `lat`, `lon`, `radius_m`, `limit` and returns `{ "status": "success", "data": [ { "id", "name", "address", "latitude", "longitude", "ai_rating", "phone", "specialties", ... } ] }`.  
  - Use database-level filtering (e.g. geo/distance) so only nearby hospitals are returned.  
  - Use integer `radius_m` (reject or coerce floats to avoid 500s).

- **Feedback / ER time**
  - Keep accepting `wait_time` (minutes) in `POST /api/feedback/submit/` and store it in the same feedback record (or linked wait-time table).  
  - Ensure `hospital_id` in feedback matches hospital IDs returned by `GET /api/hospitals/search/` (same UUIDs).  
  - Optional: expose a dedicated wait-time endpoint (e.g. `POST /api/hospitals/wait-times/update/` or per-hospital update) and document it for future “ER time only” submissions.

- **Consistency**
  - One source of truth for hospital IDs (e.g. search and list both use the same model and IDs).  
  - Return same field names the app expects (`ai_rating`, `latitude`, `longitude`, etc.).

---

## 6. Quick reference: API endpoints

| Purpose              | Method | Endpoint (example)                          | Used by app today   |
|----------------------|--------|---------------------------------------------|----------------------|
| Health               | GET    | `/api/health/`                               | Yes (debug/test)     |
| Hospital list        | GET    | `/api/hospitals/`                            | Yes (search today)   |
| Hospital search      | GET    | `/api/hospitals/search/?lat=&lon=&radius_m=&limit=` | Recommended for search |
| Submit feedback + ER time | POST | `/api/feedback/submit/`                     | Yes                  |
| List feedback        | GET    | `/api/feedback/`                             | Tests / future       |
| Wait time (per hospital) | GET  | `/api/hospitals/wait-times/?hospital_id=`    | Available in service |
| Update wait time (optional) | POST | `/api/hospitals/<id>/update-wait-time/` or `/api/hospitals/wait-times/update/` | Not used yet |

---

*Document generated for ER Time app — frontend (Flutter) and backend (Django) workflow and improvements.*
