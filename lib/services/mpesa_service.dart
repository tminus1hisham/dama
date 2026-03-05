import 'package:dama/models/payment_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Centralized M-Pesa payment service
/// Usage:
/// ```dart
/// final result = await MpesaService.pay(
///   objectId: 'plan_123',
///   model: 'Plan',  // 'Plan', 'Event', 'Resource', 'Training'
///   amount: 1000,
///   phoneNumber: '254712345678',
/// );
/// if (result.success) { /* handle success */ }
/// ```
class MpesaService {
  static final ApiService _apiService = ApiService();

  /// Process M-Pesa STK Push payment
  /// Returns [MpesaResult] with success status and optional error message
  static Future<MpesaResult> pay({
    required String objectId,
    required String model,
    required int amount,
    required String phoneNumber,
    bool showSnackbar = true,
  }) async {
    try {
      // Format phone number: remove '+' if present
      // M-Pesa expects "254712345678" not "+254712345678"
      String formattedPhone = phoneNumber.replaceFirst('+', '');

      // Validate phone number
      if (!_isValidKenyanPhone(formattedPhone)) {
        return MpesaResult.failure('Please enter a valid Kenyan phone number');
      }

      debugPrint('=== M-PESA PAYMENT ===');
      debugPrint('ObjectId: $objectId');
      debugPrint('Model: $model');
      debugPrint('Amount: KES $amount');
      debugPrint('Phone: $formattedPhone');

      final paymentModel = PaymentModel(
        objectId: objectId,
        model: model,
        amountToPay: amount,
        phoneNumber: formattedPhone,
      );

      final result = await _apiService.pay(paymentModel);

      if (result == null) {
        return MpesaResult.failure(
          'Payment service unavailable. Check your connection.',
        );
      }

      debugPrint('M-Pesa Response: $result');

      // Check for failure
      final status = result['status']?.toString().toLowerCase() ?? '';
      final message = result['message']?.toString() ?? '';
      final transaction = result['transaction'];

      if (status == 'failed') {
        String errorDetail = message;
        if (transaction != null && transaction['status'] == 'Failed') {
          errorDetail = "M-Pesa transaction failed. Possible reasons:\n"
              "• Insufficient funds\n"
              "• Wrong PIN entered\n"
              "• M-Pesa service unavailable";
        }
        return MpesaResult.failure(errorDetail);
      }

      // Success - STK push initiated
      final mpesaResult = MpesaResult.success(
        transactionId: transaction?['id']?.toString(),
        checkoutRequestId: result['CheckoutRequestID']?.toString(),
        rawResponse: result,
      );

      if (showSnackbar) {
        Get.snackbar(
          'Payment Initiated',
          'M-Pesa prompt sent to $phoneNumber! Enter your PIN to complete.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: kGreen,
          colorText: Colors.white,
          duration: const Duration(seconds: 8),
        );
      }

      return mpesaResult;
    } catch (e) {
      debugPrint('M-Pesa Error: $e');
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

      return MpesaResult.failure(error);
    }
  }

  /// Validate Kenyan phone number
  static bool _isValidKenyanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    // 254XXXXXXXXX (12 digits) or 0XXXXXXXXX (10 digits) or XXXXXXXXX (9 digits)
    if (digits.startsWith('254') && digits.length == 12) return true;
    if (digits.startsWith('0') && digits.length == 10) return true;
    if (digits.length == 9 && !digits.startsWith('0')) return true;
    return false;
  }

  /// Format phone to 254XXXXXXXXX format
  static String formatPhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '254${digits.substring(1)}';
    } else if (!digits.startsWith('254')) {
      digits = '254$digits';
    }
    return digits;
  }
}

/// Result of M-Pesa payment attempt
class MpesaResult {
  final bool success;
  final String? errorMessage;
  final String? transactionId;
  final String? checkoutRequestId;
  final Map<String, dynamic>? rawResponse;

  MpesaResult._({
    required this.success,
    this.errorMessage,
    this.transactionId,
    this.checkoutRequestId,
    this.rawResponse,
  });

  factory MpesaResult.success({
    String? transactionId,
    String? checkoutRequestId,
    Map<String, dynamic>? rawResponse,
  }) {
    return MpesaResult._(
      success: true,
      transactionId: transactionId,
      checkoutRequestId: checkoutRequestId,
      rawResponse: rawResponse,
    );
  }

  factory MpesaResult.failure(String message) {
    return MpesaResult._(
      success: false,
      errorMessage: message,
    );
  }
}
