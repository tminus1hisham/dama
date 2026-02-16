import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

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
    print(
      'DeepLinkService: Checking if LinkedIn callback - URI: $uri, isLinkedIn: $isLinkedIn',
    );
    return isLinkedIn;
  }

  Future<bool> launchLinkedInAuth(String authUrl) async {
    try {
      print('DeepLinkService: Launching LinkedIn auth URL: $authUrl');
      return await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('DeepLinkService: Error launching LinkedIn auth: $e');
      return false;
    }
  }

  Map<String, String> extractLinkedInParams(Uri uri) {
    final params = uri.queryParameters;
    print('DeepLinkService: Extracted params: $params');
    return params;
  }
}
