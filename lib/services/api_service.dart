import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dama/models/alert_model.dart';
import 'package:dama/models/article_count_model.dart';
import 'package:dama/models/blogs_model.dart';
import 'package:dama/models/certificate_model.dart';
import 'package:dama/models/comment_model.dart';
import 'package:dama/models/event_model.dart';
import 'package:dama/models/login_model.dart';
import 'package:dama/models/message_model.dart';
import 'package:dama/models/news_model.dart';
import 'package:dama/models/notification_model.dart';
import 'package:dama/models/payment_model.dart';
import 'package:dama/models/plans_model.dart';
import 'package:dama/models/rating_model.dart';
import 'package:dama/models/resources_model.dart';
import 'package:dama/models/role_request_model.dart';
import 'package:dama/models/transaction_model.dart';
import 'package:dama/models/user_event_model.dart';
import 'package:dama/models/verify_by_phone_model.dart';
import 'package:dama/models/verify_qr_code_model.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/services/modal/handle_unauthorized.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/training_model.dart';
import 'auth_service.dart';
import 'modal/network_modal.dart';

class ApiService {
  Map<String, String> _headers = {'Content-Type': 'application/json'};
  bool _isRefreshing = false;

  void updateHeaders(Map<String, String> newHeaders) {
    _headers.addAll(newHeaders);
  }

  void clearAuthorizationHeader() {
    _headers.remove('Authorization');
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final success = await AuthService.refreshToken();
      if (success) {
        // Update headers with new token
        final newToken = await StorageService.getData('access_token');
        if (newToken != null) {
          updateHeaders({'Authorization': 'Bearer $newToken'});
        }
      }
      return success;
    } finally {
      _isRefreshing = false;
    }
  }

  // Initiate payment via STK Push
  Future<Map<String, dynamic>?> initiatePayment({
    required int amount,
    required String phoneNumber,
    required String model,
    required String objectId,
  }) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse('$BASE_URL/transactions/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'object_id': objectId,
          'model': model,
          'amountToPay': amount,
          'phoneNumber': phoneNumber,
        }),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to initiate payment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('initiatePayment error: $e');
      return null;
    }
  }

  // Handle STK Push callback
  Future<Map<String, dynamic>?> handlePaymentCallback(
      Map<String, dynamic> callbackData) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse('$BASE_URL/transactions/callback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(callbackData),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to handle payment callback: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('handlePaymentCallback error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkServerHealth() async {
    try {
      // Try to get LinkedIn auth URL to check if server is reachable
      final response = await http
          .get(Uri.parse('$BASE_URL/user/linkedin'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      // Server is reachable if we get any response (even redirects or errors)
      if (response.statusCode >= 200 && response.statusCode < 500) {
        return {'status': 'healthy'};
      }
      return null;
    } catch (e) {
      debugPrint('Server health check failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final headers = Map<String, String>.from(_headers);
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.post(
        Uri.parse('$BASE_URL$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to post to $endpoint: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getNewsCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.damakenya.org/v1/news/get/all/category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The expected response is a list of category objects with a 'name' field
        if (data is List) {
          final categories = data
              .map(
                (item) =>
                    item is Map<String, dynamic> && item['name'] != null
                        ? item['name'].toString()
                        : null,
              )
              .whereType<String>()
              .toList();

          // Throw exception if categories list is empty so controller can use fallback
          if (categories.isEmpty) {
            throw Exception('Empty categories list received from API');
          }
          return categories;
        }
        throw Exception(
          'Invalid response format: expected List but got ${data.runtimeType}',
        );
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow; // Let controller handle with fallback
    }
  }

  Future<List<String>> getAllCategories() async {
    return await getCategories();
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.damakenya.org/v1/categories/get/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The expected response is a list of category objects with a 'name' field
        if (data is List) {
          final categories = data
              .map(
                (item) =>
                    item is Map<String, dynamic> && item['name'] != null
                        ? item['name'].toString()
                        : null,
              )
              .whereType<String>()
              .toList();

          // Throw exception if categories list is empty so controller can use fallback
          if (categories.isEmpty) {
            throw Exception('Empty categories list received from API');
          }
          return categories;
        }
        throw Exception(
          'Invalid response format: expected List but got ${data.runtimeType}',
        );
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow; // Let controller handle with fallback
    }
  }

  Future<List<NewsModel>> getNews({
    required int page,
    required int limit,
    String? category,
  }) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final queryParameters = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (category != null && category != 'All News') {
        queryParameters['category'] = category;
      }
      final uri = Uri.parse(
        '$BASE_URL/news/get/all',
      ).replace(queryParameters: queryParameters);
      final response = await http.get(
        uri,
        headers: {
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> newsData = [];

        if (jsonData['newsPosts'] is List) {
          newsData = jsonData['newsPosts'] as List;
        } else if (jsonData['NewsPosts'] is Map &&
            (jsonData['NewsPosts'] as Map).containsKey('docs')) {
          newsData = jsonData['NewsPosts']['docs'] as List;
        } else {
          throw Exception(
            'Invalid news data format: expected newsPosts as List or NewsPosts.docs as List',
          );
        }

        List<NewsModel> newsList = [];
        for (var item in newsData) {
          try {
            NewsModel news = NewsModel.fromJson(item);
            newsList.add(news);
          } catch (e) {
            debugPrint('Error parsing news item: $e, item: $item');
            // Skip this item
          }
        }
        return newsList;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<NewsModel>> getPopularNews(
      {int limit = 10, String? category}) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final queryParameters = {
        'limit': limit.toString(),
        if (category != null && category.isNotEmpty && category != 'All News')
          'category': category.toLowerCase(),
      };
      final uri = Uri.parse(
        '$BASE_URL/news/get/popular',
      ).replace(queryParameters: queryParameters);
      final response = await http.get(
        uri,
        headers: {
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> newsData = [];

        if (jsonData['newsPosts'] is List) {
          newsData = jsonData['newsPosts'] as List;
        } else if (jsonData['NewsPosts'] is Map &&
            (jsonData['NewsPosts'] as Map).containsKey('docs')) {
          newsData = jsonData['NewsPosts']['docs'] as List;
        } else {
          throw Exception(
            'Invalid popular news data format: expected newsPosts as List or NewsPosts.docs as List',
          );
        }

        List<NewsModel> newsList = [];
        for (var item in newsData) {
          try {
            NewsModel news = NewsModel.fromJson(item);
            newsList.add(news);
          } catch (e) {
            debugPrint('Error parsing news item: $e, item: $item');
            // Skip this item
          }
        }
        return newsList;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load popular news: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<NewsModel> getNewsById(String newsId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.get(
        Uri.parse('$BASE_URL/news/get/$newsId'),
        headers: {
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return NewsModel.fromJson(jsonData);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BlogPostModel>> getBlogs({
    required int page,
    required int limit,
    String? category,
  }) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      // Use Uri class to build parameters safely (avoids 'category=null' strings)

      final queryParameters = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (category != null && category != 'All Blogs') {
        queryParameters['category'] = category;
      }

      final uri = Uri.parse(
        '$BASE_URL/blogs/get/all',
      ).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug: Print first blog's categories field
        if (data['blogPosts'] != null &&
            (data['blogPosts'] as List).isNotEmpty) {}

        final blogResponse = BlogResponse.fromJson(data);
        return blogResponse.blogPosts;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load blogs: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getBlogCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.damakenya.org/v1/blogs/get/all/category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The expected response is a list of category objects with a 'name' field
        if (data is List) {
          final categories = data
              .map(
                (item) =>
                    item is Map<String, dynamic> && item['name'] != null
                        ? item['name'].toString()
                        : null,
              )
              .whereType<String>()
              .toList();

          // Throw exception if categories list is empty so caller can use fallback
          if (categories.isEmpty) {
            throw Exception('Empty categories list received from API');
          }
          return categories;
        }
        throw Exception(
          'Invalid response format: expected List but got ${data.runtimeType}',
        );
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow; // Let caller handle with fallback
    }
  }

  Future<BlogPostModel> getBlogById(String blogId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.get(
        Uri.parse('$BASE_URL/blogs/get/post/$blogId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['blogPost'] != null) {
          return BlogPostModel.fromJson(jsonData['blogPost']);
        } else {
          throw Exception('Invalid response format: blogPost not found');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load blog: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ResourceModel>> getResources({
    required int page,
    int limit = 10,
  }) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final queryParameters = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$BASE_URL/resources/get/all',
      ).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Check if response has nested 'data' -> 'resources' structure
        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('data') &&
            jsonData['data'] is Map<String, dynamic> &&
            jsonData['data'].containsKey('resources')) {
          List<dynamic> resourcesData = jsonData['data']['resources'];

          List<ResourceModel> resourcesList = resourcesData
              .map((item) => ResourceModel.fromJson(item))
              .toList();

          return resourcesList;
        }
        // Fallback: Check if response has 'resources' key directly (old format)
        else if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('resources')) {
          List<dynamic> resourcesData = jsonData['resources'];

          List<ResourceModel> resourcesList = resourcesData
              .map((item) => ResourceModel.fromJson(item))
              .toList();

          return resourcesList;
        }
        // Handle case where API returns a list directly
        else if (jsonData is List) {
          List<ResourceModel> resourcesList =
              jsonData.map((item) => ResourceModel.fromJson(item)).toList();
          return resourcesList;
        } else {
          throw Exception(
            'Invalid response format: expected data.resources key, resources key, or List',
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load resources: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ResourceModel>> getUserResources() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/user/resources/all'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> resources = jsonData['resources'];

        List<ResourceModel> resourcesList =
            resources.map((item) => ResourceModel.fromJson(item)).toList();

        return resourcesList;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load resources: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<EventModel>> getEvents() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final headers = <String, String>{};
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/events/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        if (jsonData.containsKey('events')) {
          List<dynamic> eventsData = jsonData['events'];

          return eventsData
              .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception("No events key in response");
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<EventModel> getEventById(String eventId) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/events/$eventId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        if (jsonData.containsKey('event')) {
          return EventModel.fromJson(jsonData['event'] as Map<String, dynamic>);
        } else {
          throw Exception("No event key in response");
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load event: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching event by ID: $e');
      rethrow;
    }
  }

  Future<List<UserEventModel>> getUserEvents() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/user/events/all'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        if (jsonData.containsKey('events')) {
          List<dynamic> eventsData = jsonData['events'];

          return eventsData
              .map(
                (item) => UserEventModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else {
          throw Exception("No events key in response");
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load user events: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching user events: $e');
      rethrow;
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/transactions/get/single/user'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        if (jsonData.containsKey('transactions')) {
          List<dynamic> transactionData = jsonData['transactions'];

          return transactionData
              .map(
                (item) =>
                    TransactionModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else {
          throw Exception("No transaction key in response");
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load transaction: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching transaction: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> pay(PaymentModel request) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      debugPrint('=== API PAYMENT DEBUG ===');
      debugPrint(
          'Token available: ${accessToken != null && accessToken.isNotEmpty}');
      debugPrint('Model: ${request.model}');
      debugPrint('ObjectId: ${request.objectId}');
      debugPrint('Amount: ${request.amountToPay}');
      debugPrint('Phone: ${request.phoneNumber}');

      // Use the generic transactions/pay endpoint for all models
      // The backend will handle initiating M-Pesa STK Push and linking the purchase to the user
      final url = '$BASE_URL/transactions/pay';
      final body = jsonEncode(request.toJson());

      debugPrint('Payment URL: $url');
      debugPrint('Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: body,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        // Try to parse error message from response
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception('Payment failed: $errorMessage');
        } catch (_) {
          throw Exception('Failed to complete payment: ${response.statusCode}');
        }
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Payment error: $e');
      rethrow; // Rethrow to let controller handle it
    }
  }

  Future<Map<String, dynamic>?> addComment(
    CommentModel request,
    String blogID,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.post(
        Uri.parse('$BASE_URL/blogs/comment/$blogID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final headers = <String, String>{};
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/notifications/get/user/notifications'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> notifications = jsonData['notifications'] ?? [];

        // Debug: Print first notification to see structure
        if (notifications.isNotEmpty) {
          debugPrint('First notification raw data: ${notifications.first}');
        }

        List<NotificationModel> notificationList = notifications
            .map((item) => NotificationModel.fromJson(item))
            .toList();

        return notificationList;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      // Try multiple endpoint patterns for compatibility
      // Pattern 1: POST /notifications/mark-as-read (mark all)
      final response = await http.post(
        Uri.parse('$BASE_URL/notifications/mark-as-read'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        return false;
      } else {
        debugPrint(
            'Failed to mark all as read: ${response.statusCode} - ${response.body}');
        // Silently fail - UI will still update locally
        return true; // Return true so UI updates even if server fails
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return true; // Return true so UI updates locally
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return true; // Return true so UI updates locally
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      // Validate notificationId before making the request
      if (notificationId.isEmpty) {
        debugPrint('Error: notificationId is empty');
        return false;
      }

      // Try the correct endpoint based on API docs: POST /notifications/mark-as-read/{notificationId}
      final response = await http.post(
        Uri.parse('$BASE_URL/notifications/mark-as-read/$notificationId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        return false;
      } else if (response.statusCode == 404) {
        debugPrint('Mark as read endpoint not found (404) - marking locally only');
        return true; // Return true so UI updates locally
      } else {
        debugPrint(
            'Failed to mark notification as read: ${response.statusCode} - ${response.body}');
        return true; // Return true so UI updates locally
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return true; // Return true so UI updates locally
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return true; // Return true so UI updates locally
    }
  }

  Future<List<PlanModel>> getPlans() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final headers = <String, String>{};
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/plans/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> plans;
        if (jsonData is List) {
          plans = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('plans')) {
          plans = jsonData['plans'] ?? [];
        } else {
          plans = [];
        }

        if (plans.isEmpty) {
          throw Exception('No plans found');
        }

        List<PlanModel> notificationList =
            plans.map((item) => PlanModel.fromJson(item)).toList();

        return notificationList;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching plans: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> likeBlog(String blogID) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.post(
        Uri.parse('$BASE_URL/blogs/like/$blogID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to like: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Error liking blog: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addNewsComment(
    CommentModel request,
    String blogID,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.post(
        Uri.parse('$BASE_URL/news/comment/$blogID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Error adding news comment: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> likeNews(String blogID) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.post(
        Uri.parse('$BASE_URL/news/like/$blogID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to like: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Error liking news: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String userID) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/user/profile/$userID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to fetch user data: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
          'Failed to fetch current user data: ${response.statusCode}',
        );
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchConversations(String userID) async {
    final accessToken = await StorageService.getData("access_token");

    debugPrint(
      'Fetching conversations from: $CHAT_BASE_URL/chat/conversations/$userID',
    );

    final response = await http.get(
      Uri.parse('$CHAT_BASE_URL/chat/conversations/$userID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    debugPrint('Conversations API status: ${response.statusCode}');
    debugPrint('Conversations API body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch conversations: ${response.statusCode}');
    }
  }

  Future<String> startConversation(String user1, String user2) async {
    final accessToken = await StorageService.getData("access_token");

    final response = await http.get(
      Uri.parse('$CHAT_BASE_URL/chat/conversation/$user1/$user2'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['conversation']['_id'];
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      HandleUnauthorizedService.showUnauthorizedDialog();
      throw Exception('Unauthorized request');
    } else {
      throw Exception("Failed to start conversation");
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final accessToken = await StorageService.getData("access_token");

    final response = await http.get(
      Uri.parse('$CHAT_BASE_URL/chat/messages/$conversationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List messagesJson = data['messages'];
      return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      HandleUnauthorizedService.showUnauthorizedDialog();
      throw Exception('Unauthorized request');
    } else {
      throw Exception("Failed to load messages");
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    final accessToken = await StorageService.getData("access_token");

    final response = await http.delete(
      Uri.parse('$CHAT_BASE_URL/chat/conversation/$conversationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      HandleUnauthorizedService.showUnauthorizedDialog();
      throw Exception('Unauthorized request');
    } else {
      throw Exception("Failed to delete conversation");
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    final accessToken = await StorageService.getData("access_token");

    final response = await http.delete(
      Uri.parse('$CHAT_BASE_URL/chat/message/$messageId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      HandleUnauthorizedService.showUnauthorizedDialog();
      throw Exception('Unauthorized request');
    } else {
      throw Exception("Failed to delete message");
    }
  }

  Future<bool> markMessagesAsRead(String conversationId, String userId) async {
    final accessToken = await StorageService.getData("access_token");

    final response = await http.post(
      Uri.parse('$CHAT_BASE_URL/chat/messages/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'conversationId': conversationId, 'userId': userId}),
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      HandleUnauthorizedService.showUnauthorizedDialog();
      throw Exception('Unauthorized request');
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/search?q=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to perform search: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error during search: $e');
      throw Exception('Error during search');
    }
  }

  Future<Map<String, dynamic>> fetchRoles() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/roles/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to fetch roles: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching roles: $e');
      throw Exception('Error fetching roles');
    }
  }

  Future<bool> requestRole(RoleRequestModel model) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.post(
        Uri.parse('$BASE_URL/roles/request/role/change'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(model.toJson()),
      );

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to request role: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error requesting role: $e');
      throw Exception('Error requesting role');
    }
  }

  Future<Map<String, dynamic>?> rate(
    String resourceID,
    RatingModel request,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      debugPrint('=== RATING DEBUG ===');
      debugPrint('Resource ID: $resourceID');
      debugPrint('Rating: ${request.toJson()}');

      final response = await http.post(
        Uri.parse('$BASE_URL/resources/rate/$resourceID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(request.toJson()),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        // Try to parse error message from response
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              'Failed to rate resource';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('Failed to rate resource: ${response.statusCode}');
        }
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error rating resource: $e');
      rethrow;
    }
  }

  Future<int> verifyByPhone(VerifyByPhoneModel request) async {
    final accessToken = await StorageService.getData("access_token");

    final body = jsonEncode(request);

    final response = await http.post(
      Uri.parse('$BASE_URL/transactions/verify/by/phone'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: body,
    );

    return response.statusCode;
  }

  Future<List<TrainingModel>> getTrainings() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      if (accessToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/trainings/all'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> trainings = jsonData['trainings'] ?? [];

        if (trainings.isEmpty) {
          throw Exception('No trainings found');
        }

        List<TrainingModel> trainingList =
            trainings.map((item) => TrainingModel.fromJson(item)).toList();

        return trainingList;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load trainings: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching trainings: $e');
      rethrow;
    }
  }

  Future<ArticleCountModel> getArticleCount() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.post(
        Uri.parse('$BASE_URL/user/articleCount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: '',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ArticleCountModel.fromJson(jsonData);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load article count: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching article count: $e');
      rethrow;
    }
  }

  Future<List<AlertModel>> getAlerts() async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/alerts/active'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> alertsJson = jsonData['alerts'];

        List<AlertModel> alertsList =
            alertsJson.map((item) => AlertModel.fromJson(item)).toList();

        return alertsList;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserTrainings() async {
    final accessToken = await StorageService.getData("access_token");
    debugPrint(
      'Making API call to get user trainings with token: ${accessToken != null ? 'present' : 'null'}',
    );

    final response = await http.get(
      Uri.parse('$BASE_URL/trainings/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    debugPrint('User trainings API response status: ${response.statusCode}');
    debugPrint('User trainings API response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      debugPrint(
        'Failed to fetch user trainings: ${response.statusCode} - ${response.body}',
      );
      throw Exception('Failed to fetch user trainings');
    }
  }

  Future<bool> cancelTrainingRegistration(String trainingId) async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.post(
      Uri.parse('$BASE_URL/trainings/cancel/$trainingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getUserTrainingDetails(String trainingId) async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.get(
      Uri.parse('$BASE_URL/trainings/user/trainings/$trainingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch training details');
    }
  }

  Future<Map<String, dynamic>> getUserTodaySessions() async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.get(
      Uri.parse('$BASE_URL/user/sessions/today'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch today sessions');
    }
  }

  Future<Map<String, dynamic>> getUserUpcomingSessions() async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.get(
      Uri.parse('$BASE_URL/user/sessions/upcoming'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch upcoming sessions');
    }
  }

  Future<Map<String, dynamic>> getUserTrainingProgress() async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.get(
      Uri.parse('$BASE_URL/user/progress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch training progress');
    }
  }

  Future<bool> joinSession(String trainingId, String sessionId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse(
          '$BASE_URL/trainings/user/trainings/$trainingId/sessions/$sessionId/join',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Try to refresh token first
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the request with new token
          final retryResponse = await http.post(
            Uri.parse(
              '$BASE_URL/trainings/user/trainings/$trainingId/sessions/$sessionId/join',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': _headers['Authorization'] ?? '',
            },
          );
          return retryResponse.statusCode == 200;
        }
        HandleUnauthorizedService.showUnauthorizedDialog();
        return false;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error joining session: $e');
      return false;
    }
  }

  Future<bool> leaveSession(String trainingId, String sessionId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse(
          '$BASE_URL/trainings/user/trainings/$trainingId/sessions/$sessionId/leave',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Try to refresh token first
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the request with new token
          final retryResponse = await http.post(
            Uri.parse(
              '$BASE_URL/trainings/user/trainings/$trainingId/sessions/$sessionId/leave',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': _headers['Authorization'] ?? '',
            },
          );
          return retryResponse.statusCode == 200;
        }
        HandleUnauthorizedService.showUnauthorizedDialog();
        return false;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error leaving session: $e');
      return false;
    }
  }

  Future<int> verifyQrCode(VerifyQrCode verifyModel) async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.post(
      Uri.parse('$BASE_URL/verify-qr'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(verifyModel.toJson()),
    );
    return response.statusCode;
  }

  Future<Map<String, dynamic>> getTrainingSessions(String trainingId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.get(
        Uri.parse('$BASE_URL/trainings/$trainingId/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Try to refresh token first
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the request with new token
          final retryResponse = await http.get(
            Uri.parse('$BASE_URL/trainings/$trainingId/sessions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': _headers['Authorization'] ?? '',
            },
          );
          if (retryResponse.statusCode == 200) {
            return json.decode(retryResponse.body);
          }
        }
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to fetch training sessions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching training sessions: $e');
      rethrow;
    }
  }

  // Auth APIs
  Future<Map<String, dynamic>> login(LoginModel loginModel) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(loginModel.toJson()),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> verify2FA(String otp) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/user/login/2fa/verify'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'otp': otp}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to verify 2FA: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> requestAccountDeletion() async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.post(
      Uri.parse('$BASE_URL/user/delete/account/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to request account deletion: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.post(
      Uri.parse('$BASE_URL/user/change/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to change password: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/user/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to initiate password reset: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithOTP(
    String otp,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/user/reset-password-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'otp': otp, 'newPassword': newPassword}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to reset password: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> initiateLinkedInAuth() async {
    final response = await http.get(
      Uri.parse('$BASE_URL/auth/social/linkedin'),
      headers: _headers,
    );
    debugPrint('LinkedIn initiate response status: ${response.statusCode}');
    debugPrint(
      'LinkedIn initiate response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
    );
    if (response.statusCode == 200) {
      try {
        return json.decode(response.body);
      } catch (e) {
        throw Exception(
          'Invalid JSON response: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...',
        );
      }
    } else {
      throw Exception(
        'Failed to initiate LinkedIn auth: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> linkedInCallback(
    String code,
    String state,
  ) async {
    debugPrint('=== LINKEDIN CALLBACK ===');
    debugPrint('Code: ${code.substring(0, min(20, code.length))}...');
    debugPrint('State: $state');

    final url =
        '$BASE_URL/auth/social/linkedin/callback?code=$code&state=$state';
    debugPrint('Request URL: $url');
    debugPrint('Headers: $_headers');

    final response = await http.get(Uri.parse(url), headers: _headers);

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response headers: ${response.headers}');
    debugPrint('Response body length: ${response.body.length}');
    debugPrint(
      'Response body preview: ${response.body.substring(0, min(200, response.body.length))}...',
    );

    if (response.statusCode == 200) {
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        throw Exception(
          'Server returned HTML error page instead of JSON. Check server logs.',
        );
      }
      try {
        final decoded = json.decode(response.body);
        debugPrint('Successfully decoded JSON: $decoded');
        return decoded;
      } catch (e) {
        debugPrint('JSON decode error: $e');
        debugPrint('Raw response body: ${response.body}');
        throw Exception('Invalid JSON response from server: $e');
      }
    } else {
      debugPrint('HTTP error: ${response.statusCode}');
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        debugPrint(
          'Server returned HTML error page: ${response.body.substring(0, min(500, response.body.length))}...',
        );
        throw Exception(
          'Server returned HTML error page (status ${response.statusCode}). Check server configuration.',
        );
      }
      debugPrint('Error response: ${response.body}');
      throw Exception(
        'Failed to handle LinkedIn callback: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> getLinkedInAuthUrl({String? state}) async {
    final url = state != null
        ? '$BASE_URL/user/linkedin?state=$state'
        : '$BASE_URL/user/linkedin';

    debugPrint('=== LINKEDIN AUTH URL REQUEST ===');
    debugPrint('URL: $url');
    debugPrint('Headers: $_headers');

    final client = http.Client();
    try {
      final response = await client.get(Uri.parse(url), headers: _headers);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body length: ${response.body.length}');
      debugPrint(
        'Response body preview: ${response.body.substring(0, min(200, response.body.length))}...',
      );

      // Handle redirect responses
      if (response.statusCode == 302 || response.statusCode == 301) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          debugPrint('Server redirected to: $redirectUrl');
          return {'authUrl': redirectUrl};
        }
      }

      if (response.statusCode == 200) {
        // Check if response is HTML (server might be proxying LinkedIn page)
        if (response.body.trim().startsWith('<!DOCTYPE html>') ||
            response.body.trim().startsWith('<html>')) {
          // Check if this is a LinkedIn OAuth page (valid response)
          if (response.headers['x-li-fabric'] != null ||
              response.body.contains('linkedin.com') ||
              response.body.contains('LinkedIn') ||
              response.body.contains('li_') ||
              response.body.contains('oauth')) {
            debugPrint(
              'Server returned LinkedIn OAuth HTML page - using request URL as auth URL',
            );
            // If server returns LinkedIn HTML, use the request URL as the auth URL
            // This means the server is proxying the LinkedIn OAuth page
            return {'authUrl': url};
          }

          // Check if this is actually an error page
          if (response.body.contains('404') ||
              response.body.contains('Not Found') ||
              response.body.contains('Page Not Found') ||
              response.body.contains('error') ||
              response.body.contains('Error')) {
            debugPrint(
              'Server returned error HTML page instead of LinkedIn auth URL',
            );
            throw Exception(
              'Authentication service returned an error page. Please try again later.',
            );
          }

          debugPrint(
            'Server returned LinkedIn HTML page - using request URL as auth URL',
          );
          // If server returns HTML, use the request URL as the auth URL
          // This means the server is proxying the LinkedIn OAuth page
          return {'authUrl': url};
        }

        // Try to parse as JSON
        try {
          return json.decode(response.body);
        } catch (e) {
          debugPrint('Failed to parse response as JSON: $e');
          throw Exception('Invalid response format from server');
        }
      } else {
        debugPrint(
          'ERROR: Failed to get LinkedIn auth URL with status ${response.statusCode}',
        );
        if (response.statusCode == 404) {
          throw Exception(
            'Authentication service is not available. Please try again later.',
          );
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception(
            'Failed to get LinkedIn auth URL: ${response.statusCode}',
          );
        }
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> exchangeLinkedInCode(
    String code,
    String state,
    String platform,
  ) async {
    debugPrint('=== EXCHANGING LINKEDIN CODE ===');
    debugPrint('Code: ${code.substring(0, min(20, code.length))}...');
    debugPrint('State: $state');
    debugPrint('Platform: $platform');

    final url = '$BASE_URL/user/linkedin/callback';
    final fullUrl = Uri.parse(url).replace(
      queryParameters: {'code': code, 'state': state, 'platform': platform},
    );

    debugPrint('Request URL: $fullUrl');
    debugPrint('Headers: $_headers');

    final response = await http.get(fullUrl, headers: _headers);

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response headers: ${response.headers}');
    debugPrint('Response body length: ${response.body.length}');
    debugPrint(
      'Response body preview: ${response.body.substring(0, min(200, response.body.length))}...',
    );

    if (response.statusCode == 200) {
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        throw Exception(
          'Server returned HTML error page instead of JSON. Check server logs.',
        );
      }
      try {
        final decoded = json.decode(response.body);
        debugPrint('Successfully decoded JSON: $decoded');
        return decoded;
      } catch (e) {
        debugPrint('JSON decode error: $e');
        debugPrint('Raw response body: ${response.body}');
        throw Exception('Invalid JSON response from server: $e');
      }
    } else {
      debugPrint('HTTP error: ${response.statusCode}');
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        debugPrint(
          'Server returned HTML error page: ${response.body.substring(0, min(500, response.body.length))}...',
        );
        throw Exception(
          'Server returned HTML error page (status ${response.statusCode}). Check server configuration.',
        );
      }
      debugPrint('Error response: ${response.body}');
      throw Exception(
        'Failed to exchange code: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Certificate APIs
  Future<List<CertificateModel>> getUserCertificates(String userId) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/certificates/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> certificates = jsonData['certificates'] ?? [];
        return certificates
            .map((item) => CertificateModel.fromJson(item))
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load certificates: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching certificates: $e');
      rethrow;
    }
  }

  Future<CertificateModel?> generateCertificate(
    String trainingId,
    String userId,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/certificates/generate/$trainingId/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return CertificateModel.fromJson(jsonData['certificate']);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Try to refresh token first
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the request with new token
          final retryResponse = await http.get(
            Uri.parse('$BASE_URL/certificates/generate/$trainingId/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': _headers['Authorization'] ?? '',
            },
          );

          if (retryResponse.statusCode == 200) {
            final jsonData = jsonDecode(retryResponse.body);
            return CertificateModel.fromJson(jsonData['certificate']);
          }
        }

        // If refresh failed or retry failed, show unauthorized dialog
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        // Parse error message from response body
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              'Unknown error';
          throw Exception('Failed to generate certificate: $errorMessage');
        } catch (parseError) {
          // If can't parse JSON, use status code
          throw Exception(
            'Failed to generate certificate: ${response.statusCode}',
          );
        }
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Error generating certificate: $e');
      return null;
    }
  }

  Future<String?> downloadCertificate(String certificateNumber) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/certificates/download/$certificateNumber'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        // Get the file bytes from response
        final bytes = response.bodyBytes;

        // Generate filename with timestamp to avoid conflicts
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'certificate_${certificateNumber}_$timestamp.pdf';

        // Get the application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';

        // Write the file to device storage
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        debugPrint('Certificate downloaded successfully: $filePath');
        return filePath; // Return the file path for further actions
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
          'Failed to download certificate: ${response.statusCode}',
        );
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error downloading certificate: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTrainingProgress(String userId) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      final response = await http.get(
        Uri.parse('$BASE_URL/trainings/user/training-progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
          'Failed to fetch training progress: ${response.statusCode}',
        );
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching training progress: $e');
      rethrow;
    }
  }
}
