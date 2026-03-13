import 'package:dama/controller/user_training_controller.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/my_trainings_screen.dart';
import 'package:dama/views/training_screen.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/modals/training_detail_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class TrainingDetailScreen extends StatefulWidget {
  const TrainingDetailScreen({super.key, required this.training});

  final TrainingModel training;

  @override
  State<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  final UserTrainingController _userTrainingController =
      Get.find<UserTrainingController>();

  late TrainingModel _training;

  final Map<String, Color> _statusColors = {
    'upcoming': Colors.blue,
    'in-progress': Colors.amber,
    'completed': Colors.green,
    'available': Colors.blue,
  };

  final Map<String, Color> _statusBgColors = {
    'upcoming': Colors.blue.withOpacity(0.1),
    'in-progress': Colors.amber.withOpacity(0.1),
    'completed': Colors.green.withOpacity(0.1),
    'available': Colors.blue.withOpacity(0.1),
  };

  @override
  void initState() {
    super.initState();
    _training = widget.training;
  }

  bool get _isEnrolled =>
      _userTrainingController.userTrainings.any((t) => t.id == _training.id);

  String get _status {
    if (!_isEnrolled) return 'available';
    final userTraining = _userTrainingController.userTrainings.firstWhere(
      (t) => t.id == _training.id,
      orElse: () => _training,
    );
    if (userTraining.status?.toLowerCase() == 'completed' ||
        (userTraining.progress ?? 0) >= 100)
      return 'completed';
    if ((userTraining.progress ?? 0) > 0) return 'in-progress';
    return 'upcoming';
  }

  double get _progress {
    if (!_isEnrolled) return 0;
    final userTraining = _userTrainingController.userTrainings.firstWhere(
      (t) => t.id == _training.id,
      orElse: () => _training,
    );
    return userTraining.progress?.toDouble() ?? 0;
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get _formattedPrice {
    if (_training.learningTracks.isEmpty) return 'Free';
    final price = _training.learningTracks.first.price;
    if (price <= 0) return 'Free';
    final currency = _training.learningTracks.first.currency ?? 'KES';
    return '$currency ${price.toStringAsFixed(0)}';
  }

  void _handleEnrollOrDashboard() {
    if (_isEnrolled) {
      // ✅ Go to MyTrainingsScreen
      Get.to(() => const MyTrainingsScreen());
    } else {
      final isDarkMode =
          Provider.of<ThemeProvider>(context, listen: false).isDark;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => TrainingDetailModal(
              training: _training,
              isDarkMode: isDarkMode,
              onRefreshPressed: () {
                _userTrainingController.refreshUserTrainings();
                setState(() {});
              },
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    // ✅ Check if training is valid (has at least an ID and title)
    final isValidTraining =
        _training.id.isNotEmpty && _training.title.isNotEmpty;

    if (!isValidTraining) {
      return _buildTrainingNotFoundScreen(isDarkMode);
    }

    final status = _status;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDarkMode),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeroCard(isDarkMode, status),
                    const SizedBox(height: 16),
                    _buildDetailsSection(isDarkMode),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(isDarkMode),
    );
  }

  /// ✅ Building the "Training Not Found" full screen
  Widget _buildTrainingNotFoundScreen(bool isDarkMode) {
    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDarkMode),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ Error icon
                      // ✅ Logo Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kBlue.withOpacity(0.1),
                        ),
                        child: Icon(Icons.school, size: 50, color: kBlue),
                      ),
                      const SizedBox(height: 24),

                      // ✅ Heading and Description
                      Text(
                        'Training not found\nThe training you\'re looking for doesn\'t exist.',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? kWhite : kBlack,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // ✅ Action button
                      CustomButton(
                        callBackFunction:
                            () => Get.off(() => const TrainingScreen()),
                        label: 'Back to Trainings',
                        backgroundColor: kBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDarkMode) {
    return Container(
      color: isDarkMode ? kDarkCard : kWhite,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? kWhite : kBlack),
            onPressed: () => Get.back(),
          ),
          Text(
            'Training Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? kWhite : kBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isDarkMode, String status) {
    final trainer = _training.trainer;
    final trainerName =
        trainer != null
            ? '${trainer.firstName} ${trainer.lastName}'.trim()
            : null;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusBgColors[status],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatStatus(status),
              style: TextStyle(
                fontSize: 12,
                color: _statusColors[status],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _training.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? kWhite : kBlack,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _training.description,
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? kGrey : Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildKeyInfoRow(isDarkMode),
          const SizedBox(height: 16),
          if (trainerName != null && trainerName.isNotEmpty) ...[
            _buildDivider(isDarkMode),
            const SizedBox(height: 16),
            _buildInstructorRow(trainerName, isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyInfoRow(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoTile(
            icon: Icons.calendar_today,
            label: 'Start Date',
            value: _formatDate(_training.startDate),
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            icon: Icons.schedule,
            label: 'Duration',
            value:
                _training.learningTracks.isNotEmpty
                    ? _training.learningTracks.first.duration
                    : 'TBD',
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            icon: Icons.school,
            label: 'Investment',
            value: _formattedPrice,
            isDarkMode: isDarkMode,
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isPrimary
                ? kBlue.withOpacity(0.08)
                : (isDarkMode ? Colors.grey[850] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? Border.all(color: kBlue.withOpacity(0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  isPrimary ? kBlue.withOpacity(0.15) : kBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kBlue, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: kGrey,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isPrimary ? 15 : 13,
              fontWeight: FontWeight.bold,
              color: isPrimary ? kBlue : (isDarkMode ? kWhite : kBlack),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorRow(String name, bool isDarkMode) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: kBlue.withOpacity(0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'I',
            style: const TextStyle(
              color: kBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instructor',
              style: TextStyle(fontSize: 12, color: kGrey),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection(bool isDarkMode) {
    final hasOutline = _training.courseOutline.isNotEmpty;
    final hasOutcomes = _training.learningOutcomes.isNotEmpty;
    final hasTracks = _training.learningTracks.isNotEmpty;
    final hasTargetAudience = _training.targetAudience.isNotEmpty;
    final hasSchedule =
        _training.learningTracks.isNotEmpty &&
        _training.learningTracks.first.schedule.isNotEmpty;

    return Column(
      children: [
        if (hasOutcomes) ...[
          _buildSectionCard(
            isDarkMode: isDarkMode,
            icon: Icons.check_circle_outline,
            title: "What You'll Learn",
            child: Column(
              children:
                  _training.learningOutcomes.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.chevron_right,
                            color: kBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? kGrey : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (hasOutline) ...[
          _buildSectionCard(
            isDarkMode: isDarkMode,
            icon: Icons.menu_book_outlined,
            title: 'Course Outline',
            child: Column(
              children:
                  _training.courseOutline.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: kBlue.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: kBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.topic,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? kWhite : kBlack,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (hasTracks) ...[
          _buildSectionCard(
            isDarkMode: isDarkMode,
            icon: Icons.track_changes,
            title: 'Learning Tracks',
            child: Column(
              children:
                  _training.learningTracks.map((track) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isDarkMode
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  track.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? kWhite : kBlack,
                                  ),
                                ),
                              ),
                              if (track.registrationStatus.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        track.registrationStatus
                                                    .toLowerCase() ==
                                                'ongoing'
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    track.registrationStatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          track.registrationStatus
                                                      .toLowerCase() ==
                                                  'ongoing'
                                              ? Colors.green
                                              : kGrey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (track.schedule.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              track.schedule,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kGrey,
                              ),
                            ),
                          ],
                          if (track.duration.isNotEmpty || track.price > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (track.duration.isNotEmpty)
                                  Text(
                                    track.duration,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: kGrey,
                                    ),
                                  ),
                                if (track.price > 0)
                                  Text(
                                    '${track.currency ?? 'KES'} ${track.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kBlue,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (hasSchedule) ...[
          _buildSectionCard(
            isDarkMode: isDarkMode,
            icon: Icons.access_time,
            title: 'Schedule',
            child: Text(
              _training.learningTracks.first.schedule,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? kGrey : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (hasTargetAudience) ...[
          _buildSectionCard(
            isDarkMode: isDarkMode,
            icon: Icons.people_outline,
            title: 'Target Audience',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  _training.targetAudience.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.chevron_right,
                            color: kBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? kGrey : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionCard({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDarkMode) {
    return Obx(() {
      final enrolled = _isEnrolled;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkCard : kWhite,
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
        ),
        child: CustomButton(
          callBackFunction: _handleEnrollOrDashboard,
          label: enrolled ? 'Go to Dashboard' : 'Enroll Now - $_formattedPrice',
          backgroundColor: kBlue,
        ),
      );
    });
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      height: 1,
    );
  }
}
