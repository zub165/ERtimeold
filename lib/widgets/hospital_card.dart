import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/django_api_service.dart';
import '../config/units_config.dart';
import '../screens/hospital_detail_screen.dart';

class HospitalCard extends StatelessWidget {
  final Hospital hospital;
  
  const HospitalCard({Key? key, required this.hospital}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          _showHospitalDetails(context);
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: hospital.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: hospital.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Icon(
                              Icons.local_hospital,
                              color: Colors.blue,
                              size: 30,
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.local_hospital,
                              color: Colors.blue,
                              size: 30,
                            ),
                          )
                        : Icon(
                            Icons.local_hospital,
                            color: Colors.blue,
                            size: 30,
                          ),
                  ),
                  SizedBox(width: 15),
                  
                  // Hospital Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hospital Name
                        Text(
                          hospital.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5),
                        
                        // Address
                        Text(
                          hospital.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        
                        // Rating and Distance
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: hospital.rating,
                              itemBuilder: (context, index) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 16.0,
                            ),
                            SizedBox(width: 8),
                            Text(
                              hospital.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              UnitsConfig.formatDistance(hospital.distance),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Wait Time (if available)
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getWaitTimeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getWaitTimeColor(),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: _getWaitTimeColor(),
                    ),
                    SizedBox(width: 6),
                    Text(
                      _getWaitTimeText(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _getWaitTimeColor(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Specialties
              if (hospital.specialties.isNotEmpty) ...[
                SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: hospital.specialties.take(3).map((specialty) => 
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getWaitTimeColor() {
    // This would normally use real wait time data
    // For now, using a mock wait time based on rating
    if (hospital.rating > 4.0) return Colors.green;
    if (hospital.rating > 3.0) return Colors.orange;
    return Colors.red;
  }
  
  String _getWaitTimeText() {
    // Mock wait time calculation based on rating and distance
    double baseWaitTime = 30.0; // Base wait time in minutes
    double ratingFactor = (5.0 - hospital.rating) * 10; // Higher rating = less wait
    double distanceFactor = hospital.distance * 2; // Further hospitals might be less busy
    
    int mockWaitTime = (baseWaitTime + ratingFactor - distanceFactor).round().clamp(5, 120);
    return 'Est. $mockWaitTime min wait';
  }
  
  void _showHospitalDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalDetailScreen(hospital: hospital),
      ),
    );
  }
  
  void _showOldHospitalDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              Text(
                hospital.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              
              Text(
                hospital.address,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              
              // Contact Info
              if (hospital.phone.isNotEmpty) ...[
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.blue),
                  title: Text(hospital.phone),
                  subtitle: Text('Tap to call'),
                  onTap: () {
                    // Implement phone call
                  },
                ),
              ],
              
              // Specialties
              if (hospital.specialties.isNotEmpty) ...[
                SizedBox(height: 20),
                Text(
                  'Specialties',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hospital.specialties.map((specialty) => 
                    Chip(
                      label: Text(specialty),
                      backgroundColor: Colors.blue[50],
                    ),
                  ).toList(),
                ),
              ],
              
              SizedBox(height: 30),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child:                   ElevatedButton.icon(
                    onPressed: () => _openDirections(context, hospital),
                    icon: Icon(Icons.directions),
                    label: Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callHospital(context, hospital),
                      icon: Icon(Icons.phone),
                      label: Text('Call'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  static void _openDirections(BuildContext context, Hospital hospital) async {
    try {
      // Try Google Maps app first
      final String googleMapsAppUrl = 
          'comgooglemaps://?daddr=${hospital.latitude},${hospital.longitude}&directionsmode=driving';
      
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        await launchUrl(
          Uri.parse(googleMapsAppUrl), 
          mode: LaunchMode.externalApplication
        );
        return;
      }
      
      // Final fallback to web Google Maps
      final String webMapsUrl = 
          'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}';
      
      if (await canLaunchUrl(Uri.parse(webMapsUrl))) {
        await launchUrl(
          Uri.parse(webMapsUrl), 
          mode: LaunchMode.externalApplication
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening directions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  static void _callHospital(BuildContext context, Hospital hospital) async {
    // Clean the phone number
    String cleanPhone = hospital.phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanPhone.startsWith('+') && cleanPhone.length == 10) {
      cleanPhone = '+1$cleanPhone';
    }
    
    final String phoneUrl = 'tel:$cleanPhone';
    
    try {
      if (await canLaunchUrl(Uri.parse(phoneUrl))) {
        await launchUrl(
          Uri.parse(phoneUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone: ${hospital.phone}'),
            backgroundColor: Colors.blue,
            action: SnackBarAction(
              label: 'Close',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone: ${hospital.phone}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}
