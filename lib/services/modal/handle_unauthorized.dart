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
    if (context == null) return;

    PanaraInfoDialog.show(
      context!,
      title: "Session Expired",
      message: "Your session has expired. Please log in again.",
      panaraDialogType: PanaraDialogType.error,
      imagePath: "images/logo.png",
      barrierDismissible: false,
      buttonText: "Okay",
      onTapDismiss: () {
        Navigator.of(context!).pop();
        navigateToLoginAndClearStack();
      },
    );
  }
}
