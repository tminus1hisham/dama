import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:dama/controller/user_progress_controller.dart';
import 'package:dama/models/session_model.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/providers/sessions_provider.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/session_utils.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Note: Certificates are automatically generated server-side when a course completes
    // and can be viewed from the "My Certificates" tab
  }

  Future<void> _loadUserId() async {
    currentUserId = await StorageService.getData('userId');
    setState(() {});
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

    }
  }

  // Track locally joined sessions to ensure UI updates immediately
  final Set<String> _locallyJoinedSessionIds = {};
  final Set<String> _locallyLeftSessionIds = {};

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
    final result =
        isJoining
            ? await _progressController.joinSession(
              widget.training.id,
              session.id,
            )
            : await _progressController.leaveSession(
              widget.training.id,
              session.id,
            );
    final success = result['success'] == true;
    final message = result['message'];
    if (success) {
      // Update local tracking sets for immediate UI feedback
      setState(() {
        if (isJoining) {
          _locallyJoinedSessionIds.add(session.id);
          _locallyLeftSessionIds.remove(session.id);
        } else {
          _locallyJoinedSessionIds.remove(session.id);
          _locallyLeftSessionIds.add(session.id);
        }
      });

      // Update local attendance via provider
      final currentSessions = sessionsProvider.sessions;
      final sessionIndex = currentSessions.indexWhere((s) => s.id == session.id);
      if (sessionIndex != -1) {
        final updatedSession = currentSessions[sessionIndex];
        if (isJoining) {
          // Add attendance if not already present
          final alreadyAttended = updatedSession.attendance.any(
            (a) => a.userId == currentUserId,
          );
          if (!alreadyAttended) {
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
          }
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
                ? 'Successfully joined the session. You can now view meeting link and resources.'
                : 'Successfully left the session',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? (isJoining
                ? 'Failed to join the session'
                : 'Failed to leave the session'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if user has joined a session, considering local changes
  bool _isUserJoinedWithLocal(TrainingSession session) {
    // If user explicitly joined this session locally, return true
    if (_locallyJoinedSessionIds.contains(session.id)) {
      return true;
    }
    // If user explicitly left this session locally, return false
    if (_locallyLeftSessionIds.contains(session.id)) {
      return false;
    }
    // Otherwise, check the actual attendance data
    return isUserJoined(session, currentUserId);
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

    // Use local joined check for consistency with UI
    final hasUserAttended = _isUserJoinedWithLocal(session);

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
                              isUserJoinedCheck: _isUserJoinedWithLocal,
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
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
    required this.isUserJoinedCheck,
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
  final bool Function(TrainingSession) isUserJoinedCheck;

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

  // Check if user can join the session (15 minutes before start time)
  bool _canJoinSession(TrainingSession session) {
    final now = DateTime.now();
    final joinWindowStart = session.startTime.subtract(Duration(minutes: 15));
    return now.isAfter(joinWindowStart) && now.isBefore(session.endTime);
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
          if (isUserJoinedCheck(session)) ...[
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
              SizedBox(height: 10),
              if (_canJoinSession(session))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      var url = session.meetingLink!;
                      // Ensure URL has proper scheme
                      if (!url.startsWith('http://') && !url.startsWith('https://')) {
                        url = 'https://$url';
                      }
                      final uri = Uri.parse(url);
                      try {
                        // Try external application mode first (better for meeting apps)
                        final launched = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched && context.mounted) {
                          // Fallback to in-app webview
                          final webViewLaunched = await launchUrl(
                            uri,
                            mode: LaunchMode.inAppWebView,
                          );
                          if (!webViewLaunched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not launch $url'),
                                action: SnackBarAction(
                                  label: 'Copy Link',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: url));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Link copied to clipboard')),
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error launching link: $e'),
                              action: SnackBarAction(
                                label: 'Copy Link',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: url));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Link copied to clipboard')),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.video_call, color: kWhite),
                    label: Text(
                      'Enter Class',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: kWhite,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Available 15 minutes before start',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
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
                      var url = resource.url;
                      // Ensure URL has proper scheme
                      if (!url.startsWith('http://') && !url.startsWith('https://')) {
                        url = 'https://$url';
                      }
                      final uri = Uri.parse(url);
                      try {
                        // Try external application mode first
                        final launched = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched && context.mounted) {
                          // Fallback to in-app webview
                          final webViewLaunched = await launchUrl(
                            uri,
                            mode: LaunchMode.inAppWebView,
                          );
                          if (!webViewLaunched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not launch $url'),
                                action: SnackBarAction(
                                  label: 'Copy Link',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: url));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Link copied to clipboard')),
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error launching link: $e'),
                              action: SnackBarAction(
                                label: 'Copy Link',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: url));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Link copied to clipboard')),
                                  );
                                },
                              ),
                            ),
                          );
                        }
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
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isUserJoinedCheck(session)
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
