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
  
  // Field-specific error messages
  var emailError = ''.obs;
  var phoneError = ''.obs;
  var generalError = ''.obs;

  final AuthService _authService = AuthService();

  void clearErrors() {
    emailError.value = '';
    phoneError.value = '';
    generalError.value = '';
  }

  void register(BuildContext context) async {
    print("Register controller called");
    print("FCM Token in controller: ${fcmToken.value}");
    
    // Clear previous errors
    clearErrors();
    
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
        // Store the user data temporarily for the profile setup flow
        if (result['user'] != null) {
          final user = result['user'];
          // Store basic user data for personal details screen
          firstName.value = user['firstName'] ?? '';
          lastName.value = user['lastName'] ?? '';
          phone.value = user['phone_number'] ?? '';
        }
        
        // Navigate to Personal Details to complete profile setup
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Success",
          "Account created! Let's complete your profile",
          colorText: kWhite,
          backgroundColor: kGreen.withOpacity(0.9),
        );
        Get.offAllNamed(AppRoutes.personal_details);
      }
    } catch (e) {
      print("Registration error: $e");
      
      // Parse field-specific errors
      final errorString = e.toString();
      
      if (errorString.contains('email_exists')) {
        emailError.value = errorString.replaceAll('Exception: email_exists: ', '').trim();
        if (emailError.value.isEmpty) {
          emailError.value = 'This email is already registered';
        }
      } else if (errorString.contains('phone_exists')) {
        phoneError.value = errorString.replaceAll('Exception: phone_exists: ', '').trim();
        if (phoneError.value.isEmpty) {
          phoneError.value = 'This phone number is already registered';
        }
      } else {
        // General error
        generalError.value = e.toString().replaceAll('Exception: ', '');
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Registration Failed",
          generalError.value,
          colorText: kWhite,
          backgroundColor: kRed.withOpacity(0.9),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
