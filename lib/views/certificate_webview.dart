import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class CertificateWebView extends StatefulWidget {
  final String certificateUrl;
  final String title;

  const CertificateWebView({
    super.key,
    required this.certificateUrl,
    required this.title,
  });

  @override
  State<CertificateWebView> createState() => _CertificateWebViewState();
}

class _CertificateWebViewState extends State<CertificateWebView> {
  WebViewController? _webViewController;
  bool isLoading = true;
  bool _webViewReady = false;
  bool _isDownloading = false;
  String? errorMessage;

  Completer<String>? _htmlCompleter;

  double get _screenWidth =>
      WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    final accessToken = await StorageService.getData("access_token");

    if (!mounted) return;

    final screenW = _screenWidth.toInt();
    const sidePadding = 16;
    final availableW = screenW - (sidePadding * 2);

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'HtmlChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('[Certificate] HTML received, length: ${message.message.length}');
          _htmlCompleter?.complete(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('[Certificate] Page loading: $url');
            if (mounted) {
              setState(() {
                isLoading = true;
                _webViewReady = false;
                errorMessage = null;
              });
              _webViewController!.runJavaScript('''
                (function() {
                  var meta = document.querySelector('meta[name="viewport"]');
                  if (!meta) {
                    meta = document.createElement('meta');
                    meta.name = 'viewport';
                    document.head.appendChild(meta);
                  }
                  meta.content = 'width=$screenW, initial-scale=1.0';
                  if (document.body) document.body.style.visibility = 'hidden';
                })();
              ''');
            }
          },
          onPageFinished: (String url) {
            debugPrint('[Certificate] Page loaded: $url');
            if (mounted) {
              setState(() { isLoading = false; });

              _webViewController!.runJavaScript('''
                (function() {
                  document.body.style.visibility = 'hidden';
                  var meta = document.querySelector('meta[name="viewport"]');
                  if (!meta) {
                    meta = document.createElement('meta');
                    meta.name = 'viewport';
                    document.head.appendChild(meta);
                  }
                  meta.content = 'width=$screenW, initial-scale=1.0';

                  // Aggressive page compression CSS
                  var style = document.createElement('style');
                  style.innerHTML = `
                    * { margin: 0 !important; padding: 0 !important; }
                    body, html { margin: 0 !important; padding: 0 !important; }
                    p { margin: 0 !important; padding: 0 !important; line-height: 1.1 !important; }
                    h1, h2, h3, h4, h5, h6 { margin: 0 !important; padding: 0 !important; line-height: 1.1 !important; }
                    div { margin: 0 !important; padding: 0 !important; }
                    table { margin: 0 !important; padding: 0 !important; border-collapse: collapse !important; }
                    td, th { margin: 0 !important; padding: 2px !important; line-height: 1 !important; }
                    br { display: none !important; }
                    
                    /* Print-specific rules */
                    @media print {
                      * { margin: 0 !important; padding: 0 !important; page-break-inside: avoid !important; }
                      body, html { margin: 0 !important; padding: 0 !important; height: auto !important; }
                      p { margin: 0 !important; padding: 0 !important; line-height: 1 !important; page-break-inside: avoid !important; }
                      h1, h2, h3, h4, h5, h6 { margin: 0 !important; padding: 0 !important; line-height: 1 !important; page-break-inside: avoid !important; }
                      div { margin: 0 !important; padding: 0 !important; page-break-inside: avoid !important; }
                      table { margin: 0 !important; padding: 0 !important; border-collapse: collapse !important; page-break-inside: avoid !important; }
                      td, th { margin: 0 !important; padding: 1px !important; line-height: 1 !important; page-break-inside: avoid !important; font-size: 11px !important; }
                      img { max-width: 100% !important; page-break-inside: avoid !important; }
                      body { font-size: 11px !important; line-height: 1 !important; }
                    }
                  `;
                  document.head.appendChild(style);

                  setTimeout(function() {
                    var availW = $availableW;
                    var contentW = Math.max(
                      document.body ? document.body.scrollWidth : 0,
                      document.body ? document.body.offsetWidth : 0,
                      document.documentElement.scrollWidth,
                      document.documentElement.offsetWidth
                    );

                    if (contentW > 0) {
                      var scale = availW / contentW;
                      document.body.style.transformOrigin = 'top left';
                      document.body.style.transform = 'scale(' + scale + ')';
                      document.body.style.width = contentW + 'px';
                      document.body.style.marginLeft = '${sidePadding}px';
                      document.body.style.marginRight = '${sidePadding}px';
                      document.documentElement.style.height =
                        (document.body.scrollHeight * scale) + 'px';
                    }

                    document.documentElement.style.overflowX = 'hidden';
                    document.body.style.overflowX = 'hidden';

                    // Hide the page built-in download/print button
                    var allEls = document.querySelectorAll('*');
                    allEls.forEach(function(el) {
                      var text = (el.innerText || el.textContent || el.value || '').trim().toLowerCase();
                      var tag = el.tagName ? el.tagName.toLowerCase() : '';
                      var isInteractive = ['button','a','input','span','div'].includes(tag);
                      if (isInteractive && (text === 'download as pdf / print' || text === 'download as pdf' || text === 'print' || text === 'download')) {
                        el.style.display = 'none';
                        if (el.parentElement && el.parentElement.children.length === 1) {
                          el.parentElement.style.display = 'none';
                        }
                      }
                    });

                    document.body.style.visibility = 'visible';
                  }, 350);
                })();
              ''');

              Future.delayed(const Duration(milliseconds: 450), () {
                if (mounted) setState(() { _webViewReady = true; });
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[Certificate] Error: ${error.description}');
            if (mounted) {
              setState(() {
                errorMessage = 'Failed to load certificate. Please try again.';
                isLoading = false;
                _webViewReady = true;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    if (accessToken != null && accessToken.isNotEmpty) {
      await _webViewController!.loadRequest(
        Uri.parse(widget.certificateUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    } else {
      if (mounted) {
        setState(() {
          errorMessage = 'Authentication required. Please log in again.';
          isLoading = false;
          _webViewReady = true;
        });
      }
    }
  }

  Future<void> _downloadCertificate() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final accessToken = await StorageService.getData("access_token");
      if (accessToken == null || accessToken.isEmpty) {
        Get.snackbar('Error', 'Authentication required.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return;
      }

      debugPrint('[Certificate] Fetching HTML...');

      // Step 1 — fetch the certificate HTML
      final response = await http
          .get(Uri.parse(widget.certificateUrl),
              headers: {'Authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      String html = response.body;
      debugPrint('[Certificate] HTML length: ${html.length}');

      // Step 2 — inline all images as base64
      debugPrint('[Certificate] Inlining images...');
      html = await _inlineImages(html, accessToken);

      // Step 3 — inject print CSS to eliminate blank second page
      // The certificate HTML has extra whitespace below the card which
      // causes a blank page 2. This CSS forces the browser to fit
      // everything on one page and hides any overflow.
      const printCss = '''
<style>
  @media print {
    @page {
      margin: 0;
      size: auto;
    }
    html, body {
      height: auto !important;
      overflow: hidden !important;
      margin: 0 !important;
      padding: 0 !important;
    }
    /* Hide anything below the certificate card */
    body > *:last-child,
    body > * + * {
      page-break-after: avoid !important;
      break-after: avoid !important;
    }
    /* Ensure no element causes a page break */
    * {
      page-break-inside: avoid !important;
      break-inside: avoid !important;
    }
  }
</style>
''';

      // Step 4 — inject auto-print script
      const printScript = '''
<script>
  window.addEventListener('load', function() {
    setTimeout(function() { window.print(); }, 800);
  });
</script>
''';

      // Inject CSS before </head> and script after
      if (html.contains('</head>')) {
        html = html.replaceFirst('</head>', '$printCss$printScript</head>');
      } else {
        html = '$printCss$printScript$html';
      }

      // Step 5 — save as a local HTML file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/certificate_print.html');
      await file.writeAsString(html, encoding: utf8);
      debugPrint('[Certificate] Saved to: ${file.path}');

      // Step 6 — share via share_plus (uses FileProvider, no FileUriExposedException)
      debugPrint('[Certificate] Sharing: ${file.path}');
      final xFile = XFile(
        file.path,
        mimeType: 'text/html',
        name: '${widget.title}.html',
      );
      final result = await Share.shareXFiles(
        [xFile],
        subject: widget.title,
        text: 'Open in Chrome → tap menu → Print → Save as PDF',
      );
      debugPrint('[Certificate] Share result: ${result.status}');
    } catch (e) {
      debugPrint('[Certificate] Error: $e');
      if (mounted) {
        Get.snackbar(
          'Download Failed',
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  /// Replace all external image src with inline base64 data URIs
  Future<String> _inlineImages(String html, String accessToken) async {
    final imgRegex = RegExp(r'src="(https?://[^"]+)"');
    final matches = imgRegex.allMatches(html).toList();
    for (final match in matches) {
      final url = match.group(1)!;
      try {
        final res = await http
            .get(Uri.parse(url),
                headers: {'Authorization': 'Bearer $accessToken'})
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final mime = res.headers['content-type'] ?? 'image/png';
          final encoded =
              Uri.dataFromBytes(res.bodyBytes.toList(), mimeType: mime)
                  .toString();
          html = html.replaceAll('src="$url"', 'src="$encoded"');
        }
      } catch (e) {
        debugPrint('[Certificate] Could not inline $url: $e');
      }
    }
    return html;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedOpacity(
                  opacity: _webViewReady ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: _webViewController != null
                      ? WebViewWidget(controller: _webViewController!)
                      : const SizedBox.shrink(),
                ),

                if (!_webViewReady || isLoading)
                  Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade700),
                          ),
                          const SizedBox(height: 16),
                          const Text('Loading Certificate...',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),

                if (errorMessage != null && !isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 2)
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade600, size: 56),
                            const SizedBox(height: 20),
                            Text('Certificate Error',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade900)),
                            const SizedBox(height: 12),
                            Text(errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    height: 1.5)),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Get.back(),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Go Back',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (errorMessage == null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadCertificate,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.print),
                  label: Text(_isDownloading
                      ? 'Preparing...'
                      : 'Download as PDF / Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.blue.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}