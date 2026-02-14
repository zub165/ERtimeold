# Message for Frontend: How to Get REAL Backend Data

**Date:** February 14, 2026  
**From:** Backend Team  
**To:** Frontend Team  
**Subject:** Rating & Wait Time - Implementation Guide for Real Backend Data

---

## 🎯 Current Issue

### What Users See Now:
- **Rating**: 4.0 ⭐ (hardcoded for OpenStreetMap hospitals)
- **Wait Time**: "Est. ~34 min (from rating)" (calculated using fake formula)

### Why This Happens:
OpenStreetMap hospitals haven't been reviewed yet, so they don't exist in Django database. When no backend data exists, the app falls back to:
- Default 4.0 star rating
- Local calculation: `30 + (5 - rating) × 10 - distance × 2`

**Example:**
```
Wait Time = 30 + (5 - 4.0) × 10 - 1.8 × 2
          = 30 + 10 - 3.6
          = 36.4 minutes → ~34 min
```

---

## ✅ Good News: Backend is ALREADY READY!

The backend is **fully implemented and tested** to handle this workflow:

### What Happens When User Submits First Review:

```
1. User reviews "Valley Specialty Center" (from OpenStreetMap)
   ↓
2. ✅ Backend receives full hospital details in review payload
   ↓
3. ✅ Backend creates hospital record (OSM → Django DB)
   ↓
4. ✅ Backend saves the review
   ↓
5. ✅ AI calculates REAL rating (e.g., 4.2/5.0 or 8.4/10)
   ↓
6. ✅ AI predicts REAL wait time (e.g., 25 min)
   ↓
7. ✅ Next search returns enriched data!
   ↓
8. 🎉 Future users see: "Est. 25 min wait" (real AI prediction)
```

---

## 🔧 What Frontend Needs to Change

### Fix #1: Include Full Hospital Details in Reviews (2 hours)

**Current Review Payload:**
```dart
await _apiService.submitEnhancedReview(
  hospitalId: 'osm_node_12597079493',
  rating: 5.0,
  comment: 'Great service!',
  waitTimeMinutes: 30,
  userLocation: '37.3161,-121.9320',
);
```

**Updated Review Payload (Already Implemented! ✅):**
```dart
await _apiService.submitEnhancedReview(
  hospitalId: 'osm_node_12597079493',
  rating: 5.0,
  comment: 'Great service!',
  waitTimeMinutes: 30,
  userLocation: '37.3161,-121.9320',
  hospitalDetails: widget.hospital,  // ← Pass full hospital object!
);
```

**What Backend Receives:**
```json
{
  "hospital_id": "osm_node_12597079493",
  "rating": 5.0,
  "comment": "Great service!",
  "wait_time": 30,
  "hospital": {
    "id": "osm_node_12597079493",
    "name": "Valley Specialty Center",
    "address": "751 South Bascom Avenue, San Jose",
    "city": "San Jose",
    "state": "CA",
    "latitude": 37.315194,
    "longitude": -121.933286,
    "phone": "",
    "website": "https://example.com",
    "external_ids": {
      "osm_node": "12597079493",
      "source": "openstreetmap"
    }
  },
  "care_quality": 5,
  "staff_friendliness": 5,
  "cleanliness": 5,
  "facility_modernity": 5
}
```

**Backend Response:**
```json
{
  "status": "success",
  "data": {
    "review_id": "uuid-here",
    "ai_updated": true,  // ← Backend used this for AI predictions
    "hospital_created": true,  // ← New hospital added to DB
    "smart_wait_time": 25,  // ← AI prediction
    "ai_rating": 4.2  // ← AI-calculated rating
  }
}
```

**Status:** ✅ Already implemented in `lib/services/django_api_service.dart` and `lib/screens/hospital_detail_screen.dart`!

---

### Fix #2: Check for Backend Wait Time First (1 hour)

**Current Code (hospital_card.dart):**
```dart
String _getWaitTimeText(BuildContext context) {
  final backendMinutes = _getWaitTimeMinutes(context);
  final minutes = backendMinutes ?? _mockWaitTimeMinutes();
  if (backendMinutes != null) {
    return 'Est. $minutes min wait';  // Backend data
  }
  return 'Est. ~$minutes min (from rating)';  // Mock data
}
```

**How It Works:**
1. First checks `hospital.estimatedWaitTimeMinutes` (from backend)
2. Then checks `HospitalProvider.getWaitTime(hospital.id)` (from wait-times API)
3. Falls back to `_mockWaitTimeMinutes()` (local calculation)

**Backend Wait Time Fields** (checked in order):
```json
{
  "smart_wait_time": 25,        // #1 priority - AI prediction
  "current_wait_time": 30,      // #2 - Real-time data
  "estimated_wait_time": 28,    // #3 - Estimate
  "ai_estimated_wait": 27,      // #4 - AI estimate
  "predicted_wait_time": 26     // #5 - Prediction
}
```

**Status:** ✅ Already implemented in `lib/widgets/hospital_card.dart`!

---

### Fix #3: Fetch Real-Time Wait Prediction (1 hour) - OPTIONAL

**Add Smart Wait Time API Call:**
```dart
// In hospital_detail_screen.dart
Future<void> _fetchSmartWaitTime() async {
  final waitTime = await _apiService.getSmartWaitTime(widget.hospital.id);
  if (waitTime != null) {
    setState(() {
      _smartWaitTime = waitTime;
    });
  }
}
```

**Backend Endpoint:**
```
GET /api/hospitals/{hospital_id}/smart-wait-time/
```

**Response:**
```json
{
  "hospital_id": "osm_node_12597079493",
  "smart_wait_time": 25,
  "confidence": 0.87,
  "factors": {
    "recent_reviews": 5,
    "avg_reported_wait": 28,
    "time_of_day_factor": 0.9,
    "day_of_week_factor": 1.1,
    "weather_factor": 1.0
  },
  "last_updated": "2026-02-14T15:45:00Z"
}
```

**Status:** Not yet implemented in frontend (optional enhancement).

---

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────┐
│ User Reviews OpenStreetMap Hospital             │
└──────────────┬──────────────────────────────────┘
               ↓
┌─────────────────────────────────────────────────┐
│ Frontend: submitEnhancedReview()                │
│ - Sends full hospital details ✅                │
│ - Includes rating, comment, wait time           │
└──────────────┬──────────────────────────────────┘
               ↓
┌─────────────────────────────────────────────────┐
│ Backend: /api/feedback/submit/                  │
│ 1. Check if hospital exists in DB               │
│ 2. Create hospital if needed (OSM → Django) ✅  │
│ 3. Save review                                  │
│ 4. Run AI analysis                              │
│ 5. Calculate ai_rating                          │
│ 6. Predict smart_wait_time                      │
│ 7. Return ai_updated: true                      │
└──────────────┬──────────────────────────────────┘
               ↓
┌─────────────────────────────────────────────────┐
│ Next Search: /api/hospitals/search/             │
│ - Returns hospital with real AI data ✅         │
│ - ai_rating: 4.2 (not 4.0)                     │
│ - smart_wait_time: 25 (not calculated)          │
└──────────────┬──────────────────────────────────┘
               ↓
┌─────────────────────────────────────────────────┐
│ Frontend: Displays Real Data 🎉                 │
│ - "Rating: 4.2⭐" (from backend)                │
│ - "Est. 25 min wait" (from backend)             │
│ - No more "(from rating)" text                  │
└─────────────────────────────────────────────────┘
```

---

## ✅ Implementation Status

| Fix | Description | Status | Time | Priority |
|-----|-------------|--------|------|----------|
| #1 | Include hospital details in reviews | ✅ Done | 0 hours | Critical |
| #2 | Check for backend wait time first | ✅ Done | 0 hours | Critical |
| #3 | Smart wait time API call | ⏳ Optional | 1 hour | Low |

**Total time needed: 1 hour (optional enhancement only)**

---

## 🧪 Testing Instructions

### Test Case 1: Review OSM Hospital
1. Search for hospitals → See "Valley Specialty Center" (4.0⭐, ~34 min from rating)
2. Tap hospital → Open detail screen
3. Write review and submit
4. Check console for: `"ai_updated": true, "hospital_created": true`
5. Search again → Should still show 4.0⭐ (wait for next backend cycle)

### Test Case 2: Backend Data Display
1. Search hospitals
2. Find a Django hospital (not OSM) → Should show real rating (e.g., 4.2⭐)
3. Check wait time text → Should say "Est. 25 min wait" (no "from rating")

### Test Case 3: Fallback Behavior
1. Search hospitals
2. OSM hospital with no reviews → Shows 4.0⭐, "~34 min (from rating)"
3. Django hospital → Shows real rating, real wait time

---

## 🎯 Expected Results

### After First Review:
**Immediate (same session):**
- Review submits successfully ✅
- Console shows: `ai_updated: true` ✅
- User sees success dialog ✅

**After Backend Processing (next search):**
- Hospital now in Django DB ✅
- Has real `ai_rating` (e.g., 4.2) ✅
- Has `smart_wait_time` (e.g., 25 min) ✅
- Future searches return enriched data ✅

### Progressive Enhancement:
```
Review #1: OSM hospital → Django (4.0 → 5.0)
Review #2: Another user → AI updates (5.0 → 4.5)
Review #3: More data → Better prediction (4.5 → 4.2)
...
After 10 reviews: Highly accurate rating & wait time ✅
```

---

## 📋 API Reference

### Submit Review (Already Implemented)
```
POST /api/feedback/submit/
Content-Type: application/json
Authorization: Token <your-auth-token>

{
  "hospital_id": "osm_node_12597079493",
  "rating": 5.0,
  "comment": "Great service!",
  "wait_time": 30,
  "hospital": {
    "id": "osm_node_12597079493",
    "name": "Valley Specialty Center",
    "address": "751 South Bascom Avenue",
    "latitude": 37.315194,
    "longitude": -121.933286,
    "phone": "",
    "website": ""
  },
  "care_quality": 5,
  "staff_friendliness": 5,
  "cleanliness": 5,
  "facility_modernity": 5
}
```

### Search Hospitals (Returns Real Data)
```
GET /api/hospitals/search/?lat=37.3382&lon=-121.8863&radius_m=10000&limit=20&page=1

Response:
{
  "status": "success",
  "data": [
    {
      "id": "osm_node_12597079493",
      "name": "Valley Specialty Center",
      "ai_rating": 4.2,              // ← Real from backend
      "smart_wait_time": 25,          // ← Real AI prediction
      "current_wait_time": null,
      "distance": 1.16
    }
  ]
}
```

---

## 💡 Key Insights

### Why This Matters:
1. **User Trust**: Real data > fake data
2. **App Store Reviews**: "Wait times are accurate!" vs "Wait times are wrong"
3. **Competitive Advantage**: AI-powered predictions vs static estimates
4. **Backend Investment**: Your Django AI is ready - just use it!

### What Makes This Work:
- ✅ Backend creates hospitals on-the-fly from any source
- ✅ AI learns from every review
- ✅ Smart wait time uses multiple factors (reviews, time, weather, traffic)
- ✅ Progressive enhancement (better with more data)

---

## 🚀 Next Steps

1. **Verify Current Implementation** (15 min)
   - Test review submission for OSM hospital
   - Check console logs for `ai_updated: true`
   - Confirm hospital details are sent

2. **Optional Enhancement** (1 hour)
   - Add smart wait time API call to detail screen
   - Show loading state while fetching
   - Display confidence level

3. **Monitor Results** (ongoing)
   - Track how many OSM hospitals get reviewed
   - Monitor AI rating accuracy
   - Watch smart wait time predictions

---

## ❓ FAQ

**Q: Why does it still show 4.0 stars after I reviewed it?**  
A: The current search results are cached. Close and reopen the app, or search again to see updated data.

**Q: How long does AI take to update?**  
A: Instant! AI runs when you submit the review. Next search will return updated data.

**Q: What if multiple sources have the same hospital?**  
A: Backend deduplication merges them. OSM data + Django data = one enriched record.

**Q: Can users see which data is real vs fake?**  
A: Yes! Text shows:
- "Est. 25 min wait" = Real from backend
- "Est. ~25 min (from rating)" = Calculated locally

---

## ✅ Backend Status

**All endpoints working:** ✅  
**AI learning active:** ✅  
**Hospital creation:** ✅  
**Smart wait time:** ✅  
**Frontend integration:** ✅ (already done!)

**Backend team ready to support!** 🚀

---

## 📞 Support

For questions about backend API, data flow, or testing:
- Check `BACKEND_ENHANCEMENTS_LIST.md`
- Check `RATING_AND_WAITTIME_SOURCE.md`
- Test with: `test_apis.sh`

**Bottom line:** Backend is ready. Frontend is ready. Just needs users to start reviewing! 🎉
