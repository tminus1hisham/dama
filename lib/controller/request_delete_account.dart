import 'package:dama/services/auth_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestDeleteAccountController extends GetxController {

  var isLoading = false.obs;

  final AuthService _authService = AuthService();

  void requestDeleteAccount(BuildContext context) async {
    isLoading.value = true;

    try {

      final result = await _authService.requestDeleteAccount();

      if (result != null) {
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Success",
          "Request sent",
          colorText: kWhite,
          backgroundColor: kGreen,
        );
      }
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to send request",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
