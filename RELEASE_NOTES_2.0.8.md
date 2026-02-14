# ER Wait Time - Version 2.0.8 Release Notes

## 🎉 What's New

### Major Features

#### 1. 🗺️ Multiple Map Providers
- **OpenStreetMap** (default - no API key required)
- **Google Maps** (optional - requires API key)
- **TomTom Maps** (optional - requires API key)
- Easy switching between map providers via menu

#### 2. 🏥 Enhanced Hospital Data
- Added **city** and **state** fields to all hospitals
- Better address information for external API hospitals
- Improved data completeness for review submissions

#### 3. 📍 Multi-Source Hospital Search
- **Django Backend** (primary source with AI features)
- **OpenStreetMap** (free, no API key required)
- **TomTom POI Search** (optional)
- **Google Places** (optional)
- Automatic merge and deduplication of results

#### 4. ⭐ Real-Time AI Ratings
- Backend AI processes reviews and calculates ratings
- Smart wait time predictions based on:
  - Historical data
  - Current reviews
  - Traffic conditions
  - Weather data
  - Time of day patterns

#### 5. 📏 Distance Units Toggle
- Switch between Miles and Kilometers
- Preference persists across app restarts
- Applies to all distance displays

### Improvements

#### Authentication
- Simplified registration (email only, no name required)
- Resolved duplicate user issues
- More reliable token-based authentication
- Better error messages

#### Review System
- Fixed review submission for external API hospitals
- Enhanced payload with complete hospital details
- City and state now included for better backend processing
- Better support for creating new hospital records

#### Maps
- Interactive hospital markers on all map types
- Info windows showing hospital name, rating, and distance
- Automatic map provider selection based on API key availability
- Smooth map controls and centering

#### User Interface
- Consistent distance unit display
- Improved hospital cards
- Better loading states
- Enhanced error handling

### Bug Fixes
- ✅ Fixed distance unit display (was stuck in km)
- ✅ Fixed review submission for OpenStreetMap hospitals
- ✅ Fixed city/state extraction from addresses
- ✅ Improved API error handling
- ✅ Fixed map provider switching

---

## 🔧 Technical Details

### Backend Integration
- Django REST API: `https://api.mywaitime.com/api`
- Token-based authentication
- PostgreSQL/MySQL database
- AI-powered wait time predictions
- Real-time rating calculations

### API Support
- OpenStreetMap (Overpass API)
- TomTom POI Search API
- Google Places Nearby Search API
- Dynamic API key management

### Data Sources
- **Ratings**: Backend AI calculates from user reviews (defaults to 4.0 for new hospitals)
- **Wait Times**: AI predictions when available, local calculation as fallback
- **Hospital Details**: Merged from multiple sources with deduplication

---

## 📱 Compatibility

- **iOS**: 12.0+
- **Android**: API 21+ (Android 5.0 Lollipop)
- **Flutter**: 3.8.1
- **Dart SDK**: ^3.8.1

---

## 🚀 Getting Started

### First Time Users
1. Allow location permissions
2. App loads nearby hospitals automatically
3. Optionally add API keys in Settings for Google Maps/TomTom
4. Browse hospitals, check wait times, submit reviews

### Submitting Reviews
1. Select a hospital
2. Rate your experience (1-5 stars)
3. Add wait time (5 min to 5+ hours)
4. Write a comment (minimum 10 characters)
5. Submit - AI processes your feedback!

### Switching Map Providers
1. Tap the map provider icon in top right
2. Select OpenStreetMap, Google Maps, or TomTom
3. Note: Google and TomTom require API keys

---

## ⚠️ Known Issues

### Rate Limiting
The backend has rate limiting to prevent spam. If you submit multiple reviews quickly, you may see:
> "Request was throttled. Expected available in X seconds."

**Solution**: Wait 1-2 minutes between submissions.

### Initial Ratings
New hospitals from external APIs start with a default 4.0 rating until users submit reviews. Once reviewed:
- Backend AI calculates real ratings
- Wait times become AI-predicted
- Data improves over time

---

## 🔒 Privacy & Security

- No API keys hardcoded in the app
- Keys loaded from backend or user input
- Location used only for nearby hospital search
- Reviews submitted anonymously (email associated with account only)
- Secure HTTPS communication

---

## 📞 Support

- **Email**: support@easytechnologiez.com
- **Website**: https://mywaitime.com
- **Privacy Policy**: https://mywaitime.com/privacy

---

## 🙏 Thank You!

Thank you for using ER Wait Time! Your reviews help other patients make informed decisions about where to seek emergency care.

---

## Version History

### 2.0.8+8 (Current)
- Multiple map providers (OSM, Google, TomTom)
- City/state fields for all hospitals
- Enhanced review submission
- Distance unit toggle fix
- Multi-source hospital search

### 2.0.7+7
- Django backend integration
- Token authentication
- Basic hospital search
- Review submission
- Initial release

---

**Release Date**: February 14, 2026  
**Build**: 2.0.8+8  
**Package**: com.easytechnologiez.ERTime
