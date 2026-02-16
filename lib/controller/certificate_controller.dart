import 'package:dama/models/certificate_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

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

      // Try to fetch from server
      try {
        final result = await _apiService.getUserCertificates(userId);
        certificates.assignAll(result);
      } catch (e) {
        // If server is unreachable, show offline message
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection refused')) {
          // Try to load cached certificates from local storage
          final cachedCertificates = await _loadCachedCertificates();
          if (cachedCertificates.isNotEmpty) {
            certificates.assignAll(cachedCertificates);
            Get.snackbar(
              'Offline Mode',
              'Showing cached certificates. Connect to internet to sync latest certificates.',
              snackPosition: SnackPosition.BOTTOM,
              duration: Duration(seconds: 4),
            );
          } else {
            Get.snackbar(
              'Offline Mode',
              'Unable to load certificates. Please check your internet connection.',
              snackPosition: SnackPosition.BOTTOM,
              duration: Duration(seconds: 4),
            );
          }
        } else {
          // Re-throw other errors
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

      // First check if user is eligible for certificate (with offline fallback)
      final isEligible = await checkCertificateEligibility(trainingId);
      print('Is eligible: $isEligible');
      if (!isEligible) {
        print(
          'User is not eligible for certificate due to strict rules',
        );
        throw Exception('Certificate generation failed: strict rules applied - training not fully completed');
      }

      // Try to generate certificate from server
      try {
        final certificate = await _apiService.generateCertificate(
          trainingId,
          userId,
        );

        if (certificate != null) {
          // Refresh certificates list
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
        // If server is unreachable, show offline message but don't block
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection refused')) {
          Get.snackbar(
            'Offline Mode',
            'Certificate generation requires internet connection. Your training completion has been recorded locally.',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 5),
          );

          // Create a local certificate record for offline use
          final localCertificate = CertificateModel(
            id:
                'offline_${trainingId}_${userId}_${DateTime.now().millisecondsSinceEpoch}',
            certificateNumber:
                'OFFLINE-${DateTime.now().millisecondsSinceEpoch}',
            trainingId: trainingId,
            trainingTitle:
                'Training Course', // Would need to get from local storage
            userId: userId,
            userName: 'User', // Would need to get from local storage
            issuerName: 'DAMA KENYA',
            issueDate: DateTime.now(),
            completionDate: DateTime.now(),
            trainingHours: 0,
            instructorName: 'Training Instructor',
            qrCode: '',
            status: 'pending_sync',
          );

          // Add to local certificates list
          certificates.add(localCertificate);

          return localCertificate;
        } else {
          // Re-throw other errors
          rethrow;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate certificate: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> downloadCertificate(String certificateNumber) async {
    try {
      isLoading.value = true;
      
      final filePath = await _apiService.downloadCertificate(certificateNumber);
      
      if (filePath != null) {
        // Share the downloaded certificate
        await _shareDownloadedCertificate(filePath);
        return filePath;
      } else {
        throw Exception('Download failed - no file path returned');
      }
      
    } catch (e) {
      debugPrint('Certificate download error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to share the downloaded certificate
  Future<void> _shareDownloadedCertificate(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Certificate downloaded from DAMA Kenya',
      );
    } catch (e) {
      debugPrint('Error sharing certificate: $e');
      Get.snackbar(
        'Share Error',
        'Could not share certificate file',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> checkCertificateEligibility(String trainingId) async {
    try {
      print('=== CHECKING CERTIFICATE ELIGIBILITY ===');
      print('Training ID: $trainingId');
      final userId = await StorageService.getData('userId');
      print('User ID: $userId');
      if (userId == null) return false;

      final trainingDetails = await _apiService.getUserTrainingDetails(
        trainingId,
      );
      print('Training details: $trainingDetails');
      final certificateConfig = trainingDetails['certificateConfig'];
      print('Certificate config: $certificateConfig');

      if (certificateConfig == null || certificateConfig['criteria'] == null) {
        print(
          'Certificate config or criteria is null - allowing certificate generation',
        );
        // If no specific criteria, allow certificate generation
        return true;
      }

      final config = CertificateConfig.fromJson(certificateConfig);
      print('Parsed config criteria: ${config.criteria}');
      if (config.criteria.isEmpty) {
        print('Criteria is empty - allowing certificate generation');
        return true;
      }

      // Check if "complete_all_sessions" is in criteria
      if (config.criteria.contains('complete_all_sessions')) {
        // Get training progress
        final progress = await _apiService.getTrainingProgress(userId);
        print('Training progress: $progress');
        final trainingProgress = progress['trainings']?.firstWhere(
          (t) => t['trainingId'] == trainingId,
          orElse: () => null,
        );

        if (trainingProgress == null) {
          print(
            'Training progress not found - allowing certificate generation for completed training',
          );
          // If we can't get progress but user has access to this training, assume eligible
          return true;
        }

        final completedSessions = trainingProgress['completedSessions'] ?? 0;
        final totalSessions = trainingProgress['totalSessions'] ?? 0;
        final attendancePercentage =
            trainingProgress['attendancePercentage'] ?? 0;

        print(
          'Completed sessions: $completedSessions, Total: $totalSessions, Attendance: $attendancePercentage',
        );

        // Check completion criteria - strict rules
        final allSessionsCompleted = completedSessions >= totalSessions; // 100% completion
        final meetsAttendance = attendancePercentage >= config.minimumAttendance; // 100% of required attendance

        print(
          'All sessions completed (100%): $allSessionsCompleted, Meets attendance (100%): $meetsAttendance',
        );

        // Require 100% completion and attendance
        return allSessionsCompleted && meetsAttendance;
      }

      // Default to allowing certificate generation
      print('Defaulting to allow certificate generation');
      return true;
    } catch (e) {
      print('Error checking certificate eligibility: $e');
      // On error, allow certificate generation
      return true;
    }
  }

  Future<List<CertificateModel>> _loadCachedCertificates() async {
    try {
      // For now, return empty list as we don't have local caching implemented
      // In a full implementation, this would load from local storage
      return [];
    } catch (e) {
      print('Error loading cached certificates: $e');
      return [];
    }
  }

  Future<void> refreshCertificates() async {
    await fetchUserCertificates();
  }
}
