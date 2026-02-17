# Flutter App – Hospital Data Contract

**Backend:** `https://api.mywaitime.com/api`  
**Endpoints:** `GET /api/hospitals/`, `GET /api/hospitals/search/`

This document describes how the ER Time Flutter app reads and displays hospital list/search response fields (order of preference, units, and fallbacks).

---

## Request: Always Send Location When Available

- **List:** `GET /api/hospitals/?lat=<lat>&lon=<lon>&page=1&page_size=20`
- **Search:** `GET /api/hospitals/search/?lat=<lat>&lon=<lon>&radius_m=<m>&limit=20`

The app sends `lat` and `lon` (user location) on both endpoints so the backend can compute distance. If the app has no location, it still calls the API but distance fields may be `null` and the app will show "—" for distance.

---

## Distance (stored in km internally)

| Backend field      | Unit  | App behavior |
|--------------------|-------|--------------|
| `distance_km`      | km    | Use as-is (preferred). |
| `distance_miles`   | miles | Convert to km (× 1.60934). |
| `distance_m`       | meters| Convert to km (÷ 1000). |
| `distance`         | miles | Treated as miles, convert to km. |

- **Preference:** `distance_km` → `distance_miles` (then convert) → `distance_m` → `distance` (miles).
- If all are `null`: app uses "—" for distance (or computes from lat/lon when user location is available).
- **Display:** Stored value is converted to user’s unit (miles/km) via `UnitsConfig`; if no value, show "—".

---

## Wait time (minutes)

| Backend field           | App behavior |
|-------------------------|--------------|
| `wait_time_prediction`  | Use (preferred). |
| `wait_time_minutes`     | Use (alias). |
| `smart_wait_time`       | Fallback. |
| `current_wait_time`     | Fallback. |
| `estimated_wait_time`   | Fallback. |

- **Preference:** `wait_time_prediction` → `wait_time_minutes` → `smart_wait_time` → others.
- If missing: `null` → app shows "—" (no fake estimate).

---

## Rating (1–10 scale internally; stars from 1–5)

| Backend field                 | Scale | App behavior |
|------------------------------|--------|--------------|
| `ai_rating`                  | 1–10   | Use as-is (preferred). |
| `rating`                     | 1–10   | Use as alias. |
| `ai_rating_5`               | 1–5    | Convert to 1–10 (× 2) for internal scale. |
| `overall_performance_score`  | any    | Use as fallback. |

- **Preference:** `ai_rating` → `rating` → `ai_rating_5` (× 2) → `overall_performance_score`.
- If missing: `null` → app shows "—" (no default 4.0).
- **Display:** Stored as 1–10; star UI uses value/2 (1–5). If null, show "—".

---

## Null handling

- **Distance:** `null` → show "—" (no `0.0 mi` when backend didn’t send distance).
- **Wait time:** `null` → show "—" (no local mock when backend has no data).
- **Rating:** `null` → show "—" (no default 4.0).

---

## Cache and refresh

- If the app shows `0.0 mi` or wrong distance after location is available: **pull to refresh** on the Emergency tab so a new request is made with current lat/lon and the list is updated with backend distances.
- Display: prefer backend fields when present; use "—" when the value is `null`.
