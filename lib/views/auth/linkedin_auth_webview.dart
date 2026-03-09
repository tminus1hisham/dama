import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:dama/controller/linkedin_controller.dart';

class LinkedInAuthWebView extends StatefulWidget {
  final String authUrl;

  const LinkedInAuthWebView({super.key, required this.authUrl});

  @override
  State<LinkedInAuthWebView> createState() => _LinkedInAuthWebViewState();
}

class _LinkedInAuthWebViewState extends State<LinkedInAuthWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Check if this is the callback URL
            if (request.url.startsWith('https://api.damakenya.org/v1/user/linkedin/mobile/callback') ||
                request.url.contains('linkedin') && request.url.contains('code=')) {
              // Extract parameters and handle
              final uri = Uri.parse(request.url);
              final linkedInController = Get.find<LinkedInController>();
              linkedInController.handleDeepLink(uri);
              // Close the webview
              Get.back();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkedIn Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}