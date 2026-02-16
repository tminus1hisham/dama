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
  });

  final CourseOutline outline;
  final TrainingModel training;
  final int sessionNumber;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopNavigationbar(title: "Session $sessionNumber"),
          SizedBox(height: 5),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session header
                  Container(
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
                                color: kBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Session $sessionNumber",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: kBlue,
                                ),
                              ),
                            ),
                            Spacer(),
                            Text(
                              outline.time,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          outline.day,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kBlue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          outline.topic,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        SizedBox(height: 5),
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
                  SizedBox(height: 20),

                  // Session content placeholder
                  Container(
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
                        Text(
                          "Session Content",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Content for this session will be available here. This may include video lectures, presentation slides, reading materials, and interactive exercises.",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 15),
                        // Placeholder for content items
                        _buildContentItem(
                          context,
                          "Video Lecture",
                          "Watch the recorded lecture for this session",
                          Icons.play_circle_outline,
                          isDarkMode,
                        ),
                        SizedBox(height: 10),
                        _buildContentItem(
                          context,
                          "Presentation Slides",
                          "Download or view the slides",
                          Icons.picture_as_pdf,
                          isDarkMode,
                        ),
                        SizedBox(height: 10),
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

                  SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement join live session
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Joining live session...')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlue,
                            foregroundColor: kWhite,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text("Join Live Session"),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Mark as completed
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Session marked as completed')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: kBlue),
                            foregroundColor: kBlue,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text("Mark Complete"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
        // TODO: Open content
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $title')),
        );
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: kBlue, size: 24),
            SizedBox(width: 10),
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