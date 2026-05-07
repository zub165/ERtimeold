import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/django_api_service.dart';
import '../models/hospital.dart';

class HospitalProvider with ChangeNotifier {
  List<Hospital> _hospitals = [];
  Map<String, WaitTime> _waitTimes = {};
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _favoriteIds = {};
  bool _favoritesLoaded = false;
  
  List<Hospital> get hospitals => _hospitals;
  Map<String, WaitTime> get waitTimes => _waitTimes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get favoriteIds => _favoriteIds;
  bool isFavorite(String hospitalId) => _favoriteIds.contains(hospitalId);
  
  void setHospitals(List<Hospital> hospitals) {
    _hospitals = hospitals;
    notifyListeners();
  }
  
  void addHospital(Hospital hospital) {
    _hospitals.add(hospital);
    notifyListeners();
  }
  
  void clearHospitals() {
    _hospitals.clear();
    _waitTimes.clear();
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    if (_favoritesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('favorite_hospital_ids') ?? const <String>[];
      _favoriteIds
        ..clear()
        ..addAll(ids);
      _favoritesLoaded = true;
      notifyListeners();
    } catch (_) {
      _favoritesLoaded = true;
    }
  }

  Future<void> toggleFavorite(String hospitalId) async {
    if (_favoriteIds.contains(hospitalId)) {
      _favoriteIds.remove(hospitalId);
    } else {
      _favoriteIds.add(hospitalId);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_hospital_ids', _favoriteIds.toList());
    } catch (_) {}
  }
  
  void setWaitTime(String hospitalId, WaitTime waitTime) {
    _waitTimes[hospitalId] = waitTime;
    notifyListeners();
  }
  
  WaitTime? getWaitTime(String hospitalId) {
    return _waitTimes[hospitalId];
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  // Sort hospitals by priority (Urgent Care > Emergency > Walk-in > Others), then by distance
  void sortByDistance() {
    Hospital.sortByPriorityAndDistance(_hospitals);
    notifyListeners();
  }
  
  // Sort hospitals by priority only (for explicit priority sorting)
  void sortByPriority() {
    Hospital.sortByPriorityAndDistance(_hospitals);
    notifyListeners();
  }
  
  // Sort hospitals by rating
  void sortByRating() {
    _hospitals.sort((a, b) {
      final ar = a.rating ?? -1;
      final br = b.rating ?? -1;
      return br.compareTo(ar);
    });
    notifyListeners();
  }
  
  // Filter hospitals by specialty
  List<Hospital> getHospitalsBySpecialty(String specialty) {
    return _hospitals.where((hospital) => 
      hospital.specialties.any((s) => 
        s.toLowerCase().contains(specialty.toLowerCase())
      )
    ).toList();
  }
}
