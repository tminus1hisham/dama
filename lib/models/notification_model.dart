import 'package:flutter/foundation.dart';

class NotificationModel {
  final String id;
  final bool read;
  final String title;
  final String body;
  final DateTime? createdAt;
  final String? type; // 'blog', 'news', 'event', etc.
  final String? referenceId; // ID of the blog/news/event
  final Map<String, dynamic>? data; // Additional data from backend

  NotificationModel({
    required this.id,
    required this.read,
    required this.title,
    required this.body,
    this.createdAt,
    this.type,
    this.referenceId,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Extract ID - check both '_id' (MongoDB style) and 'id'
    String extractedId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    
    // Extract type from 'type' field or 'data' field
    String? extractedType = json['type']?.toString();
    String? extractedRefId = json['referenceId']?.toString() ?? json['reference_id']?.toString();
    Map<String, dynamic>? dataMap;
    
    // Handle 'data' field - can be a String (the type) or a Map
    if (json['data'] != null) {
      if (json['data'] is Map) {
        dataMap = Map<String, dynamic>.from(json['data']);
        // Use 'type' from data map, or 'data' key within the map
        if (extractedType == null || extractedType.isEmpty) {
          extractedType = dataMap['type']?.toString() ?? dataMap['data']?.toString();
        }
        // Extract referenceId from data map - check multiple possible keys
        if (extractedRefId == null || extractedRefId.isEmpty) {
          extractedRefId = dataMap['referenceId']?.toString() ?? 
                          dataMap['reference_id']?.toString() ?? 
                          dataMap['id']?.toString() ??
                          dataMap['blogId']?.toString() ??
                          dataMap['newsId']?.toString() ??
                          dataMap['eventId']?.toString() ??
                          dataMap['trainingId']?.toString();
        }
      } else if (json['data'] is String) {
        // If 'data' is a string, it might be the type directly (e.g., "blog", "news")
        if (extractedType == null || extractedType.isEmpty) {
          extractedType = json['data'];
        }
        // Store string data in a map for consistency
        dataMap = {'data': json['data']};
      }
    }
    
    debugPrint('[NotificationModel.fromJson] Extracted:');
    debugPrint('  - ID: $extractedId');
    debugPrint('  - Type: $extractedType');
    debugPrint('  - ReferenceId: $extractedRefId');
    debugPrint('  - Raw data keys: ${dataMap?.keys.toList()}');
    
    return NotificationModel(
      id: extractedId,
      title: json['title']?.toString() ?? '',
      read: json['read'] ?? false,
      body: json['body']?.toString() ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : (json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : null),
      type: extractedType?.toLowerCase(),
      referenceId: extractedRefId,
      data: dataMap,
    );
  }
  
  // Helper getter to get notification category/type
  // Infers type from title or data keys if not explicitly set
  String? get notificationType {
    // First check explicit type field
    if (type != null && type!.isNotEmpty) {
      return type!.toLowerCase();
    }
    // Then check data field keys to infer type
    if (data != null) {
      // Check for specific keys in data that indicate the type
      if (data!.containsKey('blogPost') || data!.containsKey('blog')) {
        return 'blog';
      }
      if (data!.containsKey('newsPost') || data!.containsKey('news')) {
        return 'news';
      }
      if (data!.containsKey('event') || data!.containsKey('eventId')) {
        return 'event';
      }
      // Check for 'type' field in data
      final dataType = data!['type']?.toString();
      if (dataType != null && dataType.isNotEmpty) {
        return dataType.toLowerCase();
      }
    }
    // Infer from title as fallback
    final titleLower = title.toLowerCase();
    if (titleLower.contains('blog')) return 'blog';
    if (titleLower.contains('news')) return 'news';
    if (titleLower.contains('event')) return 'event';
    return null;
  }
  
  // Helper getter to get reference ID
  // Extracts ID from various possible data keys
  String? get refId {
    if (referenceId != null && referenceId!.isNotEmpty) {
      return referenceId;
    }
    if (data != null) {
      // Check for blog post ID
      final blogId = data!['blogPost'] ?? data!['blog'] ?? data!['blogId'];
      if (blogId != null) return blogId.toString();
      
      // Check for news ID
      final newsId = data!['newsPost'] ?? data!['news'] ?? data!['newsId'];
      if (newsId != null) return newsId.toString();
      
      // Check for event ID
      final eventId = data!['event'] ?? data!['eventId'];
      if (eventId != null) return eventId.toString();
      
      // Generic fallback
      return data!['referenceId'] ?? data!['reference_id'] ?? data!['id'];
    }
    return null;
  }
}
