class ResourceModel {
  final String id;
  final String title;
  final int price;
  final String description;
  final String resourceLink;
  final List<dynamic> ratings;
  final String resourceImageUrl;
  final DateTime createdAt;
  final double averageRating;

  ResourceModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.resourceLink,
    required this.ratings,
    required this.resourceImageUrl,
    required this.createdAt,
    required this.averageRating,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['_id'],
      title: json['title'],
      price: json['price'],
      description: json['description'],
      resourceLink: json['resource_link'],
      ratings: List<dynamic>.from(json['ratings']),
      resourceImageUrl: json['resource_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'price': price,
    'description': description,
    'resource_link': resourceLink,
    'ratings': ratings,
    'resource_image_url': resourceImageUrl,
    'created_at': createdAt.toIso8601String(),
    'averageRating': averageRating,
  };
}
