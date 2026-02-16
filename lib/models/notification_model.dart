class NotificationModel {
  final String id;
  final bool read;
  final String title;
  final String body;
  final DateTime? createdAt;
  final String? type; // 'blog', 'news', 'event', etc.
  final String? referenceId; // ID of the blog/news/event

  NotificationModel({
    required this.id,
    required this.read,
    required this.title,
    required this.body,
    this.createdAt,
    this.type,
    this.referenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      read: json['read'] ?? false,
      body: json['body'] ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : (json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : null),
      type: json['type'],
      referenceId: json['referenceId'] ?? json['reference_id'],
    );
  }
}
