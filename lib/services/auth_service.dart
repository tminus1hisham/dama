import 'dart:convert';
import 'dart:io';

import 'package:dama/models/change_password_model.dart';
import 'package:dama/models/login_model.dart';
import 'package:dama/models/otp_verification.dart';
import 'package:dama/models/register_model.dart';
import 'package:dama/models/request_reset_password.dart';
import 'package:dama/models/reset_password_model.dart';
import 'package:dama/models/user_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'local_storage_service.dart';

class AuthService {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final _storage = FlutterSecureStorage();

  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await StorageService.getData('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        print('No refresh token available');
        return false;
      }

      final response = await http.post(
        Uri.parse('$BASE_URL/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await AuthService.storeTokens(data);
        print('Token refreshed successfully');
        return true;
      } else {
        print('Token refresh failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  static Future<void> storeTokens(Map<String, dynamic> data) async {
    try {
      final user = data['user'];
      print('[AuthService] Storing tokens for user: $user');
      print('[AuthService] User memberId: ${user?['memberId']}');
      print('[AuthService] User membershipId: ${user?['membershipId']}');

      List<String> roles = [];
      if (user != null && user['roles'] != null && user['roles'] is List) {
        roles = List<String>.from(user['roles']);
      }

      await StorageService.storeData({
        'access_token': data['token'] ?? '',
        'refresh_token': data['refreshToken'] ?? '',
        'userId': user?['_id'] ?? '',
        'firstName': user?['firstName'] ?? '',
        'middleName': user?['middleName'] ?? '',
        'lastName': user?['lastName'] ?? '',
        'email': user?['email'] ?? '',
        'phoneNumber': user?['phone_number'] ?? '',
        'profile_picture': user?['profile_picture'] ?? '',
        'title': user?['title'] ?? '',
        'company': user?['company'] ?? '',
        'brief': user?['brief'] ?? '',
        'resources':
            user?['resources'] != null ? jsonEncode(user!['resources']) : '[]',
        'events': user?['events'] != null ? jsonEncode(user!['events']) : '[]',
        'memberId': user?['memberId'] ?? '',
        'hasMembership': user?['hasMembership'] ?? false,
        'articles_assigned_count': user?['articles_assigned_count'] ?? 0,
        'articles_seen_count': user?['articles_seen_count'] ?? 0,
        'membershipExp': user?['membershipExp'] ?? '',
        'membershipId':
            (() {
              final membershipIdRaw = user?['membershipId'];
              if (membershipIdRaw is Map) {
                return membershipIdRaw['_id'] ?? '';
              }
              return membershipIdRaw ?? '';
            })(),
        'membershipCertificate': user?['membershipCertificate'] ?? '',
        'membershipCertificateDownload':
            user?['membershipCertificateDownload'] ?? '',
        'roles_json': jsonEncode(roles),
        'authType': user?['authType'] ?? data['authType'] ?? 'email',
      });
    } catch (e) {}
  }

  static Future<void> _storeRegisterTokens(Map<String, dynamic> data) async {
    try {
      final user = data['user'];
      final token = data['token'];

      List<String> roles = [];
      if (user != null && user['roles'] != null && user['roles'] is List) {
        roles = List<String>.from(user['roles']);
      }

      Map<String, dynamic> storageData = {
        'userId': user?['_id'] ?? '',
        'phoneNumber': user?['phone_number'] ?? '',
      };

      if (token != null) {
        storageData['access_token'] = token;
        await AuthService.storeTokens(data);
      } else {
        await StorageService.storeData(storageData);
      }
    } catch (e) {
      debugPrint('Error storing register tokens: $e');
    }
  }

  Future<Map<String, dynamic>?> login(LoginModel request) async {
    try {
      debugPrint(
        '📱 [Login] FCM Token being sent: ${request.fcmToken.isNotEmpty ? "present (${request.fcmToken.substring(0, 20)}...)" : "EMPTY!"}',
      );
      debugPrint('📱 [Login] Calling POST /user/login');

      final response = await http.post(
        Uri.parse('$BASE_URL/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      debugPrint('📱 [Login] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await AuthService.storeTokens(data);
        await secureStorage.write(key: 'email', value: request.email);
        await secureStorage.write(key: 'password', value: request.password);
        debugPrint('📱 [Login] Login successful, tokens stored');
        return data;
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Invalid credentials or login failed';
        throw Exception(errorMessage);
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during login: $e');
    }
  }

  static Future<Map<String, dynamic>?> loginWithLinkedin() async {
    throw UnimplementedError(
      'Use LinkedInController for LinkedIn authentication',
    );
  }

  Future<Map<String, dynamic>?> verifyOtp(OtpVerificationModel request) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    debugPrint(
      '[OTP] Verifying OTP for userId: ${request.userId}, otp: ${request.otp}',
    );

    final response = await http.post(
      Uri.parse('$BASE_URL/user/login/2fa/verify'),
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    debugPrint('[OTP] Response status: ${response.statusCode}');
    debugPrint('[OTP] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await AuthService.storeTokens(data);
      return data;
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(
        'OTP Verification failed: ${errorBody['message'] ?? 'Unknown error'}',
      );
    }
  }

  /// Verify OTP for registration/professional details flow
  Future<Map<String, dynamic>?> verifyRegistrationOtp(
    OtpVerificationModel request,
  ) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    debugPrint(
      '[Registration OTP] Verifying OTP for userId: ${request.userId}, otp: ${request.otp}',
    );

    // Try the registration-specific endpoint first, fallback to login endpoint
    final response = await http.post(
      Uri.parse('$BASE_URL/user/register/verify-otp'),
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    debugPrint('[Registration OTP] Response status: ${response.statusCode}');
    debugPrint('[Registration OTP] Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      await AuthService.storeTokens(data);
      return data;
    } else if (response.statusCode == 404) {
      // Endpoint not found - try the login endpoint as fallback
      debugPrint(
        '[Registration OTP] Registration endpoint not found, trying login endpoint',
      );
      return await verifyOtp(request);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(
        'OTP Verification failed: ${errorBody['message'] ?? 'Unknown error'}',
      );
    }
  }

  /// Initiate 2FA/OTP after profile completion
  /// Endpoint: POST /v1/user/initiate2fa
  Future<Map<String, dynamic>?> initiate2fa() async {
    try {
      final accessToken = await StorageService.getData("access_token");
      final userId = await StorageService.getData("userId");
      final phoneNumber = await StorageService.getData("phoneNumber");
      final email = await StorageService.getData("email");

      print('[Initiate 2FA] Starting 2FA initiation');
      print('[Initiate 2FA] UserId: $userId');
      print('[Initiate 2FA] PhoneNumber from storage: $phoneNumber');
      print('[Initiate 2FA] Email from storage: $email');
      print(
        '[Initiate 2FA] AccessToken exists: ${accessToken != null && accessToken.isNotEmpty}',
      );

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('No access token available');
      }

      if (userId == null || userId.isEmpty) {
        throw Exception('No user ID available');
      }

      // Build request body
      final requestBody = {'userId': userId};

      print('[Initiate 2FA] Request body: $requestBody');
      print('[Initiate 2FA] Calling POST $BASE_URL/user/initiate2fa');

      final response = await http.post(
        Uri.parse('$BASE_URL/user/initiate2fa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      print('[Initiate 2FA] Response status: ${response.statusCode}');
      print('[Initiate 2FA] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('[Initiate 2FA] Success: $data');
        return data;
      } else if (response.statusCode == 404) {
        print('[Initiate 2FA] Endpoint not found (404)');
        throw Exception('Endpoint not found (404)');
      } else {
        print(
          '[Initiate 2FA] Error response: ${response.statusCode} - ${response.body}',
        );
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to initiate 2FA: ${errorBody['message'] ?? 'Unknown error'}',
        );
      }
    } on SocketException catch (e) {
      print('[Initiate 2FA] SocketException: $e');
      throw Exception('Network error, please check your internet connection.');
    } catch (e) {
      print('[Initiate 2FA] Error: $e');
      throw Exception('Error initiating 2FA: $e');
    }
  }

  // ✅ FIXED: Removed Authorization header — user is not logged in during password reset
  Future<Map<String, dynamic>?> resetPassword(
    ResetPasswordModel request,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/user/reset-password-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'OTP Verification failed');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your internet connection.');
    } catch (e) {
      throw Exception('An error occurred during password reset: $e');
    }
  }

  Future<bool> loginWithBiometrics(String fcmToken) async {
    try {
      final email = await _storage.read(key: 'email');
      final password = await _storage.read(key: 'password');

      if (email == null || password == null) return false;

      final loginModel = LoginModel(
        email: email,
        password: password,
        fcmToken: fcmToken,
      );

      await login(loginModel);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> register(RegisterModel request) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await _storeRegisterTokens(data);
        await secureStorage.write(key: 'email', value: request.email);
        await secureStorage.write(key: 'password', value: request.password);
        return data;
      } else {
        final error = jsonDecode(response.body);

        final errors = error['errors'];
        if (errors != null && errors is Map) {
          if (errors['email'] != null) {
            throw Exception('email_exists: ${errors['email']}');
          }
          if (errors['phone_number'] != null || errors['phone'] != null) {
            throw Exception(
              'phone_exists: ${errors['phone_number'] ?? errors['phone']}',
            );
          }
        }

        final errorMessage = error['message'] ?? 'Registration failed';
        if (errorMessage.toString().toLowerCase().contains('email')) {
          throw Exception('email_exists: $errorMessage');
        }
        if (errorMessage.toString().toLowerCase().contains('phone')) {
          throw Exception('phone_exists: $errorMessage');
        }

        throw Exception(errorMessage);
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your internet connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateUserProfile(UserProfileModel userProfileRequest) async {
    try {
      final accessToken = await StorageService.getData("access_token");

      print('[UpdateUserProfile] Request: ${userProfileRequest.toJson()}');

      final response = await http.patch(
        Uri.parse('$BASE_URL/user/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(userProfileRequest.toJson()),
      );

      print('[UpdateUserProfile] Response status: ${response.statusCode}');
      print('[UpdateUserProfile] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await StorageService.storeData({
          'firstName': data['user']['firstName'],
          'middleName': data['user']['middleName'],
          'lastName': data['user']['lastName'],
          'email': data['user']['email'],
          'phoneNumber': data['user']['phone_number'],
          'profile_picture': data['user']['profile_picture'],
          'title': data['user']['title'],
          'company': data['user']['company'],
          'brief': data['user']['brief'],
        });
        await _storeRegisterTokens(data);
        return true;
      } else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> changePassword(
    ChangePasswordModel request,
  ) async {
    try {
      final accessToken = await StorageService.getData("access_token");
      print(
        'Access token retrieved: ${accessToken != null ? "YES (${accessToken.length} chars)" : "NO"}',
      );

      final response = await http.post(
        Uri.parse('https://api.damakenya.org/v1/user/change/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      print('Request body: ${jsonEncode(request.toJson())}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Password change failed - Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
          'Failed to change password: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in changePassword: $e');
      rethrow;
    }
  }

  // ✅ FIXED: Now surfaces the real server error message + added debug logs
  Future<Map<String, dynamic>?> requestResetPassword(
    RequestChangePasswordModel request,
  ) async {
    try {
      print(
        '[requestResetPassword] Request body: ${jsonEncode(request.toJson())}',
      );

      final response = await http.post(
        Uri.parse('$BASE_URL/user/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      print('[requestResetPassword] Status: ${response.statusCode}');
      print('[requestResetPassword] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await StorageService.storeData({'userId': data['userId']});
        return data;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Failed to request password reset',
        );
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your internet connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> requestDeleteAccount() async {
    final accessToken = await StorageService.getData("access_token");

    final response = await http.post(
      Uri.parse('$BASE_URL/user/delete/account/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await AuthService.storeTokens(data);
      return data;
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(
        'Request failed: ${errorBody['message'] ?? 'Unknown error'}',
      );
    }
  }

  Future<bool> logoutUser() async {
    try {
      await StorageService.removeData('access_token');
      await StorageService.removeData('user_data');
      await StorageService.removeData('login_method');
      await StorageService.removeData('authType');
      await StorageService.removeData('otp_flow');
      await StorageService.removeData('firstName');
      await StorageService.removeData('middleName');
      await StorageService.removeData('lastName');
      await StorageService.removeData('email');
      await StorageService.removeData('phoneNumber');
      await StorageService.removeData('profile_picture');
      await StorageService.removeData('title');
      await StorageService.removeData('company');
      await StorageService.removeData('brief');
      await StorageService.removeData('userId');
      await StorageService.removeData('memberId');
      await StorageService.removeData('hasMembership');
      await StorageService.removeData('membershipExp');
      await StorageService.removeData('membershipId');
      await StorageService.removeData('roles_json');
      await StorageService.removeData('resources');
      await StorageService.removeData('events');
      await StorageService.removeData('articles_assigned_count');
      await StorageService.removeData('articles_seen_count');
      await StorageService.removeData('roles');

      await secureStorage.delete(key: 'auth_token');
      await secureStorage.delete(key: 'user_data');
      await secureStorage.delete(key: 'login_method');
      await secureStorage.delete(key: 'email');
      await secureStorage.delete(key: 'password');

      return true;
    } catch (e) {
      return false;
    }
  }
}
