import 'dart:ui';

import 'package:dama/models/certificate_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class CertificatePreviewSheet extends StatelessWidget {
  final CertificateModel certificate;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const CertificatePreviewSheet({
    super.key,
    required this.certificate,
    this.onDownload,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    // Always use light mode for certificates
    const bool isDarkMode = false;

    return SafeArea(
      bottom: true,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: (isDarkMode ? kDarkThemeBg : kBGColor).withOpacity(0.9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 10),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? kWhite.withOpacity(0.3)
                          : kBlack.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),

              // Certificate Content
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? kDarkCard : kWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kBlue.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: kBlue.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    // Header
                    Text(
                      'CERTIFICATE OF COMPLETION',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kBlue,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'DAMA Kenya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                    SizedBox(height: 24),

                    // Certificate Body
                    Text(
                      'This is to certify that',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? kWhite : kGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      certificate.userName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'has successfully completed the training program',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? kWhite : kGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      certificate.trainingTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),

                    // Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Certificate #:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? kWhite : kGrey,
                              ),
                            ),
                            Text(
                              certificate.certificateNumber,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Issue Date:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? kWhite : kGrey,
                              ),
                            ),
                            Text(
                              '${certificate.issueDate.day}/${certificate.issueDate.month}/${certificate.issueDate.year}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (certificate.trainingHours > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: isDarkMode ? kWhite : kGrey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${certificate.trainingHours} Training Hours',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? kWhite : kGrey,
                            ),
                          ),
                        ],
                      ),

                    // Instructor
                    if (certificate.instructorName.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Instructor: ${certificate.instructorName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? kWhite : kGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    // Seal/Logo placeholder
                    SizedBox(height: 24),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kBlue.withOpacity(0.1),
                        border: Border.all(
                          color: kBlue.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(Icons.verified, color: kBlue, size: 30),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Action Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (onShare != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onShare,
                          icon: Icon(Icons.share, color: kBlue),
                          label: Text('Share'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: kBlue),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (onShare != null) SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        callBackFunction: onDownload ?? () {},
                        label: "Download Certificate",
                        backgroundColor: kBlue,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
