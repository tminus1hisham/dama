import 'package:dama/models/notification_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends GetxController {
  var notificationList = <NotificationModel>[].obs;
  var isLoading = false.obs;

  final ApiService _notificationService = ApiService();

  // Local storage key for read notification IDs
  static const String _readNotificationsKey = 'read_notification_ids';
  Set<String> _locallyReadIds = {};

  @override
  void onInit() {
    super.onInit();
    _loadLocallyReadIds();
  }

  // Load locally read notification IDs from SharedPreferences
  Future<void> _loadLocallyReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_readNotificationsKey) ?? [];
      _locallyReadIds = readIds.toSet();
      debugPrint(
        'Loaded ${_locallyReadIds.length} locally read notification IDs',
      );
    } catch (e) {
      debugPrint('Error loading locally read IDs: $e');
    }
  }

  // Save locally read notification IDs to SharedPreferences
  Future<void> _saveLocallyReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _readNotificationsKey,
        _locallyReadIds.toList(),
      );
      debugPrint(
        'Saved ${_locallyReadIds.length} locally read notification IDs',
      );
    } catch (e) {
      debugPrint('Error saving locally read IDs: $e');
    }
  }

  Future<void> fetchnotifications() async {
    isLoading.value = true;
    debugPrint('📱 [Notifications] Starting fetch...');
    try {
      // Always load locally read IDs to ensure we have the latest
      await _loadLocallyReadIds();
      debugPrint(
        '📱 [Notifications] Local read IDs count: ${_locallyReadIds.length}',
      );

      List<NotificationModel> fetchedNotifications =
          await _notificationService.getNotifications();

      debugPrint(
        '📱 [Notifications] === FETCHED ${fetchedNotifications.length} NOTIFICATIONS ===',
      );
      if (fetchedNotifications.isEmpty) {
        debugPrint('⚠️ [Notifications] No notifications returned from API!');
        debugPrint('   - This could mean: User has no notifications, OR');
        debugPrint('   - API authorization issue, OR');
        debugPrint('   - Backend not sending notifications to this user');
      }
      for (var n in fetchedNotifications) {
        debugPrint('Notification: ${n.title}');
        debugPrint('  - type: ${n.type}');
        debugPrint('  - data: ${n.data}');
        debugPrint('  - notificationType: ${n.notificationType}');
        debugPrint('  - refId: ${n.refId}');
      }

      // Merge server read status with local read status
      int mergedCount = 0;
      final mergedNotifications =
          fetchedNotifications.map((notification) {
            final isLocallyRead = _locallyReadIds.contains(notification.id);
            if (isLocallyRead && !notification.read) {
              mergedCount++;
              // Notification was marked read locally but server doesn't know
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
            }
            return notification;
          }).toList();

      debugPrint(
        'Merged $mergedCount notifications as read from local storage',
      );

      // Sort by createdAt descending (newest first)
      mergedNotifications.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      notificationList.assignAll(mergedNotifications);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      // Get list of unread notifications to mark
      final unreadNotifications =
          notificationList.where((n) => !n.read && n.id.isNotEmpty).toList();

      if (unreadNotifications.isEmpty) {
        debugPrint('No unread notifications to mark');
        return true;
      }

      debugPrint(
        'Marking ${unreadNotifications.length} notifications as read locally...',
      );

      // Add all unread notification IDs to local storage
      for (final notification in unreadNotifications) {
        _locallyReadIds.add(notification.id);
      }
      await _saveLocallyReadIds();

      // Update UI locally
      final updatedList =
          notificationList.map((notification) {
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
      notificationList.assignAll(updatedList);

      debugPrint(
        'Successfully marked ${unreadNotifications.length} notifications as read locally',
      );
      return true;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      if (notificationId.isEmpty) {
        debugPrint('Error: Cannot mark notification with empty ID as read');
        return false;
      }

      // Add to locally read IDs and save
      _locallyReadIds.add(notificationId);
      await _saveLocallyReadIds();

      // Update UI locally
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
        notificationList.refresh();
      }

      debugPrint('Marked notification $notificationId as read locally');
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }
}
