import 'package:dama/views/auth/login_screen.dart';
import 'package:dama/views/auth/otp_screen.dart';
import 'package:dama/views/auth/register_screen.dart';
import 'package:dama/views/auth/request_change_password.dart';
import 'package:dama/views/auth/reset_password.dart';
import 'package:dama/views/chat/chat_users_screen.dart';
import 'package:dama/views/dashboard.dart';
import 'package:dama/views/drawer_screen/about_dama.dart';
import 'package:dama/views/drawer_screen/change_password.dart';
import 'package:dama/views/drawer_screen/notification_preferences.dart';
import 'package:dama/views/drawer_screen/notifications_screen.dart';
import 'package:dama/views/drawer_screen/plans_screen.dart';
import 'package:dama/views/drawer_screen/settings_screen.dart';
import 'package:dama/views/drawer_screen/profile_screen.dart';
import 'package:dama/views/drawer_screen/transactions.dart';
import 'package:dama/views/my_certificates_screen.dart';
import 'package:dama/views/my_trainings_screen.dart';
import 'package:dama/views/personal_details.dart';
import 'package:dama/views/professional_details.dart';
import 'package:dama/views/splash_screen.dart';
import 'package:dama/views/today_sessions_screen.dart';
import 'package:dama/views/training_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String otp = '/otp';
  static const String personal_details = '/personal_details';
  static const String professional_details = '/professional_details';
  static const String plans = '/plans';
  static const String profile = '/profile';
  static const String transcation = '/transactions';
  static const String usersChatScreen = '/usersChatScreen';
  static const String notifications = '/notifications';
  static const String notificationPreferences = '/notification-preferences';
  static const String aboutDama = '/aboutDama';
  static const String settingsPage = '/settings';
  static const String changePassword = '/changePassword';
  static const String requestChangePassword = '/requestChangePassword';
  static const String resetPassword = '/resetPassword';
  static const String trainings = '/trainings';
  static const String todaySessions = '/today-sessions';
  static const String myTrainings = '/my-trainings';
  static const String certificates = '/my-certificates';
  // NOTE: trainingDashboard removed — always navigate using:
  // Get.to(() => TrainingDashboard(training: training))

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return PageTransition(
          child: SplashScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case login:
        return PageTransition(
          child: LoginScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case register:
        return PageTransition(
          child: RegisterScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case home:
        return PageTransition(
          child: Dashboard(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case otp:
        return PageTransition(
          child: OtpScreen(),
          type: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 300),
        );

      case personal_details:
        return PageTransition(
          child: PersonalDetails(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case professional_details:
        return PageTransition(
          child: ProfessionalDetails(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case plans:
        return PageTransition(
          child: PlansScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case profile:
        return PageTransition(
          child: ProfileScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case transcation:
        return PageTransition(
          child: Transactions(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case usersChatScreen:
        return PageTransition(
          child: ChatUsersScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case notifications:
        return PageTransition(
          child: NotificationsScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case aboutDama:
        return PageTransition(
          child: AboutScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case settingsPage:
        return PageTransition(
          child: SettingsScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case changePassword:
        return PageTransition(
          child: ChangePassword(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case notificationPreferences:
        return PageTransition(
          child: NotificationPreferencesScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case requestChangePassword:
        return PageTransition(
          child: RequestChangePassword(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case resetPassword:
        return PageTransition(
          child: ResetPassword(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case trainings:
        return PageTransition(
          child: TrainingScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case todaySessions:
        return PageTransition(
          child: TodaySessionsScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case myTrainings:
        return PageTransition(
          child: MyTrainingsScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      case certificates:
        return PageTransition(
          child: MyCertificatesScreen(),
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 300),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}