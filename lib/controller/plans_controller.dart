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

  Future<void> fetchPlans() async {
    isLoading.value = true;
    try {
      List<PlanModel> fetchedPlans = await _plansService.getPlans();
      plansList.assignAll(fetchedPlans);

      // After fetching plans, get current user plan
      await getCurrentUserPlan();
    } catch (e) {
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

  // Apply default professional membership
  Future<void> _applyDefaultProfessionalMembership() async {
    try {
      // Find professional plan
      final professionalPlan = plansList.firstWhereOrNull(
        (plan) => plan.membership.toLowerCase().contains('professional'),
      );

      if (professionalPlan != null) {
        // Set expiry to 1 year from now
        final expiryDate = DateTime.now().add(Duration(days: 365));
        final expiryString = expiryDate.toIso8601String();

        // Store default membership data
        await StorageService.storeData({
          'hasMembership': true,
          'membershipId': professionalPlan.id,
          'membershipExp': expiryString,
        });

        currentMembershipId.value = professionalPlan.id;
        currentUserPlan.value = 'professional';
        hasActivePlan.value = true;
      }
    } catch (e) {
      debugPrint('Error applying default professional membership: $e');
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
        id: 'professional_plan_id',
        membership: 'Professional',
        type: 'premium',
        price: 5000,
        included: ['All features', 'Priority support', 'Advanced training'],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      PlanModel(
        id: 'student_plan_id',
        membership: 'Student',
        type: 'basic',
        price: 2000,
        included: ['Basic features', 'Training access', 'Community support'],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      PlanModel(
        id: 'corporate_plan_id',
        membership: 'Corporate',
        type: 'enterprise',
        price: 15000,
        included: ['All features', 'Dedicated support', 'Custom training'],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];

    plansList.assignAll(defaultPlans);
  }

  // Method to get membership name (similar to your existing function)
  String getMembershipName() {
    try {
      if (currentMembershipId.value.isNotEmpty) {
        final plan = plansList.firstWhereOrNull(
          (plan) => plan.id == currentMembershipId.value,
        );
        if (plan != null) {
          return '${plan.membership} Membership';
        }
      }
      return 'No Active Membership';
    } catch (e) {
      return 'No Active Membership';
    }
  }

  // Method to refresh plan status after payment
  Future<void> refreshPlanStatus() async {
    await getCurrentUserPlan();
  }

  // Check if user has specific plan
  bool hasSpecificPlan(String planType) {
    return currentUserPlan.value.toLowerCase() == planType.toLowerCase() &&
        hasActivePlan.value;
  }

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }
}
