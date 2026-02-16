import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class plansCard extends StatelessWidget {
  const plansCard({
    super.key,
    required this.plan,
    required this.icon,
    required this.amount,
    required this.onClick,
    this.buttonText = "Activate",
    this.isEnabled = true,
    this.buttonColor,
  });

  final String plan;
  final String amount;
  final IconData icon;
  final VoidCallback onClick;
  final String buttonText;
  final bool isEnabled;
  final Color? buttonColor;

  String _getPlanDescription(String planType) {
    switch (planType.toLowerCase()) {
      case "student":
        return "Get up to 10 blogs and news articles";
      case "professional":
        return "Get up to 100 blogs and news articles";
      case "corporate":
        return "Get unlimited news and blogs";
      default:
        return "Get unlimited news and blogs";
    }
  }

  // Get benefits based on plan type
  List<String> _getPlanBenefits(String planType) {
    final lower = planType.toLowerCase();

    if (lower.contains('student')) {
      return [
        'Mentorship',
        'Training & Resources',
        'Event Discounts',
        'Free Career Consultation',
        'Job Platform & Forum Access',
      ];
    } else if (lower.contains('professional')) {
      return [
        'Exclusive Member Area Access',
        'Training & Resources',
        'Event Discounts',
        'Networking Opportunities',
        'Job Platform & Forum Access',
      ];
    } else if (lower.contains('corporate')) {
      return [
        'Company Certification',
        'High Visibility',
        'Event Perks',
        'Premium Training',
        'Exclusive Networking',
      ];
    } else {
      return ['Basic Access', 'Community Support', 'Event Information'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    // Determine the actual button color to use
    Color actualButtonColor = buttonColor ?? kBlue;

    // If button is disabled (Active plan), use green color
    if (!isEnabled && buttonText == "Active") {
      actualButtonColor = Colors.green;
    }

    final benefits = _getPlanBenefits(plan);

    return Padding(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? kBlack : kWhite,
          border:
              !isEnabled && buttonText == "Active"
                  ? Border.all(color: Colors.green.withOpacity(0.3), width: 2)
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with icon and current plan indicator
            Padding(
              padding: EdgeInsets.only(left: 20, top: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: actualButtonColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: actualButtonColor, size: 24),
                    ),
                  ),
                  // Current plan badge
                  if (!isEnabled && buttonText == "Active")
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Current Plan",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Plan name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                plan,
                style: TextStyle(
                  fontSize: kBigTextSize,
                  color: isDarkMode ? kWhite : kBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Text(
                _getPlanDescription(plan),
                style: TextStyle(
                  color: kGrey,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // Security info
            Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Row(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Icon(FontAwesomeIcons.lock, color: kGrey, size: 15),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Payments are secure & encrypted",
                    style: TextStyle(color: kGrey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kSidePadding,
                vertical: 15,
              ),
              child: Container(height: 1, color: kGrey.withOpacity(0.3)),
            ),

            // Benefits Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's included:",
                    style: TextStyle(
                      color: isDarkMode ? kWhite : kBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Benefits list
                  ...benefits.map(
                    (benefit) => Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: actualButtonColor,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              benefit,
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kSidePadding,
                vertical: 15,
              ),
              child: Container(height: 1, color: kGrey.withOpacity(0.3)),
            ),

            // Price section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "KES ",
                    style: TextStyle(
                      color: kGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                      color: actualButtonColor,
                      fontSize: kBigTextSize + 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text("/ month", style: TextStyle(color: kGrey, fontSize: 14)),
                ],
              ),
            ),

            SizedBox(height: 15),

            // Action button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: CustomButton(
                callBackFunction: buttonText == "Active" ? null : onClick,
                label: buttonText,
                backgroundColor:
                    buttonText == "Active"
                        ? actualButtonColor.withOpacity(0.6)
                        : actualButtonColor,
              ),
            ),

            // Plan status description
            if (buttonText != "Activate")
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: kSidePadding,
                  vertical: 8,
                ),
                child: Text(
                  _getStatusDescription(buttonText),
                  style: TextStyle(
                    color: kGrey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(String buttonText) {
    switch (buttonText) {
      case "Active":
        return "You are currently subscribed to this plan";
      case "Upgrade":
        return "Upgrade to access more features";
      case "Downgrade":
        return "Switch to a basic plan";
      default:
        return "";
    }
  }
}
