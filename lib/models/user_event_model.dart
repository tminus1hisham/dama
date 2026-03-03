import 'package:flutter/material.dart';

class UserEventModel {
  final String id;
  final String eventTitle;
  final String description;
  final List<Speaker> speakers;
  final DateTime eventDate;
  final List<dynamic> attendees;
  final String location;
  final int price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String eventImageUrl;

  UserEventModel({
    required this.id,
    required this.eventTitle,
    required this.description,
    required this.speakers,
    required this.eventDate,
    required this.attendees,
    required this.location,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    required this.eventImageUrl,
  });

  // factory UserEventModel.fromJson(Map<String, dynamic> json) {
  //   final eventTitle = json['event_title'] ?? '';
  factory UserEventModel.fromJson(Map<String, dynamic> json) {
    final eventTitle = json['event_title'] ?? '';

    // Try multiple field name variations to find the date
    final eventDateValue = json['event_date'] ?? json['eventDate'] ?? json['event_date_time'];

    return UserEventModel(
      id: json['_id'] ?? '',
      eventTitle: eventTitle,
      description: json['description'] ?? '',
      speakers:
          (json['speakers'] as List).map((e) => Speaker.fromJson(e)).toList(),
      // FIXED: Convert UTC to local time, matching EventModel behavior
      eventDate: _parseEventDate(eventDateValue, eventTitle),
      attendees: json['attendees'] ?? [],
      location: json['location'] ?? '',
      price: json['price'] ?? 0,
      // FIXED: Convert UTC to local time for consistency
      createdAt:
          json['created_at'] != null
              ? (DateTime.tryParse(json['created_at'])?.toLocal() ?? DateTime.now())
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? (DateTime.tryParse(json['updated_at'])?.toLocal() ?? DateTime.now())
              : DateTime.now(),
      eventImageUrl: json['event_image_url'] ?? '',
    );
  }

  // Helper to parse event date with debugging
  static DateTime _parseEventDate(dynamic dateStr, String eventTitle) {
    if (dateStr == null) {
      return DateTime.now();
    }
    
    try {
      final dateString = dateStr.toString().trim();
      
      final parsed = DateTime.tryParse(dateString);
      if (parsed == null) {
        return DateTime.now();
      }
      
      final local = parsed.toLocal();
      return local;
    } catch (e) {
      return DateTime.now();
    }
  }
}

class EventCreator {
  final String id;
  final String firstName;
  final String lastName;
  final String profilePicture;

  EventCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
  });

  factory EventCreator.fromJson(Map<String, dynamic> json) {
    return EventCreator(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
    );
  }
}

class Speaker {
  final String name;
  final String image;
  final String id;

  Speaker({required this.name, required this.image, required this.id});

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}
