enum DistanceUnit { kilometers, miles }

class UnitsConfig {
  static DistanceUnit _distanceUnit = DistanceUnit.kilometers;
  
  static DistanceUnit get distanceUnit => _distanceUnit;
  
  static void setDistanceUnit(DistanceUnit unit) {
    _distanceUnit = unit;
  }
  
  static String formatDistance(double distanceInKm) {
    if (_distanceUnit == DistanceUnit.miles) {
      double miles = distanceInKm * 0.621371;
      return '${miles.toStringAsFixed(1)} mi';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }
  
  static String getDistanceUnitString() {
    return _distanceUnit == DistanceUnit.miles ? 'miles' : 'km';
  }
  
  static String getDistanceUnitAbbr() {
    return _distanceUnit == DistanceUnit.miles ? 'mi' : 'km';
  }
  
  static double convertToDisplayUnit(double distanceInKm) {
    if (_distanceUnit == DistanceUnit.miles) {
      return distanceInKm * 0.621371;
    }
    return distanceInKm;
  }
  
  static double convertFromDisplayUnit(double distance) {
    if (_distanceUnit == DistanceUnit.miles) {
      return distance / 0.621371; // Convert miles to km
    }
    return distance;
  }
}
