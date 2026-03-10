import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class CustomAppbar extends StatelessWidget {
  const CustomAppbar({
    super.key,
    required this.onMenuTap,
    required this.imageUrl,
    required this.onChatTap,
    this.onSearchSubmitted,
    required this.onNotificationTap,
    required this.unreadNotificationCount,
  });

  final VoidCallback onMenuTap;
  final String? imageUrl;
  final VoidCallback onChatTap;
  final Function(String)? onSearchSubmitted;
  final VoidCallback onNotificationTap;
  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    return Container(
      color: isDarkMode ? kBlack : kWhite,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: onMenuTap,
              child: ProfileAvatar(
                radius: 22,
                backgroundColor: kLightGrey,
                backgroundImage:
                    (imageUrl != null && imageUrl!.isNotEmpty)
                        ? NetworkImage(imageUrl!)
                        : null,
                borderColor: kBlue,
                borderWidth: 3,
                animateBorder: true,
                glowColor: kBlue,
                child:
                    (imageUrl == null || imageUrl!.isEmpty)
                        ? Icon(Icons.person, size: 30, color: kGrey)
                        : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 45,
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDarkMode ? kDarkThemeBg : kLightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  style: TextStyle(
                    color: isDarkMode ? kWhite : kBlack,
                  ),
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 12, right: 0, top: 12, bottom: 12),
                    suffixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 24),
                    suffixIcon: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        color: kGrey,
                        iconSize: 20,
                        padding: EdgeInsets.only(right: 8),
                        onPressed: () {
                          if (searchController.text.isNotEmpty &&
                              onSearchSubmitted != null) {
                            onSearchSubmitted!(searchController.text);
                            searchController.clear();
                          }
                        },
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  onSubmitted: (query) {
                    if (onSearchSubmitted != null) {
                      onSearchSubmitted!(query);
                    }
                    searchController.clear();
                  },
                ),
              ),
            ),
            const SizedBox(width: 5),
            IconButton(
              onPressed: onChatTap,
              icon: Icon(FontAwesomeIcons.comment, size: 18),
              color: kGrey,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: onNotificationTap,
                  icon: Icon(Icons.notifications_outlined),
                  color: kGrey,
                ),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: 2,
                    top: 4,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          unreadNotificationCount > 99 ? '99+' : unreadNotificationCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
