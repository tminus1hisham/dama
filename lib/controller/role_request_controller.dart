import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:dama/models/role_request_model.dart';
import 'package:dama/services/api_service.dart';

class RoleRequestController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;

  Future<void> requestRole(String role) async {
    isLoading.value = true;
    try {
      RoleRequestModel model = RoleRequestModel(roleRequested: role);
      bool success = await _apiService.requestRole(model);

      if (success) {
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Success",
          "Role request submitted successfully",
          colorText: kWhite,
          backgroundColor: kGreen.withOpacity(0.9),
        );
      }
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to request role",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
