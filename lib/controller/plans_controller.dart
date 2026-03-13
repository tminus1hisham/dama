import 'package:dama/models/plans_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlansController extends GetxController {
  var plansList = <PlanModel>[].obs;
  var isLoading = false.obs;
  var isLoadingPlanStatus = false.obs;

  // Simple observable for current user plan
  var currentUserPlan = ''.obs;
  var currentMembershipId = ''.obs;
  var hasActivePlan = false.obs;

  final ApiService _plansService = ApiService();

  // Correct prices for each plan type
  static const Map<String, int> _correctPrices = {
    'student': 6000,
    'professional': 12000,
    'corporate': 60000,
    'institution': 100000,
  };

  Future<void> fetchPlans() async {
    isLoading.value = true;
    try {
      final resp = await _plansService.getPlans();
      debugPrint('[PlansController] Fetching plans from API...');
      if (resp != null && resp['success'] == true) {
        // API returns 'plans' not 'data'
        final data = (resp['plans'] ?? resp['data']) as List<dynamic>? ?? [];
        debugPrint('[PlansController] Received ${data.length} plans from API');
        List<PlanModel> fetchedPlans =
            data
                .map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
                .toList();

        // Log the prices
        for (var plan in fetchedPlans) {
          debugPrint('[PlansController] ${plan.membership}: KES ${plan.price}');
        }

        // Use API prices directly - they are correct
        plansList.assignAll(fetchedPlans);
      } else {
        debugPrint('[PlansController] API failed, using default plans');
        // API failed, use default plans
        await _loadDefaultPlans();
      }

      // After fetching plans, get current user plan
      await getCurrentUserPlan();
    } catch (e) {
      debugPrint('[PlansController] Error fetching plans: $e');
      // If server is unreachable, try to use cached/default plans
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        // Use default plans for offline mode
        await _loadDefaultPlans();
        await getCurrentUserPlan();
      } else {
        // Only show snackbar if not unauthorized (dialog will be shown)
        if (!e.toString().contains('Unauthorized')) {
          _showErrorSnackbar("Error", "Failed to fetch plans");
        }
        // Still load defaults if fetch fails
        await _loadDefaultPlans();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _showErrorSnackbar(String title, String message) {
    Future.delayed(Duration.zero, () {
      if (Get.isSnackbarOpen || Get.context == null) return;
      try {
        Get.snackbar(
          title,
          message,
          margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
          colorText: kWhite,
          backgroundColor: kRed.withOpacity(0.9),
        );
      } catch (e) {
        // Fallback: print to console if snackbar fails
        debugPrint('Failed to show snackbar: $e');
      }
    });
  }

  // Get current user plan using stored membership ID
  Future<String> getCurrentUserPlan() async {
    isLoadingPlanStatus.value = true;
    try {
      // Get membershipId from storage
      String? membershipId = await StorageService.getData('membershipId');
      bool? hasMembership = await StorageService.getData('hasMembership');
      String? membershipExp = await StorageService.getData('membershipExp');

      print(
        '[PlansController] getCurrentUserPlan - membershipId: $membershipId, hasMembership: $hasMembership, membershipExp: $membershipExp',
      );

      // Check if user has active membership
      bool hasActiveMembership =
          membershipId != null &&
          membershipId.isNotEmpty &&
          hasMembership == true &&
          membershipExp != null &&
          DateTime.parse(membershipExp).isAfter(DateTime.now());

      print('[PlansController] hasActiveMembership: $hasActiveMembership');

      if (!hasActiveMembership) {
        // Apply default professional membership
        print('[PlansController] Applying default professional membership');
        await _applyDefaultProfessionalMembership();
        return await _getDefaultPlan();
      }

      currentMembershipId.value = membershipId;

      // Find the plan with matching ID
      final plan = plansList.firstWhereOrNull(
        (plan) => plan.id == membershipId,
      );

      if (plan != null) {
        currentUserPlan.value = plan.membership.toLowerCase();
        hasActivePlan.value = true;
        return plan.membership.toLowerCase();
      } else {
        // If plan not found, apply default
        await _applyDefaultProfessionalMembership();
        return await _getDefaultPlan();
      }
    } catch (e) {
      // On error, try to apply default
      try {
        await _applyDefaultProfessionalMembership();
        return await _getDefaultPlan();
      } catch (defaultError) {
        currentUserPlan.value = '';
        currentMembershipId.value = '';
        hasActivePlan.value = false;
        return '';
      }
    } finally {
      isLoadingPlanStatus.value = false;
    }
  }

  // Apply default professional membership (FREE FOR ONE YEAR)
  Future<void> _applyDefaultProfessionalMembership() async {
    try {
      // Find professional plan
      final professionalPlan = plansList.firstWhereOrNull(
        (plan) => plan.membership.toLowerCase().contains('professional'),
      );

      if (professionalPlan != null) {
        // Set membership expiry to 1 year from now
        final membershipExpiryDate = DateTime.now().add(Duration(days: 365));
        final membershipExpiryString = membershipExpiryDate.toIso8601String();

        // Professional membership is FREE for 1 year from signup
        final freeUntilDate = membershipExpiryDate;
        final freeUntilString = freeUntilDate.toIso8601String();

        debugPrint(
          '[PlansController] Applying professional membership - FREE until $freeUntilString',
        );

        // Store default membership data with free period
        await StorageService.storeData({
          'hasMembership': true,
          'membershipId': professionalPlan.id,
          'membershipExp': membershipExpiryString,
          'freeUntil': freeUntilString,
          'membershipStartDate': DateTime.now().toIso8601String(),
        });

        currentMembershipId.value = professionalPlan.id;
        currentUserPlan.value = 'professional';
        hasActivePlan.value = true;
      }
    } catch (e) {
      debugPrint('Error applying default professional membership: $e');
    }
  }

  /// Check if professional membership is still free
  /// 3-Factor Check:
  /// 1. hasMembership == true
  /// 2. memberId exists (not null/empty)
  /// 3. membershipExp/freeUntil not expired
  Future<bool> isProfessionalMembershipFree() async {
    try {
      // Factor 1: Check hasMembership flag
      final hasMembership = await StorageService.getData('hasMembership');
      if (hasMembership != true) {
        return false;
      }

      // Factor 2: Check memberId exists
      final memberId = await StorageService.getData('memberId');
      if (memberId == null || memberId.toString().isEmpty) {
        return false;
      }

      // Factor 3: Check expiry date (use freeUntil or membershipExp)
      var expiryDateStr = await StorageService.getData('freeUntil');
      expiryDateStr ??= await StorageService.getData('membershipExp');

      if (expiryDateStr == null || expiryDateStr.toString().isEmpty) {
        return false;
      }

      try {
        final expiryDate = DateTime.parse(expiryDateStr.toString());
        final isFree = DateTime.now().isBefore(expiryDate);

        // Optionally validate with API (async, non-blocking)
        _validateWithApiAsync();

        return isFree;
      } catch (e) {
        debugPrint('Error parsing expiry date from local storage: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking if professional membership is free: $e');
      return false;
    }
  }

  /// Async API validation (non-blocking, for security)
  Future<void> _validateWithApiAsync() async {
    try {
      final response = await _plansService.getUserMembershipWithFreeTrial();
      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final apiFreeTrial = data['freeUntil'];

        if (apiFreeTrial != null) {
          // Sync API data with local storage if different
          final localFreeUntil = await StorageService.getData('freeUntil');
          if (localFreeUntil != apiFreeTrial) {
            debugPrint(
              '[PlansController] Syncing free trial date from API: $apiFreeTrial',
            );
            await StorageService.storeData({'freeUntil': apiFreeTrial});
          }
        }
      }
    } catch (e) {
      // Silent fail - don't block on API validation
      debugPrint('Background API validation failed (non-blocking): $e');
    }
  }

  /// Get days remaining for free professional membership
  /// Returns 0 if not free or already expired
  Future<int> getDaysRemainingInFreePeriod() async {
    try {
      // First check if membership is free
      final isFree = await isProfessionalMembershipFree();
      if (!isFree) return 0;

      // Get expiry date
      var expiryDateStr = await StorageService.getData('freeUntil');
      expiryDateStr ??= await StorageService.getData('membershipExp');

      if (expiryDateStr == null || expiryDateStr.toString().isEmpty) return 0;

      try {
        final expiryDate = DateTime.parse(expiryDateStr.toString());
        final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
        return daysRemaining > 0 ? daysRemaining : 0;
      } catch (e) {
        debugPrint('Error parsing expiry date: $e');
        return 0;
      }
    } catch (e) {
      debugPrint('Error getting days remaining in free period: $e');
      return 0;
    }
  }

  /// Get the effective price for a plan (0 if free, otherwise actual price)
  /// Fetches free trial status from API
  Future<int> getEffectivePrice(PlanModel plan) async {
    // Always use correct hardcoded prices, not API prices
    final correctPrice =
        _correctPrices[plan.membership.toLowerCase()] ?? plan.price;

    // For professional membership, check if it's currently free via API
    if (plan.membership.toLowerCase().contains('professional')) {
      final isFree = await isProfessionalMembershipFree();
      return isFree ? 0 : correctPrice;
    }
    return correctPrice;
  }

  /// Get a summary of professional membership free status
  /// Uses 3-factor validation: hasMembership, memberId, and expiry date
  Future<Map<String, dynamic>> getProfessionalMembershipStatus() async {
    try {
      debugPrint('[PlansController] Getting professional membership status...');

      // Check if membership is free using 3-factor validation
      final isFree = await isProfessionalMembershipFree();

      if (!isFree) {
        return {
          'isFree': false,
          'daysRemaining': 0,
          'startDate': null,
          'freeUntilDate': null,
          'expiryDate': null,
        };
      }

      // Get expiry date
      var expiryDateStr = await StorageService.getData('freeUntil');
      expiryDateStr ??= await StorageService.getData('membershipExp');

      if (expiryDateStr != null && expiryDateStr.toString().isNotEmpty) {
        try {
          final expiryDate = DateTime.parse(expiryDateStr.toString());
          final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
          final startDate = await StorageService.getData('membershipStartDate');

          debugPrint('[PlansController] Professional membership is free:');
          debugPrint('  Days Remaining: $daysRemaining');
          debugPrint('  Expires: $expiryDateStr');

          // Async API validation (non-blocking)
          _validateWithApiAsync();

          return {
            'isFree': true,
            'daysRemaining': daysRemaining > 0 ? daysRemaining : 0,
            'startDate': startDate,
            'freeUntilDate': expiryDateStr,
            'expiryDate': expiryDateStr,
          };
        } catch (e) {
          debugPrint('Error parsing expiry date: $e');
        }
      }

      // No valid expiry date found
      return {
        'isFree': false,
        'daysRemaining': 0,
        'startDate': null,
        'freeUntilDate': null,
        'expiryDate': null,
      };
    } catch (e) {
      debugPrint('Error getting professional membership status: $e');
      return {
        'isFree': false,
        'daysRemaining': 0,
        'startDate': null,
        'freeUntilDate': null,
        'expiryDate': null,
      };
    }
  }

  // Get default plan (professional)
  Future<String> _getDefaultPlan() async {
    return 'professional';
  }

  Future<void> _loadDefaultPlans() async {
    // Create default plans for offline mode
    final defaultPlans = [
      PlanModel(
        id: 'student_plan_id',
        membership: 'Student',
        type: 'basic',
        price: 6000,
        included: [
          'Latest News Updates',
          'Mentorship Opportunities',
          'Latest Job Updates',
          'Access To Training Discounts',
          'Access To Data Resources',
        ],
        benefits: [
          'Stay updated with industry news and trends',
          'Get guidance from experienced professionals',
          'Never miss career opportunities',
          'Save on professional development costs',
          'Access premium industry resources',
        ],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      PlanModel(
        id: 'professional_plan_id',
        membership: 'Professional',
        type: 'premium',
        price: 12000,
        included: [
          'Exclusive Member Area Access',
          'Training & Resources',
          'Event Discounts',
          'Networking Opportunities',
          'Job Platform & Forum Access',
          'Access To View Certificate',
        ],
        benefits: [
          'Access exclusive tools and resources',
          'Advance your skills and career growth',
          'Attend events at special member rates',
          'Build meaningful professional relationships',
          'Explore job and opportunity listings',
          'Showcase your achievements with certificates',
        ],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      PlanModel(
        id: 'corporate_plan_id',
        membership: 'Corporate',
        type: 'enterprise',
        price: 60000,
        included: [
          'Company Certification',
          'High Visibility',
          'Event Perks',
          'Premium Training',
          'Exclusive Networking',
        ],
        benefits: [
          'Certify your entire team\'s expertise',
          'Increase your company\'s visibility in the industry',
          'Unlock exclusive event access and benefits',
          'Invest in team development and growth',
          'Build strong industry partnerships and connections',
        ],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];

    plansList.assignAll(defaultPlans);
  }

  // Method to get membership name (similar to your existing function)
  String getMembershipName() {
    try {
      // First try by ID
      if (currentMembershipId.value.isNotEmpty) {
        final plan = plansList.firstWhereOrNull(
          (plan) => plan.id == currentMembershipId.value,
        );
        if (plan != null) {
          return plan.membership;
        }
      }

      // Fallback: try by currentUserPlan name (set by getCurrentUserPlan)
      if (currentUserPlan.value.isNotEmpty) {
        final plan = plansList.firstWhereOrNull(
          (plan) =>
              plan.membership.toLowerCase() ==
              currentUserPlan.value.toLowerCase(),
        );
        if (plan != null) {
          return plan.membership;
        }
        // If we have a plan type but can't find it in list, capitalize and return it
        return currentUserPlan.value[0].toUpperCase() +
            currentUserPlan.value.substring(1);
      }

      // Final fallback: check hasActivePlan
      if (hasActivePlan.value) {
        return 'Professional'; // Default to Professional if active but unknown
      }

      return 'No Active Membership';
    } catch (e) {
      return 'No Active Membership';
    }
  }

  /// Method to refresh plan status after payment
  Future<void> refreshPlanStatus() async {
    await getCurrentUserPlan();
  }

  /// Validate free trial from server and sync with local storage
  /// This ensures the free trial expiry date matches the server
  Future<bool> validateAndSyncFreeTrialFromServer() async {
    try {
      debugPrint('[PlansController] Validating free trial with server...');

      final response = await _plansService.getUserMembershipWithFreeTrial();

      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;

        if (data['freeTrialActive'] == true) {
          final serverFreeUntil = data['freeUntil'];
          final serverMembershipStart = data['membershipStartDate'];

          if (serverFreeUntil != null) {
            // Sync with local storage
            await StorageService.storeData({
              'freeUntil': serverFreeUntil,
              'membershipStartDate': serverMembershipStart,
            });

            debugPrint(
              '[PlansController] Free trial synced from server: $serverFreeUntil',
            );
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error validating free trial from server: $e');
      return false;
    }
  }

  /// Check if user has specific plan
  bool hasSpecificPlan(String planType) {
    return currentUserPlan.value.toLowerCase() == planType.toLowerCase() &&
        hasActivePlan.value;
  }

  /// Check if membership has expired (free trial or paid)
  /// Returns true if membership was active but has now expired
  Future<bool> isMembershipExpired() async {
    try {
      final hasMembership = await StorageService.getData('hasMembership');

      // If user never had membership, it's not "expired" - just inactive
      if (hasMembership != true && hasMembership != 'true') {
        return false;
      }

      // Check freeUntil first (for free trial users)
      var expiryDateStr = await StorageService.getData('freeUntil');
      expiryDateStr ??= await StorageService.getData('membershipExp');

      if (expiryDateStr == null || expiryDateStr.toString().isEmpty) {
        return false;
      }

      try {
        final expiryDate = DateTime.parse(expiryDateStr.toString());
        final isExpired = DateTime.now().isAfter(expiryDate);

        if (isExpired) {
          debugPrint('[PlansController] Membership EXPIRED on $expiryDateStr');
        }

        return isExpired;
      } catch (e) {
        debugPrint('Error parsing expiry date: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking if membership expired: $e');
      return false;
    }
  }

  /// Check if user has a VALID (non-expired) membership
  /// This is the primary method to check for premium access
  /// Returns true only if membership is active AND not expired
  Future<bool> hasValidMembership() async {
    try {
      // Factor 1: Check hasMembership flag
      final hasMembership = await StorageService.getData('hasMembership');
      if (hasMembership != true && hasMembership != 'true') {
        debugPrint(
          '[PlansController] hasValidMembership: false (no membership flag)',
        );
        return false;
      }

      // Factor 2: Check memberId exists
      final memberId = await StorageService.getData('memberId');
      final membershipId = await StorageService.getData('membershipId');
      if ((memberId == null || memberId.toString().isEmpty) &&
          (membershipId == null || membershipId.toString().isEmpty)) {
        debugPrint(
          '[PlansController] hasValidMembership: false (no member ID)',
        );
        return false;
      }

      // Factor 3: Check not expired
      final isExpired = await isMembershipExpired();
      if (isExpired) {
        debugPrint('[PlansController] hasValidMembership: false (EXPIRED)');
        // Update local storage to reflect expired status
        await StorageService.storeData({'hasMembership': false});
        hasActivePlan.value = false;
        return false;
      }

      debugPrint('[PlansController] hasValidMembership: true');
      return true;
    } catch (e) {
      debugPrint('Error checking valid membership: $e');
      return false;
    }
  }

  /// Get membership expiry information for UI display
  Future<Map<String, dynamic>> getMembershipExpiryInfo() async {
    try {
      var expiryDateStr = await StorageService.getData('freeUntil');
      expiryDateStr ??= await StorageService.getData('membershipExp');

      if (expiryDateStr == null || expiryDateStr.toString().isEmpty) {
        return {
          'hasExpiry': false,
          'isExpired': false,
          'expiryDate': null,
          'daysRemaining': 0,
          'formattedExpiry': 'No expiry date',
        };
      }

      final expiryDate = DateTime.parse(expiryDateStr.toString());
      final now = DateTime.now();
      final isExpired = now.isAfter(expiryDate);
      final daysRemaining = isExpired ? 0 : expiryDate.difference(now).inDays;

      // Format the date nicely
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final formattedDate =
          '${months[expiryDate.month - 1]} ${expiryDate.day}, ${expiryDate.year}';

      return {
        'hasExpiry': true,
        'isExpired': isExpired,
        'expiryDate': expiryDate,
        'daysRemaining': daysRemaining,
        'formattedExpiry': formattedDate,
      };
    } catch (e) {
      debugPrint('Error getting membership expiry info: $e');
      return {
        'hasExpiry': false,
        'isExpired': false,
        'expiryDate': null,
        'daysRemaining': 0,
        'formattedExpiry': 'Error',
      };
    }
  }

  /// Show renewal prompt dialog when membership has expired
  /// Call this when user tries to access premium content with expired membership
  void showRenewalPrompt({String? featureName}) {
    final context = Get.context;
    if (context == null) return;

    final feature = featureName ?? 'this feature';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.timer_off_rounded, color: kOrange, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Membership Expired',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your free professional membership has expired.',
              style: TextStyle(fontSize: 15, color: kGrey),
            ),
            const SizedBox(height: 12),
            Text(
              'To continue accessing $feature, please renew your membership.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, color: kBlue, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Professional Membership\nKES 12,000/year',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Later', style: TextStyle(color: kGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Get.back();
              // Navigate to plans screen
              Get.toNamed('/plans');
            },
            child: const Text('Renew Now', style: TextStyle(color: kWhite)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Check membership and show renewal prompt if expired
  /// Returns true if membership is valid, false if expired (and shows prompt)
  Future<bool> checkMembershipOrPrompt({String? featureName}) async {
    final isValid = await hasValidMembership();

    if (!isValid) {
      final wasExpired = await isMembershipExpired();
      if (wasExpired) {
        showRenewalPrompt(featureName: featureName);
      }
      return false;
    }

    return true;
  }

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }
}
