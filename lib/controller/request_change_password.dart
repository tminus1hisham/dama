import 'package:dama/models/request_reset_password.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/auth_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestChangePasswordController extends GetxController {
  var phone_number = ''.obs;

  var isLoading = false.obs;

  final AuthService _authService = AuthService();

  void requestChangePassword(BuildContext context) async {
    isLoading.value = true;

    try {
      final requestChangePasswordrModel = RequestChangePasswordModel(
        phone_number: phone_number.value,
      );

      final result = await _authService.requestResetPassword(
        requestChangePasswordrModel,
      );

      if (result != null) {
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Success",
          "An otp has been sent",
          colorText: kWhite,
          backgroundColor: kGreen,
        );
        Get.offAllNamed(AppRoutes.resetPassword);
      }
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to send otp",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
