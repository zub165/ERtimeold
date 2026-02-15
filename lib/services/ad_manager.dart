import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

/// Ad Manager for handling interstitial ads
/// Shows full-screen ads between user actions to maximize revenue
class AdManager {
  // Singleton pattern
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  InterstitialAd? _interstitialAd;
  int _actionCount = 0;
  bool _isAdLoading = false;

  // YOUR AD UNIT IDs
  // Android Interstitial: From your AdMob account
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-2497524301046342/4743268477';
  
  // Test ID for iOS (since iOS is paid app, won't show)
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  /// Get the correct ad unit ID based on platform
  String get _adUnitId {
    if (Platform.isAndroid) {
      return _androidInterstitialAdUnitId;
    } else {
      return _iosInterstitialAdUnitId; // Won't be used since iOS is paid
    }
  }

  /// Initialize ad manager and load first ad
  Future<void> initialize() async {
    // iOS is paid app - no ads
    if (Platform.isIOS) {
      debugPrint('📱 iOS paid app - ads disabled');
      return;
    }

    debugPrint('🎬 Initializing AdManager for Android...');
    await MobileAds.instance.initialize();
    await loadInterstitialAd();
  }

  /// Load interstitial ad
  Future<void> loadInterstitialAd() async {
    // iOS is paid app - no ads
    if (Platform.isIOS) return;

    if (_isAdLoading) {
      debugPrint('⏳ Ad already loading, skipping...');
      return;
    }

    _isAdLoading = true;
    
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('✅ Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isAdLoading = false;
          
          // Set up callbacks for when ad is shown
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              debugPrint('📺 Interstitial ad showed full screen');
            },
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              debugPrint('👋 User dismissed interstitial ad');
              ad.dispose();
              _interstitialAd = null;
              // Load next ad
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              debugPrint('❌ Failed to show ad: $error');
              ad.dispose();
              _interstitialAd = null;
              // Try to load another ad
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isAdLoading = false;
          
          // Retry after 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            loadInterstitialAd();
          });
        },
      ),
    );
  }

  /// Call this when user performs an action (viewing hospital, submitting review, etc.)
  /// Shows ad every 3 actions
  void incrementAction({String? actionName}) {
    // iOS is paid app - no ads
    if (Platform.isIOS) return;

    _actionCount++;
    debugPrint('🎯 Action count: $_actionCount ${actionName != null ? "($actionName)" : ""}');

    // Show ad every 3 actions
    if (_actionCount >= 3) {
      showInterstitialAd();
      _actionCount = 0; // Reset counter
    }
  }

  /// Show the interstitial ad if available
  void showInterstitialAd() {
    // iOS is paid app - no ads
    if (Platform.isIOS) return;

    if (_interstitialAd != null) {
      debugPrint('📺 Showing interstitial ad...');
      _interstitialAd!.show();
    } else {
      debugPrint('⚠️ Interstitial ad not ready yet');
      // Try to load if not already loading
      if (!_isAdLoading) {
        loadInterstitialAd();
      }
    }
  }

  /// Dispose of current ad
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
