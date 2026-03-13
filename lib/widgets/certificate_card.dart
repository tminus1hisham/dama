import 'package:dama/models/certificate_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CertificateCard extends StatelessWidget {
  final CertificateModel certificate;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const CertificateCard({
    super.key,
    required this.certificate,
    this.onView,
    this.onDownload,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    return GestureDetector(
      onTap: onView,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          // bg-card/60 backdrop equivalent
          color: (isDarkMode ? kDarkCard : kWhite).withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDarkMode
                    ? Colors.grey[800]!.withOpacity(0.5)
                    : Colors.grey[200]!.withOpacity(0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Subtle gradient overlay (group-hover effect, always faintly visible)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.03),
                      Colors.purple.withOpacity(0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Corner ribbon — "VERIFIED" diagonal
            Positioned(
              top: -2,
              right: -2,
              child: SizedBox(
                width: 72,
                height: 72,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                  ),
                  child: OverflowBox(
                    maxWidth: 120,
                    maxHeight: 120,
                    child: Transform.rotate(
                      angle: 0.785, // 45 degrees
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'VERIFIED',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: Award icon + title + Completed badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Award icon with gradient bg
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.15),
                              Colors.purple.withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          size: 22,
                          color: Color(0xFF60A5FA), // blue-400
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title + Completed
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              certificate.trainingTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? kWhite : kBlack,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  size: 13,
                                  color: Color(0xFF4ADE80), // green-400
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4ADE80),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Details: cert number, issue date, issuer
                  _detailRow(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF60A5FA).withOpacity(0.6),
                    text: certificate.certificateNumber,
                    mono: true,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    icon: Icons.calendar_today_outlined,
                    iconColor: Colors.purple.withOpacity(0.6),
                    text: _formatDate(certificate.issueDate),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    icon: Icons.emoji_events_outlined,
                    iconColor: Colors.amber.withOpacity(0.6),
                    text: certificate.issuerName,
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 16),

                  // ── Action buttons
                  Row(
                    children: [
                      // View (flex-1, gradient)
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                            ),
                            icon: const Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'View',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: onView,
                          ),
                        ),
                      ),

                      // Download (icon only, outlined)
                      if (onDownload != null) ...[
                        const SizedBox(width: 8),
                        _iconBtn(
                          icon: Icons.download_rounded,
                          onPressed: onDownload,
                          isDarkMode: isDarkMode,
                        ),
                      ],

                      // Share (icon only, outlined)
                      if (onShare != null) ...[
                        const SizedBox(width: 6),
                        _iconBtn(
                          icon: Icons.share_rounded,
                          onPressed: onShare,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isDarkMode,
    bool mono = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontFamily: mono ? 'monospace' : null,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isDarkMode
                    ? Colors.grey[700]!.withOpacity(0.5)
                    : Colors.grey[300]!.withOpacity(0.8),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: kBlue),
      ),
    );
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
