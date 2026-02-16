import 'package:dama/models/notification_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  var notificationList = <NotificationModel>[].obs;

  var isLoading = false.obs;

  final ApiService _notificationService = ApiService();

  Future<void> fetchnotifications() async {
    isLoading.value = true;
    try {
      List<NotificationModel> fetchedTranscations;
      fetchedTranscations = await _notificationService.getNotifications();
      notificationList.assignAll(fetchedTranscations);
    } catch (e) {
      print(e);
      // Get.snackbar(
      //   margin: EdgeInsets.only(top: 15, left: 15, right: 15),
      //   "Error",
      //   "Failed to fetch notifications",
      //   colorText: kWhite,
      //   backgroundColor: kRed.withOpacity(0.9),
      // );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllNotificationsAsRead();
      if (success) {
        // Update local state to mark all as read
        for (var i = 0; i < notificationList.length; i++) {
          final notification = notificationList[i];
          notificationList[i] = NotificationModel(
            id: notification.id,
            read: true,
            title: notification.title,
            body: notification.body,
            createdAt: notification.createdAt,
            type: notification.type,
            referenceId: notification.referenceId,
          );
        }
      }
      return success;
    } catch (e) {
      print('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await _notificationService.deleteNotification(
        notificationId,
      );
      if (success) {
        // Remove from local list
        notificationList.removeWhere((n) => n.id == notificationId);
      }
      return success;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }
}
