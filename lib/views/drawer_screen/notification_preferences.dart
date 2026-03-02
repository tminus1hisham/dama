import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late bool emailNotifications;
  late bool eventReminders;
  late bool newResources;
  late bool marketing;

  @override
  void initState() {
    super.initState();
    // Initialize with user preferences (these would come from API/local storage)
    emailNotifications = true;
    eventReminders = true;
    newResources = true;
    marketing = false;
  }

  void _savePreferences() {
    // TODO: Call API to save preferences
    // For now, just show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification preferences saved'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kBlack : kWhite,
      appBar: AppBar(
        backgroundColor: isDarkMode ? kDarkCard : kLightGrey,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? kWhite : kBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: TextStyle(
            color: isDarkMode ? kWhite : kBlack,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? kWhite : kBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose what notifications you receive',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Color(0xFFa0a8b8) : kGrey,
                    ),
                  ),
                ],
              ),
            ),

            // Notification preference items
            _buildPreferenceItem(
              isDarkMode: isDarkMode,
              title: 'Email Notifications',
              subtitle: 'Receive updates via email',
              value: emailNotifications,
              onChanged: (val) {
                setState(() => emailNotifications = val);
              },
            ),
            _buildDivider(isDarkMode),
            _buildPreferenceItem(
              isDarkMode: isDarkMode,
              title: 'Event Reminders',
              subtitle: 'Get reminders about upcoming events',
              value: eventReminders,
              onChanged: (val) {
                setState(() => eventReminders = val);
              },
            ),
            _buildDivider(isDarkMode),
            _buildPreferenceItem(
              isDarkMode: isDarkMode,
              title: 'New Resources',
              subtitle: 'Notify when new resources are available',
              value: newResources,
              onChanged: (val) {
                setState(() => newResources = val);
              },
            ),
            _buildDivider(isDarkMode),
            _buildPreferenceItem(
              isDarkMode: isDarkMode,
              title: 'Marketing',
              subtitle: 'Receive marketing and promotional emails',
              value: marketing,
              onChanged: (val) {
                setState(() => marketing = val);
              },
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem({
    required bool isDarkMode,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? kWhite : kBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Color(0xFFa0a8b8) : kGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: kBlue,
              inactiveThumbColor: isDarkMode ? Color(0xFF4a5568) : Color(0xFFe5e7eb),
              inactiveTrackColor:
                  isDarkMode ? Color(0xFF2d3748) : Color(0xFFd1d5db),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        color:
            isDarkMode ? Color(0xFF2a3040).withOpacity(0.5) : Color(0xFFe5e7eb),
        height: 1,
      ),
    );
  }
}
