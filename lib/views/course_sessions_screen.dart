import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:dama/controller/certificate_controller.dart';
import 'package:dama/controller/user_progress_controller.dart';
import 'package:dama/models/certificate_model.dart';
import 'package:dama/models/session_model.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/providers/sessions_provider.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/session_utils.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/certificate_preview_sheet.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseSessionsScreen extends StatefulWidget {
  const CourseSessionsScreen({super.key, required this.training});

  final TrainingModel training;

  @override
  State<CourseSessionsScreen> createState() => _CourseSessionsScreenState();
}

class _CourseSessionsScreenState extends State<CourseSessionsScreen> {
  bool isLoading = true;
  String errorMessage = '';
  String? currentUserId;
  bool isCertificateEligible = false;

  final CertificateController _certificateController = Get.put(
    CertificateController(),
  );
  final UserProgressController _progressController = Get.put(
    UserProgressController(),
  );

  @override
  void initState() {
    super.initState();
    _loadUserId();
    // Delay loading sessions until after the first build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessions();
    });
    _checkCertificateEligibility();
    // If training is already completed, check and generate certificate
    if (widget.training.status == 'completed') {
      _checkAndGenerateCertificateOnCompletion();
    }
  }

  Future<void> _loadUserId() async {
    currentUserId = await StorageService.getData('userId');
    setState(() {});
  }

  Future<void> _checkCertificateEligibility() async {
    final eligible = await _certificateController.checkCertificateEligibility(
      widget.training.id,
    );
    setState(() {
      isCertificateEligible = eligible;
    });

    // Only auto-generate certificate if training is explicitly marked as completed
    // and this is not being called after a session join/leave operation
    // Auto-generation should only happen when training status changes to completed
  }

  Future<void> _checkAndGenerateCertificateOnCompletion() async {
    // Only check eligibility and generate certificate when training is completed
    if (widget.training.status == 'completed' && currentUserId != null) {
      final eligible = await _certificateController.checkCertificateEligibility(
        widget.training.id,
      );
      setState(() {
        isCertificateEligible = eligible;
      });

      if (eligible) {
        await _autoGenerateCertificate();
      }
    }
  }

  Future<void> _autoGenerateCertificate() async {
    try {
      // Check if certificate already exists to avoid duplicates
      final existingCertificates = _certificateController.certificates;
      final certificateExists = existingCertificates.any(
        (cert) =>
            cert.trainingId == widget.training.id &&
            cert.userId == currentUserId,
      );

      if (!certificateExists) {
        // Only generate certificate if training is marked as completed
        // This method should only be called when training completion is confirmed
        if (widget.training.status == 'completed') {
          final certificate = await _certificateController.generateCertificate(
            widget.training.id,
            currentUserId!,
          );

          if (certificate != null) {
            // Show a subtle notification that certificate was generated
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🎉 Certificate generated for ${widget.training.title}!',
                ),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );

            // Refresh certificate eligibility to update UI
            await _checkCertificateEligibility();
          }
        }
      }
    } catch (e) {
      // Don't show error for auto-generation failures to avoid spam
      print('Auto certificate generation failed: $e');
    }
  }

  Future<void> _loadSessions() async {
    final sessionsProvider = Provider.of<SessionsProvider>(
      context,
      listen: false,
    );
    try {
      // Load sessions from API to get current attendance data
      await sessionsProvider.loadSessions(widget.training.id);
      setState(() {
        isLoading = false;
        errorMessage = '';
      });

      // Recheck certificate eligibility after loading sessions
      // in case training status has been updated
      await _checkCertificateEligibility();

      // If training is now completed, check and generate certificate
      if (widget.training.status == 'completed') {
        await _checkAndGenerateCertificateOnCompletion();
      }
    } catch (e) {
      // On error, try loading from cache for offline support
      await sessionsProvider.loadSessionsFromCache();
      setState(() {
        isLoading = false;
        errorMessage =
            sessionsProvider.sessions.isEmpty
                ? 'Failed to load sessions. No cached data available.'
                : '';
      });

      // Still check certificate eligibility even with cached data
      await _checkCertificateEligibility();
    }
  }

  Future<void> _handleJoinLeave(TrainingSession session, bool isJoining) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not authenticated. Please log in again.')),
      );
      return;
    }

    final sessionsProvider = Provider.of<SessionsProvider>(
      context,
      listen: false,
    );
    final success =
        isJoining
            ? await _progressController.joinSession(
              widget.training.id,
              session.id,
            )
            : await _progressController.leaveSession(
              widget.training.id,
              session.id,
            );
    if (success) {
      // Update local attendance via provider
      final currentSessions = sessionsProvider.sessions;
      final sessionIndex = currentSessions.indexWhere((s) => s.id == session.id);
      if (sessionIndex != -1) {
        final updatedSession = currentSessions[sessionIndex];
        if (isJoining) {
          // Add attendance
          updatedSession.attendance.add(
            SessionAttendance(
              sessionId: session.id,
              userId: currentUserId!,
              present: true,
              checkInTime: DateTime.now(),
              checkOutTime: null,
              duration: null,
              notes: 'Auto-checked via app',
            ),
          );
        } else {
          // Remove attendance
          updatedSession.attendance.removeWhere(
            (a) => a.userId == currentUserId,
          );
        }
        sessionsProvider.updateSession(updatedSession);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isJoining
                ? 'Successfully joined the session'
                : 'Successfully left the session',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isJoining
                ? 'Failed to join the session'
                : 'Failed to leave the session',
          ),
        ),
      );
    }
  }

  Widget _buildTrainingProgressIndicator(bool isDarkMode) {
    final sessionsProvider = Provider.of<SessionsProvider>(context, listen: false);
    final currentSessions = sessionsProvider.sessions;
    final totalSessions = currentSessions.length;
    if (totalSessions == 0) return SizedBox.shrink();

    // Calculate progress based on status
    int completedSessions = 0;
    for (var session in currentSessions) {
      if (_isSessionCompleted(session)) {
        completedSessions++;
      }
    }

    final progress =
        totalSessions > 0 ? completedSessions / totalSessions : 0.0;
    final isCompleted = progress >= 1.0;

    return Column(
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
              'Training Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            isCompleted ? Colors.green : kBlue,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${completedSessions}/${totalSessions} sessions completed (${(progress * 100).toStringAsFixed(0)}%)',
          style: TextStyle(fontSize: 12, color: isDarkMode ? kWhite : kGrey),
        ),
      ],
    );
  }

  bool _isSessionCompleted(TrainingSession session) {
    // A session is considered completed for UI purposes if:
    // 1. The training itself is completed or cancelled, OR
    // 2. The user has already attended this session

    // If the entire training is completed or cancelled, all sessions are completed
    if (widget.training.status == 'completed' ||
        widget.training.status == 'cancelled') {
      return true;
    }

    final hasUserAttended = session.attendance.any(
      (a) => a.userId == currentUserId,
    );

    if (hasUserAttended) {
      return true; // User has already attended this session
    }

    // If user hasn't attended and training is active, session is only completed if it's explicitly cancelled
    return session.status == 'cancelled';
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
          TopNavigationbar(title: "Course Sessions"),
          SizedBox(height: 5),
          Container(
            color: isDarkMode ? kDarkCard : kWhite,
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.training.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? kWhite : kBlack,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Sessions (${Provider.of<SessionsProvider>(context, listen: false).sessions.length})",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? kWhite : kGrey,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Training Progress Indicator
                  _buildTrainingProgressIndicator(isDarkMode),
                ],
              ),
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : errorMessage.isNotEmpty
                    ? Center(
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
                            errorMessage,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadSessions,
                            child: Text("Retry"),
                          ),
                        ],
                      ),
                    )
                    : Provider.of<SessionsProvider>(context, listen: false).sessions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No sessions available yet",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : Consumer<SessionsProvider>(
                      builder: (context, sessionsProvider, child) {
                        return ListView.builder(
                          padding: EdgeInsets.all(15),
                          itemCount: sessionsProvider.sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessionsProvider.sessions[index];
                            return TrainingSessionCard(
                              session: session,
                              isDarkMode: isDarkMode,
                              sessionNumber: index + 1,
                              training: widget.training,
                              currentUserId: currentUserId,
                              onJoinLeave: _handleJoinLeave,
                              onReloadSessions: _loadSessions,
                              isSessionCompleted: _isSessionCompleted,
                              trainingStatus: widget.training.status,
                              onCheckCertificateEligibility:
                                  _checkCertificateEligibility,
                            );
                          },
                        );
                      },
                    ),
          ),
          // Certificate Buttons - Show when user is eligible
          if (isCertificateEligible && currentUserId != null) ...[
            Container(
              padding: EdgeInsets.all(15),
              color: isDarkMode ? kDarkCard : kWhite,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _viewCertificate,
                      icon: Icon(Icons.visibility),
                      label: Text("View Certificate"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: kWhite,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _downloadCertificate,
                    icon: Icon(Icons.download),
                    label: Text("Download"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: kWhite,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _viewCertificate() async {
    try {
      print('=== VIEW CERTIFICATE DEBUG ===');
      print('Training ID: ${widget.training.id}');
      print('Training Status: ${widget.training.status}');
      print('Current User ID: $currentUserId');
      print('Is Certificate Eligible: $isCertificateEligible');

      final certificate = await _certificateController.generateCertificate(
        widget.training.id,
        currentUserId!,
      );
      if (certificate != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (context) => CertificatePreviewSheet(
                certificate: certificate,
                onDownload: () => _downloadCertificate(),
                onShare: () => _shareCertificate(certificate),
              ),
        );
      } else {
        print('Certificate generation returned null');
        Get.snackbar(
          'Error',
          'Failed to generate certificate',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error in _viewCertificate: $e');
      Get.snackbar(
        'Error',
        'Failed to view certificate: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _downloadCertificate() async {
    try {
      // For now, we'll generate the certificate first to ensure it exists
      final certificate = await _certificateController.generateCertificate(
        widget.training.id,
        currentUserId!,
      );
      if (certificate != null) {
        await _certificateController.downloadCertificate(
          certificate.certificateNumber,
        );
        Get.snackbar(
          'Success',
          'Certificate downloaded successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download certificate: $e',
        snackPosition: SnackPosition.BOTTOM,
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
}

class TrainingSessionCard extends StatelessWidget {
  const TrainingSessionCard({
    super.key,
    required this.session,
    required this.isDarkMode,
    required this.sessionNumber,
    required this.training,
    required this.currentUserId,
    required this.onJoinLeave,
    required this.onReloadSessions,
    required this.isSessionCompleted,
    required this.trainingStatus,
    required this.onCheckCertificateEligibility,
  });

  final TrainingSession session;
  final bool isDarkMode;
  final int sessionNumber;
  final TrainingModel training;
  final String? currentUserId;
  final Future<void> Function(TrainingSession session, bool isJoining)
  onJoinLeave;
  final Future<void> Function() onReloadSessions;
  final bool Function(TrainingSession) isSessionCompleted;
  final String? trainingStatus;
  final Future<void> Function() onCheckCertificateEligibility;

  // Removed duplicate _isUserJoined, using utility instead

  Color _getStatusColor(TrainingSession session, bool isCompleted) {
    if (isCompleted) return Colors.green;
    if (session.status == 'cancelled') return Colors.red;
    if (session.status == 'ongoing') return Colors.blue;
    if (session.startTime.isBefore(DateTime.now()) &&
        session.endTime.isAfter(DateTime.now()))
      return Colors.blue;
    if (session.startTime.isAfter(DateTime.now())) return Colors.orange;
    return Colors.grey;
  }

  String _getStatusText(TrainingSession session, bool isCompleted) {
    if (isCompleted) return 'Completed';
    if (session.status == 'cancelled') return 'Cancelled';
    if (session.status == 'ongoing') return 'Ongoing';
    if (session.startTime.isBefore(DateTime.now()) &&
        session.endTime.isAfter(DateTime.now()))
      return 'Live';
    if (session.startTime.isAfter(DateTime.now())) return 'Scheduled';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isSessionCompleted(session)
                          ? Colors.green.withOpacity(0.1)
                          : session.status == 'ongoing' ||
                              (session.startTime.isBefore(DateTime.now()) &&
                                  session.endTime.isAfter(DateTime.now()))
                          ? Colors.blue.withOpacity(0.1)
                          : kBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Session $sessionNumber",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        isSessionCompleted(session)
                            ? Colors.green
                            : session.status == 'ongoing' ||
                                (session.startTime.isBefore(DateTime.now()) &&
                                    session.endTime.isAfter(DateTime.now()))
                            ? Colors.blue
                            : kBlue,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    session,
                    isSessionCompleted(session),
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(session, isSessionCompleted(session)),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(
                      session,
                      isSessionCompleted(session),
                    ),
                  ),
                ),
              ),
              Spacer(),
              Text(
                '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            session.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? kWhite : kBlack,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')} - ${session.endTime.hour}:${session.endTime.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 5),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.calendar_today, size: 16, color: kBlue),
                onPressed: () {
                  final event = Event(
                    title: session.title,
                    description: session.notes ?? 'Session details',
                    location: session.meetingPlatform ?? '',
                    startDate: session.startTime,
                    endDate: session.endTime,
                  );
                  Add2Calendar.addEvent2Cal(event);
                },
                tooltip: 'Add to Calendar',
              ),
              SizedBox(width: 5),
              Text(
                'Add to Calendar',
                style: TextStyle(fontSize: 12, color: kBlue),
              ),
            ],
          ),
          if (isUserJoined(session, currentUserId)) ...[
            if (session.meetingPlatform != null &&
                session.meetingPlatform!.isNotEmpty)
              Text(
                'Platform: ${session.meetingPlatform}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            if (session.meetingLink != null &&
                session.meetingLink!.isNotEmpty) ...[
              SizedBox(height: 5),
              GestureDetector(
                onTap: () async {
                  final url = session.meetingLink!;
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.inAppWebView,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch $url')),
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: kBlue),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Join Meeting',
                        style: TextStyle(
                          fontSize: 14,
                          color: kBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              SizedBox(height: 5),
              Text(
                'Notes: ${session.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
            ],
            SizedBox(height: 10),
            Text(
              'Resources:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? kWhite : kBlack,
              ),
            ),
            SizedBox(height: 5),
            if (session.resources.isNotEmpty)
              ...session.resources.map(
                (resource) => Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: GestureDetector(
                    onTap: () async {
                      final url = resource.url;
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.inAppWebView,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch $url')),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 16, color: kBlue),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            resource.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: kBlue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Text(
                'No resources available',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
          ] else ...[
            SizedBox(height: 10),
            Text(
              'Join the session to view platform, notes, and resources',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
          SizedBox(height: 15),
          if (!isSessionCompleted(session) &&
              session.status != 'cancelled' &&
              training.status != 'cancelled') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        currentUserId == null
                            ? null
                            : () async {
                              try {
                                final isJoined = isUserJoined(
                                  session,
                                  currentUserId,
                                );
                                await onJoinLeave(session, !isJoined);
                                // Refresh sessions to update attendance
                                await onReloadSessions();
                                // Check if this action completed the training and triggers certificate generation
                                await onCheckCertificateEligibility();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isUserJoined(session, currentUserId)
                              ? Colors.red
                              : kBlue,
                      foregroundColor: kWhite,
                      padding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      currentUserId == null
                          ? "Please log in to join"
                          : isUserJoined(session, currentUserId)
                          ? "Leave Session"
                          : "Join Session",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
