import 'dart:io';

import 'package:dama/models/certificate_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dama/views/certificate_webview.dart';

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
  Future<void> downloadCertificate(CertificateModel certificate) async {
    try {
      // Use downloadUrl from certificate if available, otherwise construct URL
      final url = certificate.downloadUrl?.isNotEmpty == true
          ? certificate.downloadUrl!
          : '$BASE_URL/certificates/download/${certificate.certificateNumber}';
      
      debugPrint('[Certificate] Download URL: $url');
      debugPrint('[Certificate] Certificate Number: ${certificate.certificateNumber}');
      
      await openCertificateCompressed(url, 'certificate_training_${certificate.certificateNumber}.html');
    } catch (e) {
      debugPrint('[Certificate] Error in downloadCertificate: $e');
      Get.snackbar(
        'Download Failed',
        'Unable to download certificate. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // ── GENERIC: Download any certificate URL with compression ────
  Future<void> openCertificateCompressed(String? url, String fileName) async {
    if (url == null || url.isEmpty) {
      debugPrint('[Certificate] No URL provided');
      throw Exception('Certificate URL is empty or invalid');
    }

    debugPrint('[Certificate] Fetching and compressing: $url');
    try {
      final accessToken = await StorageService.getData("access_token");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('[Certificate] Server error: ${response.statusCode}');
        throw Exception('Failed to download certificate (${response.statusCode})');
      }

      // Check if response is HTML
      if (!response.body.toLowerCase().contains('<html') && 
          !response.body.toLowerCase().contains('<!doctype')) {
        debugPrint('[Certificate] Response is not HTML: ${response.body.substring(0, 200)}');
        throw Exception('Invalid certificate response - not HTML');
      }

      // Inject ULTRA-AGGRESSIVE CSS compression into the HTML
      var html = response.body;
      final compressionCSS = '''
        <style>
          * { 
            margin: 0 !important; 
            padding: 0 !important; 
            border: none !important;
            box-sizing: border-box !important;
          }
          html, body { 
            margin: 0 !important; 
            padding: 0 !important; 
            width: 100% !important;
            height: auto !important;
            background: white !important;
          }
          body {
            font-size: 12px !important;
            line-height: 1 !important;
          }
          p, div, span, li { 
            margin: 0 !important; 
            padding: 0 !important; 
            line-height: 1.2 !important;
          }
          h1, h2, h3, h4, h5, h6 { 
            margin: 0 !important; 
            padding: 0 !important; 
            line-height: 1 !important;
          }
          table { 
            margin: 0 !important; 
            padding: 0 !important; 
            border-collapse: collapse !important; 
            width: 100% !important;
          }
          td, th { 
            margin: 0 !important; 
            padding: 1px !important; 
            line-height: 1 !important;
            border: 1px solid #ddd !important;
          }
          img { 
            max-width: 100% !important; 
            height: auto !important;
            display: block !important;
          }
          br, hr { 
            display: none !important; 
          }
          
          /* PRINT MEDIA - ULTRA AGGRESSIVE */
          @media print {
            * { 
              margin: 0 !important; 
              padding: 0 !important; 
              page-break-inside: avoid !important; 
              page-break-before: auto !important;
              page-break-after: auto !important;
              box-sizing: border-box !important;
            }
            html, body { 
              margin: 0 !important; 
              padding: 0 !important; 
              width: 100% !important;
              height: auto !important;
              background: white !important;
            }
            body {
              font-size: 10px !important;
              line-height: 1 !important;
            }
            p, div, span, li { 
              margin: 0 !important; 
              padding: 0 !important; 
              line-height: 1 !important;
              page-break-inside: avoid !important;
            }
            h1, h2, h3, h4, h5, h6 { 
              margin: 0 !important; 
              padding: 0 !important; 
              line-height: 1 !important;
              page-break-inside: avoid !important;
              page-break-after: avoid !important;
            }
            table { 
              margin: 0 !important; 
              padding: 0 !important; 
              border-collapse: collapse !important; 
              width: 100% !important;
              page-break-inside: avoid !important;
            }
            tbody { page-break-inside: avoid !important; }
            tr { page-break-inside: avoid !important; page-break-after: auto !important; }
            td, th { 
              margin: 0 !important; 
              padding: 0px !important; 
              line-height: 1 !important;
              page-break-inside: avoid !important;
              font-size: 10px !important;
            }
            img { 
              max-width: 100% !important; 
              height: auto !important;
              page-break-inside: avoid !important;
            }
            br, hr { display: none !important; }
            .page-break { page-break-after: always !important; }
          }
        </style>
        ''';
      
      // Inject CSS before closing head tag, or create head if missing
      if (html.contains('</head>')) {
        html = html.replaceFirst('</head>', '$compressionCSS</head>');
      } else if (html.contains('<body')) {
        html = html.replaceFirst('<body', '$compressionCSS<body');
      } else {
        html = compressionCSS + html;
      }
      
      // Save to local file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(html);
      
      // Open the local file in browser (external) if possible; otherwise show in-app webview
      final fileUrl = 'file://${file.path}';
      debugPrint('[Certificate] Opening compressed file: $fileUrl');
      final uri = Uri.parse(fileUrl);
      bool opened = false;

      try {
        if (await canLaunchUrl(uri)) {
          opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('[Certificate] External open failed: $e');
      }

      if (!opened) {
        // Fallback: show in-app webview (works even when external browser can't open file:// URIs)
        Get.to(
          () => CertificateWebView(
            certificateUrl: fileUrl,
            title: 'Certificate',
          ),
        );
      }
    } catch (e) {
      debugPrint('[Certificate] Error downloading/compressing: $e');
      rethrow;
    }
  }

  // ── SHARE: share the certificate URL directly via OS share sheet ──────────
  Future<void> shareCertificate(CertificateModel certificate) async {
    final url = certificate.downloadUrl?.isNotEmpty == true
        ? certificate.downloadUrl!
        : '$BASE_URL/certificates/download/${certificate.certificateNumber}';
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
