import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DamaTrainingScreen extends StatelessWidget {
  const DamaTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('DAMA Training Course')),
      body: Column(
        children: [
          const Spacer(),
          _buildClassCard(
            context,
            title: 'Weekday Virtual Classes',
            schedule: 'Monday to Friday from 7:00 AM to 8:00 PM (10 Days)',
            price: 'KES 30,000',
            image: 'assets/virtual_class.jpg',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          _buildClassCard(
            isDarkMode: isDarkMode,
            context,
            title: 'Weekend Physical Classes',
            schedule: 'Saturday 8:00 AM to 1:00 PM (4 Weeks)',
            price: 'KES 50,000',
            image: 'assets/physical_class.jpg',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context, {
    required String title,
    required String schedule,
    required String price,
    required String image,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: isDarkMode ? kDarkBG : kWhite,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.asset(
                image,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Course details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    schedule,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: isDarkMode ? kWhite : kBlack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Handle enroll button tap
                        },
                        child: const Text('Enroll Now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
