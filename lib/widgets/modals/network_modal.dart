import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';

class CustomInfomationDialog {
  static void showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    PanaraDialogType dialogType = PanaraDialogType.normal,
    VoidCallback? onTap,
  }) {
    PanaraInfoDialog.show(
      context,
      title: title,
      message: message,
      buttonText: "Okay",
      imagePath: 'images/logo.png',
      onTapDismiss:
      onTap ??
              () {
            Navigator.of(context).pop();
          },
      panaraDialogType: dialogType,
      barrierDismissible: true,
    );
  }
}