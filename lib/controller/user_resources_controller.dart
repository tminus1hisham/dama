import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:dama/models/resources_model.dart';

class UserResourceController extends GetxController {
  var resourceList = <ResourceModel>[].obs;

  var isLoading = false.obs;

  final ApiService _userResourceService = ApiService();

  Future<void> fetchUserResources() async {
    isLoading.value = true;
    try {
      List<ResourceModel> fetchedBlogs =
          await _userResourceService.getUserResources();
      resourceList.assignAll(fetchedBlogs);
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to fetch resources",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
