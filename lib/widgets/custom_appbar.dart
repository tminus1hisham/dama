import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class CustomAppbar extends StatefulWidget {
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
  State<CustomAppbar> createState() => _CustomAppbarState();
}

class _CustomAppbarState extends State<CustomAppbar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDark;

    return Container(
      color: isDarkMode ? kBlack : kWhite,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onMenuTap,
              child: ProfileAvatar(
                radius: 22,
                backgroundColor: kLightGrey,
                backgroundImage:
                    (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                        ? NetworkImage(widget.imageUrl!)
                        : null,
                borderColor: kBlue,
                borderWidth: 3,
                animateBorder: true,
                glowColor: kBlue,
                child:
                    (widget.imageUrl == null || widget.imageUrl!.isEmpty)
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
                  color:
                      isDarkMode
                          ? const Color(0xFF1a2537)
                          : const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    return TextField(
                      style: TextStyle(
                        color: isDarkMode ? kWhite : kBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      controller: _searchController,
                      cursorColor: kBlue,
                      cursorWidth: 2,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[500] : Colors.grey[500],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        prefixIcon: null,
                        suffixIcon: null,
                        prefixIconConstraints: BoxConstraints(),
                        suffixIconConstraints: BoxConstraints(),
                      ),
                      onSubmitted: (query) {
                        if (widget.onSearchSubmitted != null) {
                          widget.onSearchSubmitted!(query);
                        }
                        _searchController.clear();
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_searchController.text.isNotEmpty &&
                    widget.onSearchSubmitted != null) {
                  widget.onSearchSubmitted!(_searchController.text);
                  _searchController.clear();
                }
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.search,
                  size: 20,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 5),
            IconButton(
              onPressed: widget.onChatTap,
              icon: Icon(FontAwesomeIcons.comment, size: 18),
              color: kGrey,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: widget.onNotificationTap,
                  icon: Icon(Icons.notifications_outlined),
                  color: kGrey,
                ),
                if (widget.unreadNotificationCount > 0)
                  Positioned(
                    right: 2,
                    top: 4,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          widget.unreadNotificationCount > 99
                              ? '99+'
                              : widget.unreadNotificationCount.toString(),
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
