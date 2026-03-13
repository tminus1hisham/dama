import 'package:dama/models/training_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({
    super.key,
    required this.outline,
    required this.training,
    required this.sessionNumber,
    required this.userCompletedSessions, // ← passed from parent / provider / API
  });

  final CourseOutline outline;
  final TrainingModel training;
  final int sessionNumber;
  final int userCompletedSessions;

  bool get isAlreadyCompleted => userCompletedSessions >= sessionNumber;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopNavigationbar(title: "Session $sessionNumber"),
          const SizedBox(height: 5),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session header card
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isDarkMode ? kDarkCard : kWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Session $sessionNumber",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: kBlue,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              outline.time,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          outline.day,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          outline.topic,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Completed badge
                        if (isAlreadyCompleted) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Completed",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),
                        Text(
                          outline.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? kWhite : kBlack,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Session content placeholder
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isDarkMode ? kDarkCard : kWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Session Content",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Content for this session will be available here. This may include video lectures, presentation slides, reading materials, and interactive exercises.",
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildContentItem(
                          context,
                          "Video Lecture",
                          "Watch the recorded lecture for this session",
                          Icons.play_circle_outline,
                          isDarkMode,
                        ),
                        const SizedBox(height: 10),
                        _buildContentItem(
                          context,
                          "Presentation Slides",
                          "Download or view the slides",
                          Icons.picture_as_pdf,
                          isDarkMode,
                        ),
                        const SizedBox(height: 10),
                        _buildContentItem(
                          context,
                          "Reading Materials",
                          "Additional resources and references",
                          Icons.book_outlined,
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action area – main logic here
                  if (isAlreadyCompleted)
                    _buildCompletedView(context)
                  else
                    _buildActiveActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implement join live session / enter room
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Joining live session...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: kWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Join Live Session",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // TODO: Call your backend API to mark this session as completed
              // Then refresh userCompletedSessions (via provider / state)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session marked as completed')),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kBlue),
              foregroundColor: kBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Mark Complete", style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 72, color: Colors.green[700]),
          const SizedBox(height: 20),
          Text(
            "Session $sessionNumber – Completed",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.green[800],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Well done! You have successfully finished this session.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[700],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Optional: if you later have recordings available
          // OutlinedButton.icon(
          //   icon: const Icon(Icons.play_arrow),
          //   label: const Text("Watch Recording Again"),
          //   style: OutlinedButton.styleFrom(
          //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          //   ),
          //   onPressed: () {
          //     // TODO: open video player / replay
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildContentItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Opening $title')));
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: kBlue, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? kWhite : kBlack,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
