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

  final ApiService _paymentService = ApiService();

  Future<bool> pay(BuildContext context) async {
    isLoading.value = true;
    try {
      final paymentModel = PaymentModel(
        objectId: object_id.value,
        model: model.value,
        amountToPay: amountToPay.value,
        phoneNumber: phoneNumber.value,
      );

      final result = await _paymentService.pay(paymentModel);
      print("HAPA");
      print(result);

      if (result != null && result['status'] == 'Completed') {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You cancelled or the payment did not go through"),
            backgroundColor: kRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred during payment"),
          backgroundColor: kRed,
        ),
      );
    } finally {
      isLoading.value = false;
    }
    return false;
  }
}
