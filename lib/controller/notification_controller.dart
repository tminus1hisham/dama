import 'package:dama/models/notification_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  var notificationList = <NotificationModel>[].obs;

  var isLoading = false.obs;

  final ApiService _notificationService = ApiService();

  Future<void> fetchnotifications() async {
    isLoading.value = true;
    try {
      List<NotificationModel> fetchedNotifications;
      fetchedNotifications = await _notificationService.getNotifications();
      
      // Debug logging
      debugPrint('=== FETCHED ${fetchedNotifications.length} NOTIFICATIONS ===');
      for (var n in fetchedNotifications) {
        debugPrint('Notification: ${n.title}');
        debugPrint('  - type: ${n.type}');
        debugPrint('  - data: ${n.data}');
        debugPrint('  - notificationType: ${n.notificationType}');
        debugPrint('  - refId: ${n.refId}');
      }
      
      notificationList.assignAll(fetchedNotifications);
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllNotificationsAsRead();
      if (success) {
        // Update local state to mark all as read - create new list to trigger update
        final updatedList = notificationList.map((notification) {
          return NotificationModel(
            id: notification.id,
            read: true,
            title: notification.title,
            body: notification.body,
            createdAt: notification.createdAt,
            type: notification.type,
            referenceId: notification.referenceId,
            data: notification.data,
          );
        }).toList();
        
        // Use assignAll to trigger reactive update
        notificationList.assignAll(updatedList);
      }
      return success;
    } catch (e) {
      print('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      if (notificationId.isEmpty) {
        debugPrint('Error: Cannot mark notification with empty ID as read');
        return false;
      }
      
      final success = await _notificationService.markNotificationAsRead(notificationId);
      
      if (success) {
        // Update local state
        final index = notificationList.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = notificationList[index];
          notificationList[index] = NotificationModel(
            id: notification.id,
            read: true,
            title: notification.title,
            body: notification.body,
            createdAt: notification.createdAt,
            type: notification.type,
            referenceId: notification.referenceId,
            data: notification.data,
          );
          notificationList.refresh(); // Trigger update
        }
      }
      
      return success;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }
}
