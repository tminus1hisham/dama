import 'package:dama/models/event_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';

class EventsController extends GetxController {
  var eventsList = <EventModel>[].obs;
  var trendingEvents = <EventModel>[].obs;
  var isLoading = false.obs;
  
  // Current filter for trending events
  var selectedFilter = 'all'.obs; // all, upcoming, past, free, paid

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
    // Filter events based on selected filter
    final filtered = _getFilteredEvents(eventsList);
    
    // Get events with most attendees as trending
    final sorted = List<EventModel>.from(filtered);
    sorted.sort((a, b) => b.attendees.length.compareTo(a.attendees.length));
    trendingEvents.value = sorted.take(5).toList();
  }
  
  List<EventModel> _getFilteredEvents(List<EventModel> events) {
    final now = DateTime.now();
    switch (selectedFilter.value) {
      case 'upcoming':
        return events.where((e) => e.eventDate.isAfter(now)).toList();
      case 'past':
        return events.where((e) => e.eventDate.isBefore(now)).toList();
      case 'free':
        return events.where((e) => e.price == 0).toList();
      case 'paid':
        return events.where((e) => e.price > 0).toList();
      default:
        return events;
    }
  }
  
  void setFilter(String filter) {
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
    _computeTrendingEvents();
  }

  Future<void> refreshEvents() async {
    await fetchEvents();
  }
}
