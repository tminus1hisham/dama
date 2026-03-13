import 'package:dama/models/blogs_model.dart' show SourceReference;
import 'package:flutter/foundation.dart';

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
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        ) // Normalize whitespace (newlines, tabs -> single space)
        .trim();
  }

  /// Extract opening sentences for preview (2-3 sentences, max 80 words)
  /// Ensures first sentence is shown completely, expands only if needed
  static String getOpeningSentence(String description) {
    final cleaned = _stripHtml(description).trim();
    if (cleaned.isEmpty) return '';

    // Find the first sentence (ends with . ! or ?)
    final match = RegExp(r'^([^.!?]*[.!?])').firstMatch(cleaned);
    if (match != null) {
      final sentence = match.group(1)?.trim() ?? '';
      final words = sentence.split(RegExp(r'\s+'));

      // If first sentence is very short (< 15 words), extend to next sentences
      if (words.length < 15) {
        final twoSentences = RegExp(
          r'^([^.!?]*[.!?]\s*[^.!?]*[.!?])',
        ).firstMatch(cleaned);
        if (twoSentences != null) {
          final extended = twoSentences.group(1)?.trim() ?? sentence;
          final extendedWords = extended.split(RegExp(r'\s+'));

          // If still short and under 50 words, try adding third sentence
          if (extendedWords.length < 50) {
            final threeSentences = RegExp(
              r'^([^.!?]*[.!?]\s*[^.!?]*[.!?]\s*[^.!?]*[.!?])',
            ).firstMatch(cleaned);
            if (threeSentences != null) {
              final result = threeSentences.group(1)?.trim() ?? extended;
              final resultWords = result.split(RegExp(r'\s+'));

              // Cap at 80 words total for preview
              if (resultWords.length > 80) {
                return resultWords.take(80).join(' ') + '...';
              }
              return result;
            }
          }
          return extended;
        }
      }

      return sentence;
    }

    // No sentence terminator found, return whole text
    return cleaned;
  }

  /// Cleans up HTML content to normalize spacing
  static String _cleanupHtml(String html) {
    return html
        // Remove multiple consecutive <br> tags (keep max 1)
        .replaceAll(
          RegExp(r'(<br\s*/?>\s*){2,}', caseSensitive: false),
          '<br/>',
        )
        // Remove <br> at start/end of paragraphs
        .replaceAll(RegExp(r'<p>\s*<br\s*/?>\s*', caseSensitive: false), '<p>')
        .replaceAll(
          RegExp(r'\s*<br\s*/?>\s*</p>', caseSensitive: false),
          '</p>',
        )
        // Remove empty paragraphs
        .replaceAll(RegExp(r'<p>\s*</p>', caseSensitive: false), '')
        // Normalize multiple spaces
        .replaceAll(RegExp(r' {2,}'), ' ')
        // Remove excessive newlines between tags
        .replaceAll(RegExp(r'>\s*\n\s*\n+\s*<'), '>\n<')
        .trim();
  }

  /// Converts plain text with newlines into HTML paragraphs
  static String _convertToHtmlParagraphs(String text) {
    if (text.contains('<p>') ||
        text.contains('<br') ||
        text.contains('<div>')) {
      // Already contains HTML structure, clean it up and return
      return _cleanupHtml(text);
    }

    // Normalize excessive whitespace first
    String normalized =
        text
            .replaceAll(RegExp(r'\r\n'), '\n') // Normalize line endings
            .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Max 2 newlines
            .replaceAll(RegExp(r' {2,}'), ' ') // Normalize spaces
            .trim();

    // Split by double newlines (paragraph breaks)
    final paragraphs = normalized.split(RegExp(r'\n\n+'));
    if (paragraphs.length > 1) {
      return paragraphs
          .where((p) => p.trim().isNotEmpty)
          .map(
            (p) => '<p>${p.trim().replaceAll('\n', ' ')}</p>',
          ) // Single newlines become spaces
          .join('\n');
    }

    // Single paragraph - single newlines become spaces for proper flow
    return '<p>${normalized.replaceAll('\n', ' ')}</p>';
  }

  static String _parseDescription(dynamic description) {
    if (description is String) {
      // Preserve HTML for flutter_html rendering
      return _convertToHtmlParagraphs(description);
    } else if (description is Map<String, dynamic>) {
      // Try different possible formats
      if (description.containsKey('ops')) {
        // Quill delta format - convert ops to HTML
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
          return _convertToHtmlParagraphs(text.trim());
        }
      }

      // Try HTML format first (no stripping)
      if (description.containsKey('html')) {
        return description['html']?.toString() ?? '';
      }

      // Try other formats
      final text = description['text'] ?? description['content'] ?? '';
      if (text is String) {
        return _convertToHtmlParagraphs(text);
      }

      // Last resort: convert to string
      return _convertToHtmlParagraphs(description.toString());
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
          categoryData['title']?.toString() ??
          '';
    }
    return categoryData.toString();
  }

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('[NewsModel.fromJson] Raw JSON keys: ${json.keys.toList()}');
      debugPrint('[NewsModel.fromJson] Full JSON: $json');
      return NewsModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled',
        author:
            json['author'] != null
                ? Author.fromJson(json['author'])
                : Author.empty(),
        description: _parseDescription(json['description']),
        comments:
            (json['comments'] is List)
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
                        print(
                          'Error parsing comment: '
                          '[31m$err[0m, data: $e',
                        );
                        return null;
                      }
                    })
                    .whereType<Comment>()
                    .toList()
                : [],
        likes:
            (json['likes'] is List)
                ? (json['likes'] as List).map((e) {
                  try {
                    if (e is Map<String, dynamic>) {
                      return e;
                    } else if (e is String) {
                      return {'userId': e};
                    } else {
                      return <String, dynamic>{};
                    }
                  } catch (err) {
                    print(
                      'Error parsing like: '
                      '\u001b[31m$err\u001b[0m, data: $e',
                    );
                    return <String, dynamic>{};
                  }
                }).toList()
                : [],
        isFeatured:
            json['isFeatured'] is List
                ? (json['isFeatured'].isNotEmpty
                    ? json['isFeatured'][0] == true
                    : false)
                : (json['isFeatured'] ?? false),
        imageUrl: json['image_url']?.toString() ?? '',
        createdAt:
            json['created_at'] != null
                ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
                : DateTime.now(),
        sources:
            (json['sources'] is List)
                ? (json['sources'] as List)
                    .map((e) {
                      try {
                        return SourceReference.fromJson(e);
                      } catch (err) {
                        print(
                          'Error parsing source: '
                          '\u001b[31m$err\u001b[0m, data: $e',
                        );
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
    // Handle roles - can be List<String> or empty
    List<String> roles = [];
    final rolesData = json['roles'];
    if (rolesData is List) {
      roles = List<String>.from(rolesData.map((r) => r.toString()));
    } else if (rolesData is Map) {
      // If roles is a map, extract keys (e.g., {"ADMIN": "admin"} -> ["ADMIN"])
      roles = (rolesData as Map).keys.toList().cast<String>();
    }

    return Author(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString() ?? '',
      roles: roles,
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
