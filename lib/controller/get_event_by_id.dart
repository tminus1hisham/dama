import 'package:dama/models/event_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FetchEventByIdController extends GetxController {
  final ApiService _apiService = ApiService();

  Rx<EventModel?> event = Rx<EventModel?>(null);
  RxBool isLoading = false.obs;
  RxString error = ''.obs;

  Future<void> fetchEvent(String eventId) async {
    try {
      isLoading.value = true;
      error.value = '';
      final fetchedEvent = await _apiService.getEventById(eventId);
      event.value = fetchedEvent;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
