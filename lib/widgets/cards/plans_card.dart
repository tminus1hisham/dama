import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class plansCard extends StatelessWidget {
  const plansCard({
    super.key,
    required this.plan,
    required this.icon,
    required this.amount,
    required this.onPrimaryClick,
    this.onViewDetails,
    this.buttonText = "Activate",
    this.isEnabled = true,
    this.buttonColor,
    this.showViewDetails = false,
    this.secondaryButton,
  });

  final String plan;
  final String amount;
  final IconData icon;
  final VoidCallback onPrimaryClick;
  final VoidCallback? onViewDetails;
  final String buttonText;
  final bool isEnabled;
  final Color? buttonColor;
  final bool showViewDetails;
  final Widget? secondaryButton;

  // Get gradient colors based on plan type (glass morphism effect)
  LinearGradient _getCardGradient(String planType) {
    final lower = planType.toLowerCase();
    if (lower.contains('student')) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2D1F21).withOpacity(0.85),
          Color(0xFF1A1213).withOpacity(0.90),
        ],
      );
    } else if (lower.contains('professional')) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2A3A52).withOpacity(0.85),
          Color(0xFF1C2637).withOpacity(0.90),
        ],
      );
    } else if (lower.contains('corporate')) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF5C4D26).withOpacity(0.85),
          Color(0xFF3C3119).withOpacity(0.90),
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [kWhite, kWhite],
    );
  }

  // Get glass morphism border color
  Color _getGlassBorderColor(String planType) {
    final lower = planType.toLowerCase();
    if (lower.contains('student')) {
      return Color(0xFF8B5A5A).withOpacity(0.3);
    } else if (lower.contains('professional')) {
      return Color(0xFF5A7A9B).withOpacity(0.3);
    } else if (lower.contains('corporate')) {
      return Color(0xFFB8A05C).withOpacity(0.3);
    }
    return Colors.grey.withOpacity(0.2);
  }

  // Get text color based on plan type (light text for dark gradient backgrounds)
  Color _getTextColor(String planType) {
    final lower = planType.toLowerCase();
    if (lower.contains('student') ||
        lower.contains('professional') ||
        lower.contains('corporate')) {
      return kWhite;
    }
    return kBlack;
  }

  // Get secondary text color based on plan type
  Color _getSecondaryTextColor(String planType) {
    final lower = planType.toLowerCase();
    if (lower.contains('student') ||
        lower.contains('professional') ||
        lower.contains('corporate')) {
      return kWhite.withOpacity(0.7);
    }
    return kBlack.withOpacity(0.7);
  }

  // Get benefits based on plan type
  List<String> _getPlanBenefits(String planType) {
    final lower = planType.toLowerCase();

    if (lower.contains('student')) {
      return [
        'Latest News Updates',
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

  // Get hardcoded plan data
  Map<String, dynamic> _getPlanData(String planType) {
    final lower = planType.toLowerCase();
    
    if (lower.contains('student')) {
      return {
        'title': 'Student',
        'amount': '6,000',
      };
    } else if (lower.contains('professional')) {
      return {
        'title': 'Professional',
        'amount': '12,000',
      };
    } else if (lower.contains('corporate')) {
      return {
        'title': 'Corporate',
        'amount': '60,000',
      };
    } else {
      return {
        'title': planType,
        'amount': amount,
      };
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
    final cardGradient = _getCardGradient(plan);
    final textColor = _getTextColor(plan);
    final secondaryTextColor = _getSecondaryTextColor(plan);
    final planData = _getPlanData(plan);
    final displayTitle = planData['title'];
    final displayAmount = planData['amount'];

    return Padding(
      padding: EdgeInsets.only(top: 10, left: kSidePadding, right: kSidePadding),
      child: Container(
        decoration: BoxDecoration(
          gradient: cardGradient,
          border:
              !isEnabled && buttonText == "Active"
                  ? Border.all(color: Colors.green.withOpacity(0.5), width: 2)
                  : Border.all(color: _getGlassBorderColor(plan), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kBlack.withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
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
                        color: textColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: textColor, size: 24),
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
                displayTitle,
                style: TextStyle(
                  fontSize: kBigTextSize,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kSidePadding,
                vertical: 15,
              ),
              child: Container(height: 1, color: textColor.withOpacity(0.2)),
            ),

            // Benefits Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Benefits list
                  ...benefits.map(
                    (benefit) => Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              benefit,
                              style: TextStyle(
                                color: textColor,
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
              child: Container(height: 1, color: textColor.withOpacity(0.2)),
            ),

            // Price section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "Ksh ",
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    displayAmount,
                    style: TextStyle(
                      color: textColor,
                      fontSize: kBigTextSize + 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text("/year", style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                ],
              ),
            ),

            SizedBox(height: 15),

            // Primary Action button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: CustomButton(
                callBackFunction: isEnabled ? onPrimaryClick : null,
                label: buttonText,
                backgroundColor: isEnabled 
                  ? actualButtonColor 
                  : actualButtonColor.withOpacity(0.5),
              ),
            ),

            // Secondary button (if provided) - placed above View Details
            if (secondaryButton != null)
              Padding(
                padding: EdgeInsets.only(left: kSidePadding, right: kSidePadding, top: 8),
                child: secondaryButton!,
              ),

            // View Details button (if needed)
            if (showViewDetails && onViewDetails != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: kSidePadding, vertical: 8),
                child: CustomButton(
                  callBackFunction: onViewDetails,
                  label: "View Details",
                  backgroundColor: Colors.transparent,
                ),
              ),

            // Plan status description
            if (!isEnabled && buttonText == "Active")
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: kSidePadding,
                  vertical: 8,
                ),
                child: Text(
                  _getStatusDescription(buttonText),
                  style: TextStyle(
                    color: secondaryTextColor,
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
