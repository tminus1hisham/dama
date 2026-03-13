import 'package:dama/models/get_user_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class GetUserProfileController extends GetxController {
  var profile = Rxn<GetUserModel>();
  var isLoading = false.obs;

  final ApiService _otherUserService = ApiService();

  Future<void> fetchUserProfile(String userID) async {
    isLoading.value = true;
    try {
      final data = await _otherUserService.fetchUserProfile(userID);
      if (data != null) {
        profile.value = GetUserModel.fromJson(data['user']);
      }
    } catch (e) {
      print(e);
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to fetch other user profile",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
