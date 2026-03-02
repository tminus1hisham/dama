import 'package:dama/controller/user_training_controller.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/my_certificates_screen.dart';
import 'package:dama/views/training_dashboard.dart';
import 'package:dama/views/training_detail_screen.dart';
import 'package:dama/widgets/shimmer/plan_card_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────
// STATUS HELPERS
// ─────────────────────────────────────────────
Color _statusBg(String status) {
  switch (status) {
    case 'in-progress': return Colors.amber.withOpacity(0.12);
    case 'completed':   return Colors.green.withOpacity(0.12);
    case 'upcoming':    return Colors.blue.withOpacity(0.12);
    default:            return kBlue.withOpacity(0.10);
  }
}

Color _statusText(String status) {
  switch (status) {
    case 'in-progress': return Colors.amber[700]!;
    case 'completed':   return Colors.green[700]!;
    case 'upcoming':    return Colors.blue[700]!;
    default:            return kBlue;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'in-progress': return 'In Progress';
    case 'completed':   return 'Completed';
    case 'upcoming':    return 'Upcoming';
    default:            return 'Available';
  }
}

bool _isCompleted(TrainingModel t) =>
    (t.status ?? '').toLowerCase() == 'completed';

// ─────────────────────────────────────────────
// TRAINING CARD — matches React horizontal layout
// ─────────────────────────────────────────────
class _TrainingCard extends StatelessWidget {
  const _TrainingCard({
    required this.training,
    required this.isDarkMode,
    this.onViewCertificate,
  });

  final TrainingModel training;
  final bool isDarkMode;
  final VoidCallback? onViewCertificate;

  @override
  Widget build(BuildContext context) {
    final progress = training.progress?.toDouble() ?? 0;
    final status = training.status ?? 'upcoming';
    final completed = _isCompleted(training);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left: Image area (fixed width, matches React md:w-64)
            SizedBox(
              width: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kBlue.withOpacity(0.2),
                            Colors.purple.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.school,
                          size: 40,
                          color: kBlue.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),

                  // Progress overlay on image (in-progress only)
                  if (status == 'in-progress')
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          color: Colors.black.withOpacity(0.70),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${progress.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  minHeight: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // CERTIFIED badge (top-right on image)
                  if (completed)
                    Positioned(
                      top: 8,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.emoji_events,
                                size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'DONE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Right: Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + track badges
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBg(status),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _statusText(status).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusText(status),
                          ),
                        ),
                      ),
                      if (training.learningTracks.isNotEmpty &&
                          training.learningTracks.first.type != 'General') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            training.learningTracks.first.type,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ]),

                    const SizedBox(height: 8),

                    // Title (matches React: font-bold text-lg, hover:text-primary)
                    Text(
                      training.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Details (instructor, schedule, start date)
                    if (training.trainer != null) ...[
                      Text(
                        'Instructor: ${training.trainer!.firstName} ${training.trainer!.lastName}'
                            .trim(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],

                    if (training.learningTracks.isNotEmpty &&
                        training.learningTracks.first.schedule != null) ...[
                      Row(children: [
                        Icon(Icons.access_time,
                            size: 13,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            training.learningTracks.first.schedule!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 3),
                    ],

                    if (training.startDate != null) ...[
                      Row(children: [
                        Icon(Icons.calendar_today,
                            size: 13,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                        const SizedBox(width: 5),
                        Text(
                          'Starts: ${_formatDate(training.startDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 12),

                    // Action buttons
                    _buildButtons(status, progress),

                    // Progress bar for in-progress (below buttons, like React mobile)
                    if (status == 'in-progress') ...[
                      const SizedBox(height: 12),
                      Divider(
                        color: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        height: 1,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${progress.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? kWhite : kBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(kBlue),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(String status, double progress) {
    if (status == 'completed') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.emoji_events,
                    size: 15, color: Colors.white),
                label: const Text(
                  'View Certificate',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                onPressed: onViewCertificate,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.visibility,
                  size: 15,
                  color: isDarkMode ? kWhite : kBlack),
              label: Text(
                'View Details',
                style: TextStyle(
                  color: isDarkMode ? kWhite : kBlack,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDarkMode
                      ? Colors.grey[600]!
                      : Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () =>
                  Get.to(() => TrainingDetailScreen(training: training)),
            ),
          ),
        ],
      );
    }

    final hasStarted = progress > 0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(
          hasStarted ? Icons.play_circle : Icons.menu_book,
          size: 15,
          color: Colors.white,
        ),
        label: Text(
          hasStarted ? 'Continue Learning' : 'Start Learning',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () =>
            Get.to(() => TrainingDashboard(training: training)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.isDarkMode,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: kGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MY TRAININGS SCREEN
// ─────────────────────────────────────────────
class MyTrainingsScreen extends StatefulWidget {
  const MyTrainingsScreen({super.key});

  @override
  State<MyTrainingsScreen> createState() => _MyTrainingsScreenState();
}

class _MyTrainingsScreenState extends State<MyTrainingsScreen>
    with SingleTickerProviderStateMixin {
  final UserTrainingController _userTrainingController =
      Get.isRegistered<UserTrainingController>()
          ? Get.find<UserTrainingController>()
          : Get.put(UserTrainingController());

  late TabController _tabController;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userTrainingController.fetchUserTrainings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleViewCertificate(TrainingModel training) async {
    final apiService = ApiService();
    final userId = await StorageService.getData('userId');

    debugPrint('[ViewCert] ══════════════════════════════');
    debugPrint('[ViewCert] userId: $userId');
    debugPrint('[ViewCert] trainingId: ${training.id}');
    debugPrint('[ViewCert] training.status: ${training.status}');
    debugPrint('[ViewCert] training.progress: ${training.progress}');
    debugPrint('[ViewCert] certificate obj: ${training.certificate}');
    debugPrint('[ViewCert] certNumber on model: ${training.certificate?.certificateNumber}');
    debugPrint('[ViewCert] certificate.issued: ${training.certificate?.issued}');
    debugPrint('[ViewCert] certificateConfig: ${training.certificateConfig}');
    debugPrint('[ViewCert] ══════════════════════════════');

    if (userId == null) {
      Get.snackbar('Error', 'User not authenticated',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      String? certNumber = training.certificate?.certificateNumber;

      if (certNumber == null || certNumber.isEmpty) {
        final cert =
            await apiService.generateCertificate(training.id, userId);
        if (cert != null) certNumber = cert.certificateNumber;
      }

      Get.back();

      if (certNumber != null && certNumber.isNotEmpty) {
        final url = '$BASE_URL/certificates/download/$certNumber';
        await _launchUrl(url);
      } else {
        Get.snackbar(
          'Certificate',
          'Certificate not available yet. Please try again shortly.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Failed to load certificate: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('Could not open URL');
    } catch (e) {
      Get.snackbar('Error', 'Could not open certificate: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER
            Container(
              color: isDarkMode ? kDarkCard : kWhite,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Learning',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Track your enrolled trainings and certificates',
                              style: TextStyle(fontSize: 13, color: kGrey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.school,
                            size: 16, color: Colors.white),
                        label: const Text(
                          'Browse Trainings',
                          style: TextStyle(
                              fontSize: 13, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => Get.toNamed('/trainings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── TABS
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey[900]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Obx(() {
                      final total =
                          _userTrainingController.userTrainings.length;
                      return Row(children: [
                        _buildTab(
                          index: 0,
                          icon: Icons.school,
                          label: 'My Trainings',
                          badge: total > 0 ? '$total' : null,
                          isDarkMode: isDarkMode,
                        ),
                        _buildTab(
                          index: 1,
                          icon: Icons.emoji_events,
                          label: 'My Certificates',
                          badge: null,
                          isDarkMode: isDarkMode,
                        ),
                      ]);
                    }),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // ── BODY
            Expanded(
              child: Obx(() {
                if (_userTrainingController.isLoading.value) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: List.generate(
                        3, (_) => const PlanCardSkeleton()),
                  );
                }
                if (_userTrainingController
                    .errorMessage.value.isNotEmpty) {
                  return _buildErrorState(isDarkMode);
                }
                if (_activeTab == 0) {
                  return _buildTrainingsTab(isDarkMode);
                }
                return const MyCertificatesScreen();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
    String? badge,
    required bool isDarkMode,
  }) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _activeTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDarkMode ? kDarkThemeBg : kWhite)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? kBlue : Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? (isDarkMode ? kWhite : kBlack)
                      : Colors.grey[500],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingsTab(bool isDarkMode) {
    final trainings = _userTrainingController.userTrainings;
    if (trainings.isEmpty) return _buildEmptyTrainings(isDarkMode);

    final inProgress = trainings
        .where((t) =>
            (t.status ?? '') == 'in-progress' ||
            (t.status ?? '') == 'upcoming')
        .toList();
    final completed = trainings.where((t) => _isCompleted(t)).toList();

    return RefreshIndicator(
      color: kWhite,
      backgroundColor: kBlue,
      onRefresh: _userTrainingController.refreshUserTrainings,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Stat cards
          Row(children: [
            Expanded(
              child: _StatCard(
                icon: Icons.menu_book,
                value: '${trainings.length}',
                label: 'Total Enrolled',
                iconBg: kBlue.withOpacity(0.1),
                iconColor: kBlue,
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.play_circle,
                value: '${inProgress.length}',
                label: 'In Progress',
                iconBg: Colors.amber.withOpacity(0.1),
                iconColor: Colors.amber[700]!,
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                value: '${completed.length}',
                label: 'Completed',
                iconBg: Colors.green.withOpacity(0.1),
                iconColor: Colors.green[700]!,
                isDarkMode: isDarkMode,
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── In Progress section
          if (inProgress.isNotEmpty) ...[
            Row(children: [
              const Icon(Icons.play_circle,
                  size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'In Progress (${inProgress.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            ...inProgress.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TrainingCard(
                    training: t,
                    isDarkMode: isDarkMode,
                    onViewCertificate: null,
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // ── Completed section
          if (completed.isNotEmpty) ...[
            Row(children: [
              const Icon(Icons.emoji_events,
                  size: 20, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Completed (${completed.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            ...completed.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TrainingCard(
                    training: t,
                    isDarkMode: isDarkMode,
                    onViewCertificate: () => _handleViewCertificate(t),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTrainings(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.school,
              size: 64,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No trainings yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? kWhite : kBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You haven't enrolled in any trainings yet. Browse our available trainings and start your learning journey!",
            style: TextStyle(fontSize: 14, color: kGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.school, size: 16, color: Colors.white),
            label: const Text('Browse Trainings',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            onPressed: () => Get.toNamed('/trainings'),
          ),
        ]),
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline,
              size: 48, color: Colors.red.withOpacity(0.7)),
          const SizedBox(height: 12),
          Text(
            _userTrainingController.errorMessage.value,
            style: const TextStyle(color: kGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _userTrainingController.refreshUserTrainings,
          ),
        ]),
      ),
    );
  }
}