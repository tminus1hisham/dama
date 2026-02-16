import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../views/selected_screens/selected_blog_screen.dart';

class BlogSearchCard extends StatelessWidget {
  final Map<String, dynamic>? blog;

  BlogSearchCard({super.key, required this.blog});

  final Utils _utils = Utils();

  String truncateText(String? text, [int maxLength = 60]) {
    if (text == null || text.isEmpty) return '';
    return text.length <= maxLength
        ? text
        : '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final title = blog?['title'] ?? 'No Title';
    final description = blog?['description'] ?? 'No Description';
    final imageUrl = blog?['image_url'];
    final createdAtString = blog?['created_at'];
    final createdAt =
        createdAtString != null ? DateTime.tryParse(createdAtString) : null;

    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return GestureDetector(
      onTap: () {
        if (createdAt != null) {
          final author = blog?['author'];
          final isAuthorMap = author is Map;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SelectedBlogScreen(
                    roles: isAuthorMap ? author['roles'] ?? [] : [],
                    comments: blog?['comments'],
                    blogId: blog?['_id'],
                    authorId: blog?['author'],
                    userId: blog?['author'],
                    title: title,
                    imageUrl: imageUrl ?? '',
                    createdAt: createdAt,
                    description: description,
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
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white70,
                              ),
                            ),
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
                    truncateText(title, 80),
                    style: TextStyle(
                      color: isDarkMode ? kWhite : kBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // const SizedBox(height: 6),
                  // Html(
                  //   data: truncateText(description, 80),
                  //   style: {
                  //     "*": Style(color: isDarkMode ? kWhite : kBlack),
                  //     "h2": Style(fontSize: FontSize.large, fontWeight: FontWeight.bold, color: isDarkMode ? kWhite : kBlack,),
                  //     "p": Style(fontSize: FontSize.large, color: isDarkMode ? kWhite : kBlack,),
                  //     "strong": Style(fontWeight: FontWeight.bold, color: isDarkMode ? kWhite : kBlack,),
                  //     "em": Style(fontStyle: FontStyle.italic, color: isDarkMode ? kWhite : kBlack,),
                  //   },
                  // ),
                  // Text(
                  //   truncateText(description, 80),
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     color: Colors.grey,
                  //   ),
                  // ),
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
