import 'package:dama/models/event_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';

class EventsController extends GetxController {
  var eventsList = <EventModel>[].obs;
  var trendingEvents = <EventModel>[].obs;
  var isLoading = false.obs;

  final ApiService _eventService = ApiService();

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    isLoading.value = true;
    try {
      final fetchedEvents = await _eventService.getEvents();
      eventsList.assignAll(fetchedEvents);
      _computeTrendingEvents();
    } catch (e) {
      print("Error fetching events: $e");
      eventsList.clear();
      trendingEvents.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void _computeTrendingEvents() {
    // Get events with most attendees as trending
    final sorted = List<EventModel>.from(eventsList);
    sorted.sort((a, b) => b.attendees.length.compareTo(a.attendees.length));
    trendingEvents.value = sorted.take(5).toList();
  }

  Future<void> refreshEvents() async {
    await fetchEvents();
  }
}
