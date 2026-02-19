import 'package:dama/controller/auth_controller.dart';
import 'package:dama/controller/blog_controller.dart';
import 'package:dama/controller/events_controller.dart';
import 'package:dama/controller/news_controller.dart';
import 'package:dama/controller/notification_controller.dart';
import 'package:dama/controller/plans_controller.dart';
import 'package:dama/controller/resource_controller.dart';
import 'package:dama/controller/update_user_profile_controller.dart';
import 'package:dama/controller/user_event_controller.dart';
import 'package:dama/controller/linkedin_controller.dart';
import 'package:dama/models/blogs_model.dart';
import 'package:dama/models/event_model.dart';
import 'package:dama/models/news_model.dart';
import 'package:dama/models/resources_model.dart';
import 'package:dama/routes/routes.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/views/dashboard/blogs.dart';
import 'package:dama/views/dashboard/events.dart';
import 'package:dama/views/dashboard/resources.dart';
import 'package:dama/views/dashboard/search_result.dart';
import 'package:dama/views/drawer_screen/QRscanner.dart';
import 'package:dama/views/home_screen.dart';
import 'package:dama/views/selected_screens/selected_blog_screen.dart';
import 'package:dama/views/selected_screens/selected_event_screen.dart';
import 'package:dama/views/selected_screens/selected_news_screen.dart';
import 'package:dama/views/selected_screens/selected_resource_screen.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/custom_appbar.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:dama/widgets/modals/alert_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motion_tab_bar_v2/motion-tab-bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/alert_controller.dart';
import '../utils/theme_provider.dart' show ThemeProvider;
import '../widgets/theme_aware_logo.dart';
import 'dashboard/news.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, this.initialTab = 0, this.initialSubTab = 0});

  final int initialTab;
  final int initialSubTab;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late int _selectedIndex;
  final AuthController _authController = Get.find<AuthController>();
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TextEditingController _searchController;

  final BlogController _blogController = Get.put(BlogController());
  final NewsController _newsController = Get.put(NewsController());
  final ResourceController _resourceController = Get.put(ResourceController());
  final EventsController _eventsController = Get.put(EventsController());
  final NotificationController _notificationController = Get.put(
    NotificationController(),
  );

  final UserEventsController _userEventsController = Get.put(
    UserEventsController(),
  );

  final UpdateUserProfileController _updateUserProfileController = Get.put(
    UpdateUserProfileController(),
  );

  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';
  bool hasMembership = false;
  String membershipExiryDate = '';
  final PlansController _plansController = Get.put(PlansController());
  String membershipName = 'No Active Membership';
  String membershipId = '';
  List<String> userRoles = [];

  bool _isProfileDropdownOpen = false;
  bool _hasShownOfflineNotification = false;

  List<Widget> _screens = [];

  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _pageController = PageController(initialPage: _selectedIndex);
    _searchController = TextEditingController();

    // Listen to profile picture changes
    _updateUserProfileController.profilePicture.listen((newPicture) {
      if (mounted) {
        setState(() {
          imageUrl = newPicture;
        });
      }
    });

    // Check if user is logged in after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });

    _screens = [
      HomeScreen(onMenuTap: () => _toggleDrawer()),
      Blogs(onMenuTap: () => _toggleDrawer()),
      News(onMenuTap: () => _toggleDrawer()),
      Resources(onMenuTap: () => _toggleDrawer()),
      Events(onMenuTap: () => _toggleDrawer(), initialTab: widget.initialSubTab),
    ];
  }

  Future<void> _loadData() async {
    final url = await StorageService.getData('profile_picture');
    final fetchedFirstName = await StorageService.getData('firstName');
    final fetchedLastName = await StorageService.getData('lastName');
    final fetchedTitle = await StorageService.getData('title');
    final fetchedMemberId = await StorageService.getData('memberId');
    final membershipStatus = await StorageService.getData('hasMembership');
    final membershipExpiry = await StorageService.getData('membershipExp');
    final fetchedMembershipId = await StorageService.getData('membershipId');
    String? fetchedBio = await StorageService.getData('brief');
    final roles = await StorageService.getUserRoles();

    // Ensure plans are loaded before getting membership name
    if (_plansController.plansList.isEmpty) {
      await _plansController.fetchPlans();
    }

    if (mounted) {
      setState(() {
        imageUrl = url ?? '';
        firstName = fetchedFirstName ?? '';
        memberId = fetchedMemberId ?? '';
        lastName = fetchedLastName ?? '';
        title = fetchedTitle ?? '';
        hasMembership = membershipStatus ?? false;
        membershipExiryDate = membershipExpiry ?? '';
        membershipId = fetchedMembershipId ?? '';
        bio = fetchedBio ?? '';
        userRoles = roles;
        membershipName = _plansController.getMembershipName();
      });
    }

    // Get membership status from plans controller (async, non-blocking)
    _getMembershipStatus();

    // Check for role approval and redirect to admin panel
    _checkRoleApproval();
  }

  String formatMemberId(String memberId) {
    if (memberId.isEmpty) return '';

    return memberId
        .replaceAll('-', '')
        .replaceAllMapped(
          RegExp(r'^D0*(\d+)$'),
          (match) => 'D${match.group(1)}',
        );
  }

  String formatMembershipExpiry(String isoDate) {
    try {
      DateTime dateTime = DateTime.parse(isoDate);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return "Invalid date";
    }
  }

  Future<void> _getMembershipName() async {
    try {
      await _plansController.fetchPlans();
      if (membershipId.isNotEmpty) {
        final plan = _plansController.plansList.firstWhereOrNull(
          (plan) => plan.id == membershipId,
        );
        if (plan != null) {
          setState(() {
            membershipName = '${plan.membership} Membership';
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _getMembershipStatus() async {
    try {
      // First try to load from local storage (offline mode)
      final storedHasMembership = await StorageService.getData('hasMembership');
      final storedMembershipId = await StorageService.getData('membershipId');
      final storedMembershipExp = await StorageService.getData('membershipExp');

      bool hasStoredMembership = false;
      if (storedHasMembership == true || storedHasMembership == 'true') {
        // Check if membership is not expired
        if (storedMembershipExp != null) {
          try {
            final expiryDate = DateTime.parse(storedMembershipExp);
            if (expiryDate.isAfter(DateTime.now())) {
              hasStoredMembership = true;
            }
          } catch (e) {
            print('Error parsing stored membership expiry: $e');
          }
        }
      }

      // If we have valid stored membership, use it
      if (hasStoredMembership && storedMembershipId != null) {
        setState(() {
          hasMembership = true;
          membershipId = storedMembershipId;
          membershipName = _plansController.getMembershipName();
        });
        print('[Dashboard] Using stored membership data (offline mode)');
        // Show offline mode notification (only once per session)
        if (!_hasShownOfflineNotification) {
          _hasShownOfflineNotification = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Offline mode - using cached data'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          });
        }
        return;
      }

      // Try to get fresh data from server
      // Ensure plans are loaded first
      if (_plansController.plansList.isEmpty) {
        await _plansController.fetchPlans();
      }

      // Get current plan from plans controller
      final currentPlan = await _plansController.getCurrentUserPlan();
      final hasActivePlan = _plansController.hasActivePlan.value;
      final membershipIdFromController =
          _plansController.currentMembershipId.value;

      print(
        '[Dashboard] Membership status - Plan: $currentPlan, Active: $hasActivePlan, ID: $membershipIdFromController',
      );

      setState(() {
        hasMembership = hasActivePlan;
        membershipName =
            hasActivePlan
                ? _plansController.getMembershipName()
                : 'No Active Membership';
        membershipId = membershipIdFromController;
      });

      // If no active membership in storage but plans controller shows active, update storage
      if (!hasMembership && hasActivePlan) {
        await StorageService.storeData({
          'hasMembership': true,
          'membershipId': membershipIdFromController,
        });
        setState(() {
          hasMembership = true;
        });
      }
    } catch (e) {
      print('Error getting membership status: $e');
      // On error, try to use stored data as fallback
      try {
        final storedHasMembership = await StorageService.getData(
          'hasMembership',
        );
        final storedMembershipId = await StorageService.getData('membershipId');

        if (storedHasMembership == true || storedHasMembership == 'true') {
          setState(() {
            hasMembership = true;
            membershipId = storedMembershipId ?? '';
            membershipName = 'Professional Membership'; // Default fallback
          });
          print('[Dashboard] Using stored membership as fallback after error');
          // Show offline mode notification (only once per session)
          if (!_hasShownOfflineNotification) {
            _hasShownOfflineNotification = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Offline mode - using cached membership data',
                    ),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            });
          }
        } else {
          // Fallback to default professional membership
          setState(() {
            hasMembership = true;
            membershipName = 'Professional Membership';
          });
          print(
            '[Dashboard] Using default professional membership as final fallback',
          );
          // Show offline mode notification (only once per session)
          if (!_hasShownOfflineNotification) {
            _hasShownOfflineNotification = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Offline mode - using default membership'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            });
          }
        }
      } catch (fallbackError) {
        // Last resort fallback
        setState(() {
          hasMembership = true;
          membershipName = 'Professional Membership';
        });
        print('Using default professional membership as last resort');
      }
    }
  }

  Future<void> _checkRoleApproval() async {
    try {
      final hasBeenRedirected = await StorageService.getData(
        'hasBeenRedirectedToAdmin',
      );
      if ((userRoles.contains('news_editor') ||
              userRoles.contains('blogger')) &&
          hasBeenRedirected != 'true') {
        // Delay the dialog to avoid blocking UI initialization
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Get.dialog(
              AlertDialog(
                title: Text('Role Approved'),
                content: Text(
                  'Congratulations! You have been approved as ${userRoles.contains('news_editor') ? 'News Editor' : 'Blogger'}. You will now be redirected to the admin panel.',
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Get.back();
                      await StorageService.storeData({
                        'hasBeenRedirectedToAdmin': 'true',
                      });
                      launchUrl(
                        Uri.parse('https://admin.damakenya.org'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error checking role approval: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    final token = await StorageService.getData('access_token');
    print('Token in storage: $token');
    if (token == null || token.isEmpty) {
      // No token, redirect to login
      Get.offAllNamed(AppRoutes.login);
    } else {
      // User is logged in, load data (non-blocking)
      _loadData();
      Get.put(AlertController());
      _blogController.pagingController.addListener(() {
        if (mounted) setState(() {});
      });
      _blogController.fetchBlogs();
      _fetchAllData();
      _notificationController.fetchnotifications();
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _checkAndShowAlerts();
        }
      });
    }
  }

  Future<void> _checkAndShowAlerts() async {
    if (!mounted) return;

    final AlertController alertController = Get.find<AlertController>();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Fetch alerts from backend
    await alertController.fetchAlerts();

    if (!mounted) return;

    // Get active alerts
    final activeAlerts =
        alertController.alerts.where((alert) => alert.isActive()).toList();

    if (activeAlerts.isEmpty) return;

    // Show alerts one by one
    for (var alert in activeAlerts) {
      if (!mounted) break;

      final shouldShow = await alertController.shouldShowAlert(alert.id);

      if (shouldShow && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => AlertDialogWidget(
                alert: alert,
                isDarkMode: themeProvider.isDark,
                onClose: () {
                  if (mounted) {
                    Navigator.of(context).pop();
                    alertController.markAlertAsShown(alert.id);
                  }
                },
              ),
        );

        // Mark as shown after dialog closes
        await alertController.markAlertAsShown(alert.id);

        // Optional: delay before showing next alert
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
  }

  Future<void> _fetchAllData() async {
    _blogController.fetchBlogs();
    await _newsController.refreshNews();

    await Future.delayed(Duration(milliseconds: 100));
  }

  void _toggleDrawer() {
    if (_scaffoldKey.currentState != null) {
      if (_scaffoldKey.currentState!.isDrawerOpen) {
        _scaffoldKey.currentState!.openEndDrawer();
      } else {
        _scaffoldKey.currentState!.openDrawer();
      }
    }
  }

  void _onNavItemTap(int index) {
    _pageController.jumpToPage(index);
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    Get.delete<PlansController>();
    super.dispose();
  }

  void _performSearch(String query) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SearchResultsScreen(query: query),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _showEventSelectionForScanner(bool isDarkMode) {
    _userEventsController.fetchUserEvents();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Obx(() {
          if (_userEventsController.isLoading.value) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final events = _userEventsController.eventsList;
          if (events.isEmpty) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No events available',
                  style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                ),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: Icon(Icons.event, color: isDarkMode ? kWhite : kBlack),
                title: Text(
                  event.eventTitle,
                  style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRScannerScreen(eventId: event.id),
                    ),
                  );
                },
              );
            },
          );
        });
      },
    );
  }

  // Web-specific layout
  Widget _buildWebLayout() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
          body: Column(
            children: [
              // Top Navigation Bar
              Container(
                height: 70,
                color: isDarkMode ? kBlack : kWhite,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // If width < 800 → use compact layout (logo + search + menu button)
                    final bool isCompact = constraints.maxWidth < 800;

                    return Row(
                      children: [
                        // Logo Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ThemeAwareLogo(
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),

                        if (!isCompact) SizedBox(width: 20),

                        // Search Bar (flexible)
                        Expanded(
                          flex: isCompact ? 1 : 2,
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              onSubmitted: (query) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => SearchResultsScreen(query: query),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(
                                      milliseconds: 200,
                                    ),
                                  ),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(
                                  color: kGrey,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: kGrey,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor:
                                    isDarkMode
                                        ? kDarkThemeBg
                                        : const Color(0xFFF0F0F0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (!isCompact) ...[
                          SizedBox(width: 20),
                          // Navigation Items (scrollable if overflow)
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildWebNavItem(
                                    'Home',
                                    Icons.home,
                                    0,
                                    isDarkMode,
                                  ),
                                  _buildWebNavItem(
                                    'Blogs',
                                    Icons.library_books,
                                    1,
                                    isDarkMode,
                                  ),
                                  _buildWebNavItem(
                                    'News',
                                    Icons.newspaper,
                                    2,
                                    isDarkMode,
                                  ),
                                  _buildWebNavItem(
                                    'Resources',
                                    Icons.folder_copy,
                                    3,
                                    isDarkMode,
                                  ),
                                  _buildWebNavItem(
                                    'Events',
                                    Icons.calendar_month,
                                    4,
                                    isDarkMode,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        Spacer(),

                        // Profile
                        Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Profile Avatar
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isProfileDropdownOpen =
                                          !_isProfileDropdownOpen;
                                    });
                                  },
                                  child: ProfileAvatar(
                                    radius: 18,
                                    backgroundImage:
                                        imageUrl.isNotEmpty
                                            ? NetworkImage(imageUrl)
                                            : null,
                                    child:
                                        imageUrl.isEmpty
                                            ? Icon(
                                              Icons.person,
                                              size: 20,
                                              color: kWhite,
                                            )
                                            : null,
                                  ),
                                ),

                                // Dropdown
                                if (_isProfileDropdownOpen)
                                  PopupMenuButton<int>(
                                    color: kWhite,
                                    onSelected: (value) {
                                      if (value == 0) {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.profile,
                                        );
                                      } else if (value == 1) {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.transcation,
                                        );
                                      } else if (value == 2) {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.trainings,
                                        );
                                      } else if (value == 3) {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.aboutDama,
                                        );
                                      } else if (value == 4) {
                                        _authController.logout(context);
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          PopupMenuItem(
                                            value: 0,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  color: kGrey,
                                                ),
                                                SizedBox(width: 8),
                                                Text("Profile"),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 1,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.history,
                                                  color: kGrey,
                                                ),
                                                SizedBox(width: 8),
                                                Text("Transaction History"),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 2,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.school,
                                                  color: kGrey,
                                                ),
                                                SizedBox(width: 8),
                                                Text("Training"),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 3,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.history,
                                                  color: kGrey,
                                                ),
                                                SizedBox(width: 8),
                                                Text("About Dama"),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 4,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.logout,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Logout",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                    child: ProfileAvatar(
                                      radius: 18,
                                      backgroundImage:
                                          imageUrl.isNotEmpty
                                              ? NetworkImage(imageUrl)
                                              : null,
                                      child:
                                          imageUrl.isEmpty
                                              ? Icon(
                                                Icons.person,
                                                size: 20,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: 20),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1450),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: ProfileCard(
                          isDarkMode: isDarkMode,
                          imageUrl: imageUrl,
                          firstName: firstName,
                          lastName: lastName,
                          title: title,
                          bio: bio,
                          hasMembership: hasMembership,
                          membershipName: membershipName,
                        ),
                      ),

                      SizedBox(width: 10),

                      // Main Content Area
                      Expanded(
                        child: Container(
                          color: isDarkMode ? kDarkThemeBg : Color(0xFFF5F5F5),
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (index) {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            children: _screens,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),

                      if (MediaQuery.of(context).size.width > 1200) ...[
                        // Right Sidebar
                        _buildRightSidebar(isDarkMode),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                height: 50,
                color: isDarkMode ? kBlack : kWhite,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Copyright 2025    All rights Reserved',
                        style: TextStyle(color: kGrey, fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              // Add privacy policy navigation
                            },
                            child: Text(
                              'Privacy policy',
                              style: TextStyle(color: kGrey, fontSize: 12),
                            ),
                          ),
                          SizedBox(width: 20),
                          TextButton(
                            onPressed: () {
                              // Add terms navigation
                            },
                            child: Text(
                              'Terms & Conditions',
                              style: TextStyle(color: kGrey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebNavItem(
    String title,
    IconData icon,
    int index,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 5, right: 20),
      child: GestureDetector(
        onTap: () => _onNavItemTap(index),
        child: Column(
          children: [
            // SizedBox(height: 2),
            Icon(
              icon,
              color:
                  _selectedIndex == index
                      ? kBlue
                      : (isDarkMode ? kWhite : kGrey),
            ),
            Text(
              title,
              style: TextStyle(
                color:
                    _selectedIndex == index
                        ? kBlue
                        : (isDarkMode ? kWhite : kGrey),
                fontWeight:
                    _selectedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItemsList<T>({
    required List<T> items,
    required bool isDarkMode,
    required String Function(T) titleGetter,
    required String? Function(T) imageGetter,
    required IconData fallbackIcon,
    required Widget Function(T) screenBuilder,
  }) {
    return Column(
      children:
          items.take(6).map((item) {
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            screenBuilder(item),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? kDarkCard : kBGColor,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Image container
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            imageGetter(item) != null &&
                                    imageGetter(item)!.isNotEmpty
                                ? Image.network(
                                  imageGetter(item)!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                                : Center(
                                  child: Icon(
                                    fallbackIcon,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(width: 15),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleGetter(item),
                            style: TextStyle(
                              color: isDarkMode ? kWhite : kBlack,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.more_vert,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildRightSidebar(bool isDarkMode) {
    String title = '';
    Widget content = SizedBox();

    switch (_selectedIndex) {
      case 0:
      case 4:
        title = "Upcoming Events";
        content = _buildSidebarItemsList<EventModel>(
          items: _eventsController.eventsList,
          isDarkMode: isDarkMode,
          titleGetter: (event) => event.eventTitle,
          imageGetter: (event) => event.eventImageUrl,
          fallbackIcon: Icons.image_not_supported,
          screenBuilder: (event) {
            final paidEventIds =
                _userEventsController.eventsList.map((e) => e.id).toSet();
            final isPaid = paidEventIds.contains(event.id);

            return SelectedEventScreen(
              title: event.eventTitle,
              price: event.price,
              date: event.eventDate,
              imageUrl: event.eventImageUrl,
              location: event.location,
              description: event.description,
              speakers: event.speakers,
              isPaid: isPaid,
              eventID: event.id,
            );
          },
        );
        break;

      case 1:
        title = "Popular Blogs";
        content = _buildSidebarItemsList<BlogPostModel>(
          items: _blogController.pagingController.itemList ?? [],
          isDarkMode: isDarkMode,
          titleGetter: (blog) => blog.title,
          imageGetter: (blog) => blog.imageUrl,
          fallbackIcon: Icons.article,
          screenBuilder:
              (blog) => SelectedBlogScreen(
                authorId: blog.author!.id,
                title: blog.title,
                imageUrl: blog.imageUrl,
                createdAt: blog.createdAt,
                description: blog.description,
                blogId: blog.id,
                comments: blog.comments,
                roles: [],
                sources: blog.sources,
              ),
        );
        break;

      case 2:
        title = "Popular News";
        content = _buildSidebarItemsList<NewsModel>(
          items: _newsController.filteredNews,
          isDarkMode: isDarkMode,
          titleGetter: (news) => news.title,
          imageGetter: (news) => news.imageUrl,
          fallbackIcon: Icons.newspaper,
          screenBuilder:
              (news) => SelectedNewsScreen(
                title: news.title,
                imageUrl: news.imageUrl,
                author: news.author.firstName,
                createdAt: "${news.createdAt}",
                description: news.description,
                profileImageUrl: news.author.profilePicture,
                authorID: news.author.id,
                newsId: news.id,
                comments: news.comments,
                roles: [],
                sources: news.sources,
              ),
        );
        break;

      case 3:
        title = "My Resources";
        content = _buildSidebarItemsList<ResourceModel>(
          items: _resourceController.resourceList,
          isDarkMode: isDarkMode,
          titleGetter: (resource) => resource.title,
          imageGetter: (resource) => resource.resourceImageUrl,
          fallbackIcon: Icons.folder,
          screenBuilder: (resource) {
            // Calculate average rating from the ratings list
            double averageRating = 0.0;
            if (resource.ratings.isNotEmpty) {
              double sum = 0.0;
              int validRatings = 0;

              for (var rating in resource.ratings) {
                if (rating is num) {
                  sum += rating.toDouble();
                  validRatings++;
                }
              }

              if (validRatings > 0) {
                averageRating = sum / validRatings;
              }
            }

            return SelectedResourceScreen(
              title: resource.title,
              price: resource.price,
              imageUrl: resource.resourceImageUrl,
              date: resource.createdAt,
              rating: averageRating,
              description: resource.description,
              viewUrl: resource.resourceLink,
              isPaid: resource.price > 0,
              resourceID: resource.id,
            );
          },
        );
        break;
    }

    return Padding(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        constraints: BoxConstraints(maxWidth: 350, minWidth: 280),
        decoration: BoxDecoration(
          color: isDarkMode ? kBlack : kWhite,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: kGrey.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: TextStyle(
                  color: isDarkMode ? kWhite : kBlack,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(child: SingleChildScrollView(child: content)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Drawer(
      backgroundColor: isDarkMode ? kBlack : kWhite,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            padding: EdgeInsets.only(top: 50, left: 15, bottom: 20),
            decoration: BoxDecoration(color: isDarkMode ? kBlack : kWhite),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child:
                      imageUrl.isEmpty
                          ? Icon(Icons.person, size: 30, color: kWhite)
                          : null,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$firstName $lastName'.trim().isNotEmpty
                            ? '$firstName $lastName'.trim()
                            : 'User',
                        style: TextStyle(
                          color: isDarkMode ? kWhite : kBlack,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (title.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          title,
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 10),
                      if (memberId.isNotEmpty)
                        Text(
                          formatMemberId(memberId),
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kGrey,
                            fontSize: 15,
                          ),
                        ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.profile);
                        },
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 2,
              color: isDarkMode ? kDarkThemeBg : kLightGrey,
            ),
          ),

          // Membership Status Section
          Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membership Status',
                  style: TextStyle(
                    color: isDarkMode ? kWhite : kBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                if (hasMembership) ...[
                  // Glass Grey Membership Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ACTIVE Status
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            // Professional Member
                            Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  color:
                                      isDarkMode ? kWhite : Colors.grey[700],
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    membershipName,
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? kWhite
                                              : Colors.grey[800],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            // All premium benefits unlocked
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_open,
                                  color:
                                      isDarkMode
                                          ? kWhite.withOpacity(0.7)
                                          : Colors.grey[600],
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'All premium benefits unlocked',
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? kWhite.withOpacity(0.7)
                                              : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (membershipExiryDate.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                'Expires: ${formatMembershipExpiry(membershipExiryDate)}',
                                style: TextStyle(
                                  color: kGrey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            SizedBox(height: 12),
                            // Manage Plan Button
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(context, AppRoutes.plans);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.settings,
                                          color:
                                              isDarkMode
                                                  ? kWhite
                                                  : Colors.grey[700],
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Manage Plan',
                                          style: TextStyle(
                                            color:
                                                isDarkMode
                                                    ? kWhite
                                                    : Colors.grey[800],
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color:
                                          isDarkMode
                                              ? kWhite
                                              : Colors.grey[700],
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? kDarkThemeBg : kBGColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not a member yet',
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Unlock exclusive benefits and resources',
                          style: TextStyle(color: kGrey, fontSize: 12),
                        ),
                        SizedBox(height: 10),
                        // Benefits now handled by profileCard widget
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, AppRoutes.plans);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              padding: EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Upgrade Today',
                              style: TextStyle(
                                color: kWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 2,
              color: isDarkMode ? kDarkThemeBg : kLightGrey,
            ),
          ),

          // Drawer Items
          ListTile(
            leading: Icon(
              Icons.person_2_outlined,
              color: isDarkMode ? kWhite : kBlack,
            ),
            title: Text(
              'Profile',
              style: TextStyle(color: isDarkMode ? kWhite : kBlack),
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          ListTile(
            leading: Icon(Icons.history, color: isDarkMode ? kWhite : kBlack),
            title: Text(
              'Transaction History',
              style: TextStyle(color: isDarkMode ? kWhite : kBlack),
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.transcation),
          ),
          ListTile(
            leading: Icon(
              Icons.notifications_none,
              color: isDarkMode ? kWhite : kBlack,
            ),
            title: Text(
              'Notifications',
              style: TextStyle(color: isDarkMode ? kWhite : kBlack),
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          ListTile(
            leading: Icon(
              Icons.school_sharp,
              color: isDarkMode ? kWhite : kBlack,
            ),
            title: Text(
              'Training',
              style: TextStyle(color: isDarkMode ? kWhite : kBlack),
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.trainings),
          ),
          ListTile(
            leading: Icon(
              Icons.workspace_premium,
              color: isDarkMode ? kWhite : kBlack,
            ),
            title: Text(
              'Membership',
              style: TextStyle(color: isDarkMode ? kWhite : kBlack),
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.plans),
          ),
          if (userRoles.contains('event_verify'))
            ListTile(
              leading: Icon(
                Icons.qr_code_scanner,
                color: isDarkMode ? kWhite : kBlack,
              ),
              title: Text(
                'Scan Tickets',
                style: TextStyle(color: isDarkMode ? kWhite : kBlack),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEventSelectionForScanner(isDarkMode);
              },
            ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: isDarkMode ? kWhite : kBlack,
            ),
            title: Text(
              'About Dama',
              style: TextStyle(color: isDarkMode ? kWhite : kBlack),
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.aboutDama),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: kRed),
            title: Text('Logout', style: TextStyle(color: kRed)),
            onTap: () {
              Navigator.pop(context);
              _authController.logout(context);
            },
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 2,
              color: isDarkMode ? kDarkThemeBg : kLightGrey,
            ),
          ),
          SizedBox(height: 30),
          SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: _buildMobileDrawer(),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: CustomAppbar(
                onMenuTap: _toggleDrawer,
                imageUrl: imageUrl,
                onChatTap: () {
                  Navigator.pushNamed(context, AppRoutes.usersChatScreen);
                },
                onSearchSubmitted: (query) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              SearchResultsScreen(query: query),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 200),
                    ),
                  );
                },
                onNotificationTap: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
                unreadNotificationCount:
                    _notificationController.notificationList
                        .where((n) => !n.read)
                        .length,
              ),
            ),
          ),

          body: SafeArea(
            bottom: true,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _screens,
            ),
          ),
          bottomNavigationBar: MotionTabBar(
            tabBarColor: isDarkMode ? kBlack : kWhite,
            labelAlwaysVisible: true,
            initialSelectedTab: "Home",
            labels: const ["Home", "Blogs", "News", "Resources", "Events"],
            icons: const [
              Icons.home,
              Icons.library_books,
              Icons.newspaper,
              Icons.folder_copy,
              Icons.calendar_month,
            ],
            tabSize: 50,
            tabBarHeight: 55,
            textStyle: TextStyle(
              fontSize: 12,
              color: kGrey,
              fontWeight: FontWeight.w500,
            ),
            tabIconColor: kGrey,
            tabSelectedColor: kBlue,
            tabIconSize: 28.0,
            tabIconSelectedSize: 26.0,
            onTabItemSelected: (int value) {
              _pageController.jumpToPage(value);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 1000;
    return isWeb ? _buildWebLayout() : _buildMobileLayout();
  }
}
