import 'package:dama/controller/get_blog_by_id.dart';
import 'package:dama/controller/get_event_by_id.dart';
import 'package:dama/controller/get_news_by_id.dart';
import 'package:dama/controller/notification_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/selected_screens/selected_blog_screen.dart';
import 'package:dama/views/selected_screens/selected_event_screen.dart';
import 'package:dama/views/selected_screens/selected_news_screen.dart';
import 'package:dama/widgets/cards/notification_card.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/shimmer/transaction_shimmer.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController _notificationController = Get.put(
    NotificationController(),
  );
  final FetchBlogByIdController _blogController = Get.put(
    FetchBlogByIdController(),
  );
  final FetchNewsByIdController _newsController = Get.put(
    FetchNewsByIdController(),
  );
  final FetchEventByIdController _eventController = Get.put(
    FetchEventByIdController(),
  );

  bool _isLoading = false;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadData();
    _showSwipeHint();
  }

  Future<void> _showSwipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenHint = prefs.getBool('notification_swipe_hint_shown') ?? false;

    if (!hasSeenHint && mounted) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Get.snackbar(
          '💡 Tip',
          'Swipe right on a notification to delete it',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: kBlue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(10),
        );
        await prefs.setBool('notification_swipe_hint_shown', true);
      }
    }
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    final fetchedFirstName = await StorageService.getData('firstName');
    final fetchedLastName = await StorageService.getData('lastName');
    final fetchedTitle = await StorageService.getData('title');
    final fetchedMemberId = await StorageService.getData('memberId');
    String? fetchedBio = await StorageService.getData('brief');

    setState(() {
      imageUrl = url;
      firstName = fetchedFirstName;
      memberId = fetchedMemberId;
      lastName = fetchedLastName;
      title = fetchedTitle;
      bio = fetchedBio ?? '';
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await _notificationController.fetchnotifications();
    setState(() => _isLoading = false);
  }

  void _handleNotificationTap(notification) async {
    final type = notification.type;
    final referenceId = notification.referenceId;

    try {
      if (type == 'blog' && referenceId != null) {
        // Fetch blog and navigate
        await _blogController.fetchBlog(referenceId);
        if (_blogController.blog.value != null) {
          final blog = _blogController.blog.value!;
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
        } else {
          _showErrorSnackbar('Could not load blog');
        }
      } else if (type == 'news' && referenceId != null) {
        // Fetch news and navigate
        await _newsController.fetchNews(referenceId);
        if (_newsController.news.value != null) {
          final news = _newsController.news.value!;
          Get.to(
            () => SelectedNewsScreen(
              newsId: news.id,
              title: news.title,
              description: news.description,
              imageUrl: news.imageUrl,
              author: '${news.author.firstName} ${news.author.lastName}'.trim(),
              authorID: news.author.id,
              profileImageUrl: news.author.profilePicture,
              createdAt: news.createdAt.toIso8601String(),
              comments: news.comments,
              roles: news.author.roles,
            ),
          );
        } else {
          _showErrorSnackbar('Could not load news');
        }
      } else if (type == 'event' && referenceId != null) {
        // Fetch event and navigate
        await _eventController.fetchEvent(referenceId);
        if (_eventController.event.value != null) {
          final event = _eventController.event.value!;
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
        } else {
          _showErrorSnackbar('Could not load event');
        }
      } else {
        // Fallback: show dialog for notifications without type/referenceId
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return NotificationDetailModal(
              title: notification.title,
              body: notification.body,
              date: '${notification.createdAt}',
            );
          },
        );
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationController.markAllAsRead();
    if (success) {
      Get.snackbar(
        'Success',
        'All notifications marked as read',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
    } else {
      _showErrorSnackbar('Failed to mark notifications as read');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final success = await _notificationController.deleteNotification(
      notificationId,
    );
    if (success) {
      Get.snackbar(
        'Deleted',
        'Notification removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      _showErrorSnackbar('Failed to delete notification');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkCard : kBGColor,
      body: SafeArea(
        child: Column(
          children: [
            TopNavigationbar(
              title: "Notifications",
              actions: [
                Obx(() {
                  if (_notificationController.notificationList.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: Icon(Icons.done_all, color: kBlue, size: 20),
                    label: Text(
                      'Mark all read',
                      style: TextStyle(color: kBlue, fontSize: 12),
                    ),
                  );
                }),
              ],
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1250),
                  child: Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (kIsWeb)
                          ProfileCard(
                            isDarkMode: isDarkMode,
                            imageUrl: imageUrl,
                            firstName: firstName,
                            lastName: lastName,
                            title: title,
                            bio: bio,
                          ),
                        if (kIsWeb) SizedBox(width: 10),
                        Expanded(
                          child: Center(
                            child: Container(
                              constraints: BoxConstraints(maxWidth: 900),
                              child: RefreshIndicator(
                                color: kWhite,
                                backgroundColor: kBlue,
                                displacement: 40,
                                onRefresh: _fetchData,
                                child: Obx(() {
                                  if (_notificationController.isLoading.value ||
                                      _isLoading) {
                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: 10,
                                      itemBuilder:
                                          (context, index) =>
                                              TransactionSkeleton(),
                                    );
                                  }

                                  if (_notificationController
                                      .notificationList
                                      .isEmpty) {
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.notifications_none,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "No notifications available",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  final reversedList =
                                      _notificationController
                                          .notificationList
                                          .reversed
                                          .toList();

                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: reversedList.length,
                                    itemBuilder: (context, index) {
                                      final notification = reversedList[index];
                                      return Dismissible(
                                        key: Key(notification.id),
                                        direction: DismissDirection.startToEnd,
                                        background: Container(
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.only(
                                            left: 20,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                        ),
                                        confirmDismiss: (direction) async {
                                          return await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Delete Notification',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to delete this notification?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.of(
                                                          context,
                                                        ).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.of(
                                                          context,
                                                        ).pop(true),
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        onDismissed: (direction) {
                                          _deleteNotification(notification.id);
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: NotoficationCard(
                                            title: notification.title,
                                            body: notification.body,
                                            date: '${notification.createdAt}',
                                            isRead: notification.read,
                                            onTap:
                                                () => _handleNotificationTap(
                                                  notification,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
