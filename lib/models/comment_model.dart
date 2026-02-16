class CommentModel {
  final String comment;

  CommentModel({required this.comment});

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(comment: json['comment']);
  }

  Map<String, dynamic> toJson() {
    return {'comment': comment};
  }
}
