class Conversation {
  final String id;
  final List<String> participants;
  final Message? lastMessage;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'] != null ? Message.fromJson(json['lastMessage']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class User {
  final String id;
  final String fullName;
  final String? profilePicture;

  User({
    required this.id,
    required this.fullName,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      profilePicture: json['profilePicture'],
    );
  }
}