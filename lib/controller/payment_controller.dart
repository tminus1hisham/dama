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
      final paymentModel = PaymentModel(
        objectId: object_id.value,
        model: model.value,
        amountToPay: amountToPay.value,
        phoneNumber: phoneNumber.value,
      );

      print("=== PAYMENT DEBUG ===");
      print("Payment Request: objectId=${paymentModel.objectId}, model=${paymentModel.model}, amount=${paymentModel.amountToPay}, phone=${paymentModel.phoneNumber}");
      
      final result = await _paymentService.pay(paymentModel);
      print("Payment API Response: $result");

      if (result != null) {
        // Check for explicit success indicators from M-Pesa
        final responseCode = result['ResponseCode']?.toString();
        final resultCode = result['ResultCode']?.toString();
        final status = result['status']?.toString().toLowerCase() ?? '';
        final message = result['message']?.toString() ?? '';
        
        // M-Pesa STK push initiated successfully
        // Check multiple possible success indicators
        final hasCheckoutId = result['CheckoutRequestID'] != null || 
                              result['checkoutRequestID'] != null;
        final isSuccessResponse = responseCode == '0' || 
                                   (resultCode != null && int.tryParse(resultCode) == 0) ||
                                   status == 'success' ||
                                   status == 'completed' ||
                                   message.toLowerCase().contains('success');
        
        if (isSuccessResponse || hasCheckoutId) {
          // Show STK push initiated message
          Get.snackbar(
            'Payment Initiated',
            "M-Pesa prompt sent to ${paymentModel.phoneNumber}! Check your phone to complete payment.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: kGreen,
            colorText: Colors.white,
            duration: Duration(seconds: 5),
          );
          return true;
        } else if (status == 'pending' || status == 'processing') {
          // Payment is being processed
          Get.snackbar(
            'Processing',
            "Payment initiated. Please complete the payment on your phone.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: kYellow,
            colorText: Colors.black,
            duration: Duration(seconds: 4),
          );
          return true;
        } else if (result['error'] != null || message.toLowerCase().contains('error')) {
          // Explicit error from API
          throw Exception(message.isNotEmpty ? message : result['error']?.toString() ?? 'Payment failed');
        }
      }
      
      // Payment failed or returned null
      throw Exception(result?['message'] ?? result?['error'] ?? "Payment could not be processed. Please try again.");
      
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
