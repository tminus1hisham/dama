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

  factory UserEventModel.fromJson(Map<String, dynamic> json) {
    return UserEventModel(
      id: json['_id'] ?? '',
      eventTitle: json['event_title'] ?? '',
      description: json['description'] ?? '',
      speakers:
          (json['speakers'] as List).map((e) => Speaker.fromJson(e)).toList(),
      eventDate: DateTime.parse(
        json['event_date'] ?? DateTime.now().toString(),
      ),
      attendees: json['attendees'] ?? [],
      location: json['location'] ?? '',
      price: json['price'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toString(),
      ),
      eventImageUrl: json['event_image_url'] ?? '',
    );
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
