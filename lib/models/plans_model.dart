class PlanModel {
  final String id;
  final String membership;
  final String type;
  final int price;
  final List<String> included;
  final String createdAt;
  final String updatedAt;

  PlanModel({
    required this.id,
    required this.membership,
    required this.type,
    required this.price,
    required this.included,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['_id'],
      membership: json['membership'],
      type: json['type'],
      price: json['price'],
      included: List<String>.from(json['included']),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'membership': membership,
      'type': type,
      'price': price,
      'included': included,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
