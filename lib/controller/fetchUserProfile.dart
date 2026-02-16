import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../models/other_user_profile_model.dart';

class FetchUserProfileController extends GetxController {
  var profile = Rxn<OtherUserDetailsModel>();
  var isLoading = false.obs;

  final ApiService _otherUserService = ApiService();

  Future<void> fetchUserProfile(String userID) async {
    isLoading.value = true;
    try {
      final data = await _otherUserService.fetchUserProfile(userID);
      if (data != null) {
        profile.value = OtherUserDetailsModel.fromJson(data['user']);
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
