import 'package:dama/controller/certificate_controller.dart';
import 'package:dama/controller/user_training_controller.dart';
import 'package:dama/models/certificate_model.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/course_sessions_screen.dart';
import 'package:dama/views/my_certificates_screen.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/certificate_preview_sheet.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MyTrainingsScreen extends StatefulWidget {
  const MyTrainingsScreen({super.key});

  @override
  State<MyTrainingsScreen> createState() => _MyTrainingsScreenState();
}

class _MyTrainingsScreenState extends State<MyTrainingsScreen>
    with SingleTickerProviderStateMixin {
  final UserTrainingController _trainingController =
      Get.find<UserTrainingController>();
  final CertificateController _certificateController = Get.put(
    CertificateController(),
  );

  final Map<String, bool> _loadingStates = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load certificates when screen initializes
    _certificateController.fetchUserCertificates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopNavigationbar(title: "My Trainings"),
          SizedBox(height: 5),

          // Tab Bar
          Container(
            color: isDarkMode ? kDarkCard : kWhite,
            child: TabBar(
              controller: _tabController,
              indicatorColor: kBlue,
              labelColor: kBlue,
              unselectedLabelColor: isDarkMode ? kWhite : kBlack,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school),
                      SizedBox(width: 8),
                      Text('Trainings'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified),
                      SizedBox(width: 8),
                      Text('Certificates'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Trainings Tab
                _buildTrainingsTab(isDarkMode),

                // Certificates Tab
                MyCertificatesScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingsTab(bool isDarkMode) {
    return Column(
      children: [
        Container(
          color: isDarkMode ? kDarkCard : kWhite,
          child: Padding(
            padding: EdgeInsets.only(top: 10, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  int inProgress =
                      _trainingController.userTrainings
                          .where((t) => t.status == 'in_progress')
                          .length;
                  int completed =
                      _trainingController.userTrainings
                          .where((t) => t.status == 'completed')
                          .length;
                  int total = _trainingController.userTrainings.length;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          'In Progress',
                          inProgress,
                          Icons.play_arrow,
                          isDarkMode,
                        ),
                        _buildStatCard(
                          'Completed',
                          completed,
                          Icons.check_circle,
                          isDarkMode,
                        ),
                        _buildStatCard('Total', total, Icons.list, isDarkMode),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_trainingController.isLoading.value) {
              return Center(child: customSpinner);
            }

            if (_trainingController.errorMessage.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Failed to load your trainings",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          () => _trainingController.refreshUserTrainings(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: kWhite,
                      ),
                      child: Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            if (_trainingController.userTrainings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      "You haven't registered for any trainings yet",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: kWhite,
                      ),
                      child: Text("Browse Trainings"),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: kWhite,
              backgroundColor: kBlue,
              onRefresh: () => _trainingController.refreshUserTrainings(),
              child: Obx(
                () => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trainingController.userTrainings.length,
                  itemBuilder: (context, index) {
                    final training = _trainingController.userTrainings[index];
                    final isLoading = _loadingStates[training.id] ?? false;
                    return MyTrainingCard(
                      training: training,
                      isDarkMode: isDarkMode,
                      onViewDetails: () {
                        if (isLoading) return;
                        setState(() {
                          _loadingStates[training.id] = true;
                        });
                        _viewTrainingDetails(training).whenComplete(() {
                          if (mounted) {
                            setState(() {
                              _loadingStates[training.id] = false;
                            });
                          }
                        });
                      },
                      isLoading: isLoading,
                      certificates: _certificateController.certificates,
                      onGenerateCertificate: () {
                        if (isLoading) return;
                        _generateCertificate(training);
                      },
                      onViewCertificate: () => _viewCertificate(training),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _viewTrainingDetails(TrainingModel training) async {
    try {
      // Fetch detailed training information using the user-specific endpoint
      final apiService = ApiService();
      final response = await apiService.getUserTrainingDetails(training.id);

      // Handle both direct response and wrapped response
      final detailedTraining =
          response['training'] ?? response['data'] ?? response;

      // Debug: Print the detailed training data
      print('Detailed training response: $response');
      print('Detailed training data: $detailedTraining');
      print('Sessions in detailed training: ${detailedTraining['sessions']}');

      // Navigate to course sessions screen with the detailed data
      Get.to(
        () => CourseSessionsScreen(
          training: TrainingModel.fromJson(detailedTraining),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load training details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateCertificate(TrainingModel training) async {
    try {
      setState(() {
        _loadingStates[training.id] = true;
      });

      final certificate = await _certificateController.generateCertificate(
        training.id,
        await StorageService.getData('userId') ?? '',
      );

      if (certificate != null) {
        // Refresh certificates to update the UI
        await _certificateController.refreshCertificates();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate certificate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[training.id] = false;
        });
      }
    }
  }

  void _viewCertificate(TrainingModel training) {
    try {
      final certificate = _certificateController.certificates.firstWhere(
        (cert) => cert.trainingId == training.id,
      );

      // Show certificate preview directly
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CertificatePreviewSheet(
          certificate: certificate,
          onDownload: () => _downloadCertificate(certificate),
          onShare: () => _shareCertificate(certificate),
        ),
      );
    } catch (e) {
      // Certificate not found, show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Certificate not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _downloadCertificate(CertificateModel certificate) async {
    try {
      final filePath = await _certificateController.downloadCertificate(certificate.certificateNumber);
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download certificate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareCertificate(CertificateModel certificate) {
    // TODO: Implement share functionality
    Get.snackbar(
      'Coming Soon',
      'Certificate sharing will be available soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
    bool isDarkMode,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: kBlue),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? kWhite : kGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MyTrainingCard extends StatelessWidget {
  const MyTrainingCard({
    super.key,
    required this.training,
    required this.isDarkMode,
    required this.onViewDetails,
    required this.isLoading,
    required this.certificates,
    this.onGenerateCertificate,
    this.onViewCertificate,
  });

  final TrainingModel training;
  final bool isDarkMode;
  final VoidCallback onViewDetails;
  final bool isLoading;
  final List<CertificateModel> certificates;
  final VoidCallback? onGenerateCertificate;
  final VoidCallback? onViewCertificate;

  double _calculateProgress() {
    // Use status-based progress calculation instead of API data
    final sessions = training.sessions;
    final totalSessions = sessions.length;

    if (totalSessions == 0) {
      return 0.0;
    }

    // Check training status first
    if (training.status == 'completed' || training.status == 'cancelled') {
      return 1.0; // 100% complete
    }

    // Count completed sessions based on status and attendance
    int completedSessions = 0;

    for (var session in sessions) {
      bool isCompleted = false;

      // Check session status
      if (session.status == 'completed' || session.status == 'cancelled') {
        isCompleted = true;
      } else {
        // Check if user attended this session
        // Note: We can't get current user ID here, so we'll rely on session status
        // The detailed progress calculation in UserProgressController handles user attendance
        isCompleted = false;
      }

      if (isCompleted) {
        completedSessions++;
      }
    }

    return totalSessions > 0 ? (completedSessions / totalSessions) : 0.0;
  }

  bool _hasProgressData() {
    // We now always have progress data based on status fields
    return training.sessions.isNotEmpty;
  }

  bool _hasCertificate() {
    return certificates.any((cert) => cert.trainingId == training.id);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final isCompleted = progress >= 1.0;
    final hasCertificate = _hasCertificate();
    final hasProgressData = _hasProgressData();

    return Card(
      color: isDarkMode ? kDarkCard : kWhite,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor:
                        isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : kBlue,
                    ),
                    strokeWidth: 4,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    training.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? kWhite : kBlack,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isCompleted
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'COMPLETE' : 'IN PROGRESS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              training.description,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? kWhite : kBlack,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            // Progress Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: isDarkMode ? kWhite : kGrey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? kWhite : kGrey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor:
                      isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : kBlue,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  hasProgressData
                      ? '${(progress * 100).toStringAsFixed(0)}% Complete'
                      : 'Progress data not available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        hasProgressData
                            ? (isCompleted ? Colors.green : kBlue)
                            : (isDarkMode ? kWhite : kGrey),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Trainer
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: isDarkMode ? kWhite : kGrey,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    training.trainer != null
                        ? 'Trainer: ${training.trainer!.firstName} ${training.trainer!.lastName}'
                        : 'Trainer: Not assigned',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? kWhite : kGrey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Duration
            if (training.learningTracks.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: isDarkMode ? kWhite : kGrey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Duration: ${training.learningTracks.first.duration}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? kWhite : kGrey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],
            // Start and End Dates
            Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: isDarkMode ? kWhite : kGrey,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    training.startDate != null && training.endDate != null
                        ? 'From ${training.startDate!.day}/${training.startDate!.month}/${training.startDate!.year} to ${training.endDate!.day}/${training.endDate!.month}/${training.endDate!.year}'
                        : 'Dates to be announced',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? kWhite : kGrey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDarkMode ? kWhite : kGrey,
                ),
                SizedBox(width: 4),
                Text(
                  'Registered on ${training.createdAt.day}/${training.createdAt.month}/${training.createdAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? kWhite : kGrey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (isCompleted && hasCertificate) ...[
              CustomButton(
                callBackFunction: onViewCertificate ?? () {},
                label: "View Certificate",
                backgroundColor: Colors.green,
                isLoading: isLoading,
              ),
            ] else if (isCompleted && !hasCertificate) ...[
              CustomButton(
                callBackFunction: onGenerateCertificate ?? () {},
                label: "Generate Certificate",
                backgroundColor: Colors.green,
                isLoading: isLoading,
              ),
            ] else ...[
              CustomButton(
                callBackFunction: onViewDetails,
                label: "View Sessions",
                backgroundColor: kBlue,
                isLoading: isLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
