# Frontend Enhancement To-Do List (Step by Step)

Use this list to enhance the ER Time Flutter app in order. Each step is a concrete task you can implement and tick off.

---

## Phase 1: Loading & Error UX

- [x] **1.1** Add a clear loading indicator on `MainScreen` when `_searchHospitals()` is running (e.g. overlay or shimmer on the list area), and disable the search button while loading.
- [x] **1.2** Show a user-friendly error message (SnackBar or inline) when hospital search fails (network error or backend error), with an optional “Retry” action.
- [x] **1.3** On `HospitalDetailScreen`, show loading state on “Submit Review & Wait Time” button and disable form while submitting; show success/error SnackBar or dialog with clear copy.
- [ ] **1.4** On `SplashScreen`, handle “no network” or backend unreachable with a message and a “Retry” or “Continue anyway” option instead of hanging.

---

## Phase 2: Empty & Edge States

- [x] **2.1** On `MainScreen`, when `hospitalProvider.hospitals.isEmpty` after a successful search (not loading), show an empty state: illustration or icon + “No hospitals found in this area” and suggest increasing radius or trying another location.
- [ ] **2.2** When location permission is denied or unavailable, show a single, clear message with a “Open settings” / “Try again” action instead of only falling back to default location silently.
- [ ] **2.3** On `MapsScreen`, handle empty hospital list (e.g. show a message and a way to go back to search or refresh).

---

## Phase 3: Search & List UX

- [x] **3.1** Add pull-to-refresh on the hospital list (`MainScreen`) to trigger `_searchHospitals()` again without changing radius.
- [ ] **3.2** Display distance in the user’s chosen unit (mi/km) on each `HospitalCard` using `UnitsConfig.distanceUnit` and convert `hospital.distance` accordingly.
- [ ] **3.3** Add optional sort controls (e.g. “By distance” / “By rating”) that call `HospitalProvider.sortByDistance()` and `sortByRating()` and update the list.
- [ ] **3.4** Debounce or throttle rapid radius changes so that changing the radius slider doesn’t fire a new search on every tiny move (e.g. search on slider release or after 300ms idle).

---

## Phase 4: Hospital Detail & Feedback Form

- [ ] **4.1** If the backend provides wait time for the hospital (`getWaitTimes(hospitalId)`), show “Current reported wait: ~X min” (or similar) on `HospitalDetailScreen` when available.
- [x] **4.2** Add basic validation on the review form: minimum comment length (e.g. 10 chars) and show inline or SnackBar error before calling the API.
- [ ] **4.3** After a successful review submit, optionally clear the form (rating, comment, wait time) or show “Submit another” so the user can submit again without navigating away.
- [ ] **4.4** Ensure hospital name and address are visible and readable on `HospitalDetailScreen` (contrast, font size, truncation with “see more” if needed).

---

## Phase 5: Context & Stability (Async Safety)

- [x] **5.1** In `MainScreen._searchHospitals()`, after each `await`, check `if (!mounted) return;` before calling `setState` or `ScaffoldMessenger.of(context)`.
- [ ] **5.2** In `SplashScreen`, before any navigation or `ScaffoldMessenger` after `await`, check `if (!mounted) return;`.
- [ ] **5.3** In `MapSettingsScreen` and `MapsScreen`, add `mounted` checks after async work before using `context`.
- [ ] **5.4** In `HospitalCard` (e.g. `_openDirections`, `_callHospital`), check `mounted` (or pass context only when widget is still active) before showing SnackBar after `await`.

---

## Phase 6: Accessibility & Consistency

- [ ] **6.1** Add semantic labels or `Semantics` where it helps (e.g. search button “Search hospitals”, submit button “Submit review and wait time”, list “Hospital list”).
- [ ] **6.2** Ensure interactive elements have minimum tap target size (e.g. 48x48) where possible.
- [ ] **6.3** Replace deprecated `withOpacity` usages with `.withValues(alpha: ...)` (or equivalent) where the analyzer reports it, file by file.

---

## Phase 7: Optional Enhancements

- [ ] **7.1** Cache last hospital list in memory (or simple JSON cache) and show “Last updated at …” with a refresh button so users see something immediately on return to the list.
- [ ] **7.2** Add a “Report wait time only” flow (no full review) that calls a dedicated wait-time endpoint if the backend exposes one (e.g. `POST /api/hospitals/wait-times/update/`).
- [ ] **7.3** On API Key Settings screen, add a “Test connection” for the current map provider and show success/failure.
- [ ] **7.4** Add a simple onboarding or tooltip the first time the user opens the app (e.g. “Allow location to find nearby hospitals” and “You can submit wait time and review from each hospital’s page”).

---

## How to Use This List

1. Work in order: Phase 1 → 2 → 3 → … so that loading and errors are solid before adding features.
2. Tick each item when done: change `- [ ]` to `- [x]`.
3. If you need to split a task (e.g. 5.1–5.4 into separate PRs), add a short note under the task.
4. Link code changes to the task (e.g. in commit message: “Frontend: 1.1 – loading indicator on MainScreen”).

---

## Quick Reference: Main Files to Touch

| Phase | Main files |
|-------|------------|
| 1 | `main_screen.dart`, `hospital_detail_screen.dart`, `splash_screen.dart` |
| 2 | `main_screen.dart`, `maps_screen.dart`, `location_provider.dart` (or UI that shows permission state) |
| 3 | `main_screen.dart`, `hospital_card.dart`, `units_config.dart` |
| 4 | `hospital_detail_screen.dart`, `django_api_service.dart` (getWaitTimes) |
| 5 | `main_screen.dart`, `splash_screen.dart`, `map_settings_screen.dart`, `maps_screen.dart`, `hospital_card.dart` |
| 6 | All screens and widgets (semantics, tap targets, deprecation fixes) |
| 7 | Settings, main_screen (cache), hospital_detail_screen (wait-time-only), onboarding |

---

*Frontend enhancement to-do — ER Time Flutter app. Update this file as you complete or add tasks.*
