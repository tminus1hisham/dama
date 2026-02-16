class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] as String,
      conversationId:
          json['conversation'] is String
              ? json['conversation']
              : json['conversation']['_id'],
      // Handle both string and object cases
      senderId:
          json['sender'] is String ? json['sender'] : json['sender']['_id'],
      // Handle both string and object cases
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'conversation': conversationId,
      'sender': senderId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
