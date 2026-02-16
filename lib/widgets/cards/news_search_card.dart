import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/views/selected_screens/selected_news_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewsSearchCard extends StatelessWidget {
  final Map<String, dynamic>? news;

  NewsSearchCard({super.key, required this.news});

  final Utils _utils = Utils();

  String truncateText(String? text, [int maxLength = 60]) {
    if (text == null || text.isEmpty) return '';
    return text.length <= maxLength
        ? text
        : '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final title = news?['title'] ?? 'No Title';
    final description = news?['description'] ?? 'No Description';
    final imageUrl = news?['image_url'];
    final createdAtString = news?['created_at'];
    final createdAt =
        createdAtString != null ? DateTime.tryParse(createdAtString) : null;

    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return GestureDetector(
      onTap: () {
        if (createdAt != null) {
          final author = news?['author'];
          final isAuthorMap = author is Map;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SelectedNewsScreen(
                    roles: isAuthorMap ? author['roles'] : [],
                    newsId: news?['_id'],
                    comments: news?['comments'],
                    authorID: news?['author'],
                    profileImageUrl: imageUrl ?? '',
                    title: title,
                    imageUrl: imageUrl ?? '',
                    author: "Author name",
                    createdAt: _utils.timeAgo(createdAt),
                    description: description,
                    userId: author,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _utils.timeAgo(createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
