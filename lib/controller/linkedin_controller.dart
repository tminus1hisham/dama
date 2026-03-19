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
    // Always use Get.snackbar() to avoid BuildContext issues with async operations
    try {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isError ? Colors.red : Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      );
    } catch (e) {
      debugPrint('Could not show snackbar: $e');
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

      debugPrint('🔵 [LinkedIn] === LOGIN STARTED ===');

      // Generate a secure state parameter
      _oauthState = _generateState();
      debugPrint('🔵 [LinkedIn] Generated state: $_oauthState');

      // Get LinkedIn auth URL from backend
      debugPrint('🔵 [LinkedIn] Calling getLinkedInAuthUrl()...');
      final response = await _apiService.getLinkedInAuthUrl(state: _oauthState);
      debugPrint('🔵 [LinkedIn] API response: ${response.keys.join(", ")}');

      if (response.containsKey('authUrl')) {
        final authUrl = response['authUrl'];
        debugPrint('🔵 [LinkedIn] Auth URL received: $authUrl');

        // Launch LinkedIn auth in external browser with deep link callback
        debugPrint('🔵 [LinkedIn] Launching browser with deep link callback...');
        final launched = await _deepLinkService.launchLinkedInAuth(authUrl);
        debugPrint('🔵 [LinkedIn] Browser launch result: $launched');

        if (!launched) {
          errorMessage.value = 'Could not launch LinkedIn';
          _showSnackbar(
            'Error',
            'Please check your internet connection and try again',
            isError: true,
            context: context,
          );
          debugPrint('❌ [LinkedIn] Failed to launch browser');
        } else {
          debugPrint('✅ [LinkedIn] Browser launched, waiting for deep link callback...');
          // Start timeout timer for LinkedIn auth
          _timeoutTimer = Timer(const Duration(minutes: 2), () {
            if (_isProcessing.value) {
              _isProcessing.value = false;
              debugPrint('❌ [LinkedIn] Timeout waiting for callback');
              _showSnackbar(
                'Timeout',
                'LinkedIn login timed out. Please try again.',
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
      debugPrint('❌ [LinkedIn] Error: $e');
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

      debugPrint('🔵 [LinkedIn] === DEEP LINK RECEIVED ===');
      debugPrint('🔵 [LinkedIn] Full URI: $uri');
      debugPrint('🔵 [LinkedIn] Scheme: ${uri.scheme}');
      debugPrint('🔵 [LinkedIn] Host: ${uri.host}');
      debugPrint('🔵 [LinkedIn] Path: ${uri.path}');
      debugPrint('🔵 [LinkedIn] Query parameters: ${uri.queryParameters}');

      final params = _deepLinkService.extractLinkedInParams(uri);
      debugPrint(
        '🔵 [LinkedIn] Extracted params keys: ${params.keys.join(", ")}',
      );

      if (params.containsKey('token') && params.containsKey('user')) {
        debugPrint('🔵 [LinkedIn] Token flow detected');
        // Direct token flow (from backend redirect)
        await _processTokenResponse(params['token']!, params['user']!);
      } else if (params.containsKey('code') && params.containsKey('state')) {
        debugPrint('🔵 [LinkedIn] Code flow detected');
        // OAuth code flow
        await _processCodeFlow(params['code']!, params['state']!);
      } else if (params.containsKey('code') &&
          params.containsKey('user') &&
          !params.containsKey('state')) {
        debugPrint('🔵 [LinkedIn] Direct token flow (code as token)');
        // Direct token flow where backend sends token as 'code' parameter
        await _processTokenResponse(params['code']!, params['user']!);
      } else {
        debugPrint('❌ [LinkedIn] Invalid callback parameters');
        throw Exception(
          'Invalid callback parameters: ${params.keys.join(", ")}',
        );
      }
    } catch (e, s) {
      debugPrint('❌ [LinkedIn] === ERROR ===');
      debugPrint('❌ [LinkedIn] Error type: ${e.runtimeType}');
      debugPrint('❌ [LinkedIn] Error message: $e');
      debugPrint(
        '❌ [LinkedIn] Stack trace: ${s.toString().split('\\n').take(5).join('\\n')}',
      );

      errorMessage.value = e.toString();
      // Don't show snackbar during deep link handling to avoid BuildContext issues
      // Just log the error instead
      debugPrint('❌ [LinkedIn] Login failed: $e');

      // Navigate back to login on error after a short delay to ensure widget tree is stable
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.offAllNamed(AppRoutes.login);
        // Show error message after navigation completes
        _showSnackbar(
          'Error',
          'LinkedIn login failed. Please try again.',
          isError: true,
        );
      });
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

      // Extract registration status
      final bool passwordSet = decodedUser['password_set'] == true;
      final bool phoneVerified = decodedUser['phone_number_verified'] == true;

      print('=== REGISTRATION STATUS ===');
      print('password_set: $passwordSet');
      print('phone_number_verified: $phoneVerified');
      print('Fully registered: ${passwordSet && phoneVerified}');
      print('===========================');

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
        'password_set': passwordSet,
        'phone_number_verified': phoneVerified,
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
      print(
        '[LinkedInController] Saving LinkedIn user data to StorageService...',
      );
      await StorageService.storeData(linkedInUserData);
      print('[LinkedInController] LinkedIn data saved successfully');

      // Mark this as a LinkedIn registration flow
      await StorageService.storeData({'authType': 'linkedin'});
      await StorageService.storeData({'registration_source': 'linkedin'});

      // Fetch complete user profile from server to ensure membership data is up to date
      // This ensures fields like membershipCertificateDownload are available
      print('[LinkedInController] Fetching complete user profile from server...');
      try {
        final profileData = await _apiService.fetchCurrentUserProfile();
        if (profileData != null && profileData['user'] != null) {
          final completeUserData = profileData['user'];
          print('[LinkedInController] ✅ Complete profile fetched');
          
          // Save the complete user data with all fields including membershipCertificateDownload
          await StorageService.storeData({
            'firstName': completeUserData['firstName'] ?? linkedInUserData['firstName'] ?? '',
            'lastName': completeUserData['lastName'] ?? linkedInUserData['lastName'] ?? '',
            'title': completeUserData['title'] ?? linkedInUserData['title'] ?? '',
            'brief': completeUserData['brief'] ?? linkedInUserData['brief'] ?? '',
            'profile_picture': completeUserData['profile_picture'] ?? linkedInUserData['profile_picture'] ?? '',
            'memberId': completeUserData['memberId'] ?? '',
            'membershipCertificate': completeUserData['membershipCertificate'] ?? '',
            'membershipCertificateDownload': completeUserData['membershipCertificateDownload'] ?? '',
          });
          print('[LinkedInController] ✅ Membership certificate data saved');
        } else {
          print('[LinkedInController] ⚠️ No complete profile data received');
        }
      } catch (e) {
        print('[LinkedInController] ⚠️ Error fetching complete profile: $e');
        // Continue anyway - user can still auth without full data
      }

      // Navigate based on registration status - use delayed callback to ensure widget tree is stable
      if (passwordSet && phoneVerified) {
        print('🏠✅ User fully registered - navigating to HOME');
        // Add a delay to ensure widget tree is stable before navigation
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.home);
        _showSnackbar(
          'Welcome Back',
          'Successfully logged in with LinkedIn',
          isError: false,
        );
      } else {
        print(
          '📝⚠️ User needs to complete registration - navigating to PERSONAL DETAILS',
        );
        // Add a delay to ensure widget tree is stable before navigation
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.personal_details);
        _showSnackbar(
          'Welcome',
          'Please complete your profile to continue',
          isError: false,
        );
      }
    } catch (e) {
      print('Error in _processTokenResponse: $e');
      rethrow;
    }
  }

  Future<void> _processCodeFlow(String code, String state) async {
    try {
      debugPrint('🔵 [LinkedIn] === PROCESSING CODE FLOW ===');
      debugPrint(
        '🔵 [LinkedIn] Code: ${code.substring(0, min(20, code.length))}...',
      );
      debugPrint('🔵 [LinkedIn] State received: $state');
      debugPrint('🔵 [LinkedIn] Expected state: $_oauthState');

      // Verify state to prevent CSRF
      if (state != _oauthState) {
        debugPrint('❌ [LinkedIn] State mismatch!');
        throw Exception('Invalid state parameter');
      }

      // Exchange code for token with backend
      debugPrint('🔵 [LinkedIn] Exchanging code with backend...');
      final response = await _apiService.exchangeLinkedInCode(
        code,
        state,
        GetPlatform.isIOS ? 'ios' : 'android',
      );

      debugPrint(
        '🔵 [LinkedIn] Exchange response received: ${response.keys.join(", ")}',
      );

      if (response.containsKey('token') && response.containsKey('user')) {
        debugPrint('✅ [LinkedIn] Token and user received, processing...');
        await _processTokenResponse(response['token'], response['user']);
      } else {
        debugPrint('❌ [LinkedIn] Missing token or user in response');
        throw Exception('Invalid response from server: missing token or user');
      }
    } catch (e) {
      debugPrint('❌ [LinkedIn] Code flow error: $e');
      rethrow;
    }
  }

  Future<void> _saveAuthData(
    String token,
    dynamic userData, {
    String? userId,
  }) async {
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
