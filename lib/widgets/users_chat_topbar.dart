import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UsersChatTopbar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback? onNewChatPressed;

  const UsersChatTopbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.onNewChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Container(
      color: isDarkMode ? kBlack : kWhite,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: Back, Messages title, New Chat button
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                    color: kGrey,
                  ),
                  Expanded(
                    child: Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                  ),
                  if (onNewChatPressed != null)
                    GestureDetector(
                      onTap: onNewChatPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF234EC6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: kWhite, size: 18),
                            SizedBox(width: 4),
                            Text(
                              "New Chat",
                              style: TextStyle(
                                color: kWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(width: 8),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
                top: 10,
                left: 8,
                right: 8,
              ),
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDarkMode ? kDarkThemeBg : kLightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: kGrey),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                        cursorColor: isDarkMode ? kWhite : kBlue,
                        controller: searchController,
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search chats...',
                          hintStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
