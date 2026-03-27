import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';

/// Centralized Stripe/Apple Pay payment service for iOS
/// Usage:
/// ```dart
/// // Initialize once at app startup (main.dart)
/// await StripeService.initialize();
///
/// // Process payment
/// final result = await StripeService.pay(
///   objectId: 'plan_123',
///   model: 'Plan',
///   amount: 1000, // KES
///   itemName: 'Professional Membership',
/// );
/// if (result.success) { /* handle success */ }
/// ```
class StripeService {
  static final ApiService _apiService = ApiService();

  // TODO: Replace with your actual Stripe publishable key from environment
  static const String _publishableKey = 'pk_test_YOUR_STRIPE_KEY';

  // Apple Pay Merchant ID - configured in Xcode
  static const String _merchantId = 'merchant.com.dama.mobile';

  /// Initialize Stripe SDK - call once at app startup
  static Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('Stripe: Web platform - Apple Pay not supported');
      return;
    }

    try {
      Stripe.publishableKey = _publishableKey;
      Stripe.merchantIdentifier = _merchantId;
      await Stripe.instance.applySettings();
      debugPrint('Stripe SDK initialized successfully');
    } catch (e) {
      debugPrint('Stripe initialization error: $e');
    }
  }

  /// Check if Apple Pay is available on this device
  static Future<bool> isApplePayAvailable() async {
    if (!defaultTargetPlatform.isIOS) {
      return false;
    }
    // MOCK: Always return true for Simulator/UI testing
    return true;
    // --- Restore this for production ---
    // try {
    //   return await Stripe.instance.isPlatformPaySupported();
    // } catch (e) {
    //   debugPrint('Apple Pay availability check failed: $e');
    //   return false;
    // }
  }

  /// Process Apple Pay payment
  /// [amount] is in KES (smallest unit conversion handled internally)
  static Future<StripeResult> pay({
    required String objectId,
    required String model,
    required int amount,
    required String itemName,
    bool showSnackbar = true,
  }) async {
    try {
      debugPrint('=== APPLE PAY PAYMENT ===');
      debugPrint('ObjectId: $objectId');
      debugPrint('Model: $model');
      debugPrint('Amount: KES $amount');
      debugPrint('Item: $itemName');

      // Check Apple Pay availability
      final isAvailable = await isApplePayAvailable();
      if (!isAvailable) {
        return StripeResult.failure(
          'Apple Pay is not available on this device. '
          'Please set up Apple Pay in Settings > Wallet & Apple Pay.',
        );
      }

      // Step 1: Create payment intent on backend
      final paymentIntent = await _createPaymentIntent(
        objectId: objectId,
        model: model,
        amount: amount,
      );

      if (paymentIntent == null) {
        return StripeResult.failure(
          'Unable to initiate payment. Please try again.',
        );
      }

      final clientSecret = paymentIntent['clientSecret'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        return StripeResult.failure(
          'Payment configuration error. Contact support.',
        );
      }

      // Step 2: Present Apple Pay sheet and confirm payment
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
            merchantCountryCode: 'KE',
            currencyCode: 'KES',
            cartItems: [
              ApplePayCartSummaryItem.immediate(
                label: itemName,
                amount: amount.toString(),
              ),
            ],
          ),
        ),
      );

      debugPrint('Apple Pay payment confirmed successfully');

      final result = StripeResult.success(
        paymentIntentId: paymentIntent['paymentIntentId']?.toString(),
        transactionId: paymentIntent['transactionId']?.toString(),
        rawResponse: paymentIntent,
      );

      if (showSnackbar) {
        Get.snackbar(
          'Payment Successful',
          'Your payment for $itemName has been processed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: kGreen,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }

      return result;
    } on StripeException catch (e) {
      debugPrint('Stripe Error: ${e.error.localizedMessage}');

      String errorMessage;
      switch (e.error.code) {
        case FailureCode.Canceled:
          errorMessage = 'Payment was cancelled';
          break;
        case FailureCode.Failed:
          errorMessage = e.error.localizedMessage ?? 'Payment failed';
          break;
        case FailureCode.Timeout:
          errorMessage = 'Payment timed out. Please try again.';
          break;
        default:
          errorMessage = e.error.localizedMessage ?? 'An error occurred';
      }

      if (showSnackbar && e.error.code != FailureCode.Canceled) {
        Get.snackbar(
          'Payment Failed',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: kRed,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }

      return StripeResult.failure(errorMessage);
    } catch (e) {
      debugPrint('Apple Pay Error: $e');
      final error = e.toString().replaceFirst('Exception: ', '');

      if (showSnackbar) {
        Get.snackbar(
          'Payment Failed',
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: kRed,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }

      return StripeResult.failure(error);
    }
  }

  /// Create payment intent on backend
  /// Backend should return { clientSecret, paymentIntentId, transactionId }
  static Future<Map<String, dynamic>?> _createPaymentIntent({
    required String objectId,
    required String model,
    required int amount,
  }) async {
    try {
      // Call backend to create Stripe PaymentIntent
      // Backend needs to:
      // 1. Create PaymentIntent with Stripe
      // 2. Store transaction record
      // 3. Return clientSecret for frontend confirmation
      final response = await _apiService.createApplePayIntent(
        objectId: objectId,
        model: model,
        amount: amount,
      );

      return response;
    } catch (e) {
      debugPrint('Create payment intent error: $e');
      return null;
    }
  }
}

/// Extension to check platform
extension TargetPlatformX on TargetPlatform {
  bool get isIOS => this == TargetPlatform.iOS;
  bool get isAndroid => this == TargetPlatform.android;
}

/// Result of Stripe/Apple Pay payment attempt
class StripeResult {
  final bool success;
  final String? errorMessage;
  final String? paymentIntentId;
  final String? transactionId;
  final Map<String, dynamic>? rawResponse;

  StripeResult._({
    required this.success,
    this.errorMessage,
    this.paymentIntentId,
    this.transactionId,
    this.rawResponse,
  });

  factory StripeResult.success({
    String? paymentIntentId,
    String? transactionId,
    Map<String, dynamic>? rawResponse,
  }) {
    return StripeResult._(
      success: true,
      paymentIntentId: paymentIntentId,
      transactionId: transactionId,
      rawResponse: rawResponse,
    );
  }

  factory StripeResult.failure(String message) {
    return StripeResult._(success: false, errorMessage: message);
  }
}
