import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../services/subscription_service.dart';
import '../config/app_config.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  ProductDetails? _monthlyProduct;
  ProductDetails? _yearlyProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    await _subscriptionService.initialize();
    
    setState(() {
      _monthlyProduct = _subscriptionService.monthlyProduct;
      _yearlyProduct = _subscriptionService.yearlyProduct;
      _isLoading = false;
    });
  }

  Future<void> _purchaseProduct(ProductDetails product) async {
    setState(() => _isLoading = true);
    
    final success = await _subscriptionService.purchaseProduct(product);
    
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for upgrading to Premium Plus!')),
      );
      Navigator.pop(context, true); // Return true to indicate purchase success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase failed or was canceled')),
      );
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    
    await _subscriptionService.restorePurchases();
    
    setState(() => _isLoading = false);
    
    if (_subscriptionService.isPremiumPlus && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchases restored successfully!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No purchases found to restore')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final isPaidApp = isIOS && AppConfig.isIOSPaidApp;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isPaidApp ? 'Premium Plus' : 'Go Premium'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _restorePurchases,
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  if (isPaidApp) ...[
                    const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
                    const SizedBox(height: 16),
                    const Text(
                      'Upgrade to Premium Plus',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You already have all basic features!\nUnlock advanced features with Premium Plus',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const Icon(Icons.star, size: 80, color: Colors.amber),
                    const SizedBox(height: 16),
                    const Text(
                      'Go Premium',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remove ads and unlock all features',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Features
                  _buildFeaturesList(isPaidApp),
                  
                  const SizedBox(height: 32),
                  
                  // Subscription Options
                  if (_yearlyProduct != null)
                    _buildSubscriptionCard(
                      product: _yearlyProduct!,
                      badge: 'BEST VALUE',
                      savings: 'Save ${_calculateSavings()}%',
                    ),
                  
                  const SizedBox(height: 16),
                  
                  if (_monthlyProduct != null)
                    _buildSubscriptionCard(
                      product: _monthlyProduct!,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Terms
                  Text(
                    'Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Payment will be charged to your iTunes/Google Play account.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeaturesList(bool isPaidApp) {
    final features = isPaidApp
        ? [
            'Real-time push notifications',
            'Historical wait time trends',
            'Save unlimited favorite hospitals',
            'Advanced search filters',
            'Appointment reminders',
            'Family health profiles',
            'Priority customer support',
            'Export health records',
          ]
        : [
            'Remove all advertisements',
            'Real-time push notifications',
            'Historical wait time trends',
            'Save unlimited favorite hospitals',
            'Advanced search filters',
            'Appointment reminders',
            'Family health profiles',
            'Priority customer support',
          ];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required ProductDetails product,
    String? badge,
    String? savings,
  }) {
    final isYearly = product.id.contains('yearly');
    
    return Card(
      elevation: badge != null ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: badge != null 
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _purchaseProduct(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isYearly ? 'Yearly' : 'Monthly',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (savings != null)
                        Text(
                          savings,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.price,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        isYearly ? '/year' : '/month',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateSavings() {
    if (_monthlyProduct == null || _yearlyProduct == null) return '0';
    
    // Extract numeric price (remove currency symbols)
    final monthlyPrice = double.tryParse(
      _monthlyProduct!.price.replaceAll(RegExp(r'[^\d.]'), ''),
    ) ?? 0;
    final yearlyPrice = double.tryParse(
      _yearlyProduct!.price.replaceAll(RegExp(r'[^\d.]'), ''),
    ) ?? 0;
    
    if (monthlyPrice == 0 || yearlyPrice == 0) return '0';
    
    final monthlyTotal = monthlyPrice * 12;
    final savings = ((monthlyTotal - yearlyPrice) / monthlyTotal * 100).round();
    
    return savings.toString();
  }
}
