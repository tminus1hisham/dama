import 'package:dama/models/payment_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentController extends GetxController {
  var object_id = ''.obs;
  var model = ''.obs;
  var amountToPay = 0.obs;
  var phoneNumber = ''.obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  final ApiService _paymentService = ApiService();

  Future<bool> pay(BuildContext context) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Format phone number for M-Pesa: remove '+' if present
      // M-Pesa API expects format like "254712345678" not "+254712345678"
      String formattedPhone = phoneNumber.value.replaceFirst('+', '');

      final paymentModel = PaymentModel(
        objectId: object_id.value,
        model: model.value,
        amountToPay: amountToPay.value,
        phoneNumber: formattedPhone,
      );

      print("=== PAYMENT DEBUG ===");
      print("Original Phone: ${phoneNumber.value}");
      print("Formatted Phone: ${paymentModel.phoneNumber}");
      print(
        "Payment Request: objectId=${paymentModel.objectId}, model=${paymentModel.model}, amount=${paymentModel.amountToPay}, phone=${paymentModel.phoneNumber}",
      );

      final result = await _paymentService.pay(paymentModel);
      print("Payment API Response: $result");

      if (result != null) {
        // Check for explicit failure indicators from M-Pesa
        final responseCode = result['ResponseCode']?.toString();
        final resultCode = result['ResultCode']?.toString();
        final status = result['status']?.toString().toLowerCase() ?? '';
        final message = result['message']?.toString() ?? '';
        final transaction = result['transaction'];

        print("Payment Status: $status");
        print("Payment Message: $message");
        print("Transaction Data: $transaction");

        // Check if transaction failed (even though we got a response)
        if (status == 'failed') {
          // Transaction was initiated but failed - common M-Pesa issues
          String errorDetail = message;
          if (transaction != null && transaction['status'] == 'Failed') {
            // Common M-Pesa failure reasons
            errorDetail =
                "M-Pesa transaction failed. Possible reasons:\n"
                "• Insufficient funds in your M-Pesa account\n"
                "• Wrong PIN entered on your phone\n"
                "• M-Pesa service temporarily unavailable\n"
                "• Test environment - use Safaricom test credentials";
          }
          throw Exception(errorDetail);
        }

        // If we got a response from the API, the STK push was initiated successfully
        // The actual payment happens on the user's phone
        // Show STK push initiated message
        Get.snackbar(
          'Payment Initiated',
          "M-Pesa prompt sent to ${phoneNumber.value}! Check your phone to enter your PIN and complete payment.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: kGreen,
          colorText: Colors.white,
          duration: Duration(seconds: 8),
        );
        return true;
      }

      // Payment API returned null - likely a network error
      throw Exception(
        "Payment service unavailable. Please check your connection and try again.",
      );
    } catch (e) {
      print("Payment Error: $e");
      errorMessage.value = e.toString();
      Get.snackbar(
        'Payment Failed',
        "Payment failed: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kRed,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
