import 'package:dama/routes/routes.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubscriptionBottomSheet {
  static void show({
    required BuildContext context,
    String? title,
    String? subtitle,
    VoidCallback? onUpgrade,
    VoidCallback? onDismiss,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDarkMode = themeProvider.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder:
          (context) => _SubscriptionBottomSheetWidget(
            isDarkMode: isDarkMode,
            title: title ?? 'Unlock Premium Content',
            subtitle:
                subtitle ??
                'You\'ve reached your plan limit, please check out our plans and their limits to see what plan best suits you',
            onUpgrade:
                onUpgrade ??
                () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.plans);
                },
            onDismiss:
                onDismiss ??
                () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
          ),
    );
  }
}

class _SubscriptionBottomSheetWidget extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final String subtitle;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  const _SubscriptionBottomSheetWidget({
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.onUpgrade,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onDismiss();
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkThemeBg : kWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Main content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // Premium Icon with gradient background
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kBlue, kBlue.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kBlue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          size: 50,
                          color: kWhite,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? kWhite : kBlack,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? kWhite.withOpacity(0.7) : kGrey,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Action Buttons
                      Column(
                        children: [
                          // Primary Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kBlue, kBlue.withOpacity(0.8)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: kBlue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: onUpgrade,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: kWhite,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.rocket_launch, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Choose Your Plan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Secondary Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: TextButton(
                              onPressed: onDismiss,
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    isDarkMode
                                        ? kWhite.withOpacity(0.7)
                                        : kGrey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Maybe Later',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
