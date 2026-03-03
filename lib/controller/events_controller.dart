import 'package:dama/models/event_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('\n✅ EventsController.fetchEvents: API returned ${fetchedEvents.length} events');
      if (fetchedEvents.isNotEmpty) {
        final firstEvent = fetchedEvents.first;
        debugPrint('   First event: "${firstEvent.eventTitle}"');
        debugPrint('   First event date: ${firstEvent.eventDate} (${firstEvent.eventDate.year}-${firstEvent.eventDate.month}-${firstEvent.eventDate.day})');
      }
      eventsList.assignAll(fetchedEvents);
      debugPrint('✅ Assigned ${eventsList.length} events to observable list');
      if (eventsList.isNotEmpty) {
        final firstInList = eventsList.first;
        debugPrint('   First in list: "${firstInList.eventTitle}"');
        debugPrint('   First in list date: ${firstInList.eventDate} (${firstInList.eventDate.year}-${firstInList.eventDate.month}-${firstInList.eventDate.day})');
      }
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
        final upcoming = events.where((e) {
          // Ensure we're using local time for comparison
          final eventLocal = e.eventDate.isUtc ? e.eventDate.toLocal() : e.eventDate;
          final isAfter = eventLocal.isAfter(now);
          return isAfter;
        }).toList();
        return upcoming;
      case 'past':
        final past = events.where((e) {
          final eventLocal = e.eventDate.isUtc ? e.eventDate.toLocal() : e.eventDate;
          final isBefore = eventLocal.isBefore(now);
          final sameDay = _isSameDay(eventLocal, now);
          final isPast = isBefore && !sameDay;
          return isPast;
        }).toList();
        debugPrint('📅 Past events: ${past.length}');
        return past;
      case 'free':
        return events.where((e) => e.price == 0).toList();
      case 'paid':
        return events.where((e) => e.price > 0).toList();
      default:
        return events;
    }
  }
  
  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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
