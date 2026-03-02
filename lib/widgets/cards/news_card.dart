import 'package:dama/models/news_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key, 
    required this.profileImageUrl,
    required this.fullName,
    required this.heading,
    required this.description,
    required this.imageUrl,
    required this.time,
    required this.category,
    required this.onPressed,
    required this.onCommentsPressed,
    required this.onLikePressed,
    required this.onSharePressed,
    required this.commentNumber,
    required this.likes,
    required this.isLiked,
    required this.onProfileClicked,
    required this.roles,
  });

  final String? profileImageUrl;
  final String fullName;
  final String time;
  final String heading;
  final String description;
  final String imageUrl;
  final String category;
  final VoidCallback onPressed;
  final String commentNumber;
  final VoidCallback onCommentsPressed;
  final VoidCallback onLikePressed;
  final VoidCallback onSharePressed;
  final String likes;
  final bool isLiked;
  final VoidCallback onProfileClicked;
  final List roles;

  // Category-based colors map
  Map<String, Color> _getCategoryColors(String category) {
    final lowerCategory = category.toLowerCase();
    switch (lowerCategory) {
      case 'science':
        return {
          'bg': const Color(0xFFECFDF5), // emerald-50
          'text': const Color(0xFF047857), // emerald-700
          'border': const Color(0xFFA7F3D0), // emerald-200
        };
      case 'education':
        return {
          'bg': const Color(0xFFFFF7ED), // orange-50
          'text': const Color(0xFFC2410C), // orange-700
          'border': const Color(0xFFFDBA74), // orange-200
        };
      case 'engineering':
        return {
          'bg': const Color(0xFFECFEFF), // cyan-50
          'text': const Color(0xFF0891B2), // cyan-700
          'border': const Color(0xFFA5F3FC), // cyan-200
        };
      case 'technology':
        return {
          'bg': const Color(0xFFEEF2FF), // indigo-50
          'text': const Color(0xFF4F46E5), // indigo-700
          'border': const Color(0xFFC7D2FE), // indigo-200
        };
      case 'politics':
        return {
          'bg': const Color(0xFFFFFBEB), // amber-50
          'text': const Color(0xFFB45309), // amber-700
          'border': const Color(0xFFFCD34D), // amber-200
        };
      default:
        return {
          'bg': kWhite,
          'text': kOrange,
          'border': kOrange.withOpacity(0.3),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    // Check if author has official role (admin, news editor, or blogger)
    // This is informational only - all posts show DAMA logo since only these roles can post
    bool isOfficialAuthor = roles.isNotEmpty && roles.any(
      (role) {
        final roleStr = role.toString().toLowerCase();
        return roleStr == 'admin' || 
               roleStr == 'news editor' || 
               roleStr == 'news_editor' || 
               roleStr == 'newseditor' || 
               roleStr == 'blogger';
      },
    );
    
    debugPrint('\n=== [NewsCard Build] ===');
    debugPrint('Author: "$fullName" (length: ${fullName.length})');
    debugPrint('Profile Image URL: "$profileImageUrl" (length: ${profileImageUrl?.length ?? 0})');
    debugPrint('Raw Roles: $roles');
    debugPrint('Roles Count: ${roles.length}');
    debugPrint('isOfficialAuthor: $isOfficialAuthor');
    debugPrint('=== [End NewsCard Build] ===\n');
    
    final categoryColors = _getCategoryColors(category);

    return Container(
      width: 300, // Fixed width for horizontal scrolling
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? kBlack : kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 10, right: 15, top: 23),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileAvatar(
                          radius: 32,
                          backgroundColor: kLightGrey,
                          backgroundImage: kDamaLogo,
                          borderWidth: 0,
                          borderColor: Colors.transparent,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DAMA KENYA",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                            ),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: kNormalTextSize,
                                color: kGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: categoryColors['bg'],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: categoryColors['border'] as Color, 
                        width: 1.5,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 7,
                    ),
                    child: Text(
                      category.isNotEmpty ? category : "News",
                      style: TextStyle(
                        color: categoryColors['text'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onDoubleTap: onLikePressed,
              onTap: onPressed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: 10,
                      left: 10,
                      right: kSidePadding,
                      bottom: 10,
                    ),
                    child: Text(
                      heading,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: 10,
                        right: kSidePadding,
                        bottom: 10,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          NewsModel.getOpeningSentence(description),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? kGrey : kGrey,
                          ),
                        ),
                      ),
                    ),
                  ],
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[200],
                    child:
                        (imageUrl.isNotEmpty &&
                                Uri.tryParse(imageUrl)?.hasAbsolutePath == true)
                            ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                            : const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: onLikePressed,
                    child: Container(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Icon(
                            isLiked
                                ? FontAwesomeIcons.solidThumbsUp
                                : FontAwesomeIcons.thumbsUp,
                            color: isLiked ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Likes $likes',
                            style: TextStyle(color: isLiked ? kBlue : kGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCommentsPressed,
                    child: Container(
                      child: Row(
                        children: [
                          const Icon(FontAwesomeIcons.comment, color: kGrey),
                          const SizedBox(width: 5),
                          Text(
                            'Comments $commentNumber',
                            style: TextStyle(color: kGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onSharePressed,
                    child: Container(
                      child: Row(
                        children: [
                          const Icon(Icons.share, color: kGrey),
                          const SizedBox(width: 5),
                          const Text('Share', style: TextStyle(color: kGrey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stripHtmlAndTruncate(String input, int maxLength) {
    // First try to parse as HTML
    try {
      final document = html_parser.parse(input);
      final text = document.body?.text ?? '';
      if (text.isNotEmpty) {
        // It was HTML, use the parsed text
        final result = text.length <= maxLength ? text : '${text.substring(0, maxLength)}...';
        return result;
      }
    } catch (e) {
      // Not valid HTML, treat as plain text
    }
    
    // Treat as plain text
    if (input.length <= maxLength) return input;
    return '${input.substring(0, maxLength)}...';
  }
}
