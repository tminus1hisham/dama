import 'package:dama/app.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'controller/auth_controller.dart';
import 'controller/global_search_controller.dart';
import 'controller/register_controller.dart';
import 'controller/user_training_controller.dart';
import 'controller/linkedin_controller.dart';
import 'providers/chat_provider.dart';
import 'providers/sessions_provider.dart';
import 'services/firebase_messaging_service.dart';
import 'services/deep_link_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(GlobalSearchController());
  Get.put(RegisterController());  // Make RegisterController available throughout the app

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
  }

  Get.put(AuthController());
  Get.put(UserTrainingController());
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
