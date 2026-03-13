import 'package:dama/models/certificate_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificateController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var certificates = <CertificateModel>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserCertificates();
  }

  Future<void> fetchUserCertificates() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final userId = await StorageService.getData('userId');
      if (userId == null) {
        errorMessage.value = 'User not logged in';
        return;
      }

      try {
        final result = await _apiService.getUserCertificates(userId);
        certificates.assignAll(result);
      } catch (e) {
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection refused')) {
          final cachedCertificates = await _loadCachedCertificates();
          if (cachedCertificates.isNotEmpty) {
            certificates.assignAll(cachedCertificates);
            Get.snackbar(
              'Offline Mode',
              'Showing cached certificates. Connect to internet to sync.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 4),
            );
          } else {
            Get.snackbar(
              'Offline Mode',
              'Unable to load certificates. Please check your internet connection.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 4),
            );
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      errorMessage.value = 'Failed to load certificates: $e';
      Get.snackbar(
        'Error',
        'Failed to load certificates',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<CertificateModel?> generateCertificate(
    String trainingId,
    String userId,
  ) async {
    try {
      isLoading.value = true;

      final isEligible = await checkCertificateEligibility(trainingId);
      if (!isEligible) {
        throw Exception(
          'Certificate generation failed: training not completed',
        );
      }

      final certificate = await _apiService.generateCertificate(
        trainingId,
        userId,
      );

      if (certificate != null) {
        await fetchUserCertificates();
        Get.snackbar(
          'Success',
          'Certificate generated successfully!',
          snackPosition: SnackPosition.BOTTOM,
        );
        return certificate;
      } else {
        throw Exception('Failed to generate certificate - API returned null');
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('401') ||
          e.toString().contains('403') ||
          e.toString().contains('Session expired')) {
        Get.snackbar(
          'Session Expired',
          'Your session has expired. Please log in again.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        Get.snackbar(
          'Offline Mode',
          'Certificate generation requires internet connection.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to generate certificate: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<CertificateModel?> generateCertificateSilent(
    String trainingId,
    String userId,
  ) async {
    try {
      isLoading.value = true;
      final isEligible = await checkCertificateEligibility(trainingId);
      if (!isEligible) return null;

      final certificate = await _apiService.generateCertificate(
        trainingId,
        userId,
      );
      if (certificate != null) {
        await fetchUserCertificates();
        return certificate;
      }
      return null;
    } catch (e) {
      debugPrint('[Silent] Error in generateCertificateSilent: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── DOWNLOAD: server returns HTML, so open in browser for user to save ────
  Future<void> downloadCertificate(String certificateNumber) async {
    final url = '$BASE_URL/certificates/download/$certificateNumber';
    debugPrint('[Certificate] Opening for download: $url');
    await _openInBrowser(url);
  }

  // ── SHARE: share the certificate URL directly via OS share sheet ──────────
  Future<void> shareCertificate(String certificateNumber) async {
    final url = '$BASE_URL/certificates/download/$certificateNumber';
    debugPrint('[Certificate] Sharing URL: $url');
    try {
      await Share.share(
        'Here is my training certificate from DAMA Kenya:\n$url',
        subject: 'My Training Certificate',
      );
    } catch (e) {
      debugPrint('Certificate share error: $e');
      Get.snackbar(
        'Share Failed',
        'Could not share certificate. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        Get.snackbar(
          'Error',
          'Could not open certificate. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error opening browser: $e');
      Get.snackbar(
        'Error',
        'Could not open certificate: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<bool> checkCertificateEligibility(String trainingId) async {
    try {
      final userId = await StorageService.getData('userId');
      if (userId == null) return false;

      final trainingDetails = await _apiService.getUserTrainingDetails(
        trainingId,
      );
      final training = trainingDetails['training'];
      final userData = trainingDetails['userData'];

      if (userData?['certificate']?['issued'] == true) return true;

      final trainingStatus =
          training?['status']?.toString().toLowerCase() ?? '';
      if (trainingStatus == 'completed') return true;

      final analytics = training?['analytics'];
      final totalSessions = analytics?['totalSessions'] ?? 0;
      final sessionsCompleted = analytics?['sessionsCompleted'] ?? 0;
      final attendanceRate = userData?['progress']?['attendanceRate'] ?? 0;
      final minimumAttendance =
          training?['certificateConfig']?['minimumAttendance'] ?? 80;

      final allSessionsDone =
          totalSessions > 0 && sessionsCompleted >= totalSessions;
      return allSessionsDone && attendanceRate >= minimumAttendance;
    } catch (e) {
      debugPrint('Error checking eligibility: $e');
      return true; // fail open
    }
  }

  Future<List<CertificateModel>> _loadCachedCertificates() async {
    return [];
  }

  Future<void> refreshCertificates() async {
    await fetchUserCertificates();
  }
}
