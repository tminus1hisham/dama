import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CertificateEarnedBanner extends StatelessWidget {
  final VoidCallback? onViewCertificate;
  final VoidCallback? onDownloadCertificate;

  const CertificateEarnedBanner({
    super.key,
    this.onViewCertificate,
    this.onDownloadCertificate,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBlue.withOpacity(0.8), kBlue.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: kWhite, size: 24),
              SizedBox(width: 8),
              Text(
                'Certificate Earned!',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Congratulations! You have successfully completed this training.',
            style: TextStyle(color: kWhite.withOpacity(0.9), fontSize: 14),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              if (onViewCertificate != null)
                Expanded(
                  child: CustomButton(
                    callBackFunction: onViewCertificate,
                    label: "View Certificate",
                    backgroundColor: kWhite,
                  ),
                ),
              if (onViewCertificate != null && onDownloadCertificate != null)
                SizedBox(width: 8),
              if (onDownloadCertificate != null)
                IconButton(
                  onPressed: onDownloadCertificate,
                  icon: Icon(Icons.download, color: kWhite),
                  tooltip: 'Download Certificate',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
