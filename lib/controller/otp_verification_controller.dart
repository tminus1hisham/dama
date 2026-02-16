import 'package:dama/routes/routes.dart';
import 'package:dama/services/auth_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:dama/models/otp_verification.dart';

class OtpVerificationController extends GetxController {
  var userId = ''.obs;
  var otp = ''.obs;

  var isLoading = false.obs;

  final AuthService _otpVerificationService = AuthService();

  @override
  void onInit() {
    super.onInit();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final storedUserId = await StorageService.getData('userId');
    if (storedUserId != null) {
      userId.value = storedUserId;
      debugPrint('[OTP] Loaded userId: $storedUserId');
    }
  }

  void verifyOtp(BuildContext context) async {
    isLoading.value = true;

    try {
      final otpVerificationModel = OtpVerificationModel(
        userId: userId.value,
        otp: otp.value,
      );

      final result = await _otpVerificationService.verifyOtp(
        otpVerificationModel,
      );
      if (result != null) {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "An error occurred",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
