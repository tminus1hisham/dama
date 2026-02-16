class RolesModel {
  final String blogger;
  final String newsAuthor;

  RolesModel({required this.blogger, required this.newsAuthor});

  factory RolesModel.fromJson(Map<String, dynamic> json) {
    return RolesModel(
      blogger: json['BLOGGER'],
      newsAuthor: json['NEWS_AUTHOR'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'BLOGGER': blogger, 'NEWS_AUTHOR': newsAuthor};
  }
}
