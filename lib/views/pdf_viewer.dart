import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final VoidCallback? onBack;

  const PDFViewerPage({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.onBack,
  });

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  int? totalPages;
  int? currentPage;

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  Future<void> loadPDF() async {
    try {
      print('[PDFViewer] Loading PDF from: ${widget.pdfUrl}');

      // Get authentication token
      final accessToken = await StorageService.getData("access_token");
      print(
        '[PDFViewer] Token available: ${accessToken != null && accessToken.isNotEmpty}',
      );

      // Make authenticated request
      final response = await http.get(
        Uri.parse(widget.pdfUrl),
        headers:
            accessToken != null && accessToken.isNotEmpty
                ? {'Authorization': 'Bearer $accessToken'}
                : {},
      );

      print('[PDFViewer] Response status: ${response.statusCode}');
      print('[PDFViewer] Content-Type: ${response.headers['content-type']}');
      print('[PDFViewer] Content length: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        // Check if response is actually a PDF
        final contentType =
            response.headers['content-type']?.toLowerCase() ?? '';
        final isPdf =
            contentType.contains('pdf') ||
            widget.pdfUrl.toLowerCase().endsWith('.pdf');
        final isHtml = contentType.contains('html');

        // If response is HTML or not a PDF, open in browser immediately
        if (isHtml || !isPdf) {
          print(
            '[PDFViewer] Error: Response is not PDF (Content-Type: $contentType)',
          );
          if (response.body.trim().startsWith('<')) {
            print('[PDFViewer] Response starts with HTML tag');
          }

          // Open in browser immediately without showing error
          _openInBrowser();
          return;
        }

        // Save PDF to temporary file
        final dir = await getTemporaryDirectory();
        final fileName =
            'certificate_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File("${dir.path}/$fileName");
        await file.writeAsBytes(response.bodyBytes, flush: true);

        print('[PDFViewer] PDF saved to: ${file.path}');
        print('[PDFViewer] File size: ${await file.length()} bytes');

        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('[PDFViewer] Authentication failed');
        setState(() {
          errorMessage = 'Authentication failed. Please login again.';
          isLoading = false;
        });
      } else {
        print('[PDFViewer] Failed to load PDF: ${response.statusCode}');
        setState(() {
          errorMessage =
              'Failed to load certificate (${response.statusCode}). Opening in browser...';
          isLoading = false;
        });

        // Fallback to browser
        await Future.delayed(Duration(seconds: 1));
        _openInBrowser();
      }
    } catch (e) {
      print('[PDFViewer] Error loading PDF: $e');
      setState(() {
        errorMessage = 'Error loading certificate: $e';
        isLoading = false;
      });
    }
  }

  void _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.pdfUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('[PDFViewer] Error opening browser: $e');
    }
  }

  void _retry() {
    setState(() {
      isLoading = true;
      errorMessage = null;
      localPath = null;
    });
    loadPDF();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBGColor,
      body: Column(
        children: [
          TopNavigationbar(
            title: widget.title,
            onBack: widget.onBack,
            actions: [
              if (!isLoading && errorMessage == null)
                IconButton(
                  icon: Icon(Icons.open_in_browser, color: Colors.white),
                  onPressed: _openInBrowser,
                  tooltip: 'Open in Browser',
                ),
            ],
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              customSpinner,
              SizedBox(height: 16),
              Text(
                'Loading ${widget.title.toLowerCase()}...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openInBrowser,
                    icon: Icon(Icons.open_in_browser),
                    label: Text('Open in Browser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (localPath != null) {
      return PDFView(
        filePath: localPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
        onRender: (pages) {
          print('[PDFViewer] PDF rendered with $pages pages');
          setState(() {
            totalPages = pages;
          });
        },
        onViewCreated: (controller) {
          print('[PDFViewer] PDF view created');
        },
        onPageChanged: (page, total) {
          setState(() {
            currentPage = page;
          });
        },
        onError: (error) {
          print('[PDFViewer] PDF Error: $error');
          setState(() {
            errorMessage = 'Error displaying PDF: $error';
          });
        },
        onPageError: (page, error) {
          print('[PDFViewer] Page $page Error: $error');
        },
      );
    }

    return Center(child: Text('Something went wrong'));
  }
}
