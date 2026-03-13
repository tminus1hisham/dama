import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:dama/models/user_model.dart';
import 'package:dama/services/auth_alert_helper.dart';
import 'package:get/get.dart';
import '../routes/routes.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../models/login_model.dart';
import '../services/local_storage_service.dart';

class AuthController extends GetxController {
  var email = ''.obs;
  var password = ''.obs;
  var fcmToken = ''.obs;
  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var user = Rxn<UserProfileModel>();

  var emailError = ''.obs;
  var passwordError = ''.obs;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final _auth = LocalAuthentication();

  void login(BuildContext context) async {
    // Clear previous errors
    emailError.value = '';
    passwordError.value = '';

    isLoading.value = true;

    try {
      // Check server connectivity first
      final isServerReachable = await _checkServerConnectivity();
      if (!isServerReachable) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.overlayContext != null) {
            Get.snackbar(
              'Connection Error',
              'Unable to connect to the server. Please check your internet connection and try again.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        });
        return;
      }

      final loginModel = LoginModel(
        fcmToken: fcmToken.value,
        email: email.value,
        password: password.value,
      );

      final result = await _authService.login(loginModel);

      debugPrint('[Login] Result: $result');
      debugPrint('[Login] Requires OTP: ${result?['requiresOtp']}');
      debugPrint('[Login] Token: ${result?['token']}');
      debugPrint('[Login] User: ${result?['user']}');

      if (result != null &&
          result['token'] != null &&
          !(result['requiresOtp'] ?? false)) {
        // Store user data and update auth state for successful login
        final user = result['user'];
        print('[AuthController] Successful login - user data: $user');
        print('[AuthController] User memberId: ${user?['memberId']}');
        print('[AuthController] User membershipId: ${user?['membershipId']}');
        if (user != null) {
          await updateAuthState(token: result['token'], userData: user);
          debugPrint('[Login] Updated auth state for successful login');
        }
        // Navigate to dashboard
        Get.offAllNamed(AppRoutes.home);
      } else if (result != null && (result['requiresOtp'] ?? false)) {
        // Store token and userId for OTP verification
        if (result['token'] != null) {
          await StorageService.storeData({'access_token': result['token']});
          debugPrint('[Login] Stored token for OTP: ${result['token']}');
        }
        final user = result['user'];
        if (user != null && user['_id'] != null) {
          await StorageService.storeData({'userId': user['_id']});
          debugPrint('[Login] Stored userId: ${user['_id']}');
        } else {
          debugPrint('[Login] No user data in response for OTP');
        }
        // Unfocus to hide keyboard before navigating
        FocusManager.instance.primaryFocus?.unfocus();
        Get.offAllNamed(AppRoutes.otp);
      } else if (result != null &&
          result['userId'] != null &&
          result['message'] != null &&
          result['message'].contains('OTP sent')) {
        // Handle case where OTP is sent but requiresOtp flag is not set
        await StorageService.storeData({'userId': result['userId']});
        debugPrint(
          '[Login] Stored userId from OTP response: ${result['userId']}',
        );
        // Unfocus to hide keyboard before navigating
        FocusManager.instance.primaryFocus?.unfocus();
        Get.offAllNamed(AppRoutes.otp);
      } else {
        // Unfocus to hide keyboard before navigating
        FocusManager.instance.primaryFocus?.unfocus();
        Get.offAllNamed(AppRoutes.otp);
      }
    } catch (e) {
      // Set error messages below the fields
      emailError.value = 'Please enter a valid username';
      passwordError.value = 'Please enter a valid password';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAuthState({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Store the token
      await _storage.write(key: 'auth_token', value: token);

      // Store user data
      await _storage.write(key: 'user_data', value: json.encode(userData));

      // Store individual profile fields for dashboard display
      await _storeProfileFields(userData);

      // Fetch complete user profile from server to ensure membership data is up to date
      Map<String, dynamic> completeUserData =
          userData; // Default to provided data

      try {
        final profileData = await _apiService.fetchCurrentUserProfile();
        if (profileData != null && profileData['user'] != null) {
          completeUserData = profileData['user'];
          print('Fetched complete profile data for current user');
          // Update stored user data with complete profile
          await _storage.write(
            key: 'user_data',
            value: json.encode(completeUserData),
          );
          // Update profile fields with complete data
          await _storeProfileFields(completeUserData);
        }
      } catch (e) {
        print(
          'Warning: Could not fetch complete user profile, using provided data: $e',
        );
        // Keep completeUserData as provided userData
      }

      // Update reactive variables
      isLoggedIn.value = true;
      user.value = UserProfileModel.fromJson(completeUserData);

      // Update API service headers
      _apiService.updateHeaders({'Authorization': 'Bearer $token'});
    } catch (e) {
      print('Error updating auth state: $e');
      rethrow;
    }
  }

  Future<void> loginWithBiometrics(BuildContext context) async {
    try {
      // Check server connectivity first
      final isServerReachable = await _checkServerConnectivity();
      if (!isServerReachable) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.overlayContext != null) {
            Get.snackbar(
              'Connection Error',
              'Unable to connect to the server. Please check your internet connection and try again.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        });
        return;
      }

      bool isAvailable = await _auth.canCheckBiometrics;
      if (!isAvailable) {
        AuthAlertHelper.showError(
          'Biometric Not Available',
          'Your device does not support biometric authentication.',
        );
        return;
      }

      // Show the biometric authentication dialog
      bool isAuthenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to log in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        isLoading.value = true;
        final success = await _authService.loginWithBiometrics(fcmToken.value);
        isLoading.value = false;

        if (success) {
          Get.offAllNamed(AppRoutes.home);
        } else {
          AuthAlertHelper.showError(
            'Biometric Login Failed',
            'Could not authenticate with biometrics.',
          );
        }
      }
    } catch (e) {
      isLoading.value = false;
      AuthAlertHelper.showError(
        'Biometric Auth Error',
        'An error occurred during biometric authentication',
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    final success = await _authService.logoutUser();
    if (success) {
      // Reset auth state
      isLoggedIn.value = false;
      user.value = null;
      email.value = '';
      password.value = '';

      // Clear API headers
      _apiService.clearAuthorizationHeader();

      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> completeLinkedInLogin(
    String token,
    Map<String, dynamic> userData,
  ) async {
    try {
      print('=== STARTING LINKEDIN LOGIN COMPLETION ===');
      print('Token length: ${token.length}');
      print('User data keys: ${userData.keys.toList()}');
      print('LinkedIn user email: ${userData['email']}');

      // Proceed with normal LinkedIn login
      await _completeLinkedInLoginFlow(token, userData);
    } catch (e) {
      print('=== LINKEDIN LOGIN COMPLETION FAILED ===');
      print('Error: $e');
      rethrow;
    }
  }

  Future<void> _completeLinkedInLoginFlow(
    String token,
    Map<String, dynamic> userData, {
    bool needsMerge = false,
  }) async {
    print('Completing LinkedIn login flow...');

    // Use the same token storage method as regular login
    final mockResponse = {'token': token, 'user': userData};
    await AuthService.storeTokens(mockResponse);

    print('Token and user data stored using AuthService.storeTokens');

    // Update API service headers
    _apiService.updateHeaders({'Authorization': 'Bearer $token'});
    print('API headers updated');

    // Fetch complete user profile from server (don't fail if this fails)
    Map<String, dynamic> completeUserData =
        userData; // Default to LinkedIn data

    try {
      final profileData = await _apiService.fetchCurrentUserProfile();
      print('Fetched current user profile data');
      if (profileData != null && profileData['user'] != null) {
        completeUserData = profileData['user'];
        print(
          'Using server profile data, memberId: ${completeUserData['memberId']}',
        );
        // Store complete profile data using the same method
        final completeMockResponse = {'token': token, 'user': completeUserData};
        await AuthService.storeTokens(completeMockResponse);
      }
    } catch (e) {
      print(
        'Warning: Could not fetch complete user profile, using LinkedIn data: $e',
      );
      // Keep completeUserData as LinkedIn data (already set above)
    }

    // Store LinkedIn login method and authType
    await _storage.write(key: 'login_method', value: 'linkedin');
    await StorageService.storeData({'authType': 'linkedin'});

    // Update reactive state BEFORE navigation
    print('Updating reactive state...');
    isLoggedIn.value = true;
    user.value = UserProfileModel.fromJson(completeUserData);
    print(
      'Reactive state updated: isLoggedIn=${isLoggedIn.value}, user exists=${user.value != null}',
    );

    print('About to navigate to home - auth state should be set');
    // Small delay to ensure reactive state propagates
    await Future.delayed(const Duration(milliseconds: 50));
    print('Navigating to home screen');
    Get.offAllNamed(AppRoutes.home);

    // Show merge suggestion if needed
    if (needsMerge) {
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Wait for navigation to complete
      Get.snackbar(
        'Account Notice',
        'You have an existing account with this email. If you see duplicate data, please contact support to merge your accounts.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _storeProfileFields(Map<String, dynamic> userData) async {
    // Apply professional membership free for one year if user doesn't have membership
    final hasMembership = userData['hasMembership'] ?? false;
    final membershipExp = userData['membershipExp'];

    // Check if user already has a membershipExp to avoid overwriting
    bool shouldApplyFree = !hasMembership;
    String? freeUntil;
    String? membershipStartDate;
    String? effectiveMembershipExp = membershipExp;

    if (shouldApplyFree) {
      // Apply 1-year free professional membership
      final expiryDate = DateTime.now().add(Duration(days: 365));
      freeUntil = expiryDate.toIso8601String();
      membershipStartDate = DateTime.now().toIso8601String();
      effectiveMembershipExp = freeUntil;

      debugPrint(
        '[AuthController] Applying free professional membership for 1 year',
      );
      debugPrint('[AuthController] Free until: $freeUntil');
    }

    await StorageService.storeData({
      'firstName': userData['firstName'] ?? '',
      'lastName': userData['lastName'] ?? '',
      'title': userData['title'] ?? '',
      'brief': userData['brief'] ?? '',
      'profile_picture': userData['profile_picture'] ?? '',
      'memberId': userData['memberId'] ?? '',
      'hasMembership': hasMembership,
      'membershipExp': effectiveMembershipExp ?? '',
      'membershipId':
          (() {
            final membershipIdRaw = userData['membershipId'];
            if (membershipIdRaw is Map) {
              return membershipIdRaw['_id'] ?? '';
            }
            return membershipIdRaw ?? '';
          })(),
      'membershipCertificate': userData['membershipCertificate'] ?? '',
      'membershipCertificateDownload':
          userData['membershipCertificateDownload'] ?? '',
      if (freeUntil != null) 'freeUntil': freeUntil,
      if (membershipStartDate != null)
        'membershipStartDate': membershipStartDate,
    });

    // Store user roles if available
    if (userData['roles'] != null) {
      await StorageService.storeUserRoles(userData['roles']);
    }
  }

  // Temporarily disabled - endpoint not implemented on server
  /*
  Future<void> _storeFcmTokenForUser(String userId) async {
    try {
      // Get FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Store FCM token for the user
        await _apiService.post('/user/update-fcm', {
          'userId': userId,
          'fcmToken': fcmToken,
        });
        print('FCM token stored successfully for user: $userId');
      } else {
        print('No FCM token available to store');
      }
    } catch (e) {
      print('Error storing FCM token: $e');
      // Don't rethrow as this is non-blocking
    }
  }
  */

  Future<void> refreshUserProfile() async {
    try {
      final userId = await StorageService.getData('userId');
      if (userId == null) {
        print('No userId found, cannot refresh profile');
        return;
      }

      final profileData = await _apiService.fetchUserProfile(userId);
      if (profileData != null && profileData['user'] != null) {
        final userData = profileData['user'];
        print('Refreshed user profile data for user: $userId');
        print('Updated memberId: ${userData['memberId']}');

        // Update stored profile fields
        await _storeProfileFields(userData);

        // Update reactive user model
        user.value = UserProfileModel.fromJson(userData);

        print('User profile refreshed successfully');
      } else {
        print('Failed to refresh user profile');
      }
    } catch (e) {
      print('Error refreshing user profile: $e');
    }
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
}
