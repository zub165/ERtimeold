import '../services/django_api_service.dart';
import 'dart:math';

class MockDataService {
  
  /// Generate mock hospitals for testing when Django backend is not available
  static List<Hospital> generateMockHospitals(double userLat, double userLng, double radius) {
    final Random random = Random();
    
    List<Hospital> mockHospitals = [];
    
    // Mock hospital names and specialties
    final List<Map<String, dynamic>> hospitalData = [
      {
        'name': 'City General Hospital',
        'specialties': ['Emergency Medicine', 'Trauma Care', 'Cardiology'],
        'phone': '+1 (555) 123-4567'
      },
      {
        'name': 'St. Mary\'s Medical Center',
        'specialties': ['Emergency Medicine', 'Pediatrics', 'Orthopedics'],
        'phone': '+1 (555) 234-5678'
      },
      {
        'name': 'University Hospital',
        'specialties': ['Emergency Medicine', 'Neurology', 'Surgery'],
        'phone': '+1 (555) 345-6789'
      },
      {
        'name': 'Community Health Center',
        'specialties': ['Emergency Medicine', 'Family Medicine'],
        'phone': '+1 (555) 456-7890'
      },
      {
        'name': 'Regional Medical Center',
        'specialties': ['Emergency Medicine', 'Trauma Care', 'ICU'],
        'phone': '+1 (555) 567-8901'
      },
      {
        'name': 'Children\'s Hospital',
        'specialties': ['Emergency Medicine', 'Pediatrics', 'NICU'],
        'phone': '+1 (555) 678-9012'
      },
      {
        'name': 'Heart & Vascular Center',
        'specialties': ['Emergency Medicine', 'Cardiology', 'Vascular Surgery'],
        'phone': '+1 (555) 789-0123'
      },
      {
        'name': 'Memorial Hospital',
        'specialties': ['Emergency Medicine', 'Oncology', 'Surgery'],
        'phone': '+1 (555) 890-1234'
      },
    ];
    
    for (int i = 0; i < hospitalData.length; i++) {
      final data = hospitalData[i];
      
      // Generate random coordinates within the radius
      double angle = random.nextDouble() * 2 * pi;
      double distance = random.nextDouble() * radius; // km
      
      // Convert distance to degrees (approximate)
      double latOffset = (distance / 111.0) * cos(angle);
      double lngOffset = (distance / (111.0 * cos(userLat * pi / 180))) * sin(angle);
      
      double hospitalLat = userLat + latOffset;
      double hospitalLng = userLng + lngOffset;
      
      // Generate random rating between 3.0 and 5.0
      double rating = 3.0 + random.nextDouble() * 2.0;
      
      // Calculate actual distance
      double actualDistance = _calculateDistance(userLat, userLng, hospitalLat, hospitalLng);
      
      mockHospitals.add(Hospital(
        id: 'mock_\$i',
        name: data['name'],
        address: '${100 + i * 50} Medical Plaza Dr, Health City, HC ${10000 + i}',
        latitude: hospitalLat,
        longitude: hospitalLng,
        distance: actualDistance,
        rating: double.parse(rating.toStringAsFixed(1)),
        phone: data['phone'],
        specialties: List<String>.from(data['specialties']),
        imageUrl: '', // No images for mock data
      ));
    }
    
    // Sort by distance
    mockHospitals.sort((a, b) => a.distance.compareTo(b.distance));
    
    return mockHospitals;
  }
  
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Get mock wait time for a hospital
  static WaitTime getMockWaitTime(String hospitalId) {
    final Random random = Random();
    
    int currentWait = 15 + random.nextInt(90); // 15-105 minutes
    int averageWait = 20 + random.nextInt(60); // 20-80 minutes
    
    String status;
    if (currentWait < 30) {
      status = 'Low';
    } else if (currentWait < 60) {
      status = 'Moderate';
    } else {
      status = 'High';
    }
    
    return WaitTime(
      hospitalId: hospitalId,
      currentWaitTime: currentWait,
      averageWaitTime: averageWait,
      lastUpdated: DateTime.now().toIso8601String(),
      status: status,
    );
  }
}
