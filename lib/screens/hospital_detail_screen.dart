import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/django_api_service.dart';
import '../config/app_config.dart';

class HospitalDetailScreen extends StatefulWidget {
  final Hospital hospital;
  
  const HospitalDetailScreen({Key? key, required this.hospital}) : super(key: key);
  
  @override
  _HospitalDetailScreenState createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  final DjangoApiService _apiService = DjangoApiService();
  double _userRating = 5.0;
  String _userComment = '';
  int _waitTimeMinutes = 30;
  bool _isSubmitting = false;
  
  final TextEditingController _commentController = TextEditingController();
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hospital Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Color(0xFF5DADE2),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.hospital.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF5DADE2),
                      Color(0xFF3498DB),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.local_hospital,
                  size: 100,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
          
          // Hospital Details
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Info Card
                  _buildInfoCard(),
                  SizedBox(height: 20),
                  
                  // Action Buttons
                  _buildActionButtons(),
                  SizedBox(height: 20),
                  
                  // ER Wait Time Section
                  _buildWaitTimeSection(),
                  SizedBox(height: 20),
                  
                  // Review Section
                  _buildReviewSection(),
                  SizedBox(height: 20),
                  
                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.hospital.address,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  widget.hospital.phone,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Rating: ${widget.hospital.rating.toStringAsFixed(1)}/5.0',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Spacer(),
                Text(
                  '${widget.hospital.distance.toStringAsFixed(1)} km away',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            if (widget.hospital.specialties.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Specialties:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.hospital.specialties.map((specialty) => 
                  Chip(
                    label: Text(specialty, style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blue[50],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openDirections,
            icon: Icon(Icons.directions),
            label: Text('Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5DADE2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _callHospital,
            icon: Icon(Icons.phone),
            label: Text('Call'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF5DADE2),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWaitTimeSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Color(0xFF5DADE2)),
                SizedBox(width: 8),
                Text(
                  'Report ER Wait Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'How long did you wait in the ER?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            
            // Wait Time Slider
            Row(
              children: [
                Text('5 min'),
                Expanded(
                  child: Slider(
                    value: _waitTimeMinutes.toDouble(),
                    min: 5,
                    max: 300,
                    divisions: 59,
                    activeColor: Color(0xFF5DADE2),
                    label: '$_waitTimeMinutes min',
                    onChanged: (value) {
                      setState(() {
                        _waitTimeMinutes = value.round();
                      });
                    },
                  ),
                ),
                Text('5+ hrs'),
              ],
            ),
            
            // Current Selection
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF5DADE2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF5DADE2)),
              ),
              child: Text(
                'Wait Time: ${_formatWaitTime(_waitTimeMinutes)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5DADE2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReviewSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review, color: Color(0xFF5DADE2)),
                SizedBox(width: 8),
                Text(
                  'Write a Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Rating
            Text(
              'Rate your experience:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            RatingBar.builder(
              initialRating: _userRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _userRating = rating;
                });
              },
            ),
            SizedBox(height: 16),
            
            // Comment
            Text(
              'Share your experience:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell others about your visit... (staff, cleanliness, wait time, etc.)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF5DADE2)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _userComment = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitReview,
        icon: _isSubmitting 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.send),
        label: Text(
          _isSubmitting ? 'Submitting to AI Backend...' : 'Submit Review & Wait Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF5DADE2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  String _formatWaitTime(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} $remainingMinutes min';
      }
    }
  }
  
  void _openDirections() async {
    try {
      // Try Google Maps app first
      final String googleMapsAppUrl = 
          'comgooglemaps://?daddr=${widget.hospital.latitude},${widget.hospital.longitude}&directionsmode=driving';
      
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        await launchUrl(
          Uri.parse(googleMapsAppUrl), 
          mode: LaunchMode.externalApplication
        );
        return;
      }
      
      // Fallback to Apple Maps on iOS or web Google Maps
      final String fallbackUrl = 
          'https://maps.apple.com/?daddr=${widget.hospital.latitude},${widget.hospital.longitude}';
      
      if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
        await launchUrl(
          Uri.parse(fallbackUrl), 
          mode: LaunchMode.externalApplication
        );
        return;
      }
      
      // Final fallback to web Google Maps
      final String webMapsUrl = 
          'https://www.google.com/maps/dir/?api=1&destination=${widget.hospital.latitude},${widget.hospital.longitude}';
      
      if (await canLaunchUrl(Uri.parse(webMapsUrl))) {
        await launchUrl(
          Uri.parse(webMapsUrl), 
          mode: LaunchMode.externalApplication
        );
      } else {
        _showErrorSnackBar('Could not open any maps application');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening directions: $e');
    }
  }
  
  void _callHospital() async {
    // Clean the phone number (remove any non-digits except +)
    String cleanPhone = widget.hospital.phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanPhone.startsWith('+') && cleanPhone.length == 10) {
      cleanPhone = '+1$cleanPhone'; // Add US country code if missing
    }
    
    final String phoneUrl = 'tel:$cleanPhone';
    
    try {
      if (await canLaunchUrl(Uri.parse(phoneUrl))) {
        await launchUrl(
          Uri.parse(phoneUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback - show a dialog with the phone number
        _showPhoneDialog(widget.hospital.phone);
      }
    } catch (e) {
      _showErrorSnackBar('Error making call: $e');
      _showPhoneDialog(widget.hospital.phone);
    }
  }
  
  void _showPhoneDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.phone, color: Color(0xFF5DADE2)),
            SizedBox(width: 8),
            Text('Hospital Phone'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Call this number:'),
            SizedBox(height: 8),
            SelectableText(
              phoneNumber,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5DADE2),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFF5DADE2))),
          ),
        ],
      ),
    );
  }
  
  void _submitReview() async {
    if (_userComment.trim().isEmpty) {
      _showErrorSnackBar('Please write a review comment');
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Submit to Django AI-enhanced backend
      bool success = await _apiService.submitEnhancedReview(
        hospitalId: widget.hospital.id,
        rating: _userRating,
        comment: _userComment.trim(),
        waitTimeMinutes: _waitTimeMinutes,
        userLocation: '${widget.hospital.latitude},${widget.hospital.longitude}',
      );
      
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar('Failed to submit review. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error submitting review: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Review Submitted!'),
          ],
        ),
        content: Text(
          'Thank you! Your review and wait time have been sent to our AI-enhanced system. This data will help improve hospital ratings and wait time predictions for other users.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to main screen
            },
            child: Text('OK', style: TextStyle(color: Color(0xFF5DADE2))),
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
