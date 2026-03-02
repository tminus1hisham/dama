class PlanModel {
  final String id;
  final String membership;
  final String type;
  final int price;
  final List<String> included;
  final List<String> benefits;
  final String createdAt;
  final String updatedAt;

  PlanModel({
    required this.id,
    required this.membership,
    required this.type,
    required this.price,
    required this.included,
    required this.benefits,
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
      benefits: json['benefits'] != null 
          ? List<String>.from(json['benefits']) 
          : [],
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
      'benefits': benefits,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create a copy of this plan
  PlanModel copyWith({
    String? id,
    String? membership,
    String? type,
    int? price,
    List<String>? included,
    List<String>? benefits,
    String? createdAt,
    String? updatedAt,
  }) {
    return PlanModel(
      id: id ?? this.id,
      membership: membership ?? this.membership,
      type: type ?? this.type,
      price: price ?? this.price,
      included: included ?? this.included,
      benefits: benefits ?? this.benefits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}