import 'package:dama/app.dart';
import 'package:dama/services/update_service.dart';
import 'package:dama/services/unified_payment_service.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'controller/alert_controller.dart';
import 'controller/auth_controller.dart';
import 'controller/global_search_controller.dart';
import 'controller/plans_controller.dart';
import 'controller/rating_controller.dart';
import 'controller/referral_controller.dart';
import 'controller/register_controller.dart';
import 'controller/support_controller.dart';
import 'controller/training_controller.dart';
import 'controller/user_training_controller.dart';
import 'controller/user_progress_controller.dart';
import 'controller/linkedin_controller.dart';
import 'controller/payment_controller.dart';
import 'providers/chat_provider.dart';
import 'providers/sessions_provider.dart';
import 'services/firebase_messaging_service.dart';
import 'services/deep_link_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(GlobalSearchController());
  Get.put(
    RegisterController(),
  ); // Make RegisterController available throughout the app
  Get.put(PlansController()); // Make PlansController available globally
  Get.put(AlertController()); // Make AlertController available for alerts

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      await FirebaseApi().initNotifications();
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Continue without Firebase - login will work without push notifications
    }

    // Initialize services
    Get.put(DeepLinkService());
    Get.put(ApiService());
    Get.put(LinkedInController());

    // Initialize payment services (Apple Pay on iOS)
    await UnifiedPaymentService.initialize();
  }

  Get.put(AuthController());
  Get.put(RatingController());
  Get.put(ReferralController());
  Get.put(SupportController());
  Get.put(TrainingController());
  Get.put(UserTrainingController());
  Get.put(UserProgressController());
  Get.put(PaymentController());

  // Initialize in-app update service (Android/iOS only)
  if (!kIsWeb) {
    final updateService = await UpdateServiceExtension.initialize();
    Get.put(updateService);
    // Check for updates after app starts (with slight delay for better UX)
    Future.delayed(const Duration(seconds: 3), () {
      updateService.checkForUpdate();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SessionsProvider()),
      ],
      child: MyApp(),
    ),
  );
}
