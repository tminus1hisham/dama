// network_modal.dart
import 'package:dama/services/modal/handle_unauthorized.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';

class NetworkModal {
  static BuildContext? get context =>
      HandleUnauthorizedService.navigatorKey.currentContext;

  static void showNetworkDialog() {
    if (context == null) {
      return;
    }

    PanaraInfoDialog.show(
      context!,
      title: "No Internet",
      message: "Please check your internet connection.",
      panaraDialogType: PanaraDialogType.error,
      imagePath: "images/network.png",
      barrierDismissible: false,
      buttonText: "Okay",
      onTapDismiss: () {
        Navigator.of(context!).pop();
      },
    );
  }
}
