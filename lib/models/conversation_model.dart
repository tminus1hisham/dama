class ConversationModel {
  final String id;
  final List<Participant> participants;
  final String createdAt;
  final LastMessage? lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['_id'] ?? '',
      participants:
          (json['participants'] as List?)
              ?.map((e) => Participant.fromJson(e))
              .toList() ??
          [],
      createdAt: json['createdAt'] ?? '',
      lastMessage:
          json['lastMessage'] != null
              ? LastMessage.fromJson(json['lastMessage'])
              : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class LastMessage {
  final String id;
  final String content;
  final String senderId;
  final String createdAt;

  LastMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      senderId:
          json['sender'] is String
              ? json['sender']
              : (json['sender']?['_id'] ?? ''),
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class Participant {
  final String id;
  final String firstName;
  final String lastName;
  final String profilePicture;

  Participant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
    );
  }
}
