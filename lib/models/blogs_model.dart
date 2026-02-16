class BlogResponse {
  final bool success;
  final List<BlogPostModel> blogPosts;

  BlogResponse({required this.success, required this.blogPosts});

  factory BlogResponse.fromJson(Map<String, dynamic> json) {
    return BlogResponse(
      success: json['success'] ?? false,
      blogPosts:
          (json['blogPosts'] as List?)
              ?.map((e) => BlogPostModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BlogPostModel {
  final String id;
  final String title;
  final Author? author;
  final String status;
  final String description;
  final String? category;
  final List<Comment> comments;
  final List<Map<String, dynamic>> likes;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SourceReference> sources;

  BlogPostModel({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    required this.description,
    this.category,
    required this.comments,
    required this.likes,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.sources = const [],
  });

  static String _stripHtml(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static String _parseDescription(dynamic description) {
    if (description is String) {
      return _stripHtml(description);
    } else if (description is Map<String, dynamic>) {
      // Handle Quill.js delta format or similar JSON structures
      if (description.containsKey('ops')) {
        // Quill delta format
        final ops = description['ops'] as List?;
        if (ops != null) {
          return ops.map((op) {
            if (op is Map && op.containsKey('insert')) {
              return op['insert']?.toString() ?? '';
            }
            return '';
          }).join('');
        }
      } else if (description.containsKey('text')) {
        return description['text']?.toString() ?? '';
      } else if (description.containsKey('html')) {
        return _stripHtml(description['html']?.toString() ?? '');
      }
      // If it's a map but doesn't match known formats, convert to string
      return description.toString();
    }
    return '';
  }

  factory BlogPostModel.fromJson(Map<String, dynamic> json) {
    // Handle 'categories' field - can be array or string
    String? categoryValue;
    final categories = json['categories'];
    if (categories is List && categories.isNotEmpty) {
      categoryValue = categories.first?.toString();
    } else if (categories is String) {
      categoryValue = categories;
    }

    return BlogPostModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] != null ? Author.fromJson(json['author']) : null,
      status: json['status'] ?? '',
      description: _parseDescription(json['description']),
      category: categoryValue ?? 'UNCATEGORIZED',
      comments:
          (json['comments'] as List?)
              ?.map((e) {
                try {
                  if (e is Map<String, dynamic>) {
                    return Comment.fromJson(e);
                  } else if (e is String) {
                    // Handle case where comment is just an ID string
                    return null; // Skip string IDs for now
                  } else {
                    return null;
                  }
                } catch (err) {
                  print('Error parsing blog comment: '
                      '[31m$err[0m, data: $e');
                  return null;
                }
              })
              .whereType<Comment>()
              .toList() ??
          [],
      likes:
          (json['likes'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      imageUrl: json['image_url'] ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updated_at'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => SourceReference.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SourceReference {
  final String title;
  final String url;

  SourceReference({
    required this.title,
    required this.url,
  });

  factory SourceReference.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return SourceReference(
        title: json['title']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
      );
    } else if (json is String) {
      // Fallback for simple string sources
      return SourceReference(title: json, url: json);
    }
    return SourceReference(title: '', url: '');
  }
}

class Author {
  final String id;
  final String firstName;
  final String lastName;
  final String profilePicture;
  final List<String> roles;

  Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.roles,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
    );
  }
}

class Comment {
  final String id;
  final UserModel? user;
  final String comment;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.user,
    required this.comment,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      user:
          json['user_id'] != null ? UserModel.fromJson(json['user_id']) : null,
      comment: json['comment'] ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String profilePicture;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
    );
  }
}
