import 'package:dama/models/training_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrainingDashboard extends StatefulWidget {
  const TrainingDashboard({super.key, required this.training});

  final TrainingModel training;

  @override
  State<TrainingDashboard> createState() => _TrainingDashboardState();
}

class _TrainingDashboardState extends State<TrainingDashboard> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopNavigationbar(title: widget.training.title),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Training Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.training.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                    // Add more dashboard content here
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}