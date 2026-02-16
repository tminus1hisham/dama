import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class blogCard extends StatelessWidget {
  const blogCard({
    super.key,
    required this.profileImageUrl,
    required this.fullName,
    required this.blog,
    required this.heading,
    required this.imageUrl,
    required this.time,
    required this.title,
    required this.onCommentsPressed,
    required this.onLikePressed,
    required this.onSharePressed,
    required this.onPressed,
    required this.commentNumber,
    required this.likes,
    required this.isLiked,
    required this.onProfileClicked,
    required this.roles,
  });

  final String? profileImageUrl;
  final String fullName;
  final String title;
  final String time;
  final String heading;
  final String blog;
  final String imageUrl;
  final String commentNumber;
  final VoidCallback onCommentsPressed;
  final VoidCallback onLikePressed;
  final VoidCallback onSharePressed;
  final VoidCallback onPressed;
  final String likes;
  final VoidCallback onProfileClicked;
  final bool isLiked;
  final List roles;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    bool isAdminOrManager =
        roles.contains('admin') || roles.contains('manager');

    return Container(
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
            // Header with author info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: isAdminOrManager ? null : onProfileClicked,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                isDarkMode ? Color(0xFF2a3040) : kLightGrey,
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
                                    ? Icon(Icons.person, size: 20, color: kGrey)
                                    : null,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdminOrManager ? "DAMA KENYA" : fullName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? kWhite : kBlack,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                time,
                                style: TextStyle(color: kGrey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: kBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                    child: Text(
                      "Blogs",
                      style: TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Blog content
            GestureDetector(
              onDoubleTap: onLikePressed,
              onTap: onPressed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      heading,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDarkMode ? kWhite : kBlack,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Description preview
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      _stripHtmlTags(blog),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDarkMode ? Color(0xFFa0a8b8) : Color(0xFF6b7280),
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Image
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          Utils().cleanUrl(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color:
                                    isDarkMode ? Color(0xFF2a3040) : kLightGrey,
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: kGrey,
                                ),
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: Row(
                children: [
                  _buildActionButton(
                    onTap: onLikePressed,
                    icon:
                        isLiked
                            ? FontAwesomeIcons.solidThumbsUp
                            : FontAwesomeIcons.thumbsUp,
                    label: likes,
                    isActive: isLiked,
                    isDarkMode: isDarkMode,
                  ),
                  _buildActionButton(
                    onTap: onCommentsPressed,
                    icon: FontAwesomeIcons.comment,
                    label: commentNumber,
                    isActive: false,
                    isDarkMode: isDarkMode,
                  ),
                  _buildActionButton(
                    onTap: onSharePressed,
                    icon: Icons.share_outlined,
                    label: 'Share',
                    isActive: false,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDarkMode,
  }) {
    final color = isActive ? kBlue : kGrey;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stripHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }
}
