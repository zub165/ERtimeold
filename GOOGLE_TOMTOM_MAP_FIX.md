# Google Maps and TomTom Maps Not Showing - Fix

## Issue
The app was displaying OpenStreetMap instead of Google Maps or TomTom Maps, even when API keys were available.

## Root Cause
The `maps_screen.dart` was checking `AppConfig.googleMapsApiKey` and `AppConfig.tomtomApiKey` directly, but these static values were set only at app startup. If:
1. API keys were added via the API Key Settings screen after startup
2. API keys were loaded from Django backend but not properly refreshed
3. User-provided keys were stored but not loaded into `AppConfig`

Then the map screen would default to OpenStreetMap because it couldn't detect the available keys.

## Solution
Updated `maps_screen.dart` to:

1. **Refresh API keys on screen load**: Now calls `ApiKeyManager.getActiveGoogleMapsApiKey()` and `ApiKeyManager.getActiveTomTomApiKey()` when the screen initializes, ensuring it always has the latest keys.

2. **Store active keys in state**: Maintains `_activeGoogleKey` and `_activeTomTomKey` in the widget state, which are refreshed dynamically.

3. **Refresh button**: The refresh icon button now refreshes API keys in addition to reloading hospital markers.

4. **Better error messages**: When Google Maps or TomTom is selected but no API key is available, shows a clear error message directing users to add their API keys in Settings.

5. **Menu indicators**: The map provider selection menu now shows "(No API Key)" next to disabled options, making it clear why certain providers aren't available.

## How to Use Google Maps or TomTom Maps

### Option 1: Add Your Own API Keys (Recommended)
1. Go to **Settings** → **API Key Settings**
2. Enter your Google Maps API key (starts with `AIza...`)
3. Or enter your TomTom API key
4. Select your preferred map provider
5. Save settings
6. Open the Map screen - it will automatically use your keys

### Option 2: Use Django Backend Keys
If your Django backend provides API keys via `/api/map-configs/`, they will be automatically loaded at app startup. The map screen will refresh these keys when opened.

### Option 3: Manual Selection
1. Open the Map screen
2. Tap the map icon (🗺️) in the top-right corner
3. Select "Google Maps" or "TomTom Maps" from the menu
4. If keys are available, the map will switch immediately
5. If keys are missing, you'll see an error message with instructions

## Technical Changes

### Files Modified
- `lib/screens/maps_screen.dart`

### Key Changes
- Added `_refreshApiKeys()` method that loads active keys from `ApiKeyManager`
- Added state variables `_activeGoogleKey`, `_activeTomTomKey`, and `_keysLoaded`
- Updated `_selectMapProvider()` to use active keys instead of `AppConfig` directly
- Added error screens for Google Maps and TomTom when keys are missing
- Updated refresh button to refresh API keys
- Added "(No API Key)" indicators in the map provider menu

## Testing
After this fix:
1. ✅ Map screen refreshes API keys when opened
2. ✅ Google Maps displays when API key is available
3. ✅ TomTom Maps displays when API key is available
4. ✅ OpenStreetMap is used as fallback when no keys are available
5. ✅ Clear error messages guide users to add API keys
6. ✅ Refresh button updates both keys and markers

## Next Steps
1. **Add API Keys**: Go to Settings → API Key Settings and add your Google Maps or TomTom API keys
2. **Test Maps**: Open the Map screen and verify Google Maps or TomTom displays correctly
3. **Verify Refresh**: Use the refresh button to ensure keys are reloaded properly
