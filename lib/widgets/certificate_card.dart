import 'package:dama/models/certificate_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CertificateCard extends StatelessWidget {
  final CertificateModel certificate;
  final VoidCallback? onView;
  final VoidCallback? onDownload;

  const CertificateCard({
    super.key,
    required this.certificate,
    this.onView,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Card(
      color: isDarkMode ? kDarkCard : kWhite,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? kWhite : kBlack).withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Certificate ribbon
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kBlue,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'CERTIFICATE',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                certificate.trainingTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Certificate #: ${certificate.certificateNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? kWhite : kGrey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Issued: ${certificate.issueDate.day}/${certificate.issueDate.month}/${certificate.issueDate.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? kWhite : kGrey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Issuer: ${certificate.issuerName}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? kWhite : kGrey,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  if (onView != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onView,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          foregroundColor: kWhite,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('View'),
                      ),
                    ),
                  if (onView != null && onDownload != null) SizedBox(width: 8),
                  if (onDownload != null)
                    IconButton(
                      onPressed: onDownload,
                      icon: Icon(Icons.download, color: kBlue),
                      tooltip: 'Download Certificate',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
