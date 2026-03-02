import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:dama/utils/constants.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/local_storage_service.dart';

class LinkedInWebView extends StatefulWidget {
  static bool isWebViewActive = false; // Static flag to track WebView state
  
  final String url;
  final Function(Map<String, dynamic> data) onSuccess;
  final Function(String error) onError;

  const LinkedInWebView({
    required this.url,
    required this.onSuccess,
    required this.onError,
    super.key,
  });

  @override
  State<LinkedInWebView> createState() => _LinkedInWebViewState();
}

class _LinkedInWebViewState extends State<LinkedInWebView> {
  late final WebViewController _controller;
  bool _hasHandledCallback = false;
  final String _callbackUrlPart = "api.damakenya.org/v1/user/linkedin/callback";

  @override
  void initState() {
    super.initState();
    LinkedInWebView.isWebViewActive = true; // Set flag when WebView opens
    _initializeWebView();
  }

  @override
  void dispose() {
    LinkedInWebView.isWebViewActive = false; // Clear flag when WebView closes
    super.dispose();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('[LinkedIn WebView] onPageStarted: $url');
          },
          onPageFinished: (url) async {
            print('[LinkedIn WebView] onPageFinished: $url');
            
            // Check for HTTP callback
            if (url.contains(_callbackUrlPart) && !_hasHandledCallback) {
              _hasHandledCallback = true;
              print('[LinkedIn WebView] Callback URL detected, extracting parameters...');
              await _handleCallback(url);
            }
          },
          onNavigationRequest: (request) {
            print('[LinkedIn WebView] onNavigationRequest: ${request.url}');
            
            // IMPORTANT: Check for custom scheme redirect
            if (request.url.startsWith('com.dama.mobile://') && !_hasHandledCallback) {
              print('[LinkedIn WebView] 🔗 Custom scheme detected: ${request.url}');
              _hasHandledCallback = true;
              
              // Handle the deep link directly
              _handleDeepLink(request.url);
              
              // Prevent the WebView from trying to load this URL
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _handleDeepLink(String deepLinkUrl) async {
    try {
      print('[LinkedIn WebView] 🔗 Processing deep link: $deepLinkUrl');
      
      final uri = Uri.parse(deepLinkUrl);
      final code = uri.queryParameters['code'];
      final encodedUser = uri.queryParameters['user'];
      
      if (code == null || encodedUser == null) {
        throw Exception('Missing code or user data in deep link');
      }
      
      // Decode and parse user data
      final userJson = Uri.decodeComponent(encodedUser);
      final userData = json.decode(userJson) as Map<String, dynamic>;
      
      print('[LinkedIn WebView] 📦 Extracted user data: $userData');
      
      // Check registration status with detailed logging
      final rawPasswordSet = userData['password_set'];
      final rawPhoneVerified = userData['phone_number_verified'];
      
      print('🔍 DEEP LINK DEBUGGING:');
      print('  - password_set raw: $rawPasswordSet (${rawPasswordSet.runtimeType})');
      print('  - phone_number_verified raw: $rawPhoneVerified (${rawPhoneVerified.runtimeType})');
      
      // Use multiple comparison methods to handle different formats
      final bool passwordSet = rawPasswordSet == true || 
                               rawPasswordSet.toString() == "true" || 
                               rawPasswordSet == 1;
      
      final bool phoneVerified = rawPhoneVerified == true || 
                                 rawPhoneVerified.toString() == "true" || 
                                 rawPhoneVerified == 1;
      
      print('  - passwordSet (final): $passwordSet');
      print('  - phoneVerified (final): $phoneVerified');
      print('  - Combined: ${passwordSet && phoneVerified}');
      
      // Get userId
      String? userId = userData['_id'];
      print('  - userId: $userId');
      
      if (userId != null && userId.isNotEmpty) {
        // Prepare data to store
        final linkedInUserData = {
          'userId': userId,
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'middleName': userData['middleName'] ?? '',
          'email': userData['email'] ?? '',
          'country': userData['country'] ?? '',
          'profile_picture': userData['profile_picture'] ?? '',
          'title': userData['title'] ?? '',
          'company': userData['company'] ?? '',
          'brief': userData['brief'] ?? '',
          'password_set': passwordSet,
          'authType': 'linkedin',
          'phone_number_verified': phoneVerified,
        };
        
        // Store data
        await StorageService.storeData(linkedInUserData);
        await StorageService.storeData({'registration_source': 'linkedin'});
        
        // Also save the token if needed
        if (code.isNotEmpty) {
          await StorageService.storeData({'access_token': code});
        }
        
        print('[LinkedIn WebView] ✅ Saved LinkedIn data');
        
        // IMPORTANT: Clear the flag BEFORE closing WebView
        LinkedInWebView.isWebViewActive = false;
        
        // Close WebView using offUntil to ensure clean navigation stack
        print('[LinkedIn WebView] Closing WebView...');
        
        // Use Get.offUntil to remove WebView and prepare for navigation
        await Get.offUntil(
          MaterialPageRoute(builder: (_) => const SizedBox.shrink()), // Empty temporary route
          (route) => false, // Remove all routes
        );
        
        // Small delay to ensure everything is cleaned up
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Navigate based on registration status
        if (passwordSet && phoneVerified) {
          print('🏠✅ User fully registered - navigating to HOME');
          Get.offAllNamed(AppRoutes.home);
        } else {
          print('📝⚠️ User needs to complete registration - navigating to PERSONAL DETAILS');
          print('  Reason: passwordSet=$passwordSet, phoneVerified=$phoneVerified');
          Get.offAllNamed(AppRoutes.personal_details);
        }
      } else {
        throw Exception('No userId found in user data');
      }
    } catch (e) {
      print('[LinkedIn WebView] Error handling deep link: $e');
      LinkedInWebView.isWebViewActive = false;
      widget.onError(e.toString());
      Get.back();
    }
  }

  Future<void> _handleCallback(String url) async {
    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];

      if (code == null) {
        throw Exception('No authorization code found in callback URL');
      }

      print('[LinkedIn WebView] Extracted code: $code, state: $state');

      final callbackUrl = Uri.parse('$BASE_URL/user/linkedin/callback').replace(
        queryParameters: {
          'code': code,
          if (state != null) 'state': state,
          'platform': GetPlatform.isIOS ? 'ios' : 'android',
        },
      );

      print('[LinkedIn WebView] Making callback request to: $callbackUrl');

      final response = await http.get(
        callbackUrl,
        headers: {'Content-Type': 'application/json'},
      );

      print('[LinkedIn WebView] Callback response status: ${response.statusCode}');
      print('[LinkedIn WebView] Callback response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[LinkedIn WebView] Success, processing response');

        // Extract user data
        Map<String, dynamic>? userData;
        if (data['user'] != null) {
          if (data['user'] is String) {
            userData = json.decode(data['user']);
          } else if (data['user'] is Map) {
            userData = Map<String, dynamic>.from(data['user']);
          }
        }

        // CRITICAL: Check if we have userData
        if (userData == null) {
          print('[LinkedIn WebView] ❌ No user data found in response');
          widget.onError('No user data received');
          Get.back();
          return;
        }

        // Log the user data for debugging
        print('[LinkedIn WebView] 📦 User data: $userData');
        
        // Check each field individually with detailed logging
        print('🔍 DEBUGGING VALUES:');
        
        // Get raw values
        var rawPasswordSet = userData['password_set'];
        var rawPhoneVerified = userData['phone_number_verified'];
        
        print('  - password_set raw value: $rawPasswordSet');
        print('  - password_set runtime type: ${rawPasswordSet.runtimeType}');
        print('  - password_set == true: ${rawPasswordSet == true}');
        print('  - password_set.toString() == "true": ${rawPasswordSet.toString() == "true"}');
        print('  - password_set is bool: ${rawPasswordSet is bool}');
        
        print('  - phone_number_verified raw value: $rawPhoneVerified');
        print('  - phone_number_verified runtime type: ${rawPhoneVerified.runtimeType}');
        print('  - phone_number_verified == true: ${rawPhoneVerified == true}');
        print('  - phone_number_verified.toString() == "true": ${rawPhoneVerified.toString() == "true"}');
        print('  - phone_number_verified is bool: ${rawPhoneVerified is bool}');
        
        // Try different comparison methods
        bool passwordSet1 = rawPasswordSet == true;
        bool passwordSet2 = rawPasswordSet.toString() == "true";
        bool passwordSet3 = rawPasswordSet == 1; // Sometimes API returns 1 for true
        
        bool phoneVerified1 = rawPhoneVerified == true;
        bool phoneVerified2 = rawPhoneVerified.toString() == "true";
        bool phoneVerified3 = rawPhoneVerified == 1; // Sometimes API returns 1 for true
        
        print('  - passwordSet (== true): $passwordSet1');
        print('  - passwordSet (toString == "true"): $passwordSet2');
        print('  - passwordSet (== 1): $passwordSet3');
        
        print('  - phoneVerified (== true): $phoneVerified1');
        print('  - phoneVerified (toString == "true"): $phoneVerified2');
        print('  - phoneVerified (== 1): $phoneVerified3');

        // Use the most appropriate comparison based on what we see
        final bool passwordSet = passwordSet1 || passwordSet2 || passwordSet3;
        final bool phoneVerified = phoneVerified1 || phoneVerified2 || phoneVerified3;
        
        print('  - FINAL passwordSet: $passwordSet');
        print('  - FINAL phoneVerified: $phoneVerified');
        print('  - Combined condition (passwordSet && phoneVerified): ${passwordSet && phoneVerified}');

        // Get userId safely
        String? userId = userData['userId'] ?? userData['_id'];
        print('  - userId: $userId');
        
        if (userId != null && userId.isNotEmpty) {
          // Prepare data to store
          final linkedInUserData = {
            'userId': userId,
            'firstName': userData['firstName'] ?? '',
            'lastName': userData['lastName'] ?? '',
            'middleName': userData['middleName'] ?? '',
            'email': userData['email'] ?? '',
            'country': userData['country'] ?? '',
            'profile_picture': userData['profile_picture'] ?? '',
            'title': userData['title'] ?? '',
            'company': userData['company'] ?? '',
            'brief': userData['brief'] ?? '',
            'password_set': passwordSet, // Store as boolean
            'authType': 'linkedin',
            'phone_number_verified': phoneVerified, // Store as boolean
          };

          // Store data
          await StorageService.storeData(linkedInUserData);
          await StorageService.storeData({'registration_source': 'linkedin'});
          print('[LinkedIn WebView] ✅ Saved LinkedIn data for registration form');

          // Clear the flag
          LinkedInWebView.isWebViewActive = false;

          // Close WebView first
          print('[LinkedIn WebView] Closing WebView...');
          Get.back();

          // Delay slightly to ensure navigation stack is stable
          await Future.delayed(const Duration(milliseconds: 500));

          // Navigate based on registration status
          if (passwordSet && phoneVerified) {
            print('🏠✅ User fully registered - navigating to HOME');
            Get.offAllNamed(AppRoutes.home);
          } else {
            print('📝⚠️ User needs to complete registration - navigating to PERSONAL DETAILS');
            print('  Reason: passwordSet=$passwordSet, phoneVerified=$phoneVerified');
            Get.offAllNamed(AppRoutes.personal_details);
          }
        } else {
          print('[LinkedIn WebView] ❌ No userId found in user data');
          widget.onSuccess(data);
          Get.back();
        }
      } else {
        throw Exception('Failed to exchange code: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[LinkedIn WebView] Error: $e');
      LinkedInWebView.isWebViewActive = false;
      widget.onError(e.toString());
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      appBar: AppBar(
        title: const Text(
          'LinkedIn Login',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: kBlue,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            LinkedInWebView.isWebViewActive = false;
            Get.back();
          },
        ),
      ),
      body: Container(
        color: const Color(0xFF1565C0),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}