import 'dart:io';

import 'package:dama/controller/plans_controller.dart';
import 'package:dama/services/unified_payment_service.dart';
import 'package:dama/models/plans_model.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/pdf_viewer.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/modals/success_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late PlansController _plansController;
  String? fetchedPhoneNumber;
  String? completePhoneNumber;
  String phoneNumber = '';
  String countryCode = '+254';

  @override
  void initState() {
    super.initState();
    _plansController = Get.find<PlansController>();
    _plansController.fetchPlans();
    _fetchPhoneNumber();
  }

  Future<void> _fetchPhoneNumber() async {
    fetchedPhoneNumber = await StorageService.getData("phoneNumber");
    setState(() {});
  }

  // Get tier display icon
  IconData _getTierIcon(String tierName) {
    final lower = tierName.toLowerCase();
    if (lower.contains('student')) return FontAwesomeIcons.graduationCap;
    if (lower.contains('professional')) return FontAwesomeIcons.briefcase;
    if (lower.contains('corporate')) return FontAwesomeIcons.building;
    return FontAwesomeIcons.crown;
  }

  // Get tier colors - matching React metallic tier colors
  Map<String, Color> _getTierColors(String tierName) {
    final lower = tierName.toLowerCase();

    if (lower.contains('student')) {
      return {
        // More saturated bronze for badge/text
        'primary': const Color(0xFFFFA726), // Saturated Bronze (orange)
        'accent': const Color(0xFFFF9B17),
        'gradientStart': const Color(0xFFFFB366),
        'gradientEnd': const Color(0xFFE8C04D),
        'badgeBg': const Color(0xFFFFA726),
      };
    } else if (lower.contains('professional')) {
      return {
        // More saturated silver for badge/text
        'primary': const Color(0xFFB0BEC5), // Saturated Silver (light blue-gray)
        'accent': const Color(0xFF64748B),
        'gradientStart': const Color(0xFFCDD5E0),
        'gradientEnd': const Color(0xFFB8C1D0),
        'badgeBg': const Color(0xFFB0BEC5),
      };
    } else if (lower.contains('corporate')) {
      return {
        'primary': const Color(0xFFE5B80B), // Gold
        'accent': const Color(0xFFCA8A04),
        'gradientStart': const Color(0xFFFCD34D),
        'gradientEnd': const Color(0xFFF59E0B),
        'badgeBg': const Color(0xFFE5B80B),
      };
    }

    return {
      'primary': kBlue,
      'accent': const Color(0xFF64748B),
      'gradientStart': const Color(0xFF93C5FD),
      'gradientEnd': const Color(0xFF60A5FA),
      'badgeBg': kBlue,
    };
  }

  // Get button text
  String _getButtonText(String planType) {
    final lower = planType.toLowerCase();
    if (lower.contains('student')) return "Not Available";
    if (lower.contains('professional')) return "Current Plan";
    if (lower.contains('corporate')) return "Upgrade";
    return "View Details";
  }

  // Check if button should be disabled
  bool _isButtonDisabled(String planType) {
    final lower = planType.toLowerCase();
    return false; // All plans are now clickable
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    return SafeArea(
      bottom: true,
      child: Obx(
        () => Scaffold(
          backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(isDarkMode),

              // Plans List
              Expanded(child: _buildPlansList(isDarkMode)),
            ],
          ),
        ),
      ),
    );
  }

  // Header Widget
  Widget _buildHeader(bool isDarkMode) {
    return Container(
      color: isDarkMode ? kBlack : kWhite,
      padding: const EdgeInsets.symmetric(
        horizontal: kSidePadding,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back_ios,
              color: isDarkMode ? kWhite : kBlack,
            ),
          ),
          const SizedBox(height: 16),

          // Header Content
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(FontAwesomeIcons.crown, color: kBlue, size: 24),
              ),
              const SizedBox(width: 16),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membership Plans',
                      style: TextStyle(
                        fontSize: kBigTextSize + 2,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade your DAMA experience',
                      style: TextStyle(fontSize: 13, color: kGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Plans count badge
          if (!_plansController.isLoading.value &&
              _plansController.plansList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FontAwesomeIcons.star, size: 12, color: kBlue),
                    const SizedBox(width: 6),
                    Text(
                      '${_plansController.plansList.length} Active Plan${_plansController.plansList.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: kBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Plans List Widget
  Widget _buildPlansList(bool isDarkMode) {
    return Obx(() {
      // Loading State
      if (_plansController.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading plans...', style: TextStyle(color: kGrey)),
            ],
          ),
        );
      }

      // Empty State
      if (_plansController.plansList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.crown,
                size: 48,
                color: kGrey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No plans available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Membership plans will appear here',
                style: TextStyle(fontSize: 13, color: kGrey),
              ),
            ],
          ),
        );
      }

      // Filter out Institution plans
      final filteredPlans = _plansController.plansList
          .where((plan) => !plan.membership.toLowerCase().contains('institution'))
          .toList();

      // Plans Grid
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // Removed mainAxisExtent to allow card height to shrink
          ),
          itemCount: filteredPlans.length,
          itemBuilder: (context, index) {
            final plan = filteredPlans[index];
            return FutureBuilder<bool>(
              future: _isMembershipExpired(),
              builder: (context, snapshot) {
                final isExpired = snapshot.data ?? false;
                return _buildPlanCard(context, plan, isDarkMode, isExpired);
              },
            );
          },
        ),
      );
    });
  }

  // Check if membership has expired
  Future<bool> _isMembershipExpired() async {
    try {
      final membershipExp = await StorageService.getData('membershipExp');
      if (membershipExp == null || membershipExp.toString().isEmpty) {
        return false;
      }
      final expiryDate = DateTime.parse(membershipExp.toString());
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      debugPrint('Error checking membership expiration: $e');
      return false;
    }
  }

  // Plan Card Widget - Updated with metallic tier styling
  Widget _buildPlanCard(
    BuildContext context,
    PlanModel plan,
    bool isDarkMode, [
    bool isMembershipExpired = false,
  ]) {
    final tierColors = _getTierColors(plan.membership);
    final tierIcon = _getTierIcon(plan.membership);
    final isCurrentPlan =
        _plansController.hasActivePlan.value &&
        _plansController.currentUserPlan.value.toLowerCase() ==
            plan.membership.toLowerCase();
    final isCorporate = plan.membership.toLowerCase().contains('corporate');
    final isCurrentPlanExpired = isCurrentPlan && isMembershipExpired;

    // Get gradient colors based on tier and dark mode
    LinearGradient _getCardGradient() {
      final lower = plan.membership.toLowerCase();
      if (lower.contains('student')) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [
                    const Color(0xFF3D2414).withValues(alpha: 0.4),
                    const Color(0xFF331D0A).withValues(alpha: 0.5),
                  ]
                  : [const Color(0xFFFFD699), const Color(0xFFFFB366)],
        );
      } else if (lower.contains('professional')) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [
                    const Color(0xFF3A4047).withValues(alpha: 0.4),
                    const Color(0xFF262B32).withValues(alpha: 0.5),
                  ]
                  : [const Color(0xFFCDD5E0), const Color(0xFFB8C1D0)],
        );
      } else if (lower.contains('corporate')) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [
                    const Color(0xFF665533).withValues(alpha: 0.5),
                    const Color(0xFF4D3D26).withValues(alpha: 0.6),
                  ]
                  : [const Color(0xFFFEE2A0), const Color(0xFFFFD580)],
        );
      } else if (lower.contains('institution')) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [
                    const Color(0xFF4C2672).withValues(alpha: 0.4),
                    const Color(0xFF2D1652).withValues(alpha: 0.5),
                  ]
                  : [const Color(0xFFE5D4FF), const Color(0xFFD9B8FF)],
        );
      }
      // Default
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors:
            isDarkMode
                ? [
                  const Color(0xFF1E2A3A).withValues(alpha: 0.5),
                  const Color(0xFF0F1A2A).withValues(alpha: 0.6),
                ]
                : [const Color(0xFFC7D9F7), const Color(0xFFA8C8F7)],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: _getCardGradient(),
          border: Border.all(
            color:
                isCurrentPlan
                    ? tierColors['primary']!
                    : kGrey.withValues(alpha: 0.2),
            width: isCurrentPlan ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: tierColors['primary']!.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient overlay (metallic shine)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Gradient top accent bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tierColors['gradientStart']!,
                      tierColors['primary']!,
                      tierColors['gradientEnd']!,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Category Badge & Popular Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tierColors['primary']!.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: tierColors['primary']!.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tierIcon,
                              size: 12,
                              color: tierColors['primary'],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              plan.membership.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tierColors['primary'],
                                letterSpacing: 0.6,
                                shadows: [
                                  Shadow(
                                    color: tierColors['primary']!.withValues(alpha: 0.35),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCorporate && !isCurrentPlan)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.withValues(alpha: 0.3),
                                Colors.orange.withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Popular',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isCurrentPlan)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tierColors['primary']!.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: tierColors['primary']!.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: tierColors['primary'],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Your Plan',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: tierColors['primary'],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price - always show actual price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Ksh ${_formatPrice(_getCorrectPrice(plan))}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isCorporate ? kWhite : tierColors['primary'],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/year',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isCorporate
                                  ? kWhite.withValues(alpha: 0.7)
                                  : kGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Divider
                  Divider(color: kGrey.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: 2),

                  // Features List
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...plan.included.map((feature) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: kGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? kWhite : kBlack,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),

                  const SizedBox(height: 0),

                  // Divider
                  Divider(color: kGrey.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: 0),

                  // Action Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isCurrentPlan)
                        // Current Plan State or Expired Membership
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isCurrentPlanExpired
                                        ? tierColors['primary']
                                        : tierColors['primary']!.withValues(
                                          alpha: 0.2,
                                        ),
                                foregroundColor:
                                    isCurrentPlanExpired
                                        ? Colors.black
                                        : tierColors['primary'],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color:
                                        isCurrentPlanExpired
                                            ? tierColors['primary']!
                                            : tierColors['primary']!.withValues(
                                              alpha: 0.5,
                                            ),
                                  ),
                                ),
                                elevation: isCurrentPlanExpired ? 2 : 0,
                              ),
                              onPressed:
                                  isCurrentPlanExpired
                                      ? () {
                                        debugPrint(
                                          'Membership expired - showing payment modal for: ${plan.membership}',
                                        );
                                        Navigator.pop(context);
                                        _showPaymentModal(
                                          context,
                                          plan,
                                          isDarkMode,
                                        );
                                      }
                                      : null,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isCurrentPlanExpired
                                        ? Icons.refresh_rounded
                                        : Icons.check_circle_rounded,
                                    size: 16,
                                    color:
                                        isCurrentPlanExpired
                                            ? Colors.black
                                            : tierColors['primary'],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isCurrentPlanExpired
                                        ? 'Activate'
                                        : 'Active',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color:
                                          isCurrentPlanExpired
                                              ? Colors.black
                                              : tierColors['primary'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 0),
                            // View Certificate button for Professional plan
                            if (plan.membership.toLowerCase().contains(
                              'professional',
                            ))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: tierColors['primary'],
                                    side: BorderSide(
                                      color: tierColors['primary']!.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () async {
                                    debugPrint(
                                      'Opening membership certificate',
                                    );
                                    final certUrl =
                                        await StorageService.getData(
                                          'membershipCertificateDownload',
                                        );
                                    final url =
                                        certUrl?.toString().trim() ?? '';
                                    if (url.isNotEmpty) {
                                      // Match drawer behavior: open in the in-app PDF viewer
                                      Navigator.pop(context);
                                      Get.to(
                                        () => PDFViewerPage(
                                          pdfUrl: url,
                                          title: 'Membership Certificate',
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Certificate not available yet',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.card_membership_rounded,
                                        size: 14,
                                        color: tierColors['primary'],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'View Certificate',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: tierColors['primary'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kBlue,
                                side: const BorderSide(color: kBlue),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed:
                                  () => _showPlanDetailsModal(
                                    context,
                                    plan,
                                    isDarkMode,
                                    isMembershipExpired,
                                  ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (isCorporate)
                        // Corporate/Upgrade Plan
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tierColors['primary'],
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                debugPrint(
                                  'Card Upgrade tapped for: ${plan.membership}',
                                );
                                _showPaymentModal(context, plan, isDarkMode);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.trending_up_rounded, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Upgrade',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kGrey,
                                side: BorderSide(
                                  color: kGrey.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed:
                                  () => _showPlanDetailsModal(
                                    context,
                                    plan,
                                    isDarkMode,
                                    isMembershipExpired,
                                  ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        // Student/Other Plans - Not Available
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF204987),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: const Color(
                                  0xFF204987,
                                ),
                                disabledForegroundColor: Colors.white,
                              ),
                              onPressed: null,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Not Available',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kGrey,
                                side: BorderSide(
                                  color: kGrey.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed:
                                  () => _showPlanDetailsModal(
                                    context,
                                    plan,
                                    isDarkMode,
                                    isMembershipExpired,
                                  ),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
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

  // Plan Details Modal - Enhanced with full features and styling matching React
  void _showPlanDetailsModal(
    BuildContext context,
    PlanModel plan,
    bool isDarkMode, [
    bool isMembershipExpired = false,
  ]) {
    final tierColors = _getTierColors(plan.membership);
    final tierIcon = _getTierIcon(plan.membership);
    final isCurrentPlan =
        _plansController.hasActivePlan.value &&
        _plansController.currentUserPlan.value.toLowerCase() ==
            plan.membership.toLowerCase();
    final isCurrentPlanExpired = isCurrentPlan && isMembershipExpired;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? kDarkCard : kWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          // Removed maxHeight constraint to allow modal to shrink
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Content - Flexible allows shrinking if content is small
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with close button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tierColors['primary']!.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: tierColors['primary']!.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Icon(
                              tierIcon,
                              color: tierColors['primary'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.membership,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? kWhite : kBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close_rounded,
                              color: isDarkMode ? kWhite : kBlack,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Price Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tierColors['primary']!.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tierColors['primary']!.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: kGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'KES ${_formatPrice(_getCorrectPrice(plan))}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: tierColors['primary'],
                                  ),
                                ),
                                Text(
                                  '/year',
                                  style: TextStyle(fontSize: 13, color: kGrey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Features Section
                      Text(
                        'Features Included',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            plan.included.map((feature) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: kGreen,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDarkMode ? kWhite : kBlack,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Benefits Section
                      if (plan.benefits.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Key Benefits',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  plan.benefits.map((benefit) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 18,
                                            color: tierColors['primary'],
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              benefit,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    isDarkMode
                                                        ? kWhite
                                                        : kBlack,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // CTA Button - Fixed at bottom
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isButtonDisabled(plan.membership)
                                ? const Color(0xFF204987)
                                : plan.membership.toLowerCase().contains(
                                  'professional',
                                )
                                ? const Color(0xFF0A161A)
                                : plan.membership.toLowerCase().contains(
                                  'corporate',
                                )
                                ? const Color(0xFF377DF4)
                                : tierColors['primary'],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: _isButtonDisabled(plan.membership) ? 0 : 2,
                        disabledBackgroundColor: const Color(0xFF204987),
                        disabledForegroundColor: Colors.white,
                      ),
                      onPressed:
                          _isButtonDisabled(plan.membership)
                              ? null
                              : () {
                                final isCorporate = plan.membership
                                    .toLowerCase()
                                    .contains('corporate');
                                final isProfessional = plan.membership
                                    .toLowerCase()
                                    .contains('professional');
                                final isStudent = plan.membership
                                    .toLowerCase()
                                    .contains('student');

                                // iOS redirect for payable plans
                                if (Platform.isIOS &&
                                    (isCorporate ||
                                        (isProfessional &&
                                            isCurrentPlanExpired) ||
                                        (isStudent &&
                                            isCurrentPlanExpired))) {
                                  Navigator.pop(context);
                                  _redirectToWebsite();
                                  return;
                                }

                                if (isCorporate) {
                                  // Show payment modal for Corporate plan
                                  Navigator.pop(context);
                                  debugPrint(
                                    'Showing payment modal for: ${plan.membership}',
                                  );
                                  _showPaymentModal(context, plan, isDarkMode);
                                } else if (isProfessional &&
                                    isCurrentPlanExpired) {
                                  // Professional plan that expired - show payment modal
                                  Navigator.pop(context);
                                  debugPrint(
                                    'Professional membership expired - showing payment modal',
                                  );
                                  _showPaymentModal(context, plan, isDarkMode);
                                } else if (isStudent &&
                                    isCurrentPlanExpired) {
                                  // Student plan after expiry - show payment modal
                                  Navigator.pop(context);
                                  debugPrint(
                                    'Student membership expired - showing payment modal',
                                  );
                                  _showPaymentModal(context, plan, isDarkMode);
                                } else if (isProfessional) {
                                  // Current plan - just close modal
                                  Navigator.pop(context);
                                  debugPrint(
                                    'Current plan: ${plan.membership}',
                                  );
                                } else {
                                  // Other plans - just close modal
                                  Navigator.pop(context);
                                  debugPrint(
                                    'Plan selected: ${plan.membership}',
                                  );
                                }
                              },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            () {
                              final isCorporate = plan.membership
                                  .toLowerCase()
                                  .contains('corporate');
                              final isProfessional = plan.membership
                                  .toLowerCase()
                                  .contains('professional');
                              final isStudent = plan.membership
                                  .toLowerCase()
                                  .contains('student');
                              final isPayable = isCorporate ||
                                  (isProfessional && isCurrentPlanExpired) ||
                                  (isStudent && isCurrentPlanExpired);

                              // Show visibility icon on iOS for payable plans
                              if (Platform.isIOS && isPayable) {
                                return Icons.visibility;
                              }

                              // Otherwise show refresh or check/crown icon
                              if (isCurrentPlanExpired) {
                                return Icons.refresh_rounded;
                              }
                              return plan.membership.toLowerCase().contains(
                                    'professional',
                                  )
                                  ? Icons.check_circle_rounded
                                  : FontAwesomeIcons.crown;
                            }(),
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            () {
                              final isCorporate = plan.membership
                                  .toLowerCase()
                                  .contains('corporate');
                              final isProfessional = plan.membership
                                  .toLowerCase()
                                  .contains('professional');
                              final isStudent = plan.membership
                                  .toLowerCase()
                                  .contains('student');
                              final isPayable = isCorporate ||
                                  (isProfessional && isCurrentPlanExpired) ||
                                  (isStudent && isCurrentPlanExpired);

                              // Show "View" on iOS for payable plans
                              if (Platform.isIOS && isPayable) {
                                return 'View';
                              }

                              // Otherwise show upgrade or button text
                              if (isCurrentPlanExpired) {
                                return 'Upgrade';
                              }
                              return _getButtonText(plan.membership);
                            }(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Correct prices for each plan type
  static const Map<String, int> _correctPrices = {
    'student': 6000,
    'professional': 12000,
    'corporate': 60000,
    'institution': 100000,
  };

  /// Get correct price for a plan
  int _getCorrectPrice(PlanModel plan) {
    return _correctPrices[plan.membership.toLowerCase()] ?? plan.price;
  }

  /// Format price with thousands separator
  String _formatPrice(int price) {
    return NumberFormat('#,###').format(price);
  }

  /// Redirect to damakenya.org website
  Future<void> _redirectToWebsite() async {
    final Uri url = Uri.parse('https://damakenya.org/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Get.snackbar(
        'Error',
        'Could not open the website',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
      );
    }
  }

  /// Show payment modal for Corporate plan upgrade
  void _showPaymentModal(BuildContext _, PlanModel plan, bool isDarkMode) {
    debugPrint('_showPaymentModal called for: ${plan.membership}');
    final correctPrice = _getCorrectPrice(plan);
    final isIOS = UnifiedPaymentService.isIOS;

    // Use the State's context instead of passed context
    final ctx = this.context;

    // Pre-populate phone number from storage (Android only)
    String initialPhoneNumber = '';
    if (!isIOS &&
        fetchedPhoneNumber != null &&
        fetchedPhoneNumber!.isNotEmpty) {
      // Extract just the number part (without country code)
      if (fetchedPhoneNumber!.startsWith('+254')) {
        initialPhoneNumber = fetchedPhoneNumber!.substring(4);
        // Also set completePhoneNumber so validation passes without user edit
        completePhoneNumber = fetchedPhoneNumber;
      } else if (fetchedPhoneNumber!.startsWith('254')) {
        initialPhoneNumber = fetchedPhoneNumber!.substring(3);
        completePhoneNumber = '+$fetchedPhoneNumber';
      } else {
        initialPhoneNumber = fetchedPhoneNumber!;
        completePhoneNumber = '+254$fetchedPhoneNumber';
      }
    }

    bool isProcessing = false;

    debugPrint('About to show modal, context mounted: ${ctx.mounted}');

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
      builder: (modalContext) {
        debugPrint('Modal builder called');
        return StatefulBuilder(
          builder: (context, setModalState) {
            debugPrint('StatefulBuilder called');
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade to ${plan.membership}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Amount: KES ${_formatPrice(correctPrice)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Payment method icon - platform specific
                    if (isIOS)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.apple,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Image.asset("images/mpesa.png", height: 50),
                    const SizedBox(height: 20),
                    // Phone number field - Android only (M-Pesa)
                    if (!isIOS)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Phone Number *",
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                                fontWeight: FontWeight.bold,
                                fontSize: kNormalTextSize,
                              ),
                            ),
                            const SizedBox(height: 8),
                            IntlPhoneField(
                              initialValue: initialPhoneNumber,
                              enabled: !isProcessing,
                              decoration: InputDecoration(
                                hintText: "7*******",
                                hintStyle: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                ),
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(
                                    color: kBlue,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              disableLengthCheck: true,
                              validator: (PhoneNumber? phone) {
                                if (phone == null || phone.number.isEmpty) {
                                  return 'Please enter a phone number';
                                }
                                if (phone.number.length != 9) {
                                  return 'Phone number must be exactly 9 digits';
                                }
                                if (!RegExp(
                                  r'^[0-9]+$',
                                ).hasMatch(phone.number)) {
                                  return 'Phone number must contain only digits';
                                }
                                return null;
                              },
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                              dropdownTextStyle: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                              dropdownIcon: Icon(
                                Icons.arrow_drop_down,
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                              initialCountryCode: 'KE',
                              onChanged: (PhoneNumber phone) {
                                completePhoneNumber = phone.completeNumber;
                              },
                              onCountryChanged: (country) {
                                countryCode = '+${country.dialCode}';
                              },
                            ),
                          ],
                        ),
                      ),
                    if (!isIOS) const SizedBox(height: 20),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: SizedBox(
                          width: double.infinity,
                          child:
                              isProcessing
                                  ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isIOS
                                            ? Colors.black.withValues(
                                              alpha: 0.7,
                                            )
                                            : kBlue.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: kWhite,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isIOS ? 'Opening...' : 'Processing Payment...',
                                        style: const TextStyle(
                                          color: kWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : isIOS
                                // View button for iOS
                                ? GestureDetector(
                                  onTap: () async {
                                    final Uri url = Uri.parse('https://damakenya.org/');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Could not open the website',
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 3),
                                        margin: const EdgeInsets.all(10),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kBlue,
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'View',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                // M-Pesa button for Android
                                : CustomButton(
                                  callBackFunction: () async {
                                    if (completePhoneNumber != null &&
                                        completePhoneNumber!.length >= 10) {
                                      phoneNumber = completePhoneNumber!;

                                      setModalState(() {
                                        isProcessing = true;
                                      });

                                      final result = await _processPayment(
                                        plan,
                                      );

                                      setModalState(() {
                                        isProcessing = false;
                                      });

                                      if (result['success'] == true) {
                                        if (modalContext.mounted) {
                                          Navigator.pop(modalContext);
                                        }
                                        if (context.mounted) {
                                          showSuccessBottomSheet(
                                            context,
                                            plan.membership,
                                            'Payment initiated',
                                            'KES ${_formatPrice(correctPrice)}',
                                            isDarkMode,
                                          );
                                        }
                                      } else {
                                        // Show error above the modal using GetX
                                        Get.snackbar(
                                          'Payment Error',
                                          result['error'] ??
                                              'Payment failed. Please try again.',
                                          snackPosition: SnackPosition.TOP,
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                          duration: const Duration(
                                            seconds: 4,
                                          ),
                                          margin: const EdgeInsets.all(10),
                                        );
                                      }
                                    } else {
                                      Get.snackbar(
                                        'Invalid Phone',
                                        'Please enter a valid phone number',
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        duration: const Duration(
                                          seconds: 3,
                                        ),
                                        margin: const EdgeInsets.all(10),
                                      );
                                    }
                                  },
                                  label: "Confirm Payment",
                                  backgroundColor: kBlue,
                                ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    debugPrint('Modal shown successfully');
  }

  /// Process payment and return result with success status and error message
  Future<Map<String, dynamic>> _processPayment(PlanModel plan) async {
    try {
      final correctPrice = _getCorrectPrice(plan);
      final isIOS = UnifiedPaymentService.isIOS;

      // Validate phone number for Android (M-Pesa)
      if (!isIOS && phoneNumber.isEmpty) {
        return {'success': false, 'error': 'Please enter a phone number'};
      }

      debugPrint(
        '[PlansScreen] Processing ${UnifiedPaymentService.paymentMethodName} payment for ${plan.membership} - KES $correctPrice',
      );
      if (!isIOS) {
        debugPrint('[PlansScreen] Phone: $phoneNumber');
      }

      // Use UnifiedPaymentService for platform-specific payment
      final result = await UnifiedPaymentService.pay(
        objectId: plan.id,
        model: 'Plan',
        amount: correctPrice,
        itemName: plan.membership,
        phoneNumber: isIOS ? null : phoneNumber,
      );

      if (result.success) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': result.errorMessage ?? 'Payment failed. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }
}
