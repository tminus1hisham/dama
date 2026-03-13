import 'package:flutter/foundation.dart';

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
      // Handle Quill.js delta format or similar JSON structures
      if (description.containsKey('ops')) {
        // Quill delta format - convert ops to HTML
        final ops = description['ops'] as List?;
        if (ops != null) {
          String text = ops
              .map((op) {
                if (op is Map && op.containsKey('insert')) {
                  return op['insert']?.toString() ?? '';
                }
                return '';
              })
              .join('');
          return _convertToHtmlParagraphs(text);
        }
      } else if (description.containsKey('html')) {
        // Already HTML, return as-is
        return description['html']?.toString() ?? '';
      } else if (description.containsKey('text')) {
        return _convertToHtmlParagraphs(description['text']?.toString() ?? '');
      }
      // If it's a map but doesn't match known formats, convert to string
      return _convertToHtmlParagraphs(description.toString());
    }
    return '';
  }

  factory BlogPostModel.fromJson(Map<String, dynamic> json) {
    // Debug: Check if sources/references exists in API response
    debugPrint('[BlogPostModel.fromJson] Raw JSON keys: ${json.keys.toList()}');
    debugPrint('[BlogPostModel.fromJson] _id value: ${json['_id']}');
    debugPrint('[BlogPostModel.fromJson] id value: ${json['id']}');

    if (json['sources'] != null ||
        json['references'] != null ||
        json['source_references'] != null) {
      print('=== BLOG SOURCES DEBUG ===');
      print('sources: ${json['sources']}');
      print('references: ${json['references']}');
      print('source_references: ${json['source_references']}');
      print('=========================');
    }

    // Handle 'categories' field - can be array or string
    String? categoryValue;
    final categories = json['categories'];
    if (categories is List && categories.isNotEmpty) {
      categoryValue = categories.first?.toString();
    } else if (categories is String) {
      categoryValue = categories;
    }

    return BlogPostModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
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
                  print(
                    'Error parsing blog comment: '
                    '[31m$err[0m, data: $e',
                  );
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
          ((json['sources'] ?? json['references'] ?? json['source_references'])
                  as List<dynamic>?)
              ?.map((e) => SourceReference.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SourceReference {
  final String title;
  final String url;

  SourceReference({required this.title, required this.url});

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
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      roles: roles,
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
