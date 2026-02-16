import 'package:dama/models/blogs_model.dart' show SourceReference;
import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SourcesReferencesSection extends StatelessWidget {
  final List<SourceReference> sources;
  final bool isDarkMode;

  const SourcesReferencesSection({
    super.key,
    required this.sources,
    required this.isDarkMode,
  });

  Future<void> _launchUrl(String url) async {
    String fullUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      fullUrl = 'https://$url';
    }
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  String _extractDomain(String url) {
    try {
      String cleanUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        cleanUrl = 'https://$url';
      }
      final uri = Uri.parse(cleanUrl);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? kBlack : kBGColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? kGrey.withOpacity(0.2) : kLightGrey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: kBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sources & References',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? kWhite : kBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sources.asMap().entries.map((entry) {
            final index = entry.key;
            final source = entry.value;
            final domain = _extractDomain(source.url);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => _launchUrl(source.url),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: kBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: kBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and URL
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.title,
                            style: TextStyle(
                              color: isDarkMode ? kWhite : kBlack,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            domain,
                            style: TextStyle(
                              color: kBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // External link icon
                    Icon(
                      Icons.open_in_new,
                      color: kGrey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
