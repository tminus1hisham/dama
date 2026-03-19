import 'dart:async';
import 'package:dama/controller/auth_controller.dart';
import 'package:dama/controller/blog_controller.dart';
import 'package:dama/controller/events_controller.dart';
import 'package:dama/controller/global_search_controller.dart';
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
import 'package:dama/views/pdf_viewer.dart';
import 'package:dama/views/selected_screens/selected_blog_screen.dart';
import 'package:dama/views/selected_screens/selected_event_screen.dart';
import 'package:dama/views/selected_screens/selected_news_screen.dart';
import 'package:dama/views/selected_screens/selected_resource_screen.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/custom_appbar.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:dama/widgets/modals/alert_modal.dart';
import 'package:dama/widgets/modals/referral_invite_modal.dart';
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

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  final AuthController _authController = Get.find<AuthController>();
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Pulse animation for drawer avatar glow
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

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
  final PlansController _plansController = Get.find<PlansController>();
  String membershipName = 'No Active Membership';
  String membershipId = '';
  List<String> userRoles = [];

  bool _isProfileDropdownOpen = false;
  bool _hasShownOfflineNotification = false;

  // Notification polling timer
  Timer? _notificationTimer;
  static const Duration _notificationPollInterval = Duration(seconds: 15);

  List<Widget> get _screens => [
    HomeScreen(onMenuTap: () => _toggleDrawer()),
    Blogs(onMenuTap: () => _toggleDrawer()),
    News(onMenuTap: () => _toggleDrawer()),
    Resources(onMenuTap: () => _toggleDrawer()),
    Events(onMenuTap: () => _toggleDrawer(), initialTab: widget.initialSubTab),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🏠 Dashboard initState: initialTab=${widget.initialTab}, initialSubTab=${widget.initialSubTab}',
    );
    _selectedIndex = widget.initialTab;
    _pageController = PageController(initialPage: _selectedIndex);
    debugPrint('🏠 Dashboard _selectedIndex set to: $_selectedIndex');

    // Pulse animation controller for avatar glow in drawer
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
  }

  // ─── Plan helpers (mirrors React ProfileMenuSidebar logic) ────────────────

  /// Strip leading zeros: "D000000096" → "D96"
  String _formatMemberIdShort(String id) {
    if (id.isEmpty) return id;
    final match = RegExp(r'^([A-Za-z]+)0*(\d+)$').firstMatch(id);
    if (match != null) return '${match.group(1)}${match.group(2)}';
    return id;
  }

  /// Remove API noise from plan names
  String _cleanPlanName(String raw) {
    return raw
        .replaceAll(
          RegExp(r'subscription transaction', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'plan transaction', caseSensitive: false), '')
        .replaceAll(RegExp(r'transaction', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*membership\s*', caseSensitive: false), '')
        .trim();
  }

  bool get _isStudent =>
      hasMembership &&
      _cleanPlanName(membershipName).toLowerCase().contains('student');

  bool get _isPro =>
      hasMembership &&
      (_cleanPlanName(membershipName).toLowerCase().contains('professional') ||
          _cleanPlanName(membershipName).toLowerCase().contains('pro'));

  bool get _isCorporate =>
      hasMembership &&
      (_cleanPlanName(membershipName).toLowerCase().contains('corporate') ||
          _cleanPlanName(membershipName).toLowerCase().contains('premium') ||
          _cleanPlanName(membershipName).toLowerCase().contains('gold'));

  LinearGradient _cardGradient(bool isDark) {
    if (_isStudent) {
      return LinearGradient(
        colors:
            isDark
                ? [
                  const Color(0xFF703804).withOpacity(0.50),
                  const Color(0xFF703804).withOpacity(0.45),
                ]
                : [const Color(0xFFFFD180), const Color(0xFFFFA726)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (_isPro) {
      return LinearGradient(
        colors:
            isDark
                ? [
                  const Color(0xFF6B6E6F).withOpacity(0.45),
                  const Color(0xFF6B6E6F).withOpacity(0.40),
                ]
                : [const Color(0xFFCFD8DC), const Color(0xFF90A4AE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (_isCorporate) {
      return LinearGradient(
        colors:
            isDark
                ? [
                  const Color(0xFFE5B80B).withOpacity(0.30),
                  const Color(0xFFE5B80B).withOpacity(0.25),
                ]
                : [const Color(0xFFFFF176), const Color(0xFFFFD600)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors:
          isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
              : [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)],
    );
  }

  Color _planIconBg() {
    if (_isStudent) return const Color(0xFF703804);
    if (_isPro) return const Color(0xFF6B6E6F);
    if (_isCorporate) return const Color(0xFFE5B80B);
    return Colors.grey.shade400;
  }

  Color _planTextColor(bool isDark) {
    if (_isStudent)
      return isDark ? const Color(0xFFFFA726) : const Color(0xFF703804);
    if (_isPro)
      return isDark ? const Color(0xFFCFD8DC) : const Color(0xFF6B6E6F);
    if (_isCorporate)
      return isDark ? const Color(0xFFFFD600) : const Color(0xFFE5B80B);
    return Colors.grey;
  }

  Color _badgeBg() {
    if (_isStudent) return const Color(0xFF703804);
    if (_isPro) return const Color(0xFF6B6E6F);
    if (_isCorporate) return const Color(0xFFE5B80B);
    return Colors.grey.shade400;
  }

  Color _badgeTextColor() => _isCorporate ? Colors.black : Colors.white;

  Color _cardBorderColor(bool isDark) {
    if (_isStudent) {
      return isDark
          ? const Color(0xFF8A4505)
          : const Color(0xFFFFA726).withOpacity(0.6);
    }
    if (_isPro) {
      return isDark
          ? const Color(0xFF7D8081)
          : const Color(0xFF6B6E6F).withOpacity(0.6);
    }
    if (_isCorporate) {
      return isDark
          ? const Color(0xFFC9A00A)
          : const Color(0xFFFFD600).withOpacity(0.6);
    }
    return Colors.grey.withOpacity(0.3);
  }

  /// User initials (mirrors React userInitials)
  String get _initials {
    final name = '$firstName $lastName'.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Role badge widget (mirrors React getRoleBadge)
  /// Tappable for blogger/news_editor to access admin panel
  Widget? _roleBadgeWidget() {
    final roles = userRoles.map((r) => r.toLowerCase()).toList();
    if (roles.contains('admin'))
      return _drawerChip('Admin', Colors.red, tappable: true);
    if (roles.contains('news_editor'))
      return _drawerChip('Editor', Colors.blue, tappable: true);
    if (roles.contains('blogger'))
      return _drawerChip('Blogger', Colors.purple, tappable: true);
    return null;
  }

  Widget _drawerChip(String label, Color color, {bool tappable = false}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 3),
            const Icon(Icons.open_in_new, color: Colors.white, size: 9),
          ],
        ],
      ),
    );

    if (tappable) {
      return GestureDetector(
        onTap: () {
          launchUrl(
            Uri.parse('https://admin.damakenya.org'),
            mode: LaunchMode.externalApplication,
          );
        },
        child: chip,
      );
    }
    return chip;
  }

  String _formatExpiry(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

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

    await _getMembershipStatus();
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
            membershipName = plan.membership;
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _getMembershipStatus() async {
    try {
      final storedHasMembership = await StorageService.getData('hasMembership');
      final storedMembershipId = await StorageService.getData('membershipId');
      final storedMembershipExp = await StorageService.getData('membershipExp');

      bool hasStoredMembership = false;
      if (storedHasMembership == true || storedHasMembership == 'true') {
        if (storedMembershipExp != null) {
          try {
            final expiryDate = DateTime.parse(storedMembershipExp);
            if (expiryDate.isAfter(DateTime.now())) {
              hasStoredMembership = true;
            }
          } catch (e) {}
        }
      }

      // Always fetch plans and get current user plan first to initialize controller state
      if (_plansController.plansList.isEmpty) {
        await _plansController.fetchPlans();
      }
      await _plansController.getCurrentUserPlan();

      if (hasStoredMembership && storedMembershipId != null) {
        setState(() {
          hasMembership = true;
          membershipId = storedMembershipId;
          membershipName = _plansController.getMembershipName();
        });
        return;
      }

      final hasActivePlan = _plansController.hasActivePlan.value;
      final membershipIdFromController =
          _plansController.currentMembershipId.value;

      setState(() {
        hasMembership = hasActivePlan;
        membershipName =
            hasActivePlan
                ? _plansController.getMembershipName()
                : 'No Active Membership';
        membershipId = membershipIdFromController;
      });

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
      try {
        final storedHasMembership = await StorageService.getData(
          'hasMembership',
        );
        final storedMembershipId = await StorageService.getData('membershipId');
        if (storedHasMembership == true || storedHasMembership == 'true') {
          setState(() {
            hasMembership = true;
            membershipId = storedMembershipId ?? '';
            membershipName = 'Professional Member';
          });
        } else {
          setState(() {
            hasMembership = true;
            membershipName = 'Professional Member';
          });
        }
      } catch (_) {
        setState(() {
          hasMembership = true;
          membershipName = 'Professional Member';
        });
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
    } catch (e) {}
  }

  Future<void> _checkAuthStatus() async {
    final token = await StorageService.getData('access_token');
    debugPrint('📱 [Dashboard] Checking auth status...');
    debugPrint(
      '📱 [Dashboard] Token present: ${token != null && token.isNotEmpty}',
    );
    if (token == null || token.isEmpty) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      debugPrint('📱 [Dashboard] User authenticated, loading data...');
      _loadData();
      Get.put(AlertController());
      _blogController.pagingController.addListener(() {
        if (mounted) setState(() {});
      });
      _blogController.fetchBlogs();
      _fetchAllData();
      debugPrint('📱 [Dashboard] Fetching notifications...');
      _notificationController.fetchnotifications();

      // Start polling for new notifications every 15 seconds
      _startNotificationPolling();
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _checkAndShowAlerts();
        }
      });
    }
  }

  Future<void> _checkAndShowAlerts() async {
    debugPrint('[Dashboard] _checkAndShowAlerts: Starting...');
    if (!mounted) {
      debugPrint('[Dashboard] _checkAndShowAlerts: Not mounted');
      return;
    }
    final AlertController alertController = Get.find<AlertController>();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    debugPrint('[Dashboard] _checkAndShowAlerts: Fetching alerts...');
    await alertController.fetchAlerts();
    debugPrint(
      '[Dashboard] _checkAndShowAlerts: Fetched ${alertController.alerts.length} total alerts',
    );

    if (!mounted) return;
    final activeAlerts =
        alertController.alerts.where((alert) => alert.isActive()).toList();
    debugPrint(
      '[Dashboard] _checkAndShowAlerts: Found ${activeAlerts.length} active alerts',
    );

    if (activeAlerts.isEmpty) {
      debugPrint(
        '[Dashboard] _checkAndShowAlerts: No active alerts, showing referral modal',
      );
      // Show referral modal even if no alerts
      await _showReferralModalIfNeeded();
      return;
    }

    for (var alert in activeAlerts) {
      if (!mounted) break;
      final shouldShow = await alertController.shouldShowAlert(alert.id);
      debugPrint(
        '[Dashboard] _checkAndShowAlerts: shouldShow alert ${alert.id}: $shouldShow',
      );
      if (shouldShow && mounted) {
        debugPrint(
          '[Dashboard] _checkAndShowAlerts: Showing alert ${alert.id}',
        );
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
        await alertController.markAlertAsShown(alert.id);
        if (mounted) await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    debugPrint(
      '[Dashboard] _checkAndShowAlerts: All alerts shown, now showing referral modal',
    );
    // Show referral modal after alerts
    if (mounted) {
      await _showReferralModalIfNeeded();
    }
  }

  Future<void> _fetchAllData() async {
    _blogController.fetchBlogs();
    await _newsController.refreshNews();
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> _showReferralModalIfNeeded() async {
    if (!mounted) {
      debugPrint(
        '[Dashboard] _showReferralModalIfNeeded: Not mounted, returning',
      );
      return;
    }

    debugPrint(
      '[Dashboard] _showReferralModalIfNeeded: about to show referral modal',
    );

    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (BuildContext dialogContext) {
          return ReferralInviteModal(
            onClose: () {
              debugPrint('[Dashboard] ReferralInviteModal onClose called');
              if (mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
          );
        },
      );
      debugPrint('[Dashboard] Referral modal closed');
    } catch (e) {
      debugPrint('[Dashboard] Error showing referral modal: $e');
    }
  }

  // Start polling for new notifications
  void _startNotificationPolling() {
    // Cancel existing timer if any
    if (_notificationTimer?.isActive ?? false) {
      _notificationTimer?.cancel();
    }

    _notificationTimer = Timer.periodic(_notificationPollInterval, (_) {
      if (mounted) {
        _notificationController.fetchnotifications();
      }
    });
    debugPrint(
      '✅ [Dashboard] Notification polling started (every ${_notificationPollInterval.inSeconds}s)',
    );
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
    _pulseController.dispose();
    // Cancel notification polling timer
    if (_notificationTimer?.isActive ?? false) {
      _notificationTimer?.cancel();
      debugPrint('✅ [Dashboard] Notification polling stopped');
    }
    // Don't delete PlansController here - it may be needed by incoming Dashboard
    // GetX will handle cleanup automatically when app is fully disposed
    super.dispose();
  }

  void _performSearch(String query) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                SearchResultsScreen(query: query),
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

  String _currentRoute = '/home';

  void _onMenuItemTap(String route, String title) {
    setState(() {
      _currentRoute = route;
    });
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  // ─── Drawer nav item (mirrors React <Link> menu row) ─────────────────────
  Widget _buildDrawerNavItem({
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onTap,
    Widget? badge,
    bool isDestructive = false,
    bool isSelected = false,
  }) {
    // Selected state uses blue, otherwise default colors
    final Color fg =
        isDestructive
            ? const Color(0xFFEF4444)
            : isSelected
            ? kBlue
            : (isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF374151));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kBlue.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontSize: kNormalTextSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (badge != null) ...[badge, const SizedBox(width: 8)],
              Icon(
                Icons.chevron_right,
                size: 15,
                color:
                    isDestructive
                        ? const Color(0xFFEF4444).withOpacity(0.5)
                        : fg.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Inline badge chip ────────────────────────────────────────────────────
  Widget _menuBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ─── MOBILE DRAWER ── mirrors React ProfileMenuSidebar exactly ───────────
  Widget _buildMobileDrawer() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDark;
    final String cleanedPlan = _cleanPlanName(membershipName);
    final String shortId = _formatMemberIdShort(memberId);
    final roles = userRoles.map((r) => r.toLowerCase()).toList();
    final bool isBlogger = roles.contains('blogger');
    final bool isEditor = roles.contains('news_editor');
    final bool isAdmin = roles.contains('admin');

    // ── colours ─────────────────────────────────────────────────────────────
    final Color surface = isDark ? kBlack : kWhite;
    final Color divider = isDark ? Colors.white12 : Colors.black12;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: surface,
      child: SafeArea(
        child: Column(
          children: [
            // ══════════════════════════════════════════════════════════════
            // HEADER  (avatar · name · role badge · member id · close btn)
            // ══════════════════════════════════════════════════════════════
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 8, 16),
              decoration: BoxDecoration(
                color: isDark ? kBlack : kWhite,
                border: Border(bottom: BorderSide(color: divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── DAMA Logo ─────────────────────────────────────────
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ThemeAwareLogo(height: 24, fit: BoxFit.contain),
                    ),
                  ),

                  // ── Avatar row ────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pulsing indigo→blue glow ring  (animate-pulse in React)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.profile);
                        },
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder:
                              (context, child) => Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF3B82F6),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withOpacity(_pulseAnim.value * 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(2.5),
                                child: child,
                              ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage:
                                imageUrl.isNotEmpty
                                    ? NetworkImage(imageUrl)
                                    : null,
                            backgroundColor:
                                isDark
                                    ? const Color(0xFF1E1E1E)
                                    : const Color(0xFFEEF2FF),
                            child:
                                imageUrl.isEmpty
                                    ? SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: Text(
                                          _initials,
                                          style: const TextStyle(
                                            color: Color(0xFF6366F1),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Name + role badge + member-id
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '$firstName $lastName'.trim().isNotEmpty
                                        ? '$firstName $lastName'.trim()
                                        : 'User',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: kTitleTextSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_roleBadgeWidget() != null) ...[
                                  const SizedBox(width: 6),
                                  _roleBadgeWidget()!,
                                ],
                              ],
                            ),
                            if (title.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                title,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                  fontSize: kSmallTextSize,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (shortId.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Member No: $shortId',
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[500],
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // X / close button
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ══════════════════════════════════════════════════════
                  // MEMBERSHIP CARD
                  // React: compact horizontal row — plan gradient bg,
                  //        Crown icon box, "Professional Member" bold,
                  //        "Active" pill badge, "Valid until …" small
                  // ══════════════════════════════════════════════════════
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.plans);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: _cardGradient(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _cardBorderColor(isDark),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Crown / workspace_premium icon box
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color:
                                  hasMembership
                                      ? _planIconBg()
                                      : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.workspace_premium, // Crown in React
                              size: 20,
                              color: _isCorporate ? Colors.black : Colors.white,
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Plan name + Active badge + Valid until
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row: "Professional Member"  [Active]
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        hasMembership
                                            ? '$cleanedPlan Member'
                                            : 'No Plan',
                                        style: TextStyle(
                                          color: _planTextColor(isDark),
                                          fontSize: kSmallTextSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasMembership) ...[
                                      const SizedBox(width: 6),
                                      // Check if expired using FutureBuilder
                                      FutureBuilder<bool>(
                                        future:
                                            _plansController
                                                .isMembershipExpired(),
                                        builder: (context, expiredSnapshot) {
                                          final isExpired =
                                              expiredSnapshot.data ?? false;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isExpired
                                                      ? kOrange.withOpacity(0.2)
                                                      : _badgeBg(),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isExpired ? 'Expired' : 'Active',
                                              style: TextStyle(
                                                color:
                                                    isExpired
                                                        ? kOrange
                                                        : _badgeTextColor(),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // Show FREE status if still in free period, otherwise show expiry date or RENEW prompt
                                if (hasMembership &&
                                    membershipExiryDate.isNotEmpty)
                                  FutureBuilder<bool>(
                                    future:
                                        _plansController.isMembershipExpired(),
                                    builder: (context, snapshot) {
                                      final isExpired = snapshot.data ?? false;
                                      if (isExpired) {
                                        return Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              size: 12,
                                              color: kOrange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Tap to renew membership',
                                              style: TextStyle(
                                                color: kOrange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return Text(
                                        'Valid until ${_formatExpiry(membershipExiryDate)}',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[700],
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  )
                                else if (!hasMembership)
                                  Text(
                                    'Upgrade for premium features',
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ══════════════════════════════════════════════════════
                  // VIEW CERTIFICATE BUTTON
                  // React: amber-gradient border container, Award icon box
                  //        (amber→orange gradient), "View Certificate" text
                  // Only rendered when URL exists in storage
                  // ══════════════════════════════════════════════════════
                  FutureBuilder<dynamic>(
                    future: StorageService.getData(
                      'membershipCertificateDownload',
                    ),
                    builder: (context, snapshot) {
                      final certUrl = snapshot.data?.toString().trim() ?? '';
                      if (certUrl.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () {
                            final url = certUrl;
                            Navigator.of(context).pop();
                            Get.to(
                              () => PDFViewerPage(
                                pdfUrl: url,
                                title: 'Membership Certificate',
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              // Subtle amber-tinted background (React: bg-amber-50 dark:bg-amber-950)
                              color:
                                  isDark
                                      ? const Color(
                                        0xFFF59E0B,
                                      ).withOpacity(0.08)
                                      : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withOpacity(isDark ? 0.25 : 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Award icon — amber→orange gradient box
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF59E0B), // amber-500
                                        Color(0xFFEA580C), // orange-600
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(
                                    Icons.military_tech, // Award in lucide
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Membership Certificate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right,
                                  size: 15,
                                  color:
                                      isDark
                                          ? const Color(
                                            0xFFFBBF24,
                                          ).withOpacity(0.6)
                                          : const Color(
                                            0xFF92400E,
                                          ).withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ), // end HEADER container
            // ══════════════════════════════════════════════════════════════
            // MENU ITEMS  (scrollable)
            // Order mirrors React baseMenuItems + role-specific splice
            // ══════════════════════════════════════════════════════════════
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                children: [
                  // Role-specific items first (React splice at index 1)
                  if (isBlogger || isAdmin) ...[
                    _buildDrawerNavItem(
                      title: 'Blog Editor',
                      icon: Icons.edit_square, // PenSquare in lucide
                      isDarkMode: isDark,
                      badge: _menuBadge(
                        'Blogger',
                        Colors.purple.withOpacity(0.15),
                        Colors.purple,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigator.pushNamed(context, AppRoutes.blogger);
                      },
                    ),
                    _buildDrawerNavItem(
                      title: 'My Blogs',
                      icon: Icons.menu_book, // BookOpen in lucide
                      isDarkMode: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        // Navigator.pushNamed(context, AppRoutes.myBlogs);
                      },
                    ),
                  ],
                  if (isEditor || isAdmin) ...[
                    _buildDrawerNavItem(
                      title: 'News Editor',
                      icon: Icons.newspaper, // Newspaper in lucide
                      isDarkMode: isDark,
                      badge: _menuBadge(
                        'Editor',
                        Colors.blue.withOpacity(0.15),
                        Colors.blue,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigator.pushNamed(context, AppRoutes.newsEditor);
                      },
                    ),
                    _buildDrawerNavItem(
                      title: 'My Articles',
                      icon: Icons.article, // FileText in lucide
                      isDarkMode: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        // Navigator.pushNamed(context, AppRoutes.myArticles);
                      },
                    ),
                  ],
                  if (isBlogger || isEditor || isAdmin)
                    Divider(
                      color: divider,
                      height: 16,
                      indent: 12,
                      endIndent: 12,
                    ),

                  // ── Base menu items — same order as React baseMenuItems ─
                  _buildDrawerNavItem(
                    title: 'Profile',
                    icon: Icons.person_outline, // User in lucide
                    isDarkMode: isDark,
                    isSelected: _currentRoute == AppRoutes.profile,
                    onTap: () => _onMenuItemTap(AppRoutes.profile, 'Profile'),
                  ),
                  _buildDrawerNavItem(
                    title: 'Referrals',
                    icon: Icons.people_alt_outlined,
                    isDarkMode: isDark,
                    isSelected: _currentRoute == AppRoutes.myReferrals,
                    onTap:
                        () => _onMenuItemTap(
                          AppRoutes.myReferrals,
                          'Referrals',
                        ),
                  ),
                  _buildDrawerNavItem(
                    title: 'Membership',
                    icon: Icons.workspace_premium, // Crown in lucide
                    isDarkMode: isDark,
                    badge: _menuBadge(
                      'Premium',
                      isDark
                          ? Color(0xFF1D2839) // Dark mode background
                          : Color(0xFFF5F5F5), // Light mode: RGB(245, 245, 245)
                      isDark
                          ? Color(0xFFFFFFFF) // White text in dark mode
                          : Color(0xFF000000), // Black text in light mode
                    ),
                    isSelected: _currentRoute == AppRoutes.plans,
                    onTap: () => _onMenuItemTap(AppRoutes.plans, 'Membership'),
                  ),
                  _buildDrawerNavItem(
                    title: 'Trainings',
                    icon: Icons.school_outlined, // GraduationCap in lucide
                    isDarkMode: isDark,
                    isSelected: _currentRoute == AppRoutes.trainings,
                    onTap:
                        () => _onMenuItemTap(AppRoutes.trainings, 'Trainings'),
                  ),
                  _buildDrawerNavItem(
                    title: 'Training Certificate',
                    icon: Icons.military_tech_outlined, // Award in lucide
                    isDarkMode: isDark,
                    isSelected: _currentRoute == AppRoutes.myTrainings,
                    onTap:
                        () => _onMenuItemTap(
                          AppRoutes.myTrainings,
                          'Training Certificate',
                        ),
                  ),
                  _buildDrawerNavItem(
                    title: 'Notifications',
                    icon: Icons.notifications_outlined, // Bell in lucide
                    isDarkMode: isDark,
                    isSelected: _currentRoute == AppRoutes.notifications,
                    onTap:
                        () => _onMenuItemTap(
                          AppRoutes.notifications,
                          'Notifications',
                        ),
                  ),
                  _buildDrawerNavItem(
                    title: 'Transaction History',
                    icon: Icons.history, // History in lucide
                    isDarkMode: isDark,
                    isSelected: _currentRoute == AppRoutes.transcation,
                    onTap:
                        () => _onMenuItemTap(
                          AppRoutes.transcation,
                          'Transaction History',
                        ),
                  ),
                  _buildDrawerNavItem(
                    title: 'About DAMA',
                    icon: Icons.info_outline, // Info in lucide
                    isDarkMode: isDark,
                    isSelected: _currentRoute == AppRoutes.aboutDama,
                    onTap:
                        () => _onMenuItemTap(AppRoutes.aboutDama, 'About DAMA'),
                  ),
                  _buildDrawerNavItem(
                    title: 'Support',
                    icon: Icons.support_agent,
                    isDarkMode: isDark,
                    isSelected: _currentRoute == AppRoutes.support,
                    onTap:
                        () => _onMenuItemTap(
                          AppRoutes.support,
                          'Support',
                        ),
                  ),
                  _buildDrawerNavItem(
                    title: 'Settings',
                    icon: Icons.settings_outlined, // Settings in lucide
                    isDarkMode: isDark,
                    isSelected: _currentRoute == AppRoutes.settingsPage,
                    onTap:
                        () =>
                            _onMenuItemTap(AppRoutes.settingsPage, 'Settings'),
                  ),

                  // QR scanner — only for event_verify role (not in React web)
                  if (roles.contains('event_verify'))
                    _buildDrawerNavItem(
                      title: 'Scan Tickets',
                      icon: Icons.qr_code_scanner,
                      isDarkMode: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        _showEventSelectionForScanner(isDark);
                      },
                    ),
                ],
              ),
            ),

            // ══════════════════════════════════════════════════════════════
            // LOGOUT  (destructive red row at bottom)
            // ══════════════════════════════════════════════════════════════
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: divider)),
              ),
              child: _buildDrawerNavItem(
                title: 'Logout',
                icon: Icons.logout, // LogOut in lucide
                isDarkMode: isDark,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _authController.logout(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
          body: Column(
            children: [
              Container(
                height: 70,
                color: isDarkMode ? kBlack : kWhite,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isCompact = constraints.maxWidth < 800;
                    return Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ThemeAwareLogo(
                            height: 10,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (!isCompact) SizedBox(width: 20),
                        if (!isCompact) ...[
                          SizedBox(width: 20),
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
                        Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
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
                                if (_isProfileDropdownOpen)
                                  PopupMenuButton<int>(
                                    color: kWhite,
                                    onSelected: (value) {
                                      if (value == 0)
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.profile,
                                        );
                                      else if (value == 1)
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.transcation,
                                        );
                                      else if (value == 2)
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.trainings,
                                        );
                                      else if (value == 3)
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.aboutDama,
                                        );
                                      else if (value == 4)
                                        _authController.logout(context);
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
                        _buildRightSidebar(isDarkMode),
                      ],
                    ],
                  ),
                ),
              ),
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
                            onPressed: () {},
                            child: Text(
                              'Privacy policy',
                              style: TextStyle(color: kGrey, fontSize: 12),
                            ),
                          ),
                          SizedBox(width: 20),
                          TextButton(
                            onPressed: () {},
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleGetter(item),
                            style: TextStyle(
                              color: isDarkMode ? kWhite : kBlack,
                              fontSize: kNormalTextSize,
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
              if (validRatings > 0) averageRating = sum / validRatings;
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

  // ─── MOBILE LAYOUT ────────────────────────────────────────────────────────
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
            tabBarHeight: 60,
            textStyle: TextStyle(
              fontSize: 12,
              color: kGrey,
              fontWeight: FontWeight.w500,
              height: 1.8,
            ),
            tabIconColor: kGrey,
            tabSelectedColor: kBlue,
            tabIconSize: 24.0,
            tabIconSelectedSize: 22.0,
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
