// lib/controller/linkedin_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/deep_link_service.dart';
import 'package:dama/routes/routes.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dama/services/local_storage_service.dart';

class LinkedInController extends GetxController {
  final ApiService _apiService = Get.find();
  final DeepLinkService _deepLinkService = Get.find();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final RxBool _isProcessing = false.obs;
  final RxString errorMessage = ''.obs;

  // Store LinkedIn OAuth state for security
  String? _oauthState;

  StreamSubscription? _linkSubscription;
  Timer? _timeoutTimer;

  @override
  void onInit() {
    super.onInit();
    _listenToDeepLinks();
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.onClose();
  }

  void _showSnackbar(
    String title,
    String message, {
    bool isError = false,
    BuildContext? context,
  }) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      try {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: isError ? Colors.red : Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        // Fallback: show snackbar in next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.overlayContext != null) {
            Get.snackbar(
              title,
              message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: isError ? Colors.red : Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        });
      }
    }
  }

  void _listenToDeepLinks() {
    print('LinkedInController: Setting up deep link listener');
    _linkSubscription = _deepLinkService.deepLinkStream.listen((uri) {
      print('LinkedInController: Received deep link: $uri');
      if (_deepLinkService.isLinkedInCallback(uri)) {
        print('LinkedInController: Processing LinkedIn deep link');
        handleDeepLink(uri);
      } else {
        print('LinkedInController: Ignoring non-LinkedIn deep link');
      }
    });
  }

  Future<void> loginWithLinkedIn(BuildContext context) async {
    try {
      _isProcessing.value = true;
      errorMessage.value = '';

      // Generate a secure state parameter
      _oauthState = _generateState();

      // Get LinkedIn auth URL from backend
      final response = await _apiService.getLinkedInAuthUrl(state: _oauthState);

      if (response.containsKey('authUrl')) {
        final authUrl = response['authUrl'];

        // Launch LinkedIn auth in external browser
        final launched = await _deepLinkService.launchLinkedInAuth(authUrl);

        if (!launched) {
          errorMessage.value = 'Could not launch LinkedIn';
          _showSnackbar(
            'Error',
            'Please install LinkedIn app or try again',
            isError: true,
            context: context,
          );
        } else {
          // Start timeout timer for LinkedIn auth
          _timeoutTimer = Timer(const Duration(minutes: 2), () {
            if (_isProcessing.value) {
              _isProcessing.value = false;
              _showSnackbar(
                'Timeout',
                'LinkedIn login timed out. Please try regular login.',
                isError: true,
                context: context,
              );
            }
          });
        }
      } else {
        throw Exception('Invalid auth data from API');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      String errorMsg = 'Failed to start LinkedIn login';
      if (e.toString().contains('HTML')) {
        errorMsg =
            'Authentication service is temporarily unavailable. Please try again later.';
      } else if (e.toString().contains('Failed to get LinkedIn auth URL')) {
        errorMsg =
            'Unable to connect to authentication service. Please check your internet connection.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMsg =
            'Network connection error. Please check your internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMsg = 'Connection timeout. Please try again.';
      }
      _showSnackbar('Error', errorMsg, isError: true, context: context);
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> handleDeepLink(Uri uri) async {
    try {
      _timeoutTimer?.cancel();
      _isProcessing.value = true;

      print('=== LINKEDIN DEEP LINK RECEIVED ===');
      print('Full URI: $uri');
      print('Scheme: ${uri.scheme}');
      print('Host: ${uri.host}');
      print('Path: ${uri.path}');
      print('Query parameters: ${uri.queryParameters}');
      print('Query string: ${uri.query}');
      print('====================================');

      final params = _deepLinkService.extractLinkedInParams(uri);

      print('Extracted params: $params');

      if (params.containsKey('token') && params.containsKey('user')) {
        // Direct token flow (from backend redirect)
        await _processTokenResponse(params['token']!, params['user']!);
      } else if (params.containsKey('code') && params.containsKey('state')) {
        // OAuth code flow
        await _processCodeFlow(params['code']!, params['state']!);
      } else if (params.containsKey('code') && params.containsKey('user') && !params.containsKey('state')) {
        // Direct token flow where backend sends token as 'code' parameter
        await _processTokenResponse(params['code']!, params['user']!);
      } else {
        throw Exception('Invalid callback parameters');
      }
    } catch (e, s) {
      print('=== LINKEDIN ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      if (e is FormatException) {
        print('FormatException details:');
        print('  Offset: ${e.offset}');
        print('  Source: ${e.source}');
      }
      print('Stack trace: ${s}');
      print('===================');

      errorMessage.value = e.toString();
      _showSnackbar(
        'Error',
        'Failed to process LinkedIn login: ${e.toString()}',
        isError: true,
      );

      // Navigate back to login on error
      Get.offAllNamed(AppRoutes.login);
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> _processTokenResponse(String token, String encodedUser) async {
    try {
      print('=== PROCESSING TOKEN RESPONSE ===');
      print('Token: ${token.substring(0, min(20, token.length))}...');
      print('Encoded user length: ${encodedUser.length}');
      print(
        'Encoded user preview: ${encodedUser.substring(0, min(100, encodedUser.length))}...',
      );

      // Decode user data
      String decodedUserString;
      try {
        decodedUserString = encodedUser;
        print('User string: $decodedUserString');
      } catch (e) {
        print('Error getting user string: $e');
        throw Exception('Failed to get user data: $e');
      }

      dynamic decodedUser;
      try {
        decodedUser = json.decode(decodedUserString);
        print('Successfully parsed user JSON: $decodedUser');
      } catch (e) {
        print('Error parsing user JSON: $e');
        print('Raw decoded string: $decodedUserString');
        throw Exception('Failed to parse user data as JSON: $e');
      }

      // Validate response - check required fields
      if (decodedUser['email'] == null) {
        throw Exception('Email not provided by LinkedIn');
      }

      // Extract userId from the callback response
      // Try 'userId' first, fallback to '_id' for compatibility
      String? userId = decodedUser['userId'] ?? decodedUser['_id'];
      print('[LinkedInController] Extracted userId: $userId');
      
      if (userId == null || userId.isEmpty) {
        throw Exception('User ID not found in LinkedIn callback response');
      }

      // Extract all user fields from LinkedIn callback for registration form
      // Save LinkedIn data to pre-populate registration form
      Map<String, dynamic> linkedInUserData = {
        'userId': userId,
        'firstName': decodedUser['firstName'] ?? '',
        'lastName': decodedUser['lastName'] ?? '',
        'middleName': decodedUser['middleName'] ?? '',
        'email': decodedUser['email'] ?? '',
        'country': decodedUser['country'] ?? '',
        'phone_number': decodedUser['phone_number'] ?? '',
        'profile_picture': decodedUser['profile_picture'] ?? '',
        'title': decodedUser['title'] ?? '',
        'company': decodedUser['company'] ?? '',
        'brief': decodedUser['brief'] ?? '',
        'password_set': true,
        'authType': 'linkedin',
      };

      print('=== LINKEDIN DATA PREPARED ===');
      print('linkedInUserData: $linkedInUserData');
      print('==============================');

      // Save authentication data with userId and token
      print('[LinkedInController] Saving auth data...');
      await _saveAuthData(token, decodedUser, userId: userId);
      
      // Update API service headers with the new token
      _apiService.updateHeaders({'Authorization': 'Bearer $token'});
      print('[LinkedInController] Updated API service headers');
      
      // Save LinkedIn data for registration form pre-population
      print('[LinkedInController] Saving LinkedIn user data to StorageService...');
      await StorageService.storeData(linkedInUserData);
      print('[LinkedInController] LinkedIn data saved successfully');
      
      // Mark this as a LinkedIn registration flow
      await StorageService.storeData({'authType': 'linkedin'});
      await StorageService.storeData({'registration_source': 'linkedin'});

      // Navigate to personal details screen to complete registration
      Get.offAllNamed(AppRoutes.personal_details);
      _showSnackbar(
        'Welcome',
        'Please complete your profile to continue',
        isError: false,
      );
    } catch (e) {
      print('Error in _processTokenResponse: $e');
      rethrow;
    }
  }

  Future<void> _processCodeFlow(String code, String state) async {
    try {
      print('=== PROCESSING CODE FLOW ===');
      print('Code: ${code.substring(0, min(20, code.length))}...');
      print('State: $state');
      print('Expected state: $_oauthState');

      // Verify state to prevent CSRF
      if (state != _oauthState) {
        throw Exception('Invalid state parameter');
      }

      // Exchange code for token with backend
      print('Calling API service exchangeLinkedInCode...');
      final response = await _apiService.exchangeLinkedInCode(
        code,
        state,
        GetPlatform.isIOS ? 'ios' : 'android',
      );

      print('API response received: $response');

      if (response.containsKey('token') && response.containsKey('user')) {
        await _processTokenResponse(response['token'], response['user']);
      } else {
        throw Exception('Invalid response from server: missing token or user');
      }
    } catch (e) {
      print('Error in _processCodeFlow: $e');
      rethrow;
    }
  }

  Future<void> _saveAuthData(String token, dynamic userData, {String? userId}) async {
    print('=== _saveAuthData STARTED ===');
    print('Token length: ${token.length}');
    print('UserId: $userId');
    print('UserData: $userData');
    
    await _storage.write(key: 'auth_token', value: token);
    print('[LinkedInController] Saved auth_token to secure storage');
    
    await _storage.write(key: 'user_data', value: json.encode(userData));
    print('[LinkedInController] Saved user_data to secure storage');
    
    await _storage.write(key: 'login_method', value: 'linkedin');
    print('[LinkedInController] Saved login_method to secure storage');
    
    // Store access_token to local storage for API calls
    await StorageService.storeData({'access_token': token});
    print('[LinkedInController] Saved access_token to StorageService');
    
    // Store userId to local storage
    if (userId != null && userId.isNotEmpty) {
      await StorageService.storeData({'userId': userId});
      print('[LinkedInController] Saved userId to StorageService: $userId');
    }
    print('=== _saveAuthData COMPLETED ===');
  }

  String _generateState() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = random.hashCode.toRadixString(36);
    return 'linkedin_${hash}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<bool> _checkServerConnectivity() async {
    try {
      // Try to connect to a basic endpoint to check if server is reachable
      final response = await _apiService.checkServerHealth().timeout(
        const Duration(seconds: 10),
      );
      return response != null;
    } catch (e) {
      print('Server connectivity check failed: $e');
      return false;
    }
  }

  // Debug method to test server connectivity
  Future<void> testServerConnection() async {
    print('=== TESTING SERVER CONNECTION ===');
    try {
      final isReachable = await _checkServerConnectivity();
      print('Server reachable: $isReachable');

      if (isReachable) {
        print('Attempting to get LinkedIn auth URL...');
        final response = await _apiService.getLinkedInAuthUrl();
        print('LinkedIn auth URL response: $response');
      }
    } catch (e) {
      print('Test failed: $e');
    }
    print('=== END SERVER CONNECTION TEST ===');
  }

  // Handle initial link when app is opened from cold start
  Future<void> handleInitialLink() async {
    try {
      print('LinkedInController: Checking for initial deep link');
      final uri = await _deepLinkService.getInitialLink();
      if (uri != null && _deepLinkService.isLinkedInCallback(uri)) {
        print('LinkedInController: Found initial LinkedIn deep link: $uri');
        await handleDeepLink(uri);
      } else {
        print('LinkedInController: No initial LinkedIn deep link found');
      }
    } catch (e) {
      print('LinkedInController: Error handling initial link: $e');
    }
  }

  bool get isProcessing => _isProcessing.value;
}