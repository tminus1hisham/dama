import 'package:dama/models/reset_password_model.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/auth_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class ResetPasswordController extends GetxController {
  var userId = ''.obs;
  var otp = ''.obs;
  var newPassword = ''.obs;

  var isLoading = false.obs;

  final AuthService _resetPasswordService = AuthService();

  void resetPassword(BuildContext context) async {
    isLoading.value = true;

    try {
      final resetPasswordModel = ResetPasswordModel(
        userId: userId.value,
        otp: otp.value,
        newPassword: newPassword.value,
      );

      await _resetPasswordService.resetPassword(resetPasswordModel);
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Success",
        "Password reset successful",
        colorText: kWhite,
        backgroundColor: kGreen.withOpacity(0.9),
      );
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to reset password",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
