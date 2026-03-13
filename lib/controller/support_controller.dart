import 'package:dama/models/support_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupportController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  var isLoading = false.obs;
  var fullName = ''.obs;
  var email = ''.obs;
  var message = ''.obs;

  var fullNameError = ''.obs;
  var emailError = ''.obs;
  var messageError = ''.obs;

  // Persistent text controllers
  late TextEditingController fullNameController;
  late TextEditingController emailController;
  late TextEditingController messageController;

  @override
  void onInit() {
    super.onInit();
    fullNameController = TextEditingController();
    emailController = TextEditingController();
    messageController = TextEditingController();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    messageController.dispose();
    super.onClose();
  }

  void clearErrors() {
    fullNameError.value = '';
    emailError.value = '';
    messageError.value = '';
  }

  bool _validateForm() {
    clearErrors();

    if (fullName.value.trim().isEmpty) {
      fullNameError.value = 'Full name is required';
      return false;
    }

    if (email.value.trim().isEmpty) {
      emailError.value = 'Email is required';
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.value)) {
      emailError.value = 'Please enter a valid email';
      return false;
    }

    if (message.value.trim().isEmpty) {
      messageError.value = 'Message is required';
      return false;
    }

    if (message.value.trim().length < 10) {
      messageError.value = 'Message must be at least 10 characters';
      return false;
    }

    return true;
  }

  Future<void> sendMessage() async {
    if (!_validateForm()) {
      return;
    }

    isLoading.value = true;

    try {
      final supportModel = SupportModel(
        fullName: fullName.value,
        email: email.value,
        message: message.value,
      );

      await _apiService.sendSupportMessage(supportModel);

      // Clear form
      fullName.value = '';
      email.value = '';
      message.value = '';
      fullNameController.clear();
      emailController.clear();
      messageController.clear();
      clearErrors();

      Get.snackbar(
        'Success',
        'Your message has been sent successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF5CB338),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
      );

      // Navigate back after delay
      await Future.delayed(const Duration(seconds: 1));
      Get.back();
    } catch (e) {
      debugPrint('Error sending support message: $e');
      Get.snackbar(
        'Error',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF0B55),
        colorText: const Color(0xFFFFFFFF),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
