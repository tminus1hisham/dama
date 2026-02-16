import 'dart:convert';
import 'package:dama/controller/auth_controller.dart';
import 'package:dama/controller/linkedin_controller.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/deep_link_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/services/modal/handle_unauthorized.dart';
import 'package:dama/views/dashboard.dart';
import 'package:dama/views/auth/login_screen.dart';
import 'package:dama/views/auth/otp_screen.dart';
import 'package:dama/views/auth/register_screen.dart';
import 'package:dama/views/auth/request_change_password.dart';
import 'package:dama/views/auth/reset_password.dart';
import 'package:dama/views/chat/chat_users_screen.dart';
import 'package:dama/views/course_sessions_screen.dart';
import 'package:dama/views/drawer_screen/about_dama.dart';
import 'package:dama/views/drawer_screen/change_password.dart';
import 'package:dama/views/drawer_screen/notifications_screen.dart';
import 'package:dama/views/drawer_screen/plans_screen.dart';
import 'package:dama/views/drawer_screen/profile_screen.dart';
import 'package:dama/views/drawer_screen/transactions.dart';
import 'package:dama/views/my_trainings_screen.dart';
import 'package:dama/views/personal_details.dart';
import 'package:dama/views/professional_details.dart';
import 'package:dama/views/splash_screen.dart';
import 'package:dama/views/today_sessions_screen.dart';
import 'package:dama/views/training_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _hasHandledInitialDeepLink = false;
  String _initialRoute = AppRoutes.login; // Default to login

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _determineInitialRoute();

    // Handle initial deep link after app is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_hasHandledInitialDeepLink) {
          _hasHandledInitialDeepLink = true;
          _handleInitialDeepLink();
        }
      });
    });
  }

  Future<void> _determineInitialRoute() async {
    try {
      // Check if user is already logged in
      String? token = await StorageService.getData('access_token');
      String? userDataString = await StorageService.getData('user_data');

      if (token != null && token.isNotEmpty) {
        // Load user data and update auth state
        final authController = Get.find<AuthController>();
        if (userDataString != null) {
          try {
            final userData = json.decode(userDataString);
            await authController.updateAuthState(
              token: token,
              userData: userData,
            );
          } catch (e) {
            print('Error parsing stored user data: $e');
            // If user data is corrupted, clear it
            await StorageService.storeData({'user_data': null});
          }
        }

        setState(() {
          _initialRoute = AppRoutes.home;
        });
        return;
      }

      // Check for initial deep link
      final deepLinkService = Get.find<DeepLinkService>();
      final uri = await deepLinkService.getInitialLink();

      if (uri != null && deepLinkService.isLinkedInCallback(uri)) {
        // Let LinkedInController handle the deep link
        setState(() {
          _initialRoute = AppRoutes.splash; // Use splash for deep link handling
        });
        return;
      }

      // No deep link, stay with login
      setState(() {
        _initialRoute = AppRoutes.login;
      });
    } catch (e) {
      print('Error determining initial route: $e');
      setState(() {
        _initialRoute = AppRoutes.login;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasHandledInitialDeepLink) {
      _hasHandledInitialDeepLink = true;
      _handleInitialDeepLink();
    }
  }

  void _handleInitialDeepLink() async {
    try {
      final deepLinkService = Get.find<DeepLinkService>();
      final initialUri = await deepLinkService.getInitialLink();
      if (initialUri != null &&
          deepLinkService.isLinkedInCallback(initialUri)) {
        final linkedInController = Get.find<LinkedInController>();
        await linkedInController.handleDeepLink(initialUri);
      }
    } catch (e) {
      print('Error handling initial deep link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: HandleUnauthorizedService.navigatorKey,
      initialRoute: _initialRoute,
      // Add GetX routing configuration
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => SplashScreen()),
        GetPage(name: AppRoutes.login, page: () => LoginScreen()),
        GetPage(name: AppRoutes.register, page: () => RegisterScreen()),
        GetPage(name: AppRoutes.home, page: () => Dashboard()),
        GetPage(name: AppRoutes.otp, page: () => OtpScreen()),
        GetPage(
          name: AppRoutes.personal_details,
          page: () => PersonalDetails(),
        ),
        GetPage(
          name: AppRoutes.professional_details,
          page: () => ProfessionalDetails(),
        ),
        GetPage(name: AppRoutes.plans, page: () => PlansScreen()),
        GetPage(name: AppRoutes.profile, page: () => ProfileScreen()),
        GetPage(name: AppRoutes.transcation, page: () => Transactions()),
        GetPage(name: AppRoutes.usersChatScreen, page: () => ChatUsersScreen()),
        GetPage(
          name: AppRoutes.notifications,
          page: () => NotificationsScreen(),
        ),
        GetPage(name: AppRoutes.aboutDama, page: () => AboutScreen()),
        GetPage(name: AppRoutes.changePassword, page: () => ChangePassword()),
        GetPage(
          name: AppRoutes.requestChangePassword,
          page: () => RequestChangePassword(),
        ),
        GetPage(name: AppRoutes.resetPassword, page: () => ResetPassword()),
        GetPage(name: AppRoutes.trainning, page: () => TrainingScreen()),
        GetPage(
          name: AppRoutes.todaySessions,
          page: () => TodaySessionsScreen(),
        ),
        GetPage(name: AppRoutes.myTrainings, page: () => MyTrainingsScreen()),
      ],
    );
  }
}
