import 'package:dama/models/user_event_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class UserEventsController extends GetxController {
  var eventsList = <UserEventModel>[].obs;

  var isLoading = false.obs;

  final ApiService _eventService = ApiService();

  Future<void> fetchUserEvents() async {
    isLoading.value = true;
    try {
      List<UserEventModel> fetchedEvents;

      fetchedEvents = await _eventService.getUserEvents();
      eventsList.assignAll(fetchedEvents);
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to fetch event",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
