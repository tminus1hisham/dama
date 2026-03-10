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

  Future<void> _clearAuthTokens() async {
    try {
      await StorageService.removeData('access_token');
      await StorageService.removeData('refresh_token');
      debugPrint('[ApiService] Auth tokens cleared');
    } catch (e) {
      debugPrint('[ApiService] Error clearing tokens: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PAYMENT
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> initiatePayment({
    required int amount,
    required String phoneNumber,
    required String model,
    required String objectId,
  }) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      debugPrint('initiatePayment - Token: $accessToken, ObjectId: $objectId');
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
      debugPrint('initiatePayment response status: ${response.statusCode}');
      debugPrint('initiatePayment response body: ${response.body}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to initiate payment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('initiatePayment error: $e');
      rethrow;
    }
  }

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
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception('Payment failed: $errorMessage');
        } catch (_) {
          throw Exception(
              'Failed to complete payment: ${response.statusCode}');
        }
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Payment error: $e');
      rethrow;
    }
  }

  /// Create Apple Pay payment intent via Stripe
  Future<Map<String, dynamic>?> createApplePayIntent({
    required String objectId,
    required String model,
    required int amount,
  }) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      debugPrint('=== APPLE PAY INTENT DEBUG ===');
      debugPrint('Model: $model, ObjectId: $objectId, Amount: $amount');

      final url = '$BASE_URL/transactions/apple-pay';
      final body = jsonEncode({
        'objectId': objectId,
        'model': model,
        'amount': amount,
        'currency': 'KES',
      });

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
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception('Apple Pay setup failed: $errorMessage');
        } catch (_) {
          throw Exception(
              'Failed to create payment intent: ${response.statusCode}');
        }
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Apple Pay intent error: $e');
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
              .map((item) =>
                  TransactionModel.fromJson(item as Map<String, dynamic>))
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

  Future<int> verifyByPhone(VerifyByPhoneModel request) async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.post(
      Uri.parse('$BASE_URL/transactions/verify/by/phone'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(request),
    );
    return response.statusCode;
  }

  // ---------------------------------------------------------------------------
  // GENERAL
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> checkServerHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$BASE_URL/user/linkedin'), headers: _headers)
          .timeout(const Duration(seconds: 10));
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
        throw Exception(
            'Failed to post to $endpoint: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
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

  // ---------------------------------------------------------------------------
  // NEWS
  // ---------------------------------------------------------------------------

  Future<List<String>> getNewsCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/news/get/all/category'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final categories = data
              .map((item) =>
                  item is Map<String, dynamic> && item['name'] != null
                      ? item['name'].toString()
                      : null)
              .whereType<String>()
              .toList();
          if (categories.isEmpty) {
            throw Exception('Empty categories list received from API');
          }
          return categories;
        }
        throw Exception(
            'Invalid response format: expected List but got ${data.runtimeType}');
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
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
      final uri = Uri.parse('$BASE_URL/news/get/all')
          .replace(queryParameters: queryParameters);
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
          throw Exception('Invalid news data format');
        }

        List<NewsModel> newsList = [];
        for (var item in newsData) {
          try {
            newsList.add(NewsModel.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing news item: $e, item: $item');
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
      final uri = Uri.parse('$BASE_URL/news/get/popular')
          .replace(queryParameters: {'limit': limit.toString()});
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
          throw Exception('Invalid popular news data format');
        }
        List<NewsModel> newsList = [];
        for (var item in newsData) {
          try {
            newsList.add(NewsModel.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing news item: $e, item: $item');
          }
        }
        return newsList;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to load popular news: ${response.statusCode}');
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
        return NewsModel.fromJson(jsonDecode(response.body));
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

  Future<Map<String, dynamic>?> likeNews(String newsId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse('$BASE_URL/news/like/$newsId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
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

  Future<Map<String, dynamic>?> addNewsComment(
    CommentModel request,
    String newsId,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse('$BASE_URL/news/comment/$newsId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
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

  // ---------------------------------------------------------------------------
  // BLOGS
  // ---------------------------------------------------------------------------

  Future<List<String>> getAllCategories() async => await getCategories();

  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/categories/get/all'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final categories = data
              .map((item) =>
                  item is Map<String, dynamic> && item['name'] != null
                      ? item['name'].toString()
                      : null)
              .whereType<String>()
              .toList();
          if (categories.isEmpty) {
            throw Exception('Empty categories list received from API');
          }
          return categories;
        }
        throw Exception(
            'Invalid response format: expected List but got ${data.runtimeType}');
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
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
        Uri.parse('$BASE_URL/blogs/get/all/category'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final categories = data
              .map((item) =>
                  item is Map<String, dynamic> && item['name'] != null
                      ? item['name'].toString()
                      : null)
              .whereType<String>()
              .toList();
          if (categories.isEmpty) {
            throw Exception('Empty categories list received from API');
          }
          return categories;
        }
        throw Exception(
            'Invalid response format: expected List but got ${data.runtimeType}');
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
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
      final queryParameters = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (category != null && category != 'All Blogs') {
        queryParameters['category'] = category;
      }
      final uri = Uri.parse('$BASE_URL/blogs/get/all')
          .replace(queryParameters: queryParameters);
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
        final blogResponse =
            BlogResponse.fromJson(data as Map<String, dynamic>);
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

  Future<Map<String, dynamic>?> likeBlog(String blogId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse('$BASE_URL/blogs/like/$blogId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
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

  Future<Map<String, dynamic>?> addComment(
    CommentModel request,
    String blogId,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse('$BASE_URL/blogs/comment/$blogId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
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

  // ---------------------------------------------------------------------------
  // RESOURCES
  // ---------------------------------------------------------------------------

  Future<List<ResourceModel>> getResources({
    required int page,
    int limit = 10,
  }) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final uri = Uri.parse('$BASE_URL/resources/get/all').replace(
          queryParameters: {
            'page': page.toString(),
            'limit': limit.toString()
          });
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('data') &&
            jsonData['data'] is Map<String, dynamic> &&
            jsonData['data'].containsKey('resources')) {
          return (jsonData['data']['resources'] as List)
              .map((item) => ResourceModel.fromJson(item))
              .toList();
        } else if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('resources')) {
          return (jsonData['resources'] as List)
              .map((item) => ResourceModel.fromJson(item))
              .toList();
        } else if (jsonData is List) {
          return jsonData.map((item) => ResourceModel.fromJson(item)).toList();
        } else {
          throw Exception('Invalid response format for resources');
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
        return (jsonData['resources'] as List)
            .map((item) => ResourceModel.fromJson(item))
            .toList();
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

  Future<Map<String, dynamic>?> rate(
    String resourceId,
    RatingModel request,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse('$BASE_URL/resources/rate/$resourceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(request.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ??
              errorData['error'] ??
              'Failed to rate resource');
        } catch (_) {
          throw Exception(
              'Failed to rate resource: ${response.statusCode}');
        }
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // EVENTS
  // ---------------------------------------------------------------------------

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
          return (jsonData['events'] as List)
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

  Future<List<EventModel>> getPopularEvents() async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final headers = <String, String>{};
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      final response = await http.get(
        Uri.parse('$BASE_URL/events/popular'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonData.containsKey('events')) {
          return (jsonData['events'] as List)
              .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception("No events key in response");
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to load popular events: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
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
          return (jsonData['events'] as List)
              .map((item) =>
                  UserEventModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception("No events key in response");
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to load user events: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      debugPrint('Error fetching user events: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> registerForEvent(String eventId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse('$BASE_URL/events/register/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Forbidden');
      } else if (response.statusCode == 401) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to register for event: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      rethrow;
    } catch (e) {
      debugPrint('Error registering for event: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> unregisterFromEvent(String eventId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.delete(
        Uri.parse('$BASE_URL/events/register/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to unregister from event: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Error unregistering from event: $e');
      return null;
    }
  }

  Future<int> getEventAttendees(String eventId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final endpoints = [
        '$BASE_URL/events/$eventId/attendees',
        '$BASE_URL/events/event/attendees?eventId=$eventId',
      ];
      for (final endpoint in endpoints) {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          if (jsonData.containsKey('count')) return jsonData['count'] as int;
          if (jsonData.containsKey('attendees')) {
            final a = jsonData['attendees'];
            if (a is List) return a.length;
            if (a is int) return a;
          }
          if (jsonData.containsKey('total')) return jsonData['total'] as int;
          return 0;
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          HandleUnauthorizedService.showUnauthorizedDialog();
          return 0;
        }
      }
      return 0;
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return 0;
    } catch (e) {
      debugPrint('Error fetching event attendees: $e');
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------------

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final accessToken = await StorageService.getData("access_token");
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('⚠️ [Notifications API] NO ACCESS TOKEN!');
        return [];
      }
      final response = await http.get(
        Uri.parse('$BASE_URL/notifications/get/user/notifications'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> notifications = jsonData['notifications'] ?? [];
        return notifications
            .map((item) => NotificationModel.fromJson(item))
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to load notifications: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    // No bulk endpoint — handled per-notification by the controller
    return true;
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      if (notificationId.isEmpty) return false;
      final response = await http.post(
        Uri.parse('$BASE_URL/notifications/mark_as_read/$notificationId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) return true;
      if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
      }
      return false;
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PLANS & MEMBERSHIP
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> getPlans() async {
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
        return {
          'success': true,
          'data': jsonData is List ? jsonData : (jsonData['plans'] ?? []),
        };
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
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPlanById(String planId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final headers = <String, String>{};
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      final response = await http.get(
        Uri.parse('$BASE_URL/plans/$planId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception('Failed to load plan: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserMembership() async {
    try {
      final hasMembership = await StorageService.getData('hasMembership');
      final membershipId = await StorageService.getData('membershipId');
      final membershipExp = await StorageService.getData('membershipExp');
      final freeUntil = await StorageService.getData('freeUntil');

      bool isExpired = false;
      String status = 'inactive';
      final expiryDateStr = freeUntil ?? membershipExp;

      if ((hasMembership == true || hasMembership == 'true') &&
          expiryDateStr != null) {
        try {
          final expiryDate = DateTime.parse(expiryDateStr.toString());
          isExpired = DateTime.now().isAfter(expiryDate);
          status = isExpired ? 'expired' : 'active';
        } catch (e) {
          debugPrint('Error parsing expiry date: $e');
          status = 'active';
        }
      }

      return {
        'success': true,
        'data': {
          'isSubscribed':
              (hasMembership == true || hasMembership == 'true') && !isExpired,
          'planId': membershipId,
          'planName': 'Professional',
          'status': status,
          'isExpired': isExpired,
          'endDate': membershipExp,
          'freeUntil': freeUntil,
          'nextBillingDate': membershipExp,
          'currentPlan': null,
        },
      };
    } catch (e) {
      debugPrint('Error fetching user membership: $e');
      return {
        'success': true,
        'data': {
          'isSubscribed': false,
          'planId': null,
          'planName': null,
          'status': null,
          'isExpired': false,
          'endDate': null,
          'nextBillingDate': null,
          'currentPlan': null,
        },
      };
    }
  }

  Future<Map<String, dynamic>?> getUserMembershipWithFreeTrial() async {
    try {
      final hasMembership = await StorageService.getData('hasMembership');
      final membershipId = await StorageService.getData('membershipId');
      final membershipExp = await StorageService.getData('membershipExp');
      final freeUntil = await StorageService.getData('freeUntil');
      final membershipStartDate =
          await StorageService.getData('membershipStartDate');

      bool isExpired = false;
      bool isFreeTrialActive = false;
      String status = 'inactive';
      int effectivePrice = 12000;
      int daysRemaining = 0;
      final expiryDateStr = freeUntil ?? membershipExp;

      if ((hasMembership == true || hasMembership == 'true') &&
          expiryDateStr != null) {
        try {
          final expiryDate = DateTime.parse(expiryDateStr.toString());
          final now = DateTime.now();
          isExpired = now.isAfter(expiryDate);
          isFreeTrialActive = !isExpired && freeUntil != null;
          daysRemaining = isExpired ? 0 : expiryDate.difference(now).inDays;
          if (isExpired) {
            status = 'expired';
            effectivePrice = 12000;
          } else if (isFreeTrialActive) {
            status = 'free_trial';
            effectivePrice = 0;
          } else {
            status = 'active';
          }
        } catch (e) {
          debugPrint('[ApiService] Error parsing expiry dates: $e');
        }
      }

      return {
        'success': true,
        'data': {
          'isSubscribed':
              (hasMembership == true || hasMembership == 'true') && !isExpired,
          'planId': membershipId,
          'planName': 'Professional',
          'status': status,
          'isExpired': isExpired,
          'endDate': membershipExp,
          'nextBillingDate': membershipExp,
          'freeTrialActive': isFreeTrialActive,
          'freeUntil': freeUntil,
          'membershipStartDate': membershipStartDate,
          'effectivePrice': effectivePrice,
          'daysRemaining': daysRemaining,
        },
      };
    } catch (e) {
      debugPrint('[ApiService] Error fetching user membership: $e');
      return {
        'success': true,
        'data': {
          'isSubscribed': false,
          'planId': null,
          'planName': null,
          'status': null,
          'endDate': null,
          'nextBillingDate': null,
          'currentPlan': null,
          'freeTrialActive': false,
        },
      };
    }
  }

  // ---------------------------------------------------------------------------
  // USER PROFILE
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.get(
        Uri.parse('$BASE_URL/user/profile/$userId'),
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
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to fetch current user data: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return null;
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
      return null;
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
      if (response.statusCode == 201) return true;
      if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      }
      throw Exception('Failed to request role: ${response.statusCode}');
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      throw Exception('Error requesting role');
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
        return ArticleCountModel.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to load article count: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ALERTS
  // ---------------------------------------------------------------------------

  Future<List<AlertModel>> getAlerts() async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.get(
        Uri.parse('$BASE_URL/alerts/active'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return (jsonData['alerts'] as List)
            .map((item) => AlertModel.fromJson(item))
            .toList();
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
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // MESSAGING
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> fetchConversations(String userId) async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.get(
      Uri.parse('$CHAT_BASE_URL/chat/conversations/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to fetch conversations: ${response.statusCode}');
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
      return (data['messages'] as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
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
    if (response.statusCode == 200) return true;
    if (response.statusCode == 401 || response.statusCode == 403) {
      HandleUnauthorizedService.showUnauthorizedDialog();
      throw Exception('Unauthorized request');
    }
    throw Exception("Failed to delete conversation");
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
    if (response.statusCode == 200) return true;
    if (response.statusCode == 401 || response.statusCode == 403) {
      HandleUnauthorizedService.showUnauthorizedDialog();
      throw Exception('Unauthorized request');
    }
    throw Exception("Failed to delete message");
  }

  Future<bool> markMessagesAsRead(
      String conversationId, String userId) async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.post(
      Uri.parse('$CHAT_BASE_URL/chat/messages/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'conversationId': conversationId, 'userId': userId}),
    );
    if (response.statusCode == 200) return true;
    if (response.statusCode == 401 || response.statusCode == 403) {
      HandleUnauthorizedService.showUnauthorizedDialog();
      throw Exception('Unauthorized request');
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // TRAININGS
  // ---------------------------------------------------------------------------

  Future<List<TrainingModel>> getTrainings() async {
    try {
      final accessToken = await StorageService.getData("access_token");
      if (accessToken == null) throw Exception('User not authenticated');
      final response = await http.get(
        Uri.parse('$BASE_URL/trainings/all'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final trainings = (jsonData['trainings'] ?? []) as List;
        if (trainings.isEmpty) throw Exception('No trainings found');
        return trainings.map((item) => TrainingModel.fromJson(item)).toList();
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
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserTrainings() async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.get(
      Uri.parse('$BASE_URL/trainings/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to fetch user trainings');
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

  Future<Map<String, dynamic>> enrollInTraining(String trainingId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.post(
        Uri.parse('$BASE_URL/trainings/enroll/$trainingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        return {
          'success': false,
          'message': 'Unauthorized. Please log in again.'
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Failed to enroll'
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Failed to enroll: ${response.statusCode}'
          };
        }
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      return {
        'success': false,
        'message': 'Network error. Please check your connection.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserTrainingDetails(
      String trainingId) async {
    final accessToken = await StorageService.getData("access_token");
    final response = await http.get(
      Uri.parse('$BASE_URL/trainings/user/trainings/$trainingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to fetch training details');
  }

  Future<Map<String, dynamic>> getTrainingSessions(
      String trainingId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.get(
        Uri.parse('$BASE_URL/trainings/$trainingId/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) return json.decode(response.body);
      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final retry = await http.get(
            Uri.parse('$BASE_URL/trainings/$trainingId/sessions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': _headers['Authorization'] ?? '',
            },
          );
          if (retry.statusCode == 200) return json.decode(retry.body);
        }
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      }
      throw Exception(
          'Failed to fetch training sessions: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> joinSession(
      String trainingId, String sessionId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final url =
          '$BASE_URL/trainings/user/trainings/$trainingId/sessions/$sessionId/join';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Successfully joined session'};
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final retry = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': _headers['Authorization'] ?? '',
            },
          );
          if (retry.statusCode == 200) {
            return {'success': true, 'message': 'Successfully joined session'};
          }
          return {
            'success': false,
            'message': 'Authentication failed. Please log in again.'
          };
        }
        HandleUnauthorizedService.showUnauthorizedDialog();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.'
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['message'] ?? errorData['error'] ?? 'Failed to join';
          if (errorMessage.toLowerCase().contains('ended') ||
              errorMessage.toLowerCase().contains('expired') ||
              errorMessage.toLowerCase().contains('closed')) {
            return {
              'success': false,
              'message': 'This session has already ended.'
            };
          }
          return {'success': false, 'message': errorMessage};
        } catch (_) {
          return {
            'success': false,
            'message': 'Failed to join session (Error ${response.statusCode})'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> leaveSession(
      String trainingId, String sessionId) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final url =
          '$BASE_URL/trainings/user/trainings/$trainingId/sessions/$sessionId/leave';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Successfully left session'};
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final retry = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': _headers['Authorization'] ?? '',
            },
          );
          if (retry.statusCode == 200) {
            return {'success': true, 'message': 'Successfully left session'};
          }
          return {
            'success': false,
            'message': 'Authentication failed. Please log in again.'
          };
        }
        HandleUnauthorizedService.showUnauthorizedDialog();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.'
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ??
                errorData['error'] ??
                'Failed to leave session'
          };
        } catch (_) {
          return {
            'success': false,
            'message':
                'Failed to leave session (Error ${response.statusCode})'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
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
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to fetch today sessions');
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
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to fetch upcoming sessions');
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
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to fetch training progress');
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
      if (response.statusCode == 200) return json.decode(response.body);
      if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      }
      throw Exception(
          'Failed to fetch training progress: ${response.statusCode}');
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // CERTIFICATES
  // ---------------------------------------------------------------------------

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
        return ((jsonData['certificates'] ?? []) as List)
            .map((item) => CertificateModel.fromJson(item))
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to load certificates: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<CertificateModel?> generateCertificate(
    String trainingId,
    String userId,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      if (accessToken == null || accessToken.isEmpty) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception(
            'Session expired. Please log in again to generate the certificate.');
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/certificates/generate/$trainingId/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CertificateModel.fromJson(
            jsonDecode(response.body)['certificate']);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Check if it's a business logic error first
        try {
          final errorData = jsonDecode(response.body);
          final msg = (errorData['message'] ?? '').toString().toLowerCase();
          if (msg.contains('attendance') ||
              msg.contains('insufficient') ||
              msg.contains('not eligible') ||
              msg.contains('criteria')) {
            throw Exception(
                'Failed to generate certificate: ${errorData['message']}');
          }
        } catch (e) {
          if (e.toString().contains('generate certificate')) rethrow;
        }

        final refreshed = await _refreshToken();
        if (refreshed) {
          final newToken = await StorageService.getData("access_token");
          if (newToken != null && newToken.isNotEmpty) {
            final retry = await http.get(
              Uri.parse(
                  '$BASE_URL/certificates/generate/$trainingId/$userId'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newToken',
              },
            );
            if (retry.statusCode == 200 || retry.statusCode == 201) {
              return CertificateModel.fromJson(
                  jsonDecode(retry.body)['certificate']);
            }
          }
        }

        await _clearAuthTokens();
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception(
            'Session expired. Please log in again to generate the certificate.');
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
              'Failed to generate certificate: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}');
        } catch (_) {
          throw Exception(
              'Failed to generate certificate: ${response.statusCode}');
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

      final contentType =
          response.headers['content-type']?.toLowerCase() ?? '';
      final isPdf = response.bodyBytes.length >= 5 &&
          response.bodyBytes[0] == 0x25 &&
          response.bodyBytes[1] == 0x50 &&
          response.bodyBytes[2] == 0x44 &&
          response.bodyBytes[3] == 0x46 &&
          response.bodyBytes[4] == 0x2D;

      if (!contentType.contains('pdf') && !isPdf) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
              'Server returned: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}');
        } catch (_) {
          throw Exception(
              'Failed to download certificate: not a PDF file (${response.statusCode})');
        }
      }

      if (response.statusCode == 200) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'certificate_${certificateNumber}_$timestamp.pdf';
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        await File(filePath).writeAsBytes(response.bodyBytes);
        debugPrint('Certificate downloaded: $filePath');
        return filePath;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      } else {
        throw Exception(
            'Failed to download certificate: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      NetworkModal.showNetworkDialog();
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // MISC
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> login(LoginModel loginModel) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(loginModel.toJson()),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to login: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> verify2FA(String otp) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/user/login/2fa/verify'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'otp': otp}),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to verify 2FA: ${response.statusCode}');
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
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        'Failed to request account deletion: ${response.statusCode}');
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
      body: json.encode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to change password: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/user/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        'Failed to initiate password reset: ${response.statusCode}');
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
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to reset password: ${response.statusCode}');
  }

  // ---------------------------------------------------------------------------
  // LINKEDIN AUTH
  // Canonical flow:
  //   Step 1 → getLinkedInAuthUrl()        → GET /v1/user/linkedin/mobile
  //                                           Server 302s to LinkedIn OAuth page
  //                                           Capture Location header, open in browser
  //   Step 2 → exchangeLinkedInCode()      → GET /v1/user/linkedin/callback/mobile
  //                                           Send code + state from deep link
  //                                           Returns token + user
  // ---------------------------------------------------------------------------

  /// Step 1: Get the LinkedIn OAuth URL.
  /// Calls GET /v1/user/linkedin/mobile — server responds with 302.
  /// We capture the Location header WITHOUT following the redirect,
  /// then pass it to url_launcher to open in the device browser.
  Future<Map<String, dynamic>> getLinkedInAuthUrl({String? state}) async {
    final uri = state != null
        ? Uri.parse('$BASE_URL/user/linkedin/mobile')
            .replace(queryParameters: {'state': state})
        : Uri.parse('$BASE_URL/user/linkedin/mobile');

    debugPrint('=== LINKEDIN MOBILE AUTH URL REQUEST: $uri ===');

    final accessToken = await StorageService.getData('access_token');
    final client = http.Client();
    try {
      // MUST use Request with followRedirects=false.
      // client.get() silently follows 302s all the way to the web app.
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers.addAll(headers);

      final streamed = await client.send(request);

      debugPrint('=== LINKEDIN RAW RESPONSE ===');
      debugPrint('Status code: ${streamed.statusCode}');
      debugPrint('All headers:');
      streamed.headers.forEach((key, value) {
        debugPrint('  $key: $value');
      });

      final body = await streamed.stream.bytesToString();
      debugPrint('Body length: ${body.length}');
      debugPrint('Body preview: ${body.substring(0, body.length.clamp(0, 500))}');
      debugPrint('=== END LINKEDIN RAW RESPONSE ===');

      // ✅ Server returns 302 → Location header contains the LinkedIn OAuth URL.
      if (streamed.statusCode == 302 ||
          streamed.statusCode == 301 ||
          streamed.statusCode == 303) {
        final location = streamed.headers['location'];
        if (location != null && location.isNotEmpty) {
          debugPrint('✅ LinkedIn OAuth URL captured: $location');
          return {'authUrl': location};
        }
        throw Exception('Server redirected but Location header is missing.');
      }

      // 200 — body already read above for logging
      if (streamed.statusCode == 200) {
        final trimmed = body.trim();
        if (trimmed.startsWith('<')) {
          throw Exception(
              'Server returned HTML — followRedirects=false not working. '
              'Body preview: ${trimmed.substring(0, trimmed.length.clamp(0, 300))}');
        }
        return json.decode(trimmed) as Map<String, dynamic>;
      }

      if (streamed.statusCode == 401 || streamed.statusCode == 403) {
        HandleUnauthorizedService.showUnauthorizedDialog();
        throw Exception('Unauthorized request');
      }
      if (streamed.statusCode >= 500) {
        throw Exception('Server error initiating LinkedIn authentication.');
      }

      throw Exception(
          'Failed to get LinkedIn auth URL: \${streamed.statusCode}');
    } finally {
      client.close();
    }
  }

  /// Step 2: Exchange OAuth code + state for user tokens.
  /// Calls GET /v1/user/linkedin/callback/mobile
  /// Called after LinkedIn redirects back to the app via deep link
  /// with ?code=...&state=... query parameters.
  Future<Map<String, dynamic>> exchangeLinkedInCode(
    String code,
    String state,
    String platform,
  ) async {
    final uri = Uri.parse('$BASE_URL/user/linkedin/callback/mobile').replace(
      queryParameters: {
        'code': code,
        'state': state,
      },
    );

    debugPrint('🔵 [ApiService] Exchanging LinkedIn code for tokens...');
    debugPrint('🔵 [ApiService] Code: ${code.substring(0, code.length.clamp(0, 20))}...');
    debugPrint('🔵 [ApiService] State: $state');
    debugPrint('🔵 [ApiService] Endpoint: $uri');

    final response = await http.get(uri, headers: _headers);

    debugPrint('🔵 [ApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = response.body.trim();
      if (body.startsWith('<')) {
        debugPrint('❌ [ApiService] Server returned HTML (likely error page)');
        throw Exception('Server returned HTML instead of JSON.');
      }
      debugPrint('🔵 [ApiService] Response body preview: ${body.substring(0, body.length.clamp(0, 200))}');
      final decoded = json.decode(body) as Map<String, dynamic>;
      debugPrint('✅ [ApiService] LinkedIn code exchange successful');
      debugPrint('✅ [ApiService] Response keys: ${decoded.keys.toList()}');
      return decoded;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      debugPrint('❌ [ApiService] Unauthorized (401/403): ${response.body}');
      HandleUnauthorizedService.showUnauthorizedDialog();
      throw Exception('Unauthorized request');
    }

    debugPrint('❌ [ApiService] Code exchange failed: HTTP ${response.statusCode}');
    debugPrint('❌ [ApiService] Response body: ${response.body}');
    throw Exception(
        'Failed to complete LinkedIn auth: ${response.statusCode} - ${response.body}');
  }
}