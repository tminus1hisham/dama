import 'package:dama/models/referral_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class ReferralController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  var isLoading = false.obs;
  var isSendingInvite = false.obs;
  var referralData = Rxn<ReferralModel>();
  var referralCode = ''.obs;
  var referralLink = ''.obs;
  var totalReferrals = 0.obs;
  var successfulReferrals = 0.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyReferrals();
  }

  Future<void> fetchMyReferrals() async {
    try {
      debugPrint(
        '🔴🔴🔴 [ReferralController] fetchMyReferrals() CALLED 🔴🔴🔴',
      );
      isLoading.value = true;
      final data = await _apiService.getMyReferrals();

      // Log raw response for debugging
      debugPrint('📋 Raw API response type: ${data.runtimeType}');
      debugPrint('📋 Raw API keys: ${data.keys.toList()}');
      debugPrint('📋 ========== FULL API RESPONSE START ==========');
      // Dump each field separately for readability
      for (var key in data.keys) {
        debugPrint(
          '📋 [$key]: type=${data[key].runtimeType}, value=${data[key].toString().substring(0, math.min(200, data[key].toString().length))}',
        );
      }
      debugPrint('📋 ========== FULL API RESPONSE END ==========');

      // Check for nested structures
      if (data.containsKey('data')) {
        debugPrint('⚠️  Found "data" key, type: ${data['data'].runtimeType}');
        debugPrint('⚠️  Data value: ${data['data']}');
      }
      if (data.containsKey('result')) {
        debugPrint(
          '⚠️  Found "result" key, type: ${data['result'].runtimeType}',
        );
        debugPrint('⚠️  Result value: ${data['result']}');
      }

      // Parse the response - check if data has nested structure
      Map<String, dynamic> referralDataRaw = data;

      // If the response is wrapped in a 'data' or 'result' key, unwrap it
      if (data.containsKey('data') && data['data'] is Map) {
        referralDataRaw = data['data'] as Map<String, dynamic>;
        debugPrint('⚠️  Unwrapped nested data structure');
      } else if (data.containsKey('result') && data['result'] is Map) {
        referralDataRaw = data['result'] as Map<String, dynamic>;
        debugPrint('⚠️  Unwrapped from result key');
      }

      debugPrint('📋 Extracted data keys: ${referralDataRaw.keys.toList()}');
      debugPrint(
        '📋 Extracted referrals field exists?: ${referralDataRaw.containsKey('referrals')}',
      );
      debugPrint(
        '📋 Extracted referrals type: ${referralDataRaw['referrals']?.runtimeType}',
      );
      debugPrint('📋 Extracted referrals: ${referralDataRaw['referrals']}');
      debugPrint(
        '📋 Total referrals field: ${referralDataRaw['totalReferrals']}',
      );
      debugPrint(
        '📋 Successful referrals field: ${referralDataRaw['successfulReferrals']}',
      );

      // Parse the response
      final referral = ReferralModel.fromJson(referralDataRaw);
      referralData.value = referral;
      referralCode.value = referral.referralCode ?? '';
      referralLink.value = referral.referralLink ?? '';
      totalReferrals.value = referral.totalReferrals ?? 0;
      successfulReferrals.value = referral.successfulReferrals ?? 0;

      debugPrint(
        '✅ Referral data loaded: Code=${referralCode.value}, Total=${totalReferrals.value}, Successful=${successfulReferrals.value}',
      );
      debugPrint(
        '📊 Referrals list: ${referralData.value?.referrals?.length ?? 0} items',
      );
      if (referralData.value?.referrals != null) {
        for (var i = 0; i < referralData.value!.referrals!.length; i++) {
          final ref = referralData.value!.referrals![i];
          debugPrint(
            '  [$i] ${ref.referredUserEmail ?? ref.referredUserId} - ${ref.status}',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching referrals: $e');
      debugPrint('❌ Stack trace: $e');
      // Set empty referral data as fallback to prevent null check errors
      referralData.value = ReferralModel(
        totalReferrals: 0,
        successfulReferrals: 0,
        referrals: [],
      );
      errorMessage.value = 'Failed to load referrals';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendInvite(String emailOrPhone) async {
    try {
      isSendingInvite.value = true;
      errorMessage.value = '';
      await _apiService.sendReferralInvite(emailOrPhone);
      debugPrint('✅ Referral invite sent to: $emailOrPhone');
      // Refresh the referrals list after sending invite
      await fetchMyReferrals();
      return true;
    } catch (e) {
      final error = e.toString();
      errorMessage.value = error.replaceAll('Exception: ', '');
      debugPrint('❌ Error sending referral invite: $error');
      return false;
    } finally {
      isSendingInvite.value = false;
    }
  }
}
