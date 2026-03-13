import 'package:dama/models/change_password_model.dart';
import 'package:dama/services/auth_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  var oldPassword = ''.obs;
  var newPassword = ''.obs;

  var isLoading = false.obs;

  final AuthService _authService = AuthService();

  void changePassword() async {
    isLoading.value = true;

    try {
      final changePasswordrModel = ChangePasswordModel(
        oldPassword: oldPassword.value,
        newPassword: newPassword.value,
      );

      print(
        'Attempting to change password with old: "${oldPassword.value}", new: "${newPassword.value}"',
      );
      print(
        'Old password length: ${oldPassword.value.length}, new password length: ${newPassword.value.length}',
      );

      final result = await _authService.changePassword(changePasswordrModel);

      if (result != null) {
        print('Password change successful');
        // Logout the user after password change for security
        await _authService.logoutUser();
        Get.offAllNamed('/login'); // Navigate to login screen
      }
    } catch (e) {
      // Handle error silently or log it
      print('Failed to change password: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
