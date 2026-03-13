import 'package:dama/widgets/modals/modern_alert.dart';

/// Helper for showing modern alerts in auth flows
class AuthAlertHelper {
  static final AlertProvider _instance = AlertProvider();

  static AlertProvider getInstance() {
    return _instance;
  }

  static void showSuccess(String title, String description) {
    getInstance().show(
      title: title,
      description: description,
      variant: AlertVariant.success,
    );
  }

  static void showError(String title, String description) {
    getInstance().show(
      title: title,
      description: description,
      variant: AlertVariant.error,
    );
  }

  static void showWarning(String title, String description) {
    getInstance().show(
      title: title,
      description: description,
      variant: AlertVariant.warning,
    );
  }

  static void showInfo(String title, String description) {
    getInstance().show(
      title: title,
      description: description,
      variant: AlertVariant.info,
    );
  }

  static void clearAll() {
    getInstance().dismissAll();
  }
}
