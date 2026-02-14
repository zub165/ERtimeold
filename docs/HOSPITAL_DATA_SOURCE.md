# Where the Hospital List Comes From

## Short answer

**The app merges hospitals from all four sources:**

1. **Django backend** – Your database with reviews, ratings, wait times  
2. **OpenStreetMap** (Overpass API) – Free, no API key  
3. **TomTom** (POI Search) – Requires TomTom API key in Settings  
4. **Google Places** (Nearby Search) – Requires Google API key in Settings

All four are called in parallel (for page 1) and results are merged, deduplicated, and sorted by distance. For page 2+, only Django is called (OSM/TomTom/Google don't support pagination).

---

## Flow in the app

1. **Django:** `GET https://api.mywaitime.com/api/hospitals/search/?lat=...&lon=...&radius_m=...&limit=20&page=1` (+ Django list fallback).  
2. **OpenStreetMap:** `GET https://overpass-api.de/api/interpreter?data=[query]` – finds `amenity=hospital` and `healthcare=hospital` near your location.  
3. **TomTom:** `GET https://api.tomtom.com/search/2/poiSearch/hospital.json?lat=&lon=&radius=&key=` (if TomTom key is available).  
4. **Google Places:** `GET https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=&radius=&type=hospital&key=` (if Google key is available).

The app **waits for all to complete** (up to ~15s each), merges the results, removes duplicates (same location or very similar name), and shows the combined list sorted by distance.

---

## Deduplication

- If two hospitals are within **100 meters** of each other, they are considered the same (keeps the first).
- If two hospitals have **very similar names** (Levenshtein distance ≤ 2), they are considered the same (keeps the first).

So "City General Hospital" from Django and "City General Hospital" from OSM → only one is shown.

---

## Why you now see more hospitals

Before: Django only → 2 hospitals.  
Now: Django + OSM + TomTom + Google → e.g. 2 (Django) + 10 (OSM) + 5 (TomTom) + 8 (Google) = 25 hospitals (after dedup, e.g. 18).

---

## API keys

- **OpenStreetMap:** No key.  
- **TomTom & Google:** The app uses keys from **Settings** or **Django backend** (if configured). If neither is set, those sources are skipped.

---

## Summary

| Order | Source               | API key           | Behavior                     |
|-------|----------------------|-------------------|------------------------------|
| 1     | Django               | No (your backend) | Called every time            |
| 2     | OpenStreetMap        | No                | Called (page 1)              |
| 3     | TomTom POI           | Yes (optional)    | If key is set (page 1)       |
| 4     | Google Places        | Yes (optional)    | If key is set (page 1)       |

All results are **merged**, **deduplicated**, and **sorted by distance**. Map display still uses Google or TomTom tiles only.

---

## Why only 2 hospitals?

- The **Django backend** only has 2 hospitals in the database that match your location and radius, **or**
- The backend search/radius logic is strict and only returns 2 for that request.

So the limit is on the **backend data or backend search**, not on the app or on map APIs.

---

## What you can do

1. **In the app:** Increase the search radius (e.g. 10 km → 20 km or more) and search again. If the backend has more hospitals farther away, they will appear.

2. **On the backend:** Add more hospitals to the database, or implement a cascade so the backend itself fetches from other sources (e.g. OpenStreetMap, Google Places) and merges them with your DB. The app will then show whatever the backend returns.

---

## Summary

| Order | Hospital list source | API key needed |
|-------|----------------------|----------------|
| 1     | Django backend       | No (your backend) |
| 2     | OpenStreetMap (Overpass) | No |
| 3     | TomTom POI Search    | Yes (Settings or Django) |
| 4     | Google Places Nearby | Yes (Settings or Django) |
| Map display | Google Maps or TomTom | Yes |

The app tries each source in order and uses the first that returns at least one hospital. To get more results, increase the search radius or add a key for TomTom/Google in Settings so fallbacks can run when Django has few or no results.
