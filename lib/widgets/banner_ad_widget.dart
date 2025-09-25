import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class BannerAdWidget extends StatefulWidget {
  final double height;
  final EdgeInsets? margin;
  
  const BannerAdWidget({
    super.key,
    this.height = 50.0,
    this.margin,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // AdMob Ad Unit IDs
  static const String _androidBannerAdUnitId = 'ca-app-pub-2497524301046342/9811576951';
  static const String _iosBannerAdUnitId = 'ca-app-pub-2497524301046342/9811576951';
  
  // Test Ad Unit IDs (use these for testing)
  static const String _testAndroidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testIosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = _getAdUnitId();
    
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded: $adUnitId');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          setState(() {
            _isLoaded = false;
          });
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
        },
        onAdImpression: (ad) {
          debugPrint('Banner ad impression recorded');
        },
      ),
    );

    _bannerAd!.load();
  }

  String _getAdUnitId() {
    // Use test ads in debug mode, real ads in release mode
    const bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    
    if (isDebugMode) {
      return Platform.isAndroid ? _testAndroidBannerAdUnitId : _testIosBannerAdUnitId;
    } else {
      return Platform.isAndroid ? _androidBannerAdUnitId : _iosBannerAdUnitId;
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// Alternative widget for showing ads with a placeholder when not loaded
class BannerAdWithPlaceholder extends StatefulWidget {
  final double height;
  final EdgeInsets? margin;
  final Widget? placeholder;
  
  const BannerAdWithPlaceholder({
    super.key,
    this.height = 50.0,
    this.margin,
    this.placeholder,
  });

  @override
  State<BannerAdWithPlaceholder> createState() => _BannerAdWithPlaceholderState();
}

class _BannerAdWithPlaceholderState extends State<BannerAdWithPlaceholder> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = true;

  // AdMob Ad Unit IDs
  static const String _androidBannerAdUnitId = 'ca-app-pub-2497524301046342/9811576951';
  static const String _iosBannerAdUnitId = 'ca-app-pub-2497524301046342/9811576951';
  
  // Test Ad Unit IDs
  static const String _testAndroidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testIosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = _getAdUnitId();
    
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded: $adUnitId');
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          setState(() {
            _isLoaded = false;
            _isLoading = false;
          });
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
        },
        onAdImpression: (ad) {
          debugPrint('Banner ad impression recorded');
        },
      ),
    );

    _bannerAd!.load();
  }

  String _getAdUnitId() {
    const bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    
    if (isDebugMode) {
      return Platform.isAndroid ? _testAndroidBannerAdUnitId : _testIosBannerAdUnitId;
    } else {
      return Platform.isAndroid ? _androidBannerAdUnitId : _iosBannerAdUnitId;
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _isLoaded && _bannerAd != null
              ? AdWidget(ad: _bannerAd!)
              : widget.placeholder ??
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'Advertisement',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
    );
  }
}
