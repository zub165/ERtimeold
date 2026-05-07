import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared Hospital model for the ER Time app
class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  /// Nullable because backend may not have an AI rating yet.
  final double? rating;
  final int? waitTimeMinutes; // Optional backend-provided wait time / prediction
  final String phone;
  final List<String> specialties;
  final String imageUrl;
  final String source; // Track which API provided this hospital
  final Map<String, String>? externalIds; // Optional provider IDs (google_place_id, tomtom_id, etc.)
  
  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.rating,
    this.waitTimeMinutes,
    required this.phone,
    required this.specialties,
    required this.imageUrl,
    this.source = 'unknown',
    this.externalIds,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    final ratingValue = _safeParseDouble(
          json['ai_rating_stars'] ??
              json['ai_rating'] ??
              json['rating'],
        );
    return Hospital(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Hospital',
      address: json['address'] ?? '',
      latitude: _safeParseDouble(json['latitude']) ?? 0.0,
      longitude: _safeParseDouble(json['longitude']) ?? 0.0,
      distance: _safeParseDouble(json['distance']) ?? 0.0,
      rating: ratingValue,
      waitTimeMinutes: _safeParseInt(
            json['wait_time_minutes'] ??
                json['wait_time_prediction'] ??
                json['current_wait_time'] ??
                json['wait_time'],
          ) ??
          _safeParseInt(json['wait_time_prediction']),
      phone: json['phone'] ?? '',
      specialties: List<String>.from(json['specialties'] ?? []),
      imageUrl: json['image_url'] ?? json['website'] ?? '',
      source: json['source'] ?? 'unknown',
      externalIds: json['external_ids'] == null
          ? null
          : Map<String, String>.from(
              (json['external_ids'] as Map).map(
                (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
              ),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      if (rating != null) 'rating': rating,
      if (waitTimeMinutes != null) 'wait_time_minutes': waitTimeMinutes,
      'phone': phone,
      'specialties': specialties,
      'image_url': imageUrl,
      'source': source,
      if (externalIds != null) 'external_ids': externalIds,
    };
  }

  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Get facility type priority for sorting
  /// Priority: 1 = Urgent Care, 2 = Hospital Emergency, 3 = Walk-in Clinic, 4 = Others
  int get facilityPriority {
    final nameLower = name.toLowerCase();
    final specialtiesLower = specialties.map((s) => s.toLowerCase()).join(' ');
    final combined = '$nameLower $specialtiesLower';
    
    // Priority 1: Urgent Care
    if (combined.contains('urgent care') || 
        combined.contains('urgentcare') ||
        combined.contains('urgent') && combined.contains('care')) {
      return 1;
    }
    
    // Priority 2: Hospital Emergency
    if (combined.contains('emergency') || 
        combined.contains('emergency room') ||
        combined.contains('er ') ||
        combined.contains('emergency department') ||
        combined.contains('emergency medicine') ||
        nameLower.contains('hospital') && combined.contains('emergency')) {
      return 2;
    }
    
    // Priority 3: Walk-in Clinic
    if (combined.contains('walk-in') || 
        combined.contains('walkin') ||
        combined.contains('walk in') ||
        (combined.contains('clinic') && !combined.contains('hospital'))) {
      return 3;
    }
    
    // Priority 4: All others (hospitals, medical centers, etc.)
    return 4;
  }

  /// Sort hospitals by priority (Urgent Care > Emergency > Walk-in > Others), then by distance
  static void sortByPriorityAndDistance(List<Hospital> hospitals) {
    hospitals.sort((a, b) {
      // First sort by priority (lower number = higher priority)
      final priorityCompare = a.facilityPriority.compareTo(b.facilityPriority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      // Within same priority, sort by distance
      return a.distance.compareTo(b.distance);
    });
  }
}

/// Opens driving directions without using [canLaunchUrl] (often false on cellular/VPN).
Future<bool> openHospitalDirections(Hospital hospital) async {
  final lat = hospital.latitude;
  final lon = hospital.longitude;
  final List<Uri> uris = <Uri>[
    Uri.parse('comgooglemaps://?daddr=$lat,$lon&directionsmode=driving'),
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      Uri.parse('google.navigation:q=$lat,$lon'),
    Uri.parse('https://maps.apple.com/?daddr=$lat,$lon'),
    Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
    ),
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      Uri.parse('geo:0,0?q=$lat,$lon'),
  ];

  for (final uri in uris) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}
    try {
      if (await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        return true;
      }
    } catch (_) {}
  }
  return false;
}
