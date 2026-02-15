import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import '../config/app_config.dart';

/// Subscription service for managing in-app purchases
/// iOS: Premium Plus features (users already paid $6.99 base price)
/// Android: Full Premium (removes ads + all features)
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _isPremiumPlus = false;
  
  // Subscription IDs
  static const String iosPremiumPlusMonthly = 'premium_plus_monthly_299';
  static const String iosPremiumPlusYearly = 'premium_plus_yearly_2999';
  static const String androidPremiumMonthly = 'premium_monthly_499';
  static const String androidPremiumYearly = 'premium_yearly_3999';
  
  /// Initialize the in-app purchase service
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    
    if (_isAvailable) {
      await _loadProducts();
      await _loadPurchaseStatus();
      _listenToPurchaseUpdates();
    }
  }
  
  /// Load available products from stores
  Future<void> _loadProducts() async {
    final Set<String> productIds = Platform.isIOS 
        ? {iosPremiumPlusMonthly, iosPremiumPlusYearly}
        : {androidPremiumMonthly, androidPremiumYearly};
    
    final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
  }
  
  /// Load purchase status from local storage
  Future<void> _loadPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremiumPlus = prefs.getBool('is_premium_plus') ?? false;
    
    // Also check with store for active subscriptions
    await _restorePurchases();
  }
  
  /// Listen to purchase updates
  void _listenToPurchaseUpdates() {
    _iap.purchaseStream.listen((purchaseDetailsList) {
      _handlePurchaseUpdates(purchaseDetailsList);
    });
  }
  
  /// Handle purchase updates
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase with backend (optional but recommended)
        await _verifyAndUnlockPremium(purchaseDetails);
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }
  
  /// Verify and unlock premium features
  Future<void> _verifyAndUnlockPremium(PurchaseDetails purchaseDetails) async {
    // Save premium status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_plus', true);
    await prefs.setString('purchase_id', purchaseDetails.purchaseID ?? '');
    await prefs.setString('product_id', purchaseDetails.productID);
    
    _isPremiumPlus = true;
    
    // Optional: Verify with backend
    // await _verifyPurchaseWithBackend(purchaseDetails);
  }
  
  /// Check if user has Premium Plus subscription
  bool get isPremiumPlus => _isPremiumPlus;
  
  /// Check if user has any premium features (base iOS purchase counts)
  bool get hasPremiumFeatures {
    if (Platform.isIOS && AppConfig.isIOSPaidApp) {
      return true; // iOS users already paid $6.99
    }
    return _isPremiumPlus;
  }
  
  /// Get available products
  List<ProductDetails> get products => _products;
  
  /// Purchase a product
  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      debugPrint('In-app purchases not available');
      return false;
    }
    
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );
    
    try {
      final bool success = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      return success;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }
  
  /// Restore previous purchases
  Future<void> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore error: $e');
    }
  }
  
  /// Public method to restore purchases
  Future<void> restorePurchases() async {
    await _restorePurchases();
  }
  
  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get monthly subscription product
  ProductDetails? get monthlyProduct {
    final productId = Platform.isIOS 
        ? iosPremiumPlusMonthly 
        : androidPremiumMonthly;
    return getProduct(productId);
  }
  
  /// Get yearly subscription product
  ProductDetails? get yearlyProduct {
    final productId = Platform.isIOS 
        ? iosPremiumPlusYearly 
        : androidPremiumYearly;
    return getProduct(productId);
  }
}
