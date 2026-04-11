import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _isProcessing = false;
  bool _paymentSuccess = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    _handlePaymentSuccess({
      'razorpay_order_id': response.orderId ?? '',
      'razorpay_payment_id': response.paymentId ?? '',
      'razorpay_signature': response.signature ?? '',
    });
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    _showError('Payment failed: ${response.message ?? "Unknown error"}');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _showError('External wallet selected: ${response.walletName}');
  }

  final _features = [
    _Feature(Icons.psychology_rounded, 'AI Smart Match', 'Detect relevant comments using AI'),
    _Feature(Icons.auto_awesome_rounded, 'AI Generated Replies', 'Unique, context-aware responses'),
    _Feature(Icons.send_rounded, 'Auto DM', 'Automatically send DMs to commenters'),
    _Feature(Icons.all_inclusive_rounded, 'Unlimited Rules', 'Create unlimited automation rules'),
    _Feature(Icons.speed_rounded, 'Priority Processing', 'Faster response times'),
    _Feature(Icons.support_agent_rounded, 'Priority Support', 'Get help when you need it'),
  ];

  Future<void> _startPayment() async {
    setState(() => _isProcessing = true);

    try {
      final orderData = await ApiService.createOrder();
      if (orderData == null) {
        _showError('Failed to create order. Please try again.');
        setState(() => _isProcessing = false);
        return;
      }

      final orderId = orderData['orderId'] ?? orderData['order_id'] ?? orderData['id'];

      // Open Razorpay
      // Note: razorpay_flutter requires native setup. Here we prepare the options.
      // In a real app, you would use Razorpay().open(options) and handle events.
      _openRazorpay(orderId);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
      setState(() => _isProcessing = false);
    }
  }

  void _openRazorpay(String orderId) {
    var options = {
      'key': AppConstants.razorpayKey,
      'amount': AppConstants.proPrice,
      'name': AppConstants.appName,
      'order_id': orderId,
      'description': 'Pro Plan - Lifetime',
      'prefill': {'contact': '', 'email': ''},
      'theme': {'color': '#6C63FF'},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      _showError('Could not open Razorpay. Please try again.');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePaymentSuccess(Map<String, dynamic> paymentData) async {
    final verified = await ApiService.verifyPayment(paymentData);
    setState(() => _isProcessing = false);

    if (verified) {
      setState(() => _paymentSuccess = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } else {
      _showError('Payment verification failed. Contact support if amount was deducted.');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppConstants.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentSuccess) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppConstants.successGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: AppConstants.successGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Pro!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All features are now unlocked',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppConstants.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Go Pro',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock the full power of AutoReply.io',
              style: GoogleFonts.inter(fontSize: 15, color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 32),

            // Features
            ...List.generate(_features.length, (i) => _buildFeatureRow(_features[i])),
            const SizedBox(height: 32),

            // Price
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'Lifetime Access',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '999',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'One-time payment. No subscriptions.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _startPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppConstants.primaryColor,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Pay with Razorpay',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Secure payment powered by Razorpay',
              style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(_Feature feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: AppConstants.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                Text(
                  feature.subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppConstants.successGreen, size: 22),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.title, this.subtitle);
}
