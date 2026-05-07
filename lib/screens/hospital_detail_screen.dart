import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/django_api_service.dart';
import '../services/local_review_service.dart';
import '../models/hospital.dart';
import '../services/auto_sync_service.dart';
import '../widgets/sync_status_widget.dart';

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
  bool _isSyncingNow = false;
  bool _isLoadingPredictedWait = false;
  int? _predictedWaitMinutes;
  
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPredictedWaitTime();
  }

  Future<void> _loadPredictedWaitTime() async {
    setState(() {
      _isLoadingPredictedWait = true;
    });
    final m = await _apiService.getSmartWaitTimeMinutes(widget.hospital.id);
    if (!mounted) return;
    setState(() {
      _predictedWaitMinutes = m;
      _isLoadingPredictedWait = false;
      if (m != null && m > 0) {
        _waitTimeMinutes = m;
      }
    });
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hospital Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: primary,
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
                      primary,
                      Theme.of(context).colorScheme.secondary,
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

                  // Review sync status
                  _buildSyncSection(),
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

  Widget _buildSyncSection() {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Expanded(child: SyncStatusWidget(showDetails: true)),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isSyncingNow
                  ? null
                  : () async {
                      setState(() => _isSyncingNow = true);
                      try {
                        await AutoSyncService.forceSync();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sync started. Pending reviews will upload in background.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not start sync.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isSyncingNow = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                surfaceTintColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: _isSyncingNow
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Sync now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
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
                  widget.hospital.phone.isNotEmpty 
                    ? widget.hospital.phone 
                    : 'Phone: Not Available',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.hospital.phone.isNotEmpty 
                      ? Colors.black 
                      : Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  widget.hospital.rating != null
                      ? 'Rating: ${widget.hospital.rating!.toStringAsFixed(1)}/5.0'
                      : 'Rating: No rating yet',
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
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openDirections,
            icon: Icon(Icons.directions),
            label: Text('Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
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
              foregroundColor: primary,
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
    final primary = Theme.of(context).colorScheme.primary;
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
                Icon(Icons.access_time, color: primary),
                SizedBox(width: 8),
                Text(
                  'ER Wait Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if (_isLoadingPredictedWait)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (_predictedWaitMinutes != null && _predictedWaitMinutes! > 0)
              Text(
                'Predicted: ${_formatWaitTime(_predictedWaitMinutes!)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
              )
            else if (!_isLoadingPredictedWait)
              Text(
                'Wait time unavailable',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                    activeColor: primary,
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
                color: primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary),
              ),
              child: Text(
                'Wait Time: ${_formatWaitTime(_waitTimeMinutes)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReviewSection() {
    final primary = Theme.of(context).colorScheme.primary;
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
                Icon(Icons.rate_review, color: primary),
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
                  borderSide: BorderSide(color: primary),
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
    final primary = Theme.of(context).colorScheme.primary;
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
          backgroundColor: primary,
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
      final ok = await openHospitalDirections(widget.hospital);
      if (ok) return;
      _showErrorSnackBar(
        'Could not open maps. On iPhone: Settings → Cellular → allow Safari (or Chrome). Install Google Maps for best results.',
      );
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
    final primary = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.phone, color: primary),
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
                color: primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: primary)),
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
      // First, save review locally for offline-first approach
      print('💾 Saving review locally...');
      final reviewId = await LocalReviewService.saveReviewLocally(
        hospitalId: widget.hospital.id,
        hospitalName: widget.hospital.name,
        rating: _userRating,
        comment: _userComment.trim(),
        waitTimeMinutes: _waitTimeMinutes,
        userLocation: '${widget.hospital.latitude},${widget.hospital.longitude}',
        externalIds: widget.hospital.externalIds,
      );
      
      if (reviewId > 0) {
        print('✅ Review saved locally with ID: $reviewId');
        
        // Show success message immediately (local-first approach)
        _showSuccessDialog();
        
        // Attempt to sync with Django backend in background
        _syncReviewInBackground(reviewId);
        
      } else {
        _showErrorSnackBar('Failed to save review locally. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving review: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  /// Sync review with Django backend in background
  void _syncReviewInBackground(int reviewId) async {
    try {
      print('🔄 Syncing review $reviewId with Django backend...');
      
      // Get the review data
      final reviews = await LocalReviewService.getPendingReviews();
      final matches = reviews.where((r) => r['id'] == reviewId);
      if (matches.isEmpty) {
        print('⚠️ Review $reviewId not found in pending list — may have already synced');
        return;
      }
      final review = matches.first;
      
      // Optional: Call dedup preview to get best match
      Map<String, String>? externalIds;
      try {
        final preview = await _apiService.dedupPreview(
          name: widget.hospital.name,
          city: widget.hospital.address.split(',').length > 1 ? widget.hospital.address.split(',')[1].trim() : null,
          state: widget.hospital.address.split(',').length > 2 ? widget.hospital.address.split(',')[2].trim() : null,
          latitude: widget.hospital.latitude,
          longitude: widget.hospital.longitude,
          address: widget.hospital.address,
          externalIds: widget.hospital.externalIds,
        );
        
        if (preview != null && preview['best_match'] != null) {
          final bestMatch = preview['best_match'] as Map<String, dynamic>;
          if (bestMatch['hospital_id'] != null) {
            print('✅ Dedup preview found best match: ${bestMatch['hospital_id']}');
            // Use the matched hospital ID for submission
            review['hospital_id'] = bestMatch['hospital_id'].toString();
          }
          if (bestMatch['external_ids'] != null) {
            externalIds = Map<String, String>.from(bestMatch['external_ids']);
          }
        }
      } catch (e) {
        print('⚠️ Dedup preview failed, using original hospital ID: $e');
      }
      
      // Attempt to sync with Django backend
      final success = await _apiService.submitEnhancedReview(
        hospitalId: review['hospital_id'],
        rating: review['rating'],
        comment: review['comment'],
        waitTimeMinutes: review['wait_time'],
        userLocation: review['user_location'],
        externalIds: externalIds,
      );
      
      if (success) {
        // Mark as synced
        await LocalReviewService.markReviewAsSynced(reviewId);
        print('✅ Review $reviewId synced with Django backend');
        
        // Also store user activity to backend
        try {
          await _apiService.submitUserActivity(
            activity: 'review_submitted',
            details: 'User submitted review and wait time for ${widget.hospital.name}',
            hospitalId: widget.hospital.id,
            metadata: {
              'rating': _userRating,
              'wait_time_minutes': _waitTimeMinutes,
              'comment_length': _userComment.trim().length,
              'hospital_name': widget.hospital.name,
              'local_review_id': reviewId,
            },
          );
          print('✅ User activity stored to backend');
        } catch (e) {
          print('⚠️ Could not store user activity: $e');
        }
      } else {
        // Mark sync attempt failed
        await LocalReviewService.incrementSyncAttempts(reviewId, 'API call failed');
        print('⚠️ Review $reviewId sync failed, will retry later');
      }
    } catch (e) {
      // Mark sync attempt failed
      await LocalReviewService.incrementSyncAttempts(reviewId, e.toString());
      print('❌ Error syncing review $reviewId: $e');
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
          'Thank you! Your review has been saved and will be sent to our AI-enhanced system for analysis. This data will help improve hospital ratings and wait time predictions for other users.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to main screen
            },
            child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
