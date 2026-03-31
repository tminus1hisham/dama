import 'dart:async';
import 'dart:io';
import 'package:dama/models/training_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dama/controller/training_controller.dart';
import 'package:dama/controller/user_training_controller.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/modals/training_detail_modal.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/views/my_trainings_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with SingleTickerProviderStateMixin {
  final TrainingController _trainingController = Get.find<TrainingController>();
  final UserTrainingController _userTrainingController =
      Get.find<UserTrainingController>();

  late TabController _tabController;
  int _activeTab = 0;

  final Map<String, Color> _statusColors = {
    'available': kBlue,
    'upcoming': kOrange,
    'in-progress': kBlue,
    'completed': kGreen,
  };

  final Map<String, Color> _statusBgColors = {
    'available': kBlue.withValues(alpha: 0.1),
    'upcoming': kOrange.withValues(alpha: 0.1),
    'in-progress': kBlue.withValues(alpha: 0.1),
    'completed': kGreen.withValues(alpha: 0.1),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
    // Delay data fetching until after build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserTrainings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshUserTrainings() async {
    await _userTrainingController.fetchUserTrainings();
    await _trainingController.fetchTrainings();
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'in-progress':
        return 'In Progress';
      case 'upcoming':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      default:
        return 'Available';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showTrainingDetails(
    BuildContext context,
    TrainingModel training,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TrainingDetailModal(
            training: training,
            isDarkMode: isDarkMode,
            onRefreshPressed: _refreshUserTrainings,
          ),
    );
  }

  // ─────────────────────────────────────────────
  // AVAILABLE TRAINING CARD
  // ─────────────────────────────────────────────
  Widget _buildTrainingCard({
    required TrainingModel training,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    final isEnrolled = _userTrainingController.userTrainings.any(
      (t) => t.id == training.id,
    );

    String status = 'available';
    double progress = 0;

    if (isEnrolled) {
      final userTraining = _userTrainingController.userTrainings.firstWhere(
        (t) => t.id == training.id,
        orElse: () => training,
      );

      final rawProgress = userTraining.progress?.toDouble() ?? 0;
      final rawStatus = userTraining.status?.toLowerCase() ?? '';

      if (rawStatus == 'completed' || rawProgress >= 100) {
        status = 'completed';
        progress = 100;
      } else if (rawProgress > 0 || rawStatus == 'in-progress') {
        status = 'in-progress';
        progress = rawProgress;
      } else {
        status = 'upcoming';
        progress = rawProgress;
      }
    }

    return GestureDetector(
      onTap: onTap ?? () => _showTrainingDetails(context, training, isDarkMode),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkCard : kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status badge + track type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBgColors[status],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: TextStyle(
                        fontSize: kBadgeTextSize,
                        color: _statusColors[status],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (training.learningTracks.isNotEmpty &&
                      training.learningTracks.first.type != 'General')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        training.learningTracks.first.type,
                        style: TextStyle(
                          fontSize: kBadgeTextSize,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                training.title,
                style: TextStyle(
                  fontSize: kTitleTextSize,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? kWhite : kBlack,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                training.description,
                style: const TextStyle(
                  fontSize: kNormalTextSize,
                  color: kGrey,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Info rows
              if (training.learningTracks.isNotEmpty) ...[
                _buildCompactInfoRow(
                  Icons.person,
                  training.trainer != null
                      ? '${training.trainer!.firstName} ${training.trainer!.lastName}'
                          .trim()
                      : 'Instructor',
                  isDarkMode,
                ),
                const SizedBox(height: 2),
                _buildCompactInfoRow(
                  Icons.calendar_today,
                  'Starts ${_formatDate(training.startDate)}',
                  isDarkMode,
                ),
                const SizedBox(height: 2),
                _buildCompactInfoRow(
                  Icons.schedule,
                  training.learningTracks.first.duration,
                  isDarkMode,
                ),
                const SizedBox(height: 2),
                _buildCompactInfoRow(
                  Icons.attach_money,
                  training.learningTracks.first.price > 0
                      ? '${training.learningTracks.first.currency} ${training.learningTracks.first.price.toStringAsFixed(0)}'
                      : 'Free',
                  isDarkMode,
                  color: kBlue,
                ),
              ],
              const SizedBox(height: 8),

              // Progress row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: const TextStyle(
                      fontSize: kBadgeTextSize,
                      color: kGrey,
                    ),
                  ),
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: kBadgeTextSize,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? kWhite : kBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor:
                      isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(kBlue),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 12),

              // Action button
              if (isEnrolled)
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: CustomButton(
                    callBackFunction:
                        () => Get.to(() => const MyTrainingsScreen()),
                    label: 'Go to Dashboard',
                    backgroundColor: kBlue,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: Platform.isIOS
                        ? _redirectToWebsite
                        : () =>
                            _showTrainingDetails(context, training, isDarkMode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      Platform.isIOS
                          ? 'View'
                          : (training.learningTracks.isNotEmpty &&
                                  training.learningTracks.first.price > 0
                              ? 'Enroll Now - ${training.learningTracks.first.currency} ${training.learningTracks.first.price.toStringAsFixed(0)}'
                              : 'Enroll Now - Free'),
                      style: const TextStyle(fontSize: kNormalTextSize),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(
    IconData icon,
    String text,
    bool isDarkMode, {
    Color? color,
  }) {
    final c = color ?? kGrey;
    return Row(
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: kBadgeTextSize,
              color: c,
              fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MY TRAINING CARD
  // ─────────────────────────────────────────────
  Widget _buildMyTrainingCard(TrainingModel training, bool isDarkMode) {
    final userTraining = _userTrainingController.userTrainings.firstWhere(
      (t) => t.id == training.id,
      orElse: () => training,
    );
    final rawProgress = userTraining.progress?.toDouble() ?? 0;
    final rawStatus = userTraining.status?.toLowerCase() ?? '';

    String status;
    double progress;

    if (rawStatus == 'completed' || rawProgress >= 100) {
      status = 'completed';
      progress = 100;
    } else if (rawProgress > 0 || rawStatus == 'in-progress') {
      status = 'in-progress';
      progress = rawProgress;
    } else {
      status = 'upcoming';
      progress = rawProgress;
    }

    return GestureDetector(
      onTap: () => Get.to(() => const MyTrainingsScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkCard : kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? kGrey.withValues(alpha: 0.3) : kLightGrey,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBgColors[status],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatStatus(status),
                style: TextStyle(
                  fontSize: kBadgeTextSize,
                  fontWeight: FontWeight.w600,
                  color: _statusColors[status],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              training.title,
              style: TextStyle(
                fontSize: kTitleTextSize,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? kWhite : kBlack,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              training.description,
              style: const TextStyle(
                fontSize: kNormalTextSize,
                color: kGrey,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Info rows
            if (training.trainer != null)
              _buildCompactInfoRow(
                Icons.person,
                '${training.trainer!.firstName} ${training.trainer!.lastName}'
                    .trim(),
                isDarkMode,
              ),
            const SizedBox(height: 2),
            _buildCompactInfoRow(
              Icons.calendar_today,
              'Starts ${_formatDate(training.startDate)}',
              isDarkMode,
            ),
            if (training.learningTracks.isNotEmpty) ...[
              const SizedBox(height: 2),
              _buildCompactInfoRow(
                Icons.schedule,
                training.learningTracks.first.duration,
                isDarkMode,
              ),
              const SizedBox(height: 2),
              _buildCompactInfoRow(
                Icons.attach_money,
                training.learningTracks.first.price > 0
                    ? '${training.learningTracks.first.currency} ${training.learningTracks.first.price.toStringAsFixed(0)}'
                    : 'Free',
                isDarkMode,
              ),
            ],
            const SizedBox(height: 10),

            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: kNormalTextSize, color: kGrey),
                ),
                Text(
                  '${progress.toInt()}%',
                  style: TextStyle(
                    fontSize: kNormalTextSize,
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
                backgroundColor:
                    isDarkMode ? Colors.grey[800] : Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(kBlue),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => Get.to(() => const MyTrainingsScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Go to Dashboard',
                  style: TextStyle(
                    color: kWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: kNormalTextSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 20,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),
                Container(
                  width: 60,
                  height: 20,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 200,
              height: 24,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 40,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 48,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: isDarkMode ? kDarkCard : kWhite,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? kDarkThemeBg : kBGColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: isDarkMode ? kWhite : kBlack,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Trainings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stat boxes
                  Obx(() {
                    final userTrainings = _userTrainingController.userTrainings;
                    final inProgress =
                        userTrainings
                            .where(
                              (t) =>
                                  (t.status ?? '') == 'in-progress' ||
                                  (t.status ?? '') == 'upcoming',
                            )
                            .length;
                    final completed =
                        userTrainings
                            .where((t) => (t.status ?? '') == 'completed')
                            .length;
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            'Total',
                            _trainingController.trainings.length.toString(),
                            Icons.menu_book,
                            isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatBox(
                            'In Progress',
                            inProgress.toString(),
                            Icons.play_circle,
                            isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatBox(
                            'Completed',
                            completed.toString(),
                            Icons.check_circle,
                            isDarkMode,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),

                  // Tab switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildTab(
                          index: 0,
                          label: 'Available Trainings',
                          isDarkMode: isDarkMode,
                        ),
                        _buildTab(
                          index: 1,
                          label: 'My Trainings',
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_trainingController.isLoading.value ||
                    _userTrainingController.isLoading.value) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: List.generate(
                      3,
                      (_) => _buildSkeletonCard(isDarkMode),
                    ),
                  );
                }
                return _activeTab == 0
                    ? _buildAvailableTrainingsTab(isDarkMode)
                    : _buildMyTrainingsTab(isDarkMode);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
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
            color:
                isActive
                    ? (isDarkMode ? kDarkThemeBg : kWhite)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: kNormalTextSize,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color:
                    isActive
                        ? (isDarkMode ? kWhite : kBlack)
                        : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableTrainingsTab(bool isDarkMode) {
    final availableTrainings =
        _trainingController.trainings
            .where(
              (t) =>
                  !_userTrainingController.userTrainings.any(
                    (ut) => ut.id == t.id,
                  ),
            )
            .toList();

    if (availableTrainings.isEmpty) {
      return _buildEmptyAvailableTrainings(isDarkMode);
    }

    return RefreshIndicator(
      color: kWhite,
      backgroundColor: kBlue,
      onRefresh: _refreshUserTrainings,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: availableTrainings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder:
            (context, index) => _buildTrainingCard(
              training: availableTrainings[index],
              isDarkMode: isDarkMode,
            ),
      ),
    );
  }

  Widget _buildMyTrainingsTab(bool isDarkMode) {
    final userTrainings = _userTrainingController.userTrainings;
    if (userTrainings.isEmpty) return _buildEmptyMyTrainings(isDarkMode);

    final inProgress =
        userTrainings
            .where(
              (t) =>
                  (t.status ?? '') == 'in-progress' ||
                  (t.status ?? '') == 'upcoming',
            )
            .toList();
    final completed =
        userTrainings.where((t) => (t.status ?? '') == 'completed').toList();

    return RefreshIndicator(
      color: kWhite,
      backgroundColor: kBlue,
      onRefresh: _refreshUserTrainings,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (inProgress.isNotEmpty) ...[
            ...inProgress.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMyTrainingCard(t, isDarkMode),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (completed.isNotEmpty) ...[
            ...completed.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMyTrainingCard(t, isDarkMode),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyAvailableTrainings(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              size: 64,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No available trainings',
              style: TextStyle(
                fontSize: kLargeHeaderSize,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You've enrolled in all available trainings! Check back soon for new opportunities.",
              style: TextStyle(fontSize: kNormalTextSize, color: kGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMyTrainings(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              size: 64,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No trainings yet',
              style: TextStyle(
                fontSize: kLargeHeaderSize,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You haven't enrolled in any trainings yet. Browse available trainings and start your learning journey!",
              style: TextStyle(fontSize: kNormalTextSize, color: kGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.school, size: 16, color: Colors.white),
              label: const Text(
                'Browse Trainings',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                _tabController.animateTo(0);
                setState(() => _activeTab = 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    IconData icon,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? kGrey.withOpacity(0.3) : kLightGrey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: kLargeHeaderSize,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: kBadgeTextSize, color: kGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _redirectToWebsite() async {
    const url = 'https://damakenya.org/';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch website')),
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening website')),
      );
    }
  }
}
