import 'package:dama/routes/routes.dart';
import 'package:dama/services/api_service.dart';
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
    print('=== OTP SCREEN - LOADING USER ID ===');
    final storedUserId = await StorageService.getData('userId');
    final authType = await StorageService.getData('authType');
    final phone = await StorageService.getData('phoneNumber');

    print('[OTP] Data from Storage:');
    print('  userId: $storedUserId');
    print('  authType: $authType');
    print('  phoneNumber: $phone');

    if (storedUserId != null) {
      userId.value = storedUserId;
      print('[OTP] userId set in controller: ${userId.value}');
    } else {
      print('[OTP] WARNING: userId is null!');
    }
    print('====================================');
  }

  void verifyOtp(BuildContext context) async {
    print('=== OTP VERIFICATION STARTED ===');
    print('[OTP] userId: ${userId.value}');
    print('[OTP] otp: ${otp.value}');

    isLoading.value = true;

    try {
      final otpVerificationModel = OtpVerificationModel(
        userId: userId.value,
        otp: otp.value,
      );

      print('[OTP] Sending verification request...');

      // Check which flow this OTP is for
      final otpFlow = await StorageService.getData('otp_flow');

      Map<String, dynamic>? result;

      if (otpFlow == 'registration' || otpFlow == 'professional_details') {
        // Use registration-specific OTP verification for profile setup flows
        result = await _otpVerificationService.verifyRegistrationOtp(
          otpVerificationModel,
        );
      } else {
        // Use login OTP verification
        result = await _otpVerificationService.verifyOtp(otpVerificationModel);
      }

      if (result != null) {
        // Clear the OTP flow flag
        await StorageService.removeData('otp_flow');

        if (otpFlow == 'professional_details') {
          // Professional details flow - profile setup complete, go to home
          Get.snackbar(
            margin: EdgeInsets.only(top: 15, left: 15, right: 15),
            "Success",
            "Phone verified! Welcome to DAMA.",
            colorText: kWhite,
            backgroundColor: kGreen.withOpacity(0.9),
          );
          Get.offAllNamed(AppRoutes.home);
        } else if (otpFlow == 'registration') {
          // Registration flow - go to personal details to complete profile
          Get.snackbar(
            margin: EdgeInsets.only(top: 15, left: 15, right: 15),
            "Success",
            "Phone verified! Let's complete your profile",
            colorText: kWhite,
            backgroundColor: kGreen.withOpacity(0.9),
          );
          Get.offAllNamed(AppRoutes.personal_details);
        } else {
          // Login flow - go to home
          Get.offAllNamed(AppRoutes.home);
        }
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

  void verifyPhoneUpdate(String otp, String phone) async {
    isLoading.value = true;

    try {
      final apiService = Get.find<ApiService>();
      await apiService.verifyPhoneUpdate(phone, otp);

      Get.back(); // Close OTP screen

      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Success",
        "Phone number updated successfully",
        colorText: kWhite,
        backgroundColor: kGreen.withOpacity(0.9),
      );
    } catch (e) {
      debugPrint('Error verifying phone update: $e');
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        e.toString().replaceFirst('Exception: ', ''),
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
