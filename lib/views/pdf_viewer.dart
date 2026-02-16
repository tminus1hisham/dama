import 'package:dama/utils/constants.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PDFViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PDFViewerPage({super.key, required this.pdfUrl, required this.title});

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  String? localPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  Future<void> loadPDF() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      final bytes = response.bodyBytes;

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/temp.pdf");
      await file.writeAsBytes(bytes, flush: true);

      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBGColor,
      body: Column(
        children: [
          TopNavigationbar(title: widget.title),
          isLoading
              ? Expanded(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(child: customSpinner),
                ),
              )
              : Expanded(
                child: PDFView(
                  filePath: localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                ),
              ),
        ],
      ),
    );
  }
}
