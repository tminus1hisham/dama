import 'package:dama/models/user_model.dart';
import 'package:dama/services/auth_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class UpdateUserProfileController extends GetxController {
  var firstName = ''.obs;
  var middleName = ''.obs;
  var lastName = ''.obs;
  var nationality = ''.obs;
  var county = ''.obs;
  var phoneNumber = ''.obs;
  var profilePicture = ''.obs;
  var title = ''.obs;
  var company = ''.obs;
  var brief = ''.obs;

  var isLoading = false.obs;

  final AuthService _authService = AuthService();

  void updateUser() async {
    isLoading.value = true;

    try {
      final userModel = UserProfileModel(
        firstName: firstName.value,
        middleName: middleName.value,
        lastName: lastName.value,
        nationality: nationality.value,
        county: county.value,
        phoneNumber: phoneNumber.value,
        profilePicture: profilePicture.value,
        title: title.value,
        company: company.value,
        brief: brief.value,
      );

      final result = await _authService.updateUserProfile(userModel);

      if (result) {
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Success",
          "You have updated your details",
          colorText: kWhite,
          backgroundColor: kGreen.withOpacity(0.9),
        );
      } else {
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Error",
          "Failed to update user",
          colorText: kWhite,
          backgroundColor: kRed.withOpacity(0.9),
        );
      }
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to update user",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
