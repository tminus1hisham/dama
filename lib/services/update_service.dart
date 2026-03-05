import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';

/// Production-ready in-app update service for Android and iOS
/// 
/// Features:
/// - Android: Flexible and Immediate update modes via Play Store
/// - iOS: iTunes API version check with App Store redirect
/// - "Remind me later" functionality with configurable delay
/// - Comprehensive error handling and logging
/// - Force update capability for critical updates
class UpdateService extends GetxService {
  static const String _remindLaterKey = 'update_remind_later_timestamp';
  static const String _skippedVersionKey = 'update_skipped_version';
  static const String _lastCheckKey = 'update_last_check_timestamp';
  
  /// Delay before showing update again after "remind me later" (in hours)
  static const int remindLaterDelayHours = 24;
  
  /// Minimum interval between update checks (in hours)
  static const int minCheckIntervalHours = 6;
  
  /// Your App Store ID (replace with your actual App Store ID)
  /// Find it in App Store Connect > App Information > Apple ID
  static const String appStoreId = 'YOUR_APP_STORE_ID'; // TODO: Replace with actual ID
  
  /// Bundle ID for iOS (must match your app's bundle identifier)
  static const String bundleId = 'com.dama.mobile';
  
  // Observable states
  final isChecking = false.obs;
  final updateAvailable = false.obs;
  final updateInfo = Rxn<AppUpdateInfo>();
  final latestVersion = ''.obs;
  final currentVersion = ''.obs;
  final updateNotes = ''.obs;
  
  late SharedPreferences _prefs;
  PackageInfo? _packageInfo;

  /// Initialize the update service
  Future<UpdateService> init() async {
    debugPrint('📲 [UpdateService] Initializing...');
    try {
      _prefs = await SharedPreferences.getInstance();
      _packageInfo = await PackageInfo.fromPlatform();
      currentVersion.value = _packageInfo?.version ?? '';
      debugPrint('📲 [UpdateService] Current version: ${currentVersion.value}');
      debugPrint('📲 [UpdateService] Build number: ${_packageInfo?.buildNumber}');
    } catch (e, stack) {
      debugPrint('📲 [UpdateService] Initialization error: $e');
      debugPrint('📲 [UpdateService] Stack trace: $stack');
    }
    return this;
  }

  /// Check for updates on the appropriate platform
  /// 
  /// [showDialogIfAvailable] - Show update dialog immediately if update found
  /// [forceCheck] - Bypass the minimum check interval
  Future<bool> checkForUpdate({
    bool showDialogIfAvailable = true,
    bool forceCheck = false,
  }) async {
    if (kIsWeb) {
      debugPrint('📲 [UpdateService] Web platform - skipping update check');
      return false;
    }

    // Check minimum interval (unless force check)
    if (!forceCheck && !_shouldCheckForUpdate()) {
      debugPrint('📲 [UpdateService] Skipping check - within minimum interval');
      return updateAvailable.value;
    }

    isChecking.value = true;
    debugPrint('📲 [UpdateService] Checking for updates...');

    try {
      bool hasUpdate = false;
      
      if (Platform.isAndroid) {
        hasUpdate = await _checkAndroidUpdate();
      } else if (Platform.isIOS) {
        hasUpdate = await _checkiOSUpdate();
      }
      
      updateAvailable.value = hasUpdate;
      
      // Save check timestamp
      await _prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
      
      if (hasUpdate && showDialogIfAvailable) {
        // Check if user chose "remind me later" recently
        if (!_shouldShowReminder()) {
          debugPrint('📲 [UpdateService] Update available but user chose remind later');
          return true;
        }
        
        // Check if user skipped this version
        final skippedVersion = _prefs.getString(_skippedVersionKey);
        if (skippedVersion == latestVersion.value) {
          debugPrint('📲 [UpdateService] User skipped this version: $skippedVersion');
          return true;
        }
        
        _showUpdateDialog();
      }
      
      return hasUpdate;
    } catch (e, stack) {
      debugPrint('📲 [UpdateService] Error checking for updates: $e');
      debugPrint('📲 [UpdateService] Stack trace: $stack');
      return false;
    } finally {
      isChecking.value = false;
    }
  }

  /// Check for Android updates using Play Store in-app update API
  Future<bool> _checkAndroidUpdate() async {
    debugPrint('📲 [UpdateService] Checking Android update via Play Store...');
    
    try {
      final info = await InAppUpdate.checkForUpdate();
      updateInfo.value = info;
      
      debugPrint('📲 [UpdateService] Update availability: ${info.updateAvailability}');
      debugPrint('📲 [UpdateService] Available version code: ${info.availableVersionCode}');
      debugPrint('📲 [UpdateService] Update priority: ${info.updatePriority}');
      debugPrint('📲 [UpdateService] Immediate update allowed: ${info.immediateUpdateAllowed}');
      debugPrint('📲 [UpdateService] Flexible update allowed: ${info.flexibleUpdateAllowed}');
      
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        latestVersion.value = 'New version available';
        return true;
      }
      
      // Handle case where update is already downloaded and pending install
      if (info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
        debugPrint('📲 [UpdateService] Update already in progress');
        return true;
      }
      
      return false;
    } on Exception catch (e) {
      debugPrint('📲 [UpdateService] Android update check failed: $e');
      // Fallback: Could check version from your own API if Play Store fails
      return false;
    }
  }

  /// Check for iOS updates using iTunes Search API
  Future<bool> _checkiOSUpdate() async {
    debugPrint('📲 [UpdateService] Checking iOS update via iTunes API...');
    
    try {
      final response = await http.get(
        Uri.parse('https://itunes.apple.com/lookup?bundleId=$bundleId&country=KE'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        debugPrint('📲 [UpdateService] iTunes API returned ${response.statusCode}');
        return false;
      }
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      
      if (results == null || results.isEmpty) {
        debugPrint('📲 [UpdateService] App not found in iTunes (may not be published yet)');
        return false;
      }
      
      final appData = results.first as Map<String, dynamic>;
      final storeVersion = appData['version'] as String?;
      final releaseNotes = appData['releaseNotes'] as String?;
      
      debugPrint('📲 [UpdateService] iTunes version: $storeVersion');
      debugPrint('📲 [UpdateService] Current version: ${currentVersion.value}');
      
      if (storeVersion == null) return false;
      
      latestVersion.value = storeVersion;
      updateNotes.value = releaseNotes ?? '';
      
      return _isNewerVersion(storeVersion, currentVersion.value);
    } on Exception catch (e) {
      debugPrint('📲 [UpdateService] iOS update check failed: $e');
      return false;
    }
  }

  /// Compare version strings to determine if store version is newer
  bool _isNewerVersion(String storeVersion, String currentVersion) {
    try {
      final storeParts = storeVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      
      // Normalize lengths
      while (storeParts.length < 3) storeParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);
      
      for (int i = 0; i < 3; i++) {
        if (storeParts[i] > currentParts[i]) {
          debugPrint('📲 [UpdateService] Newer version available: $storeVersion > $currentVersion');
          return true;
        }
        if (storeParts[i] < currentParts[i]) {
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('📲 [UpdateService] Version comparison error: $e');
      return false;
    }
  }

  /// Check if enough time has passed since last check
  bool _shouldCheckForUpdate() {
    final lastCheck = _prefs.getInt(_lastCheckKey) ?? 0;
    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    final hoursSinceCheck = DateTime.now().difference(lastCheckTime).inHours;
    
    debugPrint('📲 [UpdateService] Hours since last check: $hoursSinceCheck');
    return hoursSinceCheck >= minCheckIntervalHours;
  }

  /// Check if we should show reminder after user chose "remind me later"
  bool _shouldShowReminder() {
    final remindLater = _prefs.getInt(_remindLaterKey) ?? 0;
    if (remindLater == 0) return true;
    
    final remindTime = DateTime.fromMillisecondsSinceEpoch(remindLater);
    final hoursSinceRemind = DateTime.now().difference(remindTime).inHours;
    
    debugPrint('📲 [UpdateService] Hours since remind later: $hoursSinceRemind');
    return hoursSinceRemind >= remindLaterDelayHours;
  }

  /// Show update dialog to user
  void _showUpdateDialog({bool isForceUpdate = false}) {
    final context = Get.context;
    if (context == null) {
      debugPrint('📲 [UpdateService] No context available for dialog');
      return;
    }

    debugPrint('📲 [UpdateService] Showing update dialog (force: $isForceUpdate)');

    Get.dialog(
      PopScope(
        canPop: !isForceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.system_update,
                color: kBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isForceUpdate ? 'Update Required' : 'Update Available',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isForceUpdate
                    ? 'A critical update is required to continue using the app.'
                    : 'A new version of DAMA Kenya is available!',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              if (latestVersion.value.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current: ${currentVersion.value}',
                              style: TextStyle(
                                fontSize: 13,
                                color: kGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Latest: ${latestVersion.value}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_upward, color: kGreen),
                    ],
                  ),
                ),
              ],
              if (updateNotes.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  "What's new:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _truncateText(updateNotes.value, 150),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            if (!isForceUpdate) ...[
              TextButton(
                onPressed: () => _handleSkipVersion(),
                child: Text(
                  'Skip',
                  style: TextStyle(color: kGrey),
                ),
              ),
              TextButton(
                onPressed: () => _handleRemindLater(),
                child: Text(
                  'Later',
                  style: TextStyle(color: kGrey),
                ),
              ),
            ],
            ElevatedButton(
              onPressed: () => _performUpdate(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Update Now',
                style: TextStyle(color: kWhite),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: !isForceUpdate,
    );
  }

  /// Handle "Skip this version" action
  Future<void> _handleSkipVersion() async {
    debugPrint('📲 [UpdateService] User skipped version: ${latestVersion.value}');
    await _prefs.setString(_skippedVersionKey, latestVersion.value);
    Get.back();
  }

  /// Handle "Remind me later" action
  Future<void> _handleRemindLater() async {
    debugPrint('📲 [UpdateService] User chose remind later');
    await _prefs.setInt(_remindLaterKey, DateTime.now().millisecondsSinceEpoch);
    Get.back();
  }

  /// Perform the update
  Future<void> _performUpdate() async {
    debugPrint('📲 [UpdateService] Performing update...');
    
    try {
      if (Platform.isAndroid) {
        await _performAndroidUpdate();
      } else if (Platform.isIOS) {
        await _performiOSUpdate();
      }
    } catch (e) {
      debugPrint('📲 [UpdateService] Update failed: $e');
      _showUpdateError();
    }
  }

  /// Perform Android update using flexible or immediate mode
  Future<void> _performAndroidUpdate() async {
    final info = updateInfo.value;
    if (info == null) {
      debugPrint('📲 [UpdateService] No update info available');
      return;
    }

    Get.back(); // Close dialog first

    try {
      // Use immediate update for high priority (4-5) or if flexible not allowed
      final useImmediate = info.updatePriority >= 4 || 
                          !info.flexibleUpdateAllowed || 
                          info.immediateUpdateAllowed;

      if (useImmediate && info.immediateUpdateAllowed) {
        debugPrint('📲 [UpdateService] Starting IMMEDIATE update...');
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        debugPrint('📲 [UpdateService] Starting FLEXIBLE update...');
        await InAppUpdate.startFlexibleUpdate();
        
        // Show snackbar when download completes
        _showFlexibleUpdateDownloading();
      } else {
        // Fallback to Play Store
        debugPrint('📲 [UpdateService] Redirecting to Play Store...');
        await _openPlayStore();
      }
    } on Exception catch (e) {
      debugPrint('📲 [UpdateService] Android update error: $e');
      // Fallback to Play Store
      await _openPlayStore();
    }
  }

  /// Show flexible update downloading notification
  void _showFlexibleUpdateDownloading() {
    Get.snackbar(
      'Downloading Update',
      'Update is downloading in the background. You can continue using the app.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: kBlue.withOpacity(0.9),
      colorText: kWhite,
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.download, color: kWhite),
      mainButton: TextButton(
        onPressed: () async {
          try {
            await InAppUpdate.completeFlexibleUpdate();
          } catch (e) {
            debugPrint('📲 [UpdateService] Complete flexible update error: $e');
          }
        },
        child: Text(
          'INSTALL',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Complete a flexible update (call when ready to restart)
  Future<void> completeFlexibleUpdate() async {
    try {
      debugPrint('📲 [UpdateService] Completing flexible update...');
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('📲 [UpdateService] Error completing flexible update: $e');
    }
  }

  /// Perform iOS update by redirecting to App Store
  Future<void> _performiOSUpdate() async {
    Get.back(); // Close dialog
    
    final appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';
    debugPrint('📲 [UpdateService] Opening App Store: $appStoreUrl');
    
    try {
      final uri = Uri.parse(appStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showUpdateError();
      }
    } catch (e) {
      debugPrint('📲 [UpdateService] Error opening App Store: $e');
      _showUpdateError();
    }
  }

  /// Open Play Store directly
  Future<void> _openPlayStore() async {
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=$bundleId';
    debugPrint('📲 [UpdateService] Opening Play Store: $playStoreUrl');
    
    try {
      final uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('📲 [UpdateService] Error opening Play Store: $e');
    }
  }

  /// Show error when update fails
  void _showUpdateError() {
    Get.snackbar(
      'Update Failed',
      'Could not open the app store. Please update manually.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: kRed.withOpacity(0.9),
      colorText: kWhite,
      duration: const Duration(seconds: 4),
    );
  }

  /// Force update (for critical security updates)
  /// Call this when your backend indicates a mandatory update
  Future<void> forceUpdate() async {
    debugPrint('📲 [UpdateService] Force update requested');
    
    // Clear any "remind later" or "skip" preferences
    await _prefs.remove(_remindLaterKey);
    await _prefs.remove(_skippedVersionKey);
    
    final hasUpdate = await checkForUpdate(showDialogIfAvailable: false, forceCheck: true);
    
    if (hasUpdate) {
      _showUpdateDialog(isForceUpdate: true);
    } else {
      // Even if no update detected, show force update dialog
      // This handles the case where Play Store API isn't available
      _showUpdateDialog(isForceUpdate: true);
    }
  }

  /// Clear all update preferences (useful for testing)
  Future<void> clearPreferences() async {
    await _prefs.remove(_remindLaterKey);
    await _prefs.remove(_skippedVersionKey);
    await _prefs.remove(_lastCheckKey);
    debugPrint('📲 [UpdateService] Cleared all update preferences');
  }

  /// Get current app version info
  Map<String, String> getVersionInfo() {
    return {
      'appName': _packageInfo?.appName ?? '',
      'packageName': _packageInfo?.packageName ?? '',
      'version': _packageInfo?.version ?? '',
      'buildNumber': _packageInfo?.buildNumber ?? '',
    };
  }

  /// Truncate text for display
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

/// Extension to initialize UpdateService easily
extension UpdateServiceExtension on UpdateService {
  static Future<UpdateService> initialize() async {
    final service = UpdateService();
    await service.init();
    return service;
  }
}
