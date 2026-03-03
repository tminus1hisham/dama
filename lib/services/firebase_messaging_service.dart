import 'dart:convert';

import 'package:dama/controller/get_blog_by_id.dart';
import 'package:dama/controller/get_event_by_id.dart';
import 'package:dama/controller/get_news_by_id.dart';
import 'package:dama/controller/training_controller.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/views/selected_screens/selected_blog_screen.dart';
import 'package:dama/views/selected_screens/selected_event_screen.dart';
import 'package:dama/views/selected_screens/selected_news_screen.dart';
import 'package:dama/views/training_detail_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Request notification permissions (iOS-specific)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token for this device
    try {
      await FirebaseMessaging.instance.getToken();
    } catch (e) {
      // Token fetch failed silently
    }

    // Handle background messages (this must be a top-level function)
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(
        message.notification?.title,
        message.notification?.body,
        message.data,
      );
    });

    // Handle messages when the app is opened via notification tap (terminated state)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }

    // Initialize local notifications for in-app notifications
    await _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS initialization (Darwin platform)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combine both Android and iOS/macOS settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // Initialize the plugin for both Android and iOS/macOS
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _handleNotificationTap(data);
        }
      },
    );
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    try {
      debugPrint('=== FIREBASE NOTIFICATION TAP HANDLER ===');
      debugPrint('Data received: $data');

      // Extract type and referenceId with multiple fallback options
      final type = (data['type'] ?? data['data'] ?? '').toString().toLowerCase();
      final referenceId = data['referenceId'] ??
          data['reference_id'] ??
          data['id'] ??
          data['blogId'] ??
          data['newsId'] ??
          data['eventId'] ??
          data['trainingId'];

      debugPrint('Notification Type: $type');
      debugPrint('Reference ID: $referenceId');

      // Handle BLOG notifications
      if (type.contains('blog') && referenceId != null) {
        debugPrint('Opening blog notification...');
        final blogController = Get.put(FetchBlogByIdController());
        await blogController.fetchBlog(referenceId.toString());
        if (blogController.blog.value != null) {
          final blog = blogController.blog.value!;
          Get.to(
            () => SelectedBlogScreen(
              blogId: blog.id,
              title: blog.title,
              description: blog.description,
              imageUrl: blog.imageUrl,
              author:
                  '${blog.author?.firstName ?? ''} ${blog.author?.lastName ?? ''}'
                      .trim(),
              authorId: blog.author?.id ?? '',
              createdAt: blog.createdAt,
              comments: blog.comments,
              roles: blog.author?.roles ?? [],
            ),
          );
          debugPrint('Blog screen opened successfully');
        }
        return;
      }

      // Handle NEWS notifications
      if (type.contains('news') && referenceId != null) {
        debugPrint('Opening news notification...');
        final newsController = Get.put(FetchNewsByIdController());
        await newsController.fetchNews(referenceId.toString());
        if (newsController.news.value != null) {
          final news = newsController.news.value!;
          Get.to(
            () => SelectedNewsScreen(
              newsId: news.id,
              title: news.title,
              description: news.description,
              imageUrl: news.imageUrl,
              author:
                  '${news.author.firstName} ${news.author.lastName}'.trim(),
              authorID: news.author.id,
              profileImageUrl: news.author.profilePicture,
              createdAt: news.createdAt.toIso8601String(),
              comments: news.comments,
              roles: news.author.roles,
            ),
          );
          debugPrint('News screen opened successfully');
        }
        return;
      }

      // Handle EVENT notifications
      if (type.contains('event') && referenceId != null) {
        debugPrint('Opening event notification...');
        final eventController = Get.put(FetchEventByIdController());
        await eventController.fetchEvent(referenceId.toString());
        if (eventController.event.value != null) {
          final event = eventController.event.value!;
          Get.to(
            () => SelectedEventScreen(
              eventID: event.id,
              title: event.eventTitle,
              description: event.description,
              imageUrl: event.eventImageUrl,
              date: event.eventDate,
              location: event.location,
              price: event.price,
              speakers: event.speakers,
              isPaid: event.price > 0,
            ),
          );
          debugPrint('Event screen opened successfully');
        }
        return;
      }

      // Handle TRAINING notifications (training_completed, virtual, etc.)
      if ((type.contains('training') || type.contains('virtual')) &&
          referenceId != null) {
        debugPrint('Opening training notification...');
        try {
          // Try to get existing TrainingController
          late final TrainingController trainingController;
          try {
            trainingController = Get.find<TrainingController>();
          } catch (e) {
            trainingController = Get.put(TrainingController());
          }

          // Try to find training in already-loaded list
          var training = trainingController.trainings.firstWhereOrNull(
            (t) => t.id == referenceId.toString(),
          );

          if (training != null) {
            debugPrint('Training found in cache');
            Get.to(() => TrainingDetailScreen(training: training!));
            return;
          }

          // If not found, fetch all trainings
          debugPrint('Training not in cache, fetching all...');
          await trainingController.fetchTrainings();

          // Try again after fetch
          training = trainingController.trainings.firstWhereOrNull(
            (t) => t.id == referenceId.toString(),
          );

          if (training != null) {
            debugPrint('Training found after fetch');
            Get.to(() => TrainingDetailScreen(training: training!));
          } else {
            debugPrint('Training not found - showing my trainings');
            // Navigate to trainings list as fallback
            Get.toNamed('/my-trainings');
          }
        } catch (e) {
          debugPrint('Error handling training notification: $e');
          // Fallback to trainings
          Get.toNamed('/my-trainings');
        }
        return;
      }

      // Fallback: If we reach here, type is not supported, but don't crash
      debugPrint('Unhandled notification type: $type');
      debugPrint('Ignoring notification gracefully instead of showing error');
    } catch (e, stackTrace) {
      debugPrint('ERROR in notification tap handler: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't show error to user, just log it
    }
  }

  Future<void> _showNotification(
    String? title,
    String? body,
    Map<String, dynamic> data,
  ) async {
    // Android-specific notification details
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'com.transfa.notifications',
          'notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
        );

    // iOS/macOS-specific notification details (Darwin platform)
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    // Combine Android and iOS/macOS notification details
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await _localNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(data),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
}
