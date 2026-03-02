import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool emailNotifications;
  late bool eventReminders;
  late bool newResources;
  late bool marketing;
  late SharedPreferences prefs;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      emailNotifications = prefs.getBool('emailNotifications') ?? true;
      eventReminders = prefs.getBool('eventReminders') ?? true;
      newResources = prefs.getBool('newResources') ?? true;
      marketing = prefs.getBool('marketing') ?? false;
      isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    await prefs.setBool('emailNotifications', emailNotifications);
    await prefs.setBool('eventReminders', eventReminders);
    await prefs.setBool('newResources', newResources);
    await prefs.setBool('marketing', marketing);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification preferences saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? kBlack : kWhite,
        appBar: AppBar(
          backgroundColor: isDarkMode ? kDarkCard : kLightGrey,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? kWhite : kBlack),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Settings',
            style: TextStyle(
              color: isDarkMode ? kWhite : kBlack,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: kBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? kBlack : kWhite,
      appBar: AppBar(
        backgroundColor: isDarkMode ? kDarkCard : kLightGrey,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? kWhite : kBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
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
            // Notification Settings Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Settings',
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

            // Email Notifications Toggle
            _buildPreferenceItem(
              isDarkMode: isDarkMode,
              title: 'Email Notifications',
              subtitle: 'Receive updates via email',
              value: emailNotifications,
              onChanged: (val) {
                setState(() => emailNotifications = val);
                _savePreferences();
              },
            ),
            _buildDivider(isDarkMode),

            // Event Reminders Toggle
            _buildPreferenceItem(
              isDarkMode: isDarkMode,
              title: 'Event Reminders',
              subtitle: 'Get reminders about upcoming events',
              value: eventReminders,
              onChanged: (val) {
                setState(() => eventReminders = val);
                _savePreferences();
              },
            ),
            _buildDivider(isDarkMode),

            // New Resources Toggle
            _buildPreferenceItem(
              isDarkMode: isDarkMode,
              title: 'New Resources',
              subtitle: 'Notify when new resources are available',
              value: newResources,
              onChanged: (val) {
                setState(() => newResources = val);
                _savePreferences();
              },
            ),
            _buildDivider(isDarkMode),

            // Marketing Toggle
            _buildPreferenceItem(
              isDarkMode: isDarkMode,
              title: 'Marketing',
              subtitle: 'Receive marketing and promotional emails',
              value: marketing,
              onChanged: (val) {
                setState(() => marketing = val);
                _savePreferences();
              },
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
