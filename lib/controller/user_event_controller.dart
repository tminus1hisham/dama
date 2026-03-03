import 'package:dama/models/user_event_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class UserEventsController extends GetxController {
  var eventsList = <UserEventModel>[].obs;
  var isLoading = false.obs;
  var isRegistering = false.obs;

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

  /// Register user for an event
  Future<bool> registerForEvent(String eventId) async {
    isRegistering.value = true;
    try {
      final result = await _eventService.registerForEvent(eventId);
      if (result != null) {
        // Refresh user events list after successful registration
        await fetchUserEvents();
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Success",
          "Successfully registered for event",
          colorText: kWhite,
          backgroundColor: kGreen.withOpacity(0.9),
        );
        return true;
      } else {
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Error",
          "Failed to register for event",
          colorText: kWhite,
          backgroundColor: kRed.withOpacity(0.9),
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to register for event: $e",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
      return false;
    } finally {
      isRegistering.value = false;
    }
  }

  /// Unregister user from an event
  Future<bool> unregisterFromEvent(String eventId) async {
    isRegistering.value = true;
    try {
      final result = await _eventService.unregisterFromEvent(eventId);
      if (result != null) {
        // Refresh user events list after successful unregistration
        await fetchUserEvents();
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Success",
          "Successfully unregistered from event",
          colorText: kWhite,
          backgroundColor: kGreen.withOpacity(0.9),
        );
        return true;
      } else {
        Get.snackbar(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          "Error",
          "Failed to unregister from event",
          colorText: kWhite,
          backgroundColor: kRed.withOpacity(0.9),
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        margin: EdgeInsets.only(top: 15, left: 15, right: 15),
        "Error",
        "Failed to unregister from event: $e",
        colorText: kWhite,
        backgroundColor: kRed.withOpacity(0.9),
      );
      return false;
    } finally {
      isRegistering.value = false;
    }
  }

  /// Check if user is registered for a specific event
  bool isUserRegisteredForEvent(String eventId) {
    return eventsList.any((event) => event.id == eventId);
  }
}
