class ArticleCountModel {
  final int articlesSeenCount;
  final int articlesAssignedCount;

  ArticleCountModel({
    required this.articlesSeenCount,
    required this.articlesAssignedCount,
  });

  factory ArticleCountModel.fromJson(Map<String, dynamic> json) {
    return ArticleCountModel(
      articlesSeenCount: json['articles_seen_count'] ?? 0,
      articlesAssignedCount: json['articles_assigned_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'articles_seen_count': articlesSeenCount,
      'articles_assigned_count': articlesAssignedCount,
    };
  }

  bool get hasExceededLimit => articlesSeenCount >= articlesAssignedCount;
}
