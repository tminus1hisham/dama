import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, 
    required this.profileImageUrl,
    required this.fullName,
    required this.heading,
    required this.description,
    required this.imageUrl,
    required this.time,
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
  final VoidCallback onPressed;
  final String commentNumber;
  final VoidCallback onCommentsPressed;
  final VoidCallback onLikePressed;
  final VoidCallback onSharePressed;
  final String likes;
  final bool isLiked;
  final VoidCallback onProfileClicked;
  final List roles;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    bool isAdminOrManager =
        roles.contains('admin') || roles.contains('manager');

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
                        child: GestureDetector(
                          onTap: isAdminOrManager ? null : onProfileClicked,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: kLightGrey,
                                backgroundImage:
                                    isAdminOrManager
                                        ? kDamaLogo
                                        : (profileImageUrl != null &&
                                            profileImageUrl!.isNotEmpty &&
                                            profileImageUrl != 'null')
                                        ? NetworkImage(profileImageUrl!)
                                        : null,
                                child:
                                    (!isAdminOrManager &&
                                            (profileImageUrl == null ||
                                                profileImageUrl!.isEmpty ||
                                                profileImageUrl == 'null'))
                                        ? const Icon(
                                          Icons.person,
                                          size: 30,
                                          color: kGrey,
                                        )
                                        : null,
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAdminOrManager ? "DAMA KENYA" : fullName,
                                    style: TextStyle(
                                      fontSize: kMidText,
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
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: kOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 7,
                    ),
                    child: Text(
                      "News",
                      style: TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                      heading,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: 10,
                        right: kSidePadding,
                        bottom: 10,
                      ),
                      child: Text(
                        _stripHtmlAndTruncate(description, 100),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? kGrey : kGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
