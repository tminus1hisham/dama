import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/views/selected_screens/selected_resource_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResourceSearchCard extends StatelessWidget {
  final Map<String, dynamic>? resource;

  ResourceSearchCard({super.key, required this.resource});

  final Utils _utils = Utils();

  String truncateText(String? text, [int maxLength = 60]) {
    if (text == null || text.isEmpty) return '';
    return text.length <= maxLength
        ? text
        : '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final title = resource?['title'] ?? 'No Title';
    final description = resource?['description'] ?? 'No Description';
    final imageUrl = resource?['resource_image_url'];
    final createdAtStr = resource?['created_at'];
    final createdAt =
        createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    final resourceId = resource?['_id'] ?? '';
    final price = resource?['price'] ?? 0;
    final link = resource?['resource_link'] ?? '';
    final downloads = resource?['downloads'];
    final rating = downloads is num ? downloads.toDouble() : 0.0;

    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return GestureDetector(
      onTap: () {
        if (createdAt != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SelectedResourceScreen(
                    resourceID: resourceId,
                    isPaid: price > 0,
                    title: title,
                    imageUrl: imageUrl ?? '',
                    description: description,
                    price:
                        price is int
                            ? price
                            : int.tryParse(price.toString()) ?? 0,
                    viewUrl: link,
                    date: createdAt,
                    rating: rating,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid blog data')));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDarkMode ? kBlack : kWhite),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  imageUrl != null && imageUrl.toString().isNotEmpty
                      ? Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, color: Colors.white70),
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDarkMode ? kWhite : kBlack,
                      fontSize: kTitleTextSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    truncateText(description, 80),
                    style: const TextStyle(
                      fontSize: kNormalTextSize,
                      color: Colors.grey,
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _utils.timeAgo(createdAt),
                      style: const TextStyle(
                        fontSize: kSmallTextSize,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
