import 'package:dama/controller/get_blog_by_id.dart';
import 'package:dama/controller/get_event_by_id.dart';
import 'package:dama/controller/get_news_by_id.dart';
import 'package:dama/controller/notification_controller.dart';
import 'package:dama/controller/training_controller.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/dashboard.dart';
import 'package:dama/views/my_trainings_screen.dart';
import 'package:dama/views/selected_screens/selected_blog_screen.dart';
import 'package:dama/views/selected_screens/selected_event_screen.dart';
import 'package:dama/views/selected_screens/selected_news_screen.dart';
import 'package:dama/views/training_detail_screen.dart';
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

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  final NotificationController _notificationController =
      Get.find<NotificationController>();
  late final FetchBlogByIdController _blogController;
  late final FetchNewsByIdController _newsController;
  late final FetchEventByIdController _eventController;
  final TrainingController _trainingController = Get.find<TrainingController>();
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    // Initialize controllers safely with Get.find() or create if missing
    try {
      _blogController = Get.find<FetchBlogByIdController>();
    } catch (e) {
      _blogController = Get.put(FetchBlogByIdController());
    }
    try {
      _newsController = Get.find<FetchNewsByIdController>();
    } catch (e) {
      _newsController = Get.put(FetchNewsByIdController());
    }
    try {
      _eventController = Get.find<FetchEventByIdController>();
    } catch (e) {
      _eventController = Get.put(FetchEventByIdController());
    }
    _fetchData();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

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
    debugPrint('=== NOTIFICATION TAP HANDLER STARTED ===');

    final type = notification.notificationType;
    // Use refId getter instead of referenceId property for better ID extraction
    final referenceId = notification.refId;

    debugPrint('Notification Details:');
    debugPrint('  - ID: ${notification.id}');
    debugPrint('  - Title: ${notification.title}');
    debugPrint('  - Detected Type: $type');
    debugPrint('  - Reference ID (refId): $referenceId');
    debugPrint('  - Raw referenceId property: ${notification.referenceId}');
    debugPrint('  - Data map: ${notification.data}');

    // Mark as read and wait for it to complete
    if (!notification.read && notification.id.isNotEmpty) {
      debugPrint('Marking notification ${notification.id} as read...');
      final success = await _notificationController.markAsRead(notification.id);
      debugPrint('Mark as read result: $success');
    }

    // Only show loading dialog for types that need an API call
    // Use contains() to match variations like 'new_blog', 'event_registration', etc.
    final needsApiCall =
        type != null &&
        (type.contains('blog') ||
            type.contains('news') ||
            type.contains('event')) &&
        referenceId != null &&
        referenceId.isNotEmpty;

    debugPrint('  - Needs API call: $needsApiCall');

    if (needsApiCall) {
      debugPrint('  - Showing loading dialog...');
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
    }

    try {
      // Use contains() to match variations like 'new_blog', 'blog_comment', etc.
      if (type != null &&
          type.contains('blog') &&
          referenceId != null &&
          referenceId.isNotEmpty) {
        debugPrint('  - Branch: Blog notification (type: $type)');
        debugPrint('  - Fetching blog with ID: $referenceId');

        await _blogController.fetchBlog(referenceId);

        debugPrint('  - Blog fetch completed');
        debugPrint('  - Blog value: ${_blogController.blog.value}');

        if (_blogController.blog.value != null) {
          final blog = _blogController.blog.value!;
          debugPrint('  - Blog object details:');
          debugPrint('    - id: "${blog.id}" (length: ${blog.id.length})');
          debugPrint('    - title: "${blog.title}"');
          debugPrint(
            '    - author: "${blog.author?.firstName ?? ''} ${blog.author?.lastName ?? ''}"',
          );
          debugPrint(
            '  - Navigating to SelectedBlogScreen with blog ID: ${blog.id}',
          );
          Get.back(); // Dismiss loading dialog if visible

          Get.off(
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
          debugPrint('  - Navigation complete');
        } else {
          Get.back(); // Dismiss loading dialog
          debugPrint('  - ERROR: Blog value is null after fetch');
          _showBlogNotFoundDialog();
        }
      } else if (type != null &&
          type.contains('news') &&
          referenceId != null &&
          referenceId.isNotEmpty) {
        debugPrint('  - Branch: News notification (type: $type)');
        debugPrint('  - Fetching news with ID: $referenceId');

        await _newsController.fetchNews(referenceId);

        debugPrint('  - News fetch completed');
        debugPrint('  - News value: ${_newsController.news.value}');

        if (_newsController.news.value != null) {
          final news = _newsController.news.value!;
          debugPrint('  - News object details:');
          debugPrint('    - id: "${news.id}" (length: ${news.id.length})');
          debugPrint('    - title: "${news.title}"');
          debugPrint(
            '    - author: "${news.author?.firstName ?? 'Unknown'} ${news.author?.lastName ?? ''}".trim()',
          );
          debugPrint(
            '  - Navigating to SelectedNewsScreen with news ID: ${news.id}',
          );
          Get.back(); // Dismiss loading dialog if visible

          Get.off(
            () => SelectedNewsScreen(
              newsId: news.id,
              title: news.title,
              description: news.description,
              imageUrl: news.imageUrl,
              author:
                  news.author != null
                      ? '${news.author!.firstName} ${news.author!.lastName}'
                          .trim()
                      : 'DAMA KENYA',
              authorID: news.author?.id ?? '',
              profileImageUrl: news.author?.profilePicture ?? '',
              createdAt: news.createdAt.toIso8601String(),
              comments: news.comments,
              roles: news.author?.roles ?? [],
            ),
          );
          debugPrint('  - Navigation complete');
        } else {
          Get.back(); // Dismiss loading dialog
          debugPrint('  - ERROR: News value is null after fetch');
          _showNewsNotFoundDialog();
        }
      } else if (type != null &&
          type.contains('event') &&
          referenceId != null &&
          referenceId.isNotEmpty) {
        debugPrint('  - Branch: Event notification (type: $type)');
        debugPrint('  - Fetching event with ID: $referenceId');

        await _eventController.fetchEvent(referenceId);

        debugPrint('  - Event fetch completed');
        debugPrint('  - Event value: ${_eventController.event.value}');

        if (_eventController.event.value != null) {
          final event = _eventController.event.value!;
          debugPrint('  - Event object details:');
          debugPrint('    - id: "${event.id}" (length: ${event.id.length})');
          debugPrint('    - title: "${event.eventTitle}"');
          debugPrint('    - creator: "${event.eventCreator}"');
          debugPrint(
            '  - Navigating to SelectedEventScreen with event ID: ${event.id}',
          );
          Get.back(); // Dismiss loading dialog if visible

          Get.off(
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
          debugPrint('  - Navigation complete');
        } else {
          Get.back(); // Dismiss loading dialog
          debugPrint('  - ERROR: Event value is null after fetch');
          _showEventNotFoundDialog();
        }
      } else if (type != null &&
          type.contains('training') &&
          referenceId != null &&
          referenceId.isNotEmpty) {
        debugPrint('  - Branch: Training notification (type: $type)');
        debugPrint('  - Looking for training with ID: $referenceId');

        // Try to find training in already-loaded list
        var training = _trainingController.trainings.firstWhereOrNull(
          (t) => t.id == referenceId,
        );

        if (training != null) {
          debugPrint('  - Training found in cache');
          debugPrint(
            '  - Navigating to TrainingDetailScreen with training ID: ${training.id}',
          );
          Get.off(() => TrainingDetailScreen(training: training!));
          debugPrint('  - Navigation complete');
        } else {
          // Training not in cache - fetch all trainings
          debugPrint(
            '  - Training not found in cache, fetching all trainings...',
          );

          Get.dialog(
            const Center(child: CircularProgressIndicator()),
            barrierDismissible: false,
          );

          try {
            await _trainingController.fetchTrainings();

            // Try again after fetch
            training = _trainingController.trainings.firstWhereOrNull(
              (t) => t.id == referenceId,
            );

            Get.back(); // Dismiss loading dialog

            if (training != null) {
              debugPrint('  - Training found after fetch');
              debugPrint(
                '  - Navigating to TrainingDetailScreen with training ID: ${training.id}',
              );
              Get.off(() => TrainingDetailScreen(training: training!));
              debugPrint('  - Navigation complete');
            } else {
              debugPrint('  - Training still not found after fetch');
              // Navigate to TrainingDetailScreen with empty training (shows error state)
              Get.off(
                () => TrainingDetailScreen(
                  training: TrainingModel(
                    id: '',
                    title: '',
                    description: '',
                    learningTracks: [],
                    targetAudience: [],
                    learningOutcomes: [],
                    courseOutline: [],
                    sessions: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    category: '',
                    status: '',
                    trainer: null,
                  ),
                ),
              );
            }
          } catch (e) {
            Get.back(); // Dismiss loading dialog
            debugPrint('  - Error fetching trainings: $e');
            // Navigate to TrainingDetailScreen with empty training (shows error state)
            Get.off(
              () => TrainingDetailScreen(
                training: TrainingModel(
                  id: '',
                  title: '',
                  description: '',
                  learningTracks: [],
                  targetAudience: [],
                  learningOutcomes: [],
                  courseOutline: [],
                  sessions: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  category: '',
                  status: '',
                  trainer: null,
                ),
              ),
            );
          }
        }
      } else if (type != null &&
          type.contains('virtual') &&
          referenceId != null &&
          referenceId.isNotEmpty) {
        debugPrint('  - Branch: Virtual session notification (type: $type)');
        debugPrint('  - Training/Session ID: $referenceId');

        // Try to find training in already-loaded list
        var training = _trainingController.trainings.firstWhereOrNull(
          (t) => t.id == referenceId,
        );

        if (training != null) {
          debugPrint('  - Training found in cache');
          debugPrint(
            '  - Navigating to TrainingDetailScreen with training ID: ${training.id}',
          );
          Get.off(() => TrainingDetailScreen(training: training!));
          debugPrint('  - Navigation complete');
        } else {
          // Training not in cache - fetch all trainings
          debugPrint(
            '  - Training not found in cache, fetching all trainings...',
          );

          Get.dialog(
            const Center(child: CircularProgressIndicator()),
            barrierDismissible: false,
          );

          try {
            await _trainingController.fetchTrainings();

            // Try again after fetch
            training = _trainingController.trainings.firstWhereOrNull(
              (t) => t.id == referenceId,
            );

            Get.back(); // Dismiss loading dialog

            if (training != null) {
              debugPrint('  - Training found after fetch');
              debugPrint(
                '  - Navigating to TrainingDetailScreen with training ID: ${training.id}',
              );
              Get.off(() => TrainingDetailScreen(training: training!));
              debugPrint('  - Navigation complete');
            } else {
              debugPrint('  - Training still not found after fetch');
              // Navigate to TrainingDetailScreen with empty training (shows error state)
              Get.off(
                () => TrainingDetailScreen(
                  training: TrainingModel(
                    id: '',
                    title: '',
                    description: '',
                    learningTracks: [],
                    targetAudience: [],
                    learningOutcomes: [],
                    courseOutline: [],
                    sessions: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    category: '',
                    status: '',
                    trainer: null,
                  ),
                ),
              );
            }
          } catch (e) {
            Get.back(); // Dismiss loading dialog
            debugPrint('  - Error fetching trainings: $e');
            // Navigate to TrainingDetailScreen with empty training (shows error state)
            Get.off(
              () => TrainingDetailScreen(
                training: TrainingModel(
                  id: '',
                  title: '',
                  description: '',
                  learningTracks: [],
                  targetAudience: [],
                  learningOutcomes: [],
                  courseOutline: [],
                  sessions: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  category: '',
                  status: '',
                  trainer: null,
                ),
              ),
            );
          }
        }
      } else {
        // Truly generic notifications - handle gracefully without error
        debugPrint(
          '  - Branch: ${type ?? 'unknown'} notification (unhandled gracefully)',
        );
        // Instead of showing error, just dismiss and log
        if (needsApiCall) {
          try {
            Get.back(); // Dismiss loading dialog
          } catch (e) {
            debugPrint('  - Could not dismiss dialog: $e');
          }
        }
        debugPrint(
          '  - Notification type not specifically handled, ignoring gracefully',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('  - EXCEPTION: $e');
      debugPrint('  - Stack trace: $stackTrace');

      if (needsApiCall) {
        try {
          Get.back();
        } catch (e) {
          debugPrint('  - Could not dismiss dialog: $e');
        }
      }
      _showErrorSnackbar('Error: ${e.toString()}');
    }

    debugPrint('=== NOTIFICATION TAP HANDLER COMPLETED ===');
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

  void _showEventNotFoundDialog() {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDark;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDarkMode ? kDarkCard : kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: kGrey),
            const SizedBox(height: 16),
            Text(
              'Event Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This event may have been removed or is no longer available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: kNormalTextSize, color: kGrey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  debugPrint('🎯 Browse Events button pressed');
                  // Close all dialogs first
                  while (Get.isDialogOpen ?? false) {
                    Get.back();
                  }
                  // Small delay to ensure dialog is fully dismissed
                  await Future.delayed(const Duration(milliseconds: 100));
                  // Navigate to Events tab (index 4)
                  debugPrint('🎯 Navigating to Dashboard with initialTab: 4');
                  Get.offAll(() => Dashboard(initialTab: 4, initialSubTab: 0));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Browse Events',
                  style: TextStyle(color: kWhite, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showBlogNotFoundDialog() {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDark;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDarkMode ? kDarkCard : kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 64, color: kGrey),
            const SizedBox(height: 16),
            Text(
              'Blog Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This blog post may have been removed or is no longer available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kGrey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.offAll(
                    () => const Dashboard(initialTab: 1, initialSubTab: 0),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Browse Blogs',
                  style: TextStyle(color: kWhite, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showNewsNotFoundDialog() {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDark;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDarkMode ? kDarkCard : kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.newspaper_outlined, size: 64, color: kGrey),
            const SizedBox(height: 16),
            Text(
              'News Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This news article may have been removed or is no longer available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kGrey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.offAll(
                    () => const Dashboard(initialTab: 2, initialSubTab: 0),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Browse News',
                  style: TextStyle(color: kWhite, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _navigateToTrainingsWithError(String message) {
    Get.off(() => MyTrainingsScreen());
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.dialog(
        AlertDialog(
          title: const Text('Training Not Found'),
          content: const Text(
            'The training you\'re looking for doesn\'t exist.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
              },
              child: const Text('Back to Trainings'),
            ),
          ],
        ),
      );
    });
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
            // ✅ Tabs for All and Unread
            Container(
              color: isDarkMode ? kDarkCard : kWhite,
              child: TabBar(
                controller: _tabController,
                labelColor: kBlue,
                unselectedLabelColor: isDarkMode ? kGrey : Colors.grey[600],
                indicatorColor: kBlue,
                indicatorWeight: 3,
                tabs: const [Tab(text: 'All'), Tab(text: 'Unread')],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1250),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
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
                        if (kIsWeb) const SizedBox(width: 10),
                        Expanded(
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 900),
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

                                  // ✅ Filter notifications based on selected tab
                                  final filteredNotifications =
                                      _selectedTabIndex == 0
                                          ? _notificationController
                                              .notificationList
                                          : _notificationController
                                              .notificationList
                                              .where((n) => !n.read)
                                              .toList();

                                  if (filteredNotifications.isEmpty) {
                                    return ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        SizedBox(
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.3,
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.notifications_none,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _selectedTabIndex == 0
                                                  ? "No notifications available"
                                                  : "No unread notifications",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: filteredNotifications.length,
                                    itemBuilder: (context, index) {
                                      final notification =
                                          filteredNotifications[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Obx(() {
                                          final updatedNotification =
                                              _notificationController
                                                  .notificationList
                                                  .firstWhere(
                                                    (n) =>
                                                        n.id == notification.id,
                                                    orElse: () => notification,
                                                  );
                                          return NotificationCard(
                                            title: updatedNotification.title,
                                            body: updatedNotification.body,
                                            date:
                                                '${updatedNotification.createdAt}',
                                            isRead: updatedNotification.read,
                                            onTap:
                                                () => _handleNotificationTap(
                                                  updatedNotification,
                                                ),
                                          );
                                        }),
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
