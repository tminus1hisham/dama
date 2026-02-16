import 'package:dama/controller/certificate_controller.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/certificate_card.dart';
import 'package:dama/widgets/certificate_preview_sheet.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  final CertificateController _certificateController = Get.put(
    CertificateController(),
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopNavigationbar(title: "My Certificates"),
          Expanded(
            child: Obx(() {
              if (_certificateController.isLoading.value) {
                return Center(child: customSpinner);
              }

              if (_certificateController.certificates.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No certificates earned yet",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Complete trainings to earn certificates",
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: kWhite,
                backgroundColor: kBlue,
                onRefresh: () => _certificateController.refreshCertificates(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _certificateController.certificates.length,
                  itemBuilder: (context, index) {
                    final certificate =
                        _certificateController.certificates[index];
                    return CertificateCard(
                      certificate: certificate,
                      onView: () => _showCertificatePreview(certificate),
                      onDownload:
                          () => _downloadCertificate(
                            certificate.certificateNumber,
                          ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showCertificatePreview(certificate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CertificatePreviewSheet(
            certificate: certificate,
            onDownload:
                () => _downloadCertificate(certificate.certificateNumber),
            onShare: () => _shareCertificate(certificate),
          ),
    );
  }

  void _downloadCertificate(String certificateNumber) {
    _certificateController.downloadCertificate(certificateNumber);
  }

  void _shareCertificate(certificate) {
    // TODO: Implement share functionality
    Get.snackbar(
      'Coming Soon',
      'Certificate sharing will be available soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
