import 'package:dama/models/blogs_model.dart' show SourceReference;

class NewsModel {
  final String id;
  final String title;
  final Author author;
  final String description;
  final List<Comment> comments;
  final List<Map<String, dynamic>> likes;
  final bool isFeatured;
  final String imageUrl;
  final DateTime createdAt;
  final List<SourceReference> sources;
  final String? category;

  NewsModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.comments,
    required this.likes,
    required this.isFeatured,
    required this.imageUrl,
    required this.createdAt,
    this.sources = const [],
    this.category,
  });

  static String _stripHtml(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static String _parseDescription(dynamic description) {
    if (description is String) {
      return _stripHtml(description);
    } else if (description is Map<String, dynamic>) {
      // Try different possible formats
      if (description.containsKey('ops')) {
        // Quill delta format
        final ops = description['ops'] as List?;
        if (ops != null && ops.isNotEmpty) {
          String text = '';
          for (var op in ops) {
            if (op is Map && op.containsKey('insert')) {
              final insert = op['insert'];
              if (insert is String) {
                text += insert;
              }
            }
          }
          return text.trim();
        }
      }
      
      // Try other formats
      final text = description['text'] ?? description['html'] ?? description['content'] ?? '';
      if (text is String) {
        return _stripHtml(text);
      }
      
      // Last resort: convert to string
      return description.toString();
    }
    return '';
  }

  static String _parseCategory(dynamic categoryData) {
    if (categoryData == null) return '';
    
    if (categoryData is List && categoryData.isNotEmpty) {
      // Handle categories array like ["Education"]
      final first = categoryData.first;
      return first?.toString() ?? '';
    } else if (categoryData is String) {
      // Handle single category string
      return categoryData;
    } else if (categoryData is Map) {
      // Handle category object like {"name": "Education"}
      return categoryData['name']?.toString() ?? 
             categoryData['title']?.toString() ?? '';
    }
    return categoryData.toString();
  }

    factory NewsModel.fromJson(Map<String, dynamic> json) {
    try {
      return NewsModel(
        id: json['_id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled',
        author: json['author'] != null
            ? Author.fromJson(json['author'])
            : Author.empty(),
        description: _parseDescription(json['description']),
        comments: (json['comments'] is List)
            ? (json['comments'] as List)
                .map((e) {
                  try {
                    if (e is Map<String, dynamic>) {
                      return Comment.fromJson(e);
                    } else if (e is String) {
                      // Handle case where comment is just an ID string
                      // Create a minimal comment object or skip
                      return null; // Skip string IDs for now
                    } else {
                      return null;
                    }
                  } catch (err) {
                    print('Error parsing comment: '
                        '[31m$err[0m, data: $e');
                    return null;
                  }
                })
                .whereType<Comment>()
                .toList()
            : [],
        likes: (json['likes'] is List)
            ? (json['likes'] as List)
                .map((e) {
                  try {
                    if (e is Map<String, dynamic>) {
                      return e;
                    } else if (e is String) {
                      return {'userId': e};
                    } else {
                      return <String, dynamic>{};
                    }
                  } catch (err) {
                    print('Error parsing like: '
                        '\u001b[31m$err\u001b[0m, data: $e');
                    return <String, dynamic>{};
                  }
                })
                .toList()
            : [],
        isFeatured: json['isFeatured'] is List
            ? (json['isFeatured'].isNotEmpty
                ? json['isFeatured'][0] == true
                : false)
            : (json['isFeatured'] ?? false),
        imageUrl: json['image_url']?.toString() ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
            : DateTime.now(),
        sources: (json['sources'] is List)
            ? (json['sources'] as List)
                .map((e) {
                  try {
                    return SourceReference.fromJson(e);
                  } catch (err) {
                    print('Error parsing source: '
                        '\u001b[31m$err\u001b[0m, data: $e');
                    return null;
                  }
                })
                .whereType<SourceReference>()
                .toList()
            : [],
        category: _parseCategory(json['categories'] ?? json['category']),
      );
    } catch (e) {
      print('Error parsing NewsModel: \u001b[31m$e\u001b[0m, data: $json');
      rethrow;
    }
  }
}

class Comment {
  final String id;
  final UserModel user;
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
      id: json['_id']?.toString() ?? '',
      user:
          json['user_id'] != null
              ? UserModel.fromJson(json['user_id'])
              : UserModel.empty(),
      comment: json['comment']?.toString() ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
              : DateTime.now(),
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

  factory UserModel.fromJson(dynamic json) {
    if (json is String) {
      return UserModel(
        id: json,
        firstName: '',
        lastName: '',
        profilePicture: '',
      );
    } else if (json is Map<String, dynamic>) {
      return UserModel(
        id: json['_id']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        profilePicture: json['profile_picture']?.toString() ?? '',
      );
    } else {
      return UserModel.empty();
    }
  }

  factory UserModel.empty() =>
      UserModel(id: '', firstName: '', lastName: '', profilePicture: '');
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
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString() ?? '',
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  factory Author.empty() => Author(
    id: '',
    firstName: '',
    lastName: '',
    profilePicture: '',
    roles: [],
  );
}
