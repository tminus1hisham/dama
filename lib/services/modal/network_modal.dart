// network_modal.dart
import 'package:dama/services/modal/handle_unauthorized.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';

class NetworkModal {
  static BuildContext? get context =>
      HandleUnauthorizedService.navigatorKey.currentContext;

  static void showNetworkDialog() {
    // DISABLED: Network Error Alert
    // Dialog has been disabled as per requirement
  }
}
