import 'package:flutter/foundation.dart';

class EventModel {
  final String id;
  final String eventCreator;
  final String eventTitle;
  final String description;
  final List<Speaker> speakers;
  final List<Attendee> attendees;
  final String location;
  final DateTime eventDate;
  final int price;
  final String eventImageUrl;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.eventCreator,
    required this.eventTitle,
    required this.description,
    required this.speakers,
    required this.attendees,
    required this.location,
    required this.eventDate,
    required this.price,
    required this.eventImageUrl,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final eventCreatorData = json['event_creator'];
    final String creatorName =
        eventCreatorData != null
            ? '${eventCreatorData['firstName'] ?? ''} ${eventCreatorData['lastName'] ?? ''}'
                .trim()
            : 'Unknown';

    final eventTitle = json['event_title'] ?? '';

    // Try multiple field name variations to find the date
    final eventDateValue = json['event_date'] ?? json['eventDate'] ?? json['event_date_time'];

    final parsedEventDate = _parseEventDate(eventDateValue, eventTitle);

    final parsedPrice = json['price'] is int
        ? json['price']
        : int.tryParse(json['price']?.toString() ?? '0') ?? 0;
    
    debugPrint('🎫 EventModel.fromJson - Title: $eventTitle, Raw Price: ${json['price']} (type: ${json['price'].runtimeType}), Parsed Price: $parsedPrice');

    return EventModel(
      id: json['_id'] ?? '',
      eventCreator: creatorName,
      eventTitle: eventTitle,
      description: json['description'] ?? '',
      speakers:
          (json['speakers'] as List<dynamic>?)
              ?.map((e) => Speaker.fromJson(e))
              .toList() ??
          [],
      attendees:
          (json['attendees'] as List<dynamic>?)
              ?.map((e) => Attendee.fromJson(e))
              .toList() ??
          [],
      location: json['location'] ?? '',
      // FIX: .toLocal() ensures the date is always in device local time
      // regardless of whether the API returns UTC (with Z) or no timezone info
      eventDate: parsedEventDate,
      price:
          json['price'] is int
              ? json['price']
              : int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      eventImageUrl: json['event_image_url'] ?? '',
      createdAt:
          json['created_at'] != null
              ? (DateTime.tryParse(json['created_at'])?.toLocal() ?? DateTime.now())
              : DateTime.now(),
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

  Map<String, dynamic> toJson() => {
    '_id': id,
    'event_creator': eventCreator,
    'event_title': eventTitle,
    'description': description,
    'speakers': speakers.map((e) => e.toJson()).toList(),
    'attendees': attendees.map((e) => e.toJson()).toList(),
    'location': location,
    'event_date': eventDate.toIso8601String(),
    'price': price,
    'event_image_url': eventImageUrl,
    'created_at': createdAt.toIso8601String(),
  };
}

class Speaker {
  final String name;
  final String image;

  Speaker({required this.name, required this.image});

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(name: json['name'] ?? '', image: json['image'] ?? '');
  }

  Map<String, dynamic> toJson() => {'name': name, 'image': image};
}

class Attendee {
  final String name;
  final String profilePicture;

  Attendee({required this.name, required this.profilePicture});

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      name: json['name'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'profile_picture': profilePicture,
  };
}