import 'dart:io';
import 'package:dama/services/mpesa_service.dart';
import 'package:dama/services/stripe_service.dart';
import 'package:flutter/foundation.dart';

/// Unified payment service that routes to the appropriate
/// payment method based on platform:
/// - Android: M-Pesa STK Push
/// - iOS: Apple Pay via Stripe
///
/// Usage:
/// ```dart
/// final result = await UnifiedPaymentService.pay(
///   objectId: 'plan_123',
///   model: 'Plan',
///   amount: 1000,
///   itemName: 'Professional Membership',
///   phoneNumber: '254712345678', // Required for Android
/// );
///
/// if (result.success) {
///   // Handle success
/// } else {
///   print(result.errorMessage);
/// }
/// ```
class UnifiedPaymentService {
  /// Initialize payment services (call at app startup)
  static Future<void> initialize() async {
    if (isIOS) {
      await StripeService.initialize();
    }
  }

  /// Check if current platform is iOS
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Check if current platform is Android
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Get the payment method name for display
  static String get paymentMethodName => isIOS ? 'Apple Pay' : 'M-Pesa';

  /// Check if payment is available on current platform
  static Future<bool> isPaymentAvailable() async {
    if (isIOS) {
      return await StripeService.isApplePayAvailable();
    } else if (isAndroid) {
      // M-Pesa is always available if user has phone number
      return true;
    }
    return false;
  }

  /// Process payment using platform-appropriate method
  ///
  /// [objectId] - ID of the item being purchased (plan, event, etc.)
  /// [model] - Type of item: 'Plan', 'Event', 'Resource', 'Training'
  /// [amount] - Amount in KES
  /// [itemName] - Display name for Apple Pay sheet
  /// [phoneNumber] - Required for M-Pesa (Android only)
  static Future<PaymentResult> pay({
    required String objectId,
    required String model,
    required int amount,
    required String itemName,
    String? phoneNumber, // Required for Android/M-Pesa
    bool showSnackbar = true,
  }) async {
    debugPrint('=== UNIFIED PAYMENT ===');
    debugPrint(
      'Platform: ${isIOS
          ? 'iOS'
          : isAndroid
          ? 'Android'
          : 'Other'}',
    );
    debugPrint('Method: $paymentMethodName');

    if (isIOS) {
      // Use Apple Pay via Stripe
      final result = await StripeService.pay(
        objectId: objectId,
        model: model,
        amount: amount,
        itemName: itemName,
        showSnackbar: showSnackbar,
      );

      return PaymentResult(
        success: result.success,
        errorMessage: result.errorMessage,
        transactionId: result.transactionId,
        paymentMethod: PaymentMethod.applePay,
        rawResponse: result.rawResponse,
      );
    } else if (isAndroid) {
      // Use M-Pesa
      if (phoneNumber == null || phoneNumber.isEmpty) {
        return PaymentResult(
          success: false,
          errorMessage: 'Phone number is required for M-Pesa payment',
          paymentMethod: PaymentMethod.mpesa,
        );
      }

      final result = await MpesaService.pay(
        objectId: objectId,
        model: model,
        amount: amount,
        phoneNumber: phoneNumber,
        showSnackbar: showSnackbar,
      );

      return PaymentResult(
        success: result.success,
        errorMessage: result.errorMessage,
        transactionId: result.transactionId,
        paymentMethod: PaymentMethod.mpesa,
        rawResponse: result.rawResponse,
      );
    } else {
      // Web or unsupported platform
      return PaymentResult(
        success: false,
        errorMessage: 'Payments are not supported on this platform',
        paymentMethod: PaymentMethod.unsupported,
      );
    }
  }

  /// Check which payment methods are available
  static Future<List<PaymentMethod>> getAvailableMethods() async {
    List<PaymentMethod> methods = [];

    if (isIOS && await StripeService.isApplePayAvailable()) {
      methods.add(PaymentMethod.applePay);
    }

    if (isAndroid) {
      methods.add(PaymentMethod.mpesa);
    }

    return methods;
  }
}

/// Payment method types
enum PaymentMethod { mpesa, applePay, unsupported }

/// Extension for PaymentMethod display
extension PaymentMethodX on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.unsupported:
        return 'Unsupported';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.mpesa:
        return '📱'; // or use asset icon
      case PaymentMethod.applePay:
        return ''; // Apple Pay logo
      case PaymentMethod.unsupported:
        return '❌';
    }
  }
}

/// Unified payment result
class PaymentResult {
  final bool success;
  final String? errorMessage;
  final String? transactionId;
  final PaymentMethod paymentMethod;
  final Map<String, dynamic>? rawResponse;

  PaymentResult({
    required this.success,
    this.errorMessage,
    this.transactionId,
    required this.paymentMethod,
    this.rawResponse,
  });

  /// Create success result
  factory PaymentResult.success({
    String? transactionId,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? rawResponse,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      rawResponse: rawResponse,
    );
  }

  /// Create failure result
  factory PaymentResult.failure({
    required String message,
    required PaymentMethod paymentMethod,
  }) {
    return PaymentResult(
      success: false,
      errorMessage: message,
      paymentMethod: paymentMethod,
    );
  }

  @override
  String toString() {
    return 'PaymentResult(success: $success, method: ${paymentMethod.displayName}, '
        'transactionId: $transactionId, error: $errorMessage)';
  }
}
