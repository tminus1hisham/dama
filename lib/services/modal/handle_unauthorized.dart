import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';

class HandleUnauthorizedService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static void navigateToLoginAndClearStack() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  static void showUnauthorizedDialog() {
    // DISABLED: Session Expired Alert
    // Dialog has been disabled as per requirement
  }
}
