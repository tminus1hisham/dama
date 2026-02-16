// import 'package:dama/models/alert_model.dart';
// import 'package:dama/services/api_service.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class AlertController extends GetxController {
//   final ApiService _apiService = ApiService();
//
//   var isLoading = false.obs;
//   var alerts = <AlertModel>[].obs;
//   var errorMessage = ''.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     fetchAlerts();
//   }
//
//   Future<void> fetchAlerts() async {
//     try {
//       isLoading.value = true;
//       errorMessage.value = '';
//
//       final result = await _apiService.getAlerts();
//       alerts.assignAll(result);
//     } catch (e) {
//       errorMessage.value = e.toString();
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   Future<bool> shouldShowAlert(String alertId) async {
//     final prefs = await SharedPreferences.getInstance();
//     return !(prefs.getBool('alert_shown_$alertId') ?? false);
//   }
//
//   Future<void> markAlertAsShown(String alertId) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('alert_shown_$alertId', true);
//   }
// }

import 'package:dama/models/alert_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';

class AlertController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var alerts = <AlertModel>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _apiService.getAlerts();
      alerts.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> shouldShowAlert(String alertId) async {
    // Always show alert on every login
    return true;
  }

  Future<void> markAlertAsShown(String alertId) async {
    // No longer storing shown state since we show on every login
    // Keeping method for compatibility
  }
}
