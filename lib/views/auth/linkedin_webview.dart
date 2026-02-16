import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:dama/utils/constants.dart';

class LinkedInWebView extends StatefulWidget {
  final String url;
  final Function(Map<String, dynamic> data) onSuccess;
  final Function(String error) onError;

  const LinkedInWebView({
    required this.url,
    required this.onSuccess,
    required this.onError,
    super.key,
  });

  @override
  State<LinkedInWebView> createState() => _LinkedInWebViewState();
}

class _LinkedInWebViewState extends State<LinkedInWebView> {
  late final WebViewController _controller;
  bool _hasHandledCallback = false;
  final String _callbackUrlPart = "api.damakenya.org/v1/user/linkedin/callback";

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                print('[LinkedIn WebView] onPageStarted: $url');
              },
              onPageFinished: (url) async {
                print('[LinkedIn WebView] onPageFinished: $url');

                // Check if this is the callback URL
                if (url.contains(_callbackUrlPart) && !_hasHandledCallback) {
                  _hasHandledCallback = true;
                  print(
                    '[LinkedIn WebView] Callback URL detected, extracting parameters...',
                  );
                  await _handleCallback(url);
                }
              },
              onNavigationRequest: (request) {
                print('[LinkedIn WebView] onNavigationRequest: ${request.url}');
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _handleCallback(String url) async {
    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];

      if (code == null) {
        throw Exception('No authorization code found in callback URL');
      }

      print('[LinkedIn WebView] Extracted code: $code, state: $state');

      // Make request to backend callback endpoint
      final callbackUrl = Uri.parse('$BASE_URL/user/linkedin/callback').replace(
        queryParameters: {
          'code': code,
          if (state != null) 'state': state,
          'platform': GetPlatform.isIOS ? 'ios' : 'android',
        },
      );

      print('[LinkedIn WebView] Making callback request to: $callbackUrl');

      final response = await http.get(
        callbackUrl,
        headers: {'Content-Type': 'application/json'},
      );

      print(
        '[LinkedIn WebView] Callback response status: ${response.statusCode}',
      );
      print('[LinkedIn WebView] Callback response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[LinkedIn WebView] Success, calling onSuccess');
        widget.onSuccess(data);
        Get.back(); // Close the WebView
      } else {
        throw Exception(
          'Failed to exchange code: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('[LinkedIn WebView] Error: $e');
      widget.onError(e.toString());
      Get.back(); // Close the WebView
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // Match app theme color
      appBar: AppBar(
        title: const Text(
          'LinkedIn Login',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: kBlue,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        color: const Color(0xFF1565C0), // Match app theme color
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
