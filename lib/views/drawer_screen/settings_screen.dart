import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/drawer_screen/legal_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
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
            // Appearance Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? kDarkCard : kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Color(0xFF2a3040) : Color(0xFFe5e7eb),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.palette_outlined, color: kBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: kBigTextSize,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? kWhite : kBlack,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize how the app looks',
                            style: TextStyle(
                              fontSize: kSmallTextSize,
                              color: isDarkMode ? Color(0xFFa0a8b8) : kGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Theme Mode label
                  Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: kNormalTextSize,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? kWhite : kBlack,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Theme Mode Cards - 3 column grid
                  Row(
                    children: [
                      // Light Mode
                      Expanded(
                        child: _buildThemeModeCard(
                          isDarkMode: isDarkMode,
                          icon: Icons.light_mode_outlined,
                          label: 'Light',
                          isSelected: !isDarkMode && !themeProvider.useSystemTheme,
                          onTap: () => themeProvider.setDarkMode(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Dark Mode
                      Expanded(
                        child: _buildThemeModeCard(
                          isDarkMode: isDarkMode,
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark',
                          isSelected: isDarkMode && !themeProvider.useSystemTheme,
                          onTap: () => themeProvider.setDarkMode(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // System Mode
                      Expanded(
                        child: _buildThemeModeCard(
                          isDarkMode: isDarkMode,
                          icon: Icons.computer_outlined,
                          label: 'System',
                          isSelected: themeProvider.useSystemTheme,
                          onTap: () => themeProvider.setUseSystemTheme(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            
            // Legal Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? kDarkCard : kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Color(0xFF2a3040) : Color(0xFFe5e7eb),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.gavel_outlined, color: kBlue, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Legal',
                              style: TextStyle(
                                fontSize: kBigTextSize,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? kWhite : kBlack,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View our policies and terms',
                              style: TextStyle(
                                fontSize: kSmallTextSize,
                                color: isDarkMode ? Color(0xFFa0a8b8) : kGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  _buildDivider(isDarkMode),
                  
                  // Privacy Policy
                  _buildLegalItem(
                    isDarkMode: isDarkMode,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LegalScreen(initialTab: 0),
                      ),
                    ),
                  ),
                  _buildDivider(isDarkMode),
                  
                  // Terms of Use
                  _buildLegalItem(
                    isDarkMode: isDarkMode,
                    icon: Icons.description_outlined,
                    title: 'Terms of Use',
                    subtitle: 'Rules for using our services',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LegalScreen(initialTab: 1),
                      ),
                    ),
                  ),
                  _buildDivider(isDarkMode),
                  
                  // Cookie Policy
                  _buildLegalItem(
                    isDarkMode: isDarkMode,
                    icon: Icons.cookie_outlined,
                    title: 'Cookie Policy',
                    subtitle: 'How we use cookies',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LegalScreen(initialTab: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
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

  Widget _buildLegalItem({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: kLargeHeaderSize,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? kWhite : kBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: kSmallTextSize,
                      color: isDarkMode ? Color(0xFFa0a8b8) : kGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Color(0xFFa0a8b8) : kGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeCard({
    required bool isDarkMode,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? kBlue.withOpacity(0.08) 
              : (isDarkMode ? Color(0xFF1a1f2e) : Color(0xFFf8f9fa)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kBlue : (isDarkMode ? Color(0xFF2a3040) : Color(0xFFe5e7eb)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? kBlue : (isDarkMode ? kWhite : kBlack),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: kNormalTextSize,
                fontWeight: FontWeight.w500,
                color: isSelected ? kBlue : (isDarkMode ? kWhite : kBlack),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
