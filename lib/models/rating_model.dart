class RatingModel {
  final double rating;

  RatingModel({required this.rating});

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(rating: json['rating']);
  }

  Map<String, dynamic> toJson() {
    return {'rating': rating};
  }
}
