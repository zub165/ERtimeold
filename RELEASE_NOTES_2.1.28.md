# ER Wait Time – Version 2.1.28 Release Notes

**Release date:** January 28, 2026  
**Build:** 39

---

## What's new in 2.1.28

### Backend hospital data contract
- **Hospital list/search** aligned with backend fields and behavior.
- **Distance:** Uses `distance_km`, `distance_miles`, `distance_m`, `distance` (with fallback to computed distance when backend sends null).
- **Wait time:** Uses `wait_time_prediction`, `wait_time_minutes`, then existing fallbacks; shows **"—"** when backend sends null.
- **Rating:** Uses `ai_rating`, `rating`, `ai_rating_5`, `overall_performance_score`; shows **"—"** when null (no default 4.0).
- **List endpoint:** Sends `lat` and `lon` on `GET /api/hospitals/` so the backend can compute distance.

### UI behavior
- **"—" for missing data:** Distance, rating, and wait time show **"—"** when the backend does not provide a value (no fake numbers).
- **Distance:** `UnitsConfig.formatDistanceOrNull(double?)` used everywhere (list, detail, map).
- **Rating:** List and detail show **"—"** when rating is null; star display uses backend 1–10 scale as 5-star where present.

### Password reset
- **Forgot password** on login screen opens a reset flow.
- User enters email; app calls `POST /api/auth/password-reset/`.
- Success screen: “Check your email” with back-to-login.

### Delete account
- **Backend delete:** App calls `DELETE /api/auth/delete-account/` (and `POST` fallback) with auth token.
- **User feedback:** If the server does not accept the delete, user sees: “Account removed from this device. Server could not delete account—contact support@easytechnologiez.com to remove your data.”
- **Docs:** `BACKEND_DELETE_ACCOUNT.md` describes what the backend must implement.

### Debug screen
- **Debug Screen** moved into the **Settings** menu (Settings → Debug Screen) so it’s visible on all devices.

### Bug fixes and cleanup
- Unused variable in auth token validation removed.
- Unused import removed in hospital detail screen.
- Unused-element warning for `_openDirections` handled (method kept for possible future use).

---

## Build artifacts

### Android (AAB)
- **Path:** `build/app/outputs/bundle/release/app-release.aab`
- **Size:** ~50.6 MB
- **Version:** 2.1.28 (39)
- **Status:** Ready for Google Play upload

### iOS (IPA)
- **Path:** `build/ios/ipa/er_wait_time_flutter.ipa`
- **Size:** ~32.3 MB
- **Version:** 2.1.28 (39)
- **Status:** Ready for App Store upload (e.g. via Transporter)

---

## Testing

- **Static analysis:** `flutter analyze lib` (warnings addressed where practical; remaining are style/deprecation).
- **Emulator:** App run on iPhone 16e; backend connected, hospitals loaded, token validation and search verified.
- **Builds:** Release AAB and IPA built successfully.

---

## Documentation

- **FLUTTER_APP_HOSPITAL_EXPECTATIONS.md** – How the app uses backend hospital fields (order of preference, units, null → "—").
- **BACKEND_DELETE_ACCOUNT.md** – Backend requirements for the delete-account endpoint.

---

## Version summary

| Item        | 2.1.27 (38) | 2.1.28 (39) |
|------------|-------------|-------------|
| Version    | 2.1.27      | 2.1.28      |
| Build      | 38          | 39          |
| Hospital contract | No  | Yes (distance/rating/wait, "—") |
| Forgot password   | No  | Yes         |
| Delete-account feedback | No | Yes  |
| Debug in Settings | Yes | Yes  |

---

## Next steps

1. **Android:** Upload `app-release.aab` to Google Play Console.
2. **iOS:** Upload the IPA via Transporter (or Xcode Organizer).
3. **Backend:** Ensure `/api/auth/delete-account/` and `/api/auth/password-reset/` are implemented and return the expected status codes.
