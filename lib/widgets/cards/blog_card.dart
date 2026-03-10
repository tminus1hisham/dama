import 'package:dama/models/blogs_model.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// Category colors helper class
class _CategoryColors {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  _CategoryColors({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}

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
    required this.category,
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
  final String category;
  final String commentNumber;
  final VoidCallback onCommentsPressed;
  final VoidCallback onLikePressed;
  final VoidCallback onSharePressed;
  final VoidCallback onPressed;
  final String likes;
  final VoidCallback onProfileClicked;
  final bool isLiked;
  final List roles;

  _CategoryColors _getCategoryColors(String category) {
    final cat = category.toLowerCase();
    
    if (cat.contains('science')) {
      return _CategoryColors(
        backgroundColor: const Color(0xFFECFDF5), // emerald-50
        textColor: const Color(0xFF047857), // emerald-700
        borderColor: const Color(0xFFA7F3D0), // emerald-200
      );
    } else if (cat.contains('education')) {
      return _CategoryColors(
        backgroundColor: const Color(0xFFFFF7ED), // orange-50
        textColor: const Color(0xFFC2410C), // orange-700
        borderColor: const Color(0xFFFDBA74), // orange-200
      );
    } else if (cat.contains('engineering')) {
      return _CategoryColors(
        backgroundColor: const Color(0xFFECFEFF), // cyan-50
        textColor: const Color(0xFF0E7490), // cyan-700
        borderColor: const Color(0xFF67E8F9), // cyan-200
      );
    } else if (cat.contains('technology') || cat.contains('tech')) {
      return _CategoryColors(
        backgroundColor: const Color(0xFFEEF2FF), // indigo-50
        textColor: const Color(0xFF4338CA), // indigo-700
        borderColor: const Color(0xFFC7D2FE), // indigo-200
      );
    } else if (cat.contains('politics')) {
      return _CategoryColors(
        backgroundColor: const Color(0xFFFFFBEB), // amber-50
        textColor: const Color(0xFFB45309), // amber-700
        borderColor: const Color(0xFFFCD34D), // amber-200
      );
    }
    
    // Default blue colors
    return _CategoryColors(
      backgroundColor: const Color(0xFFEFF6FF), // blue-50
      textColor: const Color(0xFF1D4ED8), // blue-700
      borderColor: const Color(0xFFBFDBFE), // blue-200
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

// Check if author has admin or manager role - only these show as "DAMA KENYA"
// All other roles (blogger, news_editor, etc.) show their actual name and profile picture
bool isAdminOrManager = roles.isNotEmpty && roles.any(
  (role) {
    final roleStr = role.toString().toLowerCase();
    return roleStr == 'admin' || roleStr == 'manager';
  },
);

// Determine display name and image
final String displayName = isAdminOrManager ? 'DAMA KENYA' : (fullName.isNotEmpty ? fullName : 'DAMA KENYA');
final ImageProvider displayImage = isAdminOrManager 
    ? kDamaLogo 
    : (profileImageUrl?.isNotEmpty == true ? NetworkImage(profileImageUrl!) : kDamaLogo);
    // Get category-specific colors
    final categoryColors = _getCategoryColors(category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? kBlack : kWhite,
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode 
            ? Border.all(color: const Color(0xFF1D2839), width: 1)
            : null,
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
                          child: ProfileAvatar(
                            radius: 25,
                            backgroundColor:
                                isDarkMode ? Color(0xFF2a3040) : kLightGrey,
                            backgroundImage: displayImage,
                            borderWidth: 0,
                            borderColor: Colors.transparent,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: isAdminOrManager ? null : onProfileClicked,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: kTitleTextSize,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? kWhite : kBlack,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  time,
                                  style: TextStyle(color: kGrey, fontSize: kBadgeTextSize),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: categoryColors.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: categoryColors.borderColor, width: 1.5),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      category.isNotEmpty ? category : "Blogs",
                      style: TextStyle(
                        color: categoryColors.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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
                        fontSize: kTitleTextSize,
                        color: isDarkMode ? kWhite : kBlack,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Description preview
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        BlogPostModel.getOpeningSentence(blog),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: kNormalTextSize,
                          color:
                              isDarkMode ? Color(0xFFa0a8b8) : Color(0xFF6b7280),
                          height: 1.4,
                        ),
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
