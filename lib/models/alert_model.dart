class AlertModel {
  final String id;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlertModel({
    required this.id,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}
