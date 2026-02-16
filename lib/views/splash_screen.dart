import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:get/get.dart';
import 'package:dama/services/deep_link_service.dart';
import 'package:dama/controller/linkedin_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final DeepLinkService _deepLinkService = Get.find();
  final LinkedInController _linkedInController = Get.find();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(Duration(milliseconds: 1500));
    
    try {
      // Check if user is already logged in
      String? token = await StorageService.getData('access_token');
      
      if (token != null && token.isNotEmpty) {
        Get.offAllNamed(AppRoutes.home);
        return;
      }
      
      // Check for initial deep link
      final uri = await _deepLinkService.getInitialLink();
      
      if (uri != null && _deepLinkService.isLinkedInCallback(uri)) {
        // Handle LinkedIn deep link
        await _linkedInController.handleDeepLink(uri);
        return;
      }
      
      // No deep link, go to login
      Get.offAllNamed(AppRoutes.login);
      
    } catch (e) {
      print('Error initializing app: $e');
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlue,
      body: Center(child: Image.asset('images/splash.gif', fit: BoxFit.cover)),
    );
  }
}
