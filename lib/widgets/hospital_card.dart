import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/units_config.dart';
import '../services/django_api_service.dart';
import '../screens/hospital_detail_screen.dart';
import '../providers/hospital_provider.dart';

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
                        SizedBox(height: 4),
                        
                        // Phone Number (if available or show fallback) - Clickable
                        GestureDetector(
                          onTap: hospital.phone.isNotEmpty 
                            ? () => _callHospital(context, hospital)
                            : null,
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: hospital.phone.isNotEmpty 
                                  ? Colors.blue[600]
                                  : Colors.grey[500],
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hospital.phone.isNotEmpty 
                                    ? hospital.phone 
                                    : 'Phone: Not Available',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: hospital.phone.isNotEmpty 
                                      ? Colors.blue[600] 
                                      : Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                    decoration: hospital.phone.isNotEmpty 
                                      ? TextDecoration.underline 
                                      : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        // Rating and Distance (show "—" when backend sent null)
                        Row(
                          children: [
                            if (hospital.rating != null) ...[
                              RatingBarIndicator(
                                rating: (hospital.rating! / 2).clamp(0.0, 5.0),
                                itemBuilder: (context, index) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 16.0,
                              ),
                              SizedBox(width: 8),
                              Text(
                                hospital.rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else
                              Text(
                                '—',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
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
                              UnitsConfig.formatDistanceOrNull(hospital.distance),
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
              
              // Wait Time (backend when available; "—" when null per contract)
              SizedBox(height: 15),
              Builder(
                builder: (context) {
                  final minutes = _getWaitTimeMinutes(context);
                  final color = minutes != null ? _getWaitTimeColor(minutes) : Colors.grey;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 16, color: color),
                        SizedBox(width: 6),
                        Text(
                          _getWaitTimeText(context),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
  
  /// Wait time in minutes from backend (AI-enhanced) or provider (wait-times API), or null for mock.
  int? _getWaitTimeMinutes(BuildContext context) {
    if (hospital.estimatedWaitTimeMinutes != null) return hospital.estimatedWaitTimeMinutes;
    final wt = Provider.of<HospitalProvider>(context, listen: false).getWaitTime(hospital.id);
    if (wt != null && (wt.currentWaitTime > 0 || wt.averageWaitTime > 0)) {
      return wt.currentWaitTime > 0 ? wt.currentWaitTime : wt.averageWaitTime;
    }
    return null;
  }

  Color _getWaitTimeColor(int? waitMinutes) {
    final minutes = waitMinutes ?? _mockWaitTimeMinutes();
    if (minutes <= 15) return Colors.green;
    if (minutes <= 45) return Colors.orange;
    return Colors.red;
  }

  int _mockWaitTimeMinutes() {
    double baseWaitTime = 30.0;
    double ratingFactor = (5.0 - hospital.ratingOrZero) * 10;
    double distanceFactor = (hospital.distance ?? 0) * 2;
    return (baseWaitTime + ratingFactor - distanceFactor).round().clamp(5, 120);
  }

  String _getWaitTimeText(BuildContext context) {
    final backendMinutes = _getWaitTimeMinutes(context);
    if (backendMinutes != null) {
      return 'Est. $backendMinutes min wait';
    }
    return '—'; // Backend sent no wait time; show "—" per contract
  }
  
  void _showHospitalDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalDetailScreen(hospital: hospital),
      ),
    );
  }
  
  
  // ignore: unused_element - kept for future "Get directions" action
  void _openDirections(BuildContext context, Hospital hospital) async {
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
  
  void _callHospital(BuildContext context, Hospital hospital) async {
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
