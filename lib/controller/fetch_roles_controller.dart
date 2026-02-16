import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class RoleController extends GetxController {
  var roles = <String>[].obs;
  var isLoading = false.obs;

  final ApiService _rolesService = ApiService();

  Future<void> fetchRoles() async {
    isLoading.value = true;
    try {
      final response = await _rolesService.fetchRoles();
      if (response['success'] == true && response['roles'] != null) {
        List<dynamic> rolesData = response['roles'];
        roles.value = [
          'Please select',
          ...rolesData.map((e) => e['name'].toString()),
        ];
      } else {
        Get.snackbar("Error", "Invalid roles data received.");
      }
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to fetch roles",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
