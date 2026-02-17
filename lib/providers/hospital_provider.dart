import 'package:flutter/foundation.dart';
import '../services/django_api_service.dart';

class HospitalProvider with ChangeNotifier {
  List<Hospital> _hospitals = [];
  Map<String, WaitTime> _waitTimes = {};
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Hospital> get hospitals => _hospitals;
  Map<String, WaitTime> get waitTimes => _waitTimes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  void setHospitals(List<Hospital> hospitals) {
    _hospitals = hospitals;
    notifyListeners();
  }

  void appendHospitals(List<Hospital> more) {
    _hospitals.addAll(more);
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
  
  // Sort hospitals by distance
  void sortByDistance() {
    _hospitals.sort((a, b) => a.distanceOrInfinity.compareTo(b.distanceOrInfinity));
    notifyListeners();
  }
  
  // Sort hospitals by rating
  void sortByRating() {
    _hospitals.sort((a, b) => b.ratingOrZero.compareTo(a.ratingOrZero));
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
