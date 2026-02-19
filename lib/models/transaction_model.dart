import 'dart:developer' as developer;

class TransactionModel {
  final String id;
  final String amount;
  final String status;
  final DateTime createdAt;
  final String checkoutRequestID;
  final String mpesaShortCode;
  final UserModel user;
  final dynamic object; // Can be EventModel or ResourceModel
  final String onModel;
  final String? rawObjectId; // Store ID when object is not populated

  TransactionModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.checkoutRequestID,
    required this.mpesaShortCode,
    required this.user,
    this.object,
    required this.onModel,
    this.rawObjectId,
  });

  // Getters for type-safe access
  EventTransactionModel? get event =>
      object is EventTransactionModel ? object as EventTransactionModel : null;

  ResourceTransactionModel? get resource =>
      object is ResourceTransactionModel
          ? object as ResourceTransactionModel
          : null;

  // Helper getter for display title
  String get objectTitle {
    if (object is EventTransactionModel) {
      return (object as EventTransactionModel).eventTitle;
    } else if (object is ResourceTransactionModel) {
      return (object as ResourceTransactionModel).title;
    }
    return 'Unknown';
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    try {
      developer.log('Parsing transaction: ${json['_id']}');

      // Parse the object based on onModel type
      dynamic parsedObject;
      String? rawObjectId;
      final objectData = json['object_id'];
      final onModel = json['onModel']?.toString() ?? 'Event';

      if (objectData != null && objectData is Map<String, dynamic>) {
        // Object is populated with full data
        if (onModel == 'Event') {
          parsedObject = EventTransactionModel.fromJson(objectData);
        } else if (onModel == 'Resource') {
          parsedObject = ResourceTransactionModel.fromJson(objectData);
        }
      } else if (objectData != null && objectData is String) {
        // Object is just an ID string (not populated)
        rawObjectId = objectData;
      }

      return TransactionModel(
        id: json['_id']?.toString() ?? '',
        amount: json['amount']?.toString() ?? '0',
        status: json['status']?.toString() ?? 'Unknown',
        createdAt:
            json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
        checkoutRequestID: json['checkoutRequestID']?.toString() ?? '',
        mpesaShortCode: json['mpesa_short_code']?.toString() ?? '',
        user:
            json['user_id'] != null
                ? UserModel.fromJson(json['user_id'] as Map<String, dynamic>)
                : UserModel.empty(),
        object: parsedObject,
        onModel: onModel,
        rawObjectId: rawObjectId,
      );
    } catch (e, stackTrace) {
      developer.log('Error parsing TransactionModel: $e');
      developer.log('Stack trace: $stackTrace');
      developer.log('JSON data: $json');

      // Return a safe default transaction
      return TransactionModel(
        id: json['_id']?.toString() ?? 'unknown',
        amount: '0',
        status: 'Error',
        createdAt: DateTime.now(),
        checkoutRequestID: '',
        mpesaShortCode: '',
        user: UserModel.empty(),
        object: null,
        onModel: 'Unknown',
      );
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['_id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
      );
    } catch (e) {
      developer.log('Error parsing UserModel: $e');
      return UserModel.empty();
    }
  }

  factory UserModel.empty() {
    return UserModel(id: '', email: '', firstName: 'Unknown', lastName: 'User');
  }

  String get fullName => '$firstName $lastName'.trim();
}

class EventTransactionModel {
  final String id;
  final String eventCreator; // This will be just the ObjectId string
  final String eventTitle;
  final String description;
  final List<Speaker> speakers;
  final List<String> attendeeIds; // Changed to store just IDs
  final String location;
  final DateTime eventDate;
  final int price;
  final String eventImageUrl;
  final DateTime createdAt;

  EventTransactionModel({
    required this.id,
    required this.eventCreator,
    required this.eventTitle,
    required this.description,
    required this.speakers,
    required this.attendeeIds,
    required this.location,
    required this.eventDate,
    required this.price,
    required this.eventImageUrl,
    required this.createdAt,
  });

  factory EventTransactionModel.fromJson(Map<String, dynamic> json) {
    try {
      developer.log('Parsing event: ${json['_id']}');

      return EventTransactionModel(
        id: json['_id']?.toString() ?? '',
        eventCreator: json['event_creator']?.toString() ?? 'Unknown',
        // Just store the ID
        eventTitle: json['event_title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        speakers: _parseSpeakers(json['speakers']),
        attendeeIds: _parseAttendeeIds(json['attendees']),
        location: json['location']?.toString() ?? '',
        eventDate:
            json['event_date'] != null
                ? DateTime.tryParse(json['event_date'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
        price: _parsePrice(json['price']),
        eventImageUrl: json['event_image_url']?.toString() ?? '',
        createdAt:
            json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log('Error parsing EventModel: $e');
      developer.log('Stack trace: $stackTrace');
      developer.log('JSON data: $json');

      return EventTransactionModel(
        id: json['_id']?.toString() ?? 'unknown',
        eventCreator: 'Unknown',
        eventTitle: 'Unknown Event',
        description: 'No description available',
        speakers: [],
        attendeeIds: [],
        location: 'Unknown Location',
        eventDate: DateTime.now(),
        price: 0,
        eventImageUrl: '',
        createdAt: DateTime.now(),
      );
    }
  }

  static List<Speaker> _parseSpeakers(dynamic speakers) {
    if (speakers == null) return [];
    if (speakers is! List) return [];

    try {
      return speakers
          .map((speaker) {
            try {
              if (speaker is Map<String, dynamic>) {
                return Speaker.fromJson(speaker);
              }
              return null;
            } catch (e) {
              developer.log('Error parsing individual speaker: $e');
              return null;
            }
          })
          .where((speaker) => speaker != null)
          .cast<Speaker>()
          .toList();
    } catch (e) {
      developer.log('Error parsing speakers list: $e');
      return [];
    }
  }

  static List<String> _parseAttendeeIds(dynamic attendees) {
    if (attendees == null) return [];
    if (attendees is! List) return [];

    try {
      return attendees
          .map((attendee) => attendee?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      developer.log('Error parsing attendees: $e');
      return [];
    }
  }

  static int _parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is int) return price;
    if (price is double) return price.round();
    if (price is String) {
      return int.tryParse(price) ?? 0;
    }
    return 0;
  }

  int get attendeeCount => attendeeIds.length;

  Map<String, dynamic> toJson() => {
    '_id': id,
    'event_creator': eventCreator,
    'event_title': eventTitle,
    'description': description,
    'speakers': speakers.map((e) => e.toJson()).toList(),
    'attendees': attendeeIds,
    'location': location,
    'event_date': eventDate.toIso8601String(),
    'price': price,
    'event_image_url': eventImageUrl,
    'created_at': createdAt.toIso8601String(),
  };
}

class ResourceTransactionModel {
  final String id;
  final String title;
  final int price;
  final String description;
  final int downloads;
  final String resourceLink;
  final List<String> ratingIds; // Store rating IDs as strings
  final String resourceImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResourceTransactionModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.downloads,
    required this.resourceLink,
    required this.ratingIds,
    required this.resourceImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResourceTransactionModel.fromJson(Map<String, dynamic> json) {
    try {
      developer.log('Parsing resource: ${json['_id']}');

      return ResourceTransactionModel(
        id: json['_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        price: _parsePrice(json['price']),
        description: json['description']?.toString() ?? '',
        downloads: _parseDownloads(json['downloads']),
        resourceLink: json['resource_link']?.toString() ?? '',
        ratingIds: _parseRatingIds(json['ratings']),
        resourceImageUrl: json['resource_image_url']?.toString() ?? '',
        createdAt:
            json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
        updatedAt:
            json['updated_at'] != null
                ? DateTime.tryParse(json['updated_at'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log('Error parsing ResourceModel: $e');
      developer.log('Stack trace: $stackTrace');
      developer.log('JSON data: $json');

      return ResourceTransactionModel(
        id: json['_id']?.toString() ?? 'unknown',
        title: 'Unknown Resource',
        price: 0,
        description: 'No description available',
        downloads: 0,
        resourceLink: '',
        ratingIds: [],
        resourceImageUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static int _parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is int) return price;
    if (price is double) return price.round();
    if (price is String) {
      return int.tryParse(price) ?? 0;
    }
    return 0;
  }

  static int _parseDownloads(dynamic downloads) {
    if (downloads == null) return 0;
    if (downloads is int) return downloads;
    if (downloads is double) return downloads.round();
    if (downloads is String) {
      return int.tryParse(downloads) ?? 0;
    }
    return 0;
  }

  static List<String> _parseRatingIds(dynamic ratings) {
    if (ratings == null) return [];
    if (ratings is! List) return [];

    try {
      return ratings
          .map((rating) => rating?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      developer.log('Error parsing ratings: $e');
      return [];
    }
  }

  int get ratingCount => ratingIds.length;

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'price': price,
    'description': description,
    'downloads': downloads,
    'resource_link': resourceLink,
    'ratings': ratingIds,
    'resource_image_url': resourceImageUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class Speaker {
  final String id;
  final String name;
  final String image;

  Speaker({required this.id, required this.name, required this.image});

  factory Speaker.fromJson(Map<String, dynamic> json) {
    try {
      return Speaker(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Speaker',
        image: json['image']?.toString() ?? '',
      );
    } catch (e) {
      developer.log('Error parsing Speaker: $e');
      return Speaker(id: '', name: 'Unknown Speaker', image: '');
    }
  }

  Map<String, dynamic> toJson() => {'_id': id, 'name': name, 'image': image};
}

// Keep the Attendee class for future use if you need to fetch full attendee details
class Attendee {
  final String id;
  final String name;
  final String profilePicture;

  Attendee({
    required this.id,
    required this.name,
    required this.profilePicture,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'profile_picture': profilePicture,
  };
}
