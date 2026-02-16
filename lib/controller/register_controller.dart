import 'package:dama/models/login_model.dart';
import 'package:dama/models/register_model.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/auth_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  var firstName = ''.obs;
  var middleName = ''.obs;
  var lastName = ''.obs;
  var email = ''.obs;
  var password = ''.obs;
  var phone = ''.obs;
  var fcmToken = ''.obs;

  var isLoading = false.obs;

  final AuthService _authService = AuthService();

  void register(BuildContext context) async {
    print("Register controller called");
    print("FCM Token in controller: ${fcmToken.value}");
    isLoading.value = true;

    try {
      final registerModel = RegisterModel(
        firstName: firstName.value,
        middleName: middleName.value,
        lastName: lastName.value,
        phone: phone.value,
        email: email.value,
        password: password.value,
        fcmToken: fcmToken.value,
      );
      print("Register model created: ${registerModel.toJson()}");

      final result = await _authService.register(registerModel);
      print("Registration result: $result");

      if (result != null) {
        // Check if token was returned (complete registration)
        if (result['token'] != null) {
          Get.snackbar(
            margin: EdgeInsets.only(top: 15, left: 15, right: 15),
            "Success",
            "You have created an account",
            colorText: kWhite,
            backgroundColor: kGreen.withOpacity(0.9),
          );
          Get.offAllNamed(AppRoutes.home);
        } else {
          // No token returned, OTP verification required
          Get.snackbar(
            margin: EdgeInsets.only(top: 15, left: 15, right: 15),
            "OTP Sent",
            "Please check your phone for the verification code",
            colorText: kWhite,
            backgroundColor: kBlue.withOpacity(0.9),
          );
          Get.offAllNamed(AppRoutes.otp);
        }
      }
    } catch (e) {
      print("Registration error: $e");
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Registration Failed",
        e.toString().replaceAll('Exception: ', ''),
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
