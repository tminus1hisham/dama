import 'package:dama/controller/user_progress_controller.dart';
import 'package:dama/models/session_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TodaySessionsScreen extends StatefulWidget {
  const TodaySessionsScreen({super.key});

  @override
  State<TodaySessionsScreen> createState() => _TodaySessionsScreenState();
}

class _TodaySessionsScreenState extends State<TodaySessionsScreen> {
  final UserProgressController _progressController = Get.put(UserProgressController());

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopNavigationbar(title: "Today's Sessions"),
          SizedBox(height: 5),
          Container(
            color: isDarkMode ? kDarkCard : kWhite,
            child: Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "Your Training Sessions Today",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_progressController.isLoading.value) {
                return Center(child: customSpinner);
              }

              if (_progressController.errorMessage.value.isNotEmpty) {
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
                        "Failed to load today's sessions",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _progressController.refreshTodaySessions(),
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

              if (_progressController.todaySessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No sessions scheduled for today",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: kWhite,
                backgroundColor: kBlue,
                onRefresh: () => _progressController.refreshTodaySessions(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _progressController.todaySessions.length,
                  itemBuilder: (context, index) {
                    final session = _progressController.todaySessions[index];
                    return SessionCard(
                      session: session,
                      isDarkMode: isDarkMode,
                      onJoinPressed: () => _joinSession(session),
                      onLeavePressed: () => _leaveSession(session),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _joinSession(TrainingSession session) async {
    final success = await _progressController.joinSession(session.trainingId, session.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${session.title}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _leaveSession(TrainingSession session) async {
    final success = await _progressController.leaveSession(session.trainingId, session.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left ${session.title}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.isDarkMode,
    required this.onJoinPressed,
    required this.onLeavePressed,
  });

  final TrainingSession session;
  final bool isDarkMode;
  final VoidCallback onJoinPressed;
  final VoidCallback onLeavePressed;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOngoing = session.startTime.isBefore(now) && session.endTime.isAfter(now);
    final isUpcoming = session.startTime.isAfter(now);
    final isCompleted = session.endTime.isBefore(now);

    return Card(
      color: isDarkMode ? kDarkCard : kWhite,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
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
                    color: isOngoing
                        ? Colors.green.withOpacity(0.2)
                        : isUpcoming
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOngoing
                        ? 'ONGOING'
                        : isUpcoming
                            ? 'UPCOMING'
                            : 'COMPLETED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOngoing
                          ? Colors.green
                          : isUpcoming
                              ? Colors.blue
                              : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              session.description,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? kWhite : kBlack,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isDarkMode ? kWhite : kGrey,
                ),
                SizedBox(width: 4),
                Text(
                  '${DateFormat('HH:mm').format(session.startTime)} - ${DateFormat('HH:mm').format(session.endTime)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? kWhite : kGrey,
                  ),
                ),
              ],
            ),
            if (session.meetingLink != null && session.meetingLink!.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: isDarkMode ? kWhite : kGrey,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Meeting Link Available',
                      style: TextStyle(
                        fontSize: 14,
                        color: kBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                if (isUpcoming || isOngoing) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onJoinPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: kWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isOngoing ? 'Join Now' : 'Join Session'),
                    ),
                  ),
                  if (false) ...[ // session.attendees.contains('current_user_id')
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onLeavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: kWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Leave'),
                    ),
                  ],
                ] else ...[
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Session Completed',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}