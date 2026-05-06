import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../config/units_config.dart';
import '../config/production_mode_config.dart';
import '../models/hospital.dart';
import '../screens/hospital_detail_screen.dart';
import '../providers/hospital_provider.dart';

class HospitalCard extends StatelessWidget {
  final Hospital hospital;
  
  const HospitalCard({Key? key, required this.hospital}) : super(key: key);

  // Interstitial policy: show at most every N hospital opens, with cooldown.
  static int _hospitalOpenCount = 0;
  static DateTime? _lastInterstitialShownAt;
  static InterstitialAd? _cachedInterstitial;
  static bool _isLoadingInterstitial = false;

  static String _androidInterstitialUnitId() {
    // Use test interstitial in debug; real unit in release.
    const bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    if (isDebugMode) return 'ca-app-pub-3940256099942544/1033173712';
    return ProductionModeConfig.androidInterstitialAdUnitId;
  }

  static Future<void> _preloadInterstitialIfNeeded() async {
    if (!Platform.isAndroid) return;
    if (!ProductionModeConfig.enableInterstitialAds) return;
    if (_cachedInterstitial != null) return;
    if (_isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    try {
      await InterstitialAd.load(
        adUnitId: _androidInterstitialUnitId(),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _cachedInterstitial = ad;
            _isLoadingInterstitial = false;
          },
          onAdFailedToLoad: (error) {
            _cachedInterstitial = null;
            _isLoadingInterstitial = false;
            debugPrint('Interstitial failed to load: $error');
          },
        ),
      );
    } catch (e) {
      _cachedInterstitial = null;
      _isLoadingInterstitial = false;
      debugPrint('Interstitial load threw: $e');
    }
  }

  static Future<void> _maybeShowInterstitial(BuildContext context) async {
    if (!Platform.isAndroid) return;
    if (!ProductionModeConfig.enableInterstitialAds) return;

    _hospitalOpenCount++;

    // Show every 3rd hospital open, with a 60s cooldown.
    if (_hospitalOpenCount % 3 != 0) {
      await _preloadInterstitialIfNeeded();
      return;
    }

    final lastShown = _lastInterstitialShownAt;
    if (lastShown != null && DateTime.now().difference(lastShown) < const Duration(seconds: 60)) {
      await _preloadInterstitialIfNeeded();
      return;
    }

    // Ensure we have an ad loaded.
    await _preloadInterstitialIfNeeded();
    final ad = _cachedInterstitial;
    if (ad == null) return;
    _cachedInterstitial = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _lastInterstitialShownAt = DateTime.now();
        _preloadInterstitialIfNeeded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _lastInterstitialShownAt = DateTime.now();
        _preloadInterstitialIfNeeded();
      },
    );

    try {
      await ad.show();
    } catch (_) {
      // If show fails, just dispose and continue.
      ad.dispose();
      _preloadInterstitialIfNeeded();
    }
  }

  /// `canLaunchUrl` is unreliable (often `false` on cellular/VPN while `launchUrl` still works).
  static Future<bool> _launchUriReliably(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
    } catch (_) {}
    try {
      if (await launchUrl(uri, mode: LaunchMode.platformDefault)) return true;
    } catch (_) {}
    return false;
  }
  
  @override
  Widget build(BuildContext context) {
    final isFav = context.select<HospitalProvider, bool>(
      (p) => p.isFavorite(hospital.id),
    );
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
                  IconButton(
                    onPressed: () => context.read<HospitalProvider>().toggleFavorite(hospital.id),
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber[700] : Colors.grey[500],
                    ),
                    tooltip: isFav ? 'Unfavorite' : 'Favorite',
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

              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openDirections(context, hospital),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openGoogleSearch(context, hospital),
                    icon: const Icon(Icons.search),
                    label: const Text('Google'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                ],
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
    final wt = hospital.waitTimeMinutes;
    if (wt != null && wt > 0) {
      return '$wt min wait (est.)';
    }
    // Fallback mock wait time calculation based on rating and distance
    final baseWaitTime = 30.0;
    final ratingFactor = (5.0 - hospital.rating) * 10;
    final distanceFactor = hospital.distance * 2;
    final mockWaitTime = (baseWaitTime + ratingFactor - distanceFactor).round().clamp(5, 120);
    return 'Est. $mockWaitTime min wait';
  }
  
  void _showHospitalDetails(BuildContext context) {
    // Show details immediately; interstitial is a non-blocking companion action.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalDetailScreen(hospital: hospital),
      ),
    );
    // Fire-and-forget: do not block navigation.
    _maybeShowInterstitial(context);
  }

  static Future<void> _openDirections(BuildContext context, Hospital hospital) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await openHospitalDirections(hospital);
    if (!ok) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open directions. Install Google Maps or allow Safari/Chrome to use cellular data.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _openGoogleSearch(BuildContext context, Hospital hospital) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final q = Uri.encodeComponent(hospital.name);
    final uri = Uri.parse('https://www.google.com/search?q=$q');
    final ok = await _launchUriReliably(uri);
    if (!ok) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Could not open Google. Check cellular data for Safari/Browser in Settings.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  static void _callHospital(BuildContext context, Hospital hospital) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
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
        messenger?.showSnackBar(
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
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Phone: ${hospital.phone}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}
