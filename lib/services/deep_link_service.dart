import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService extends GetxService {
  final AppLinks _appLinks = AppLinks();

  Stream<Uri> get deepLinkStream => _appLinks.uriLinkStream;

  Future<Uri?> getInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      print('DeepLinkService: Initial link: $uri');
      return uri;
    } catch (e) {
      print('DeepLinkService: Error getting initial link: $e');
      return null;
    }
  }

  bool isLinkedInCallback(Uri uri) {
    // Check if the URI is a LinkedIn callback
    final isLinkedIn =
        uri.host.contains('linkedin') ||
        uri.path.contains('linkedin') ||
        uri.queryParameters.containsKey('code') ||
        uri.path.contains('callback');
    debugPrint(
      '🔵 [DeepLink] Checking LinkedIn callback - URI: $uri, isLinkedIn: $isLinkedIn',
    );
    return isLinkedIn;
  }

  Future<bool> launchLinkedInAuth(String authUrl) async {
    try {
      debugPrint('🔵 [DeepLink] Launching LinkedIn auth URL: $authUrl');
      final result = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );
      debugPrint('🔵 [DeepLink] Launch result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ [DeepLink] Error launching LinkedIn auth: $e');
      return false;
    }
  }

  Map<String, String> extractLinkedInParams(Uri uri) {
    final params = uri.queryParameters;
    debugPrint('🔵 [DeepLink] Extracted params: ${params.keys.join(", ")}');
    return params;
  }
}
