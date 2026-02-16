import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UsersChatTopbar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;

  const UsersChatTopbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 10),
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
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? kDarkThemeBg : kLightGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                          cursorColor: isDarkMode ? kWhite : kBlue,
                          controller: searchController,
                          onChanged: onSearchChanged,
                          decoration:  InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        color: kGrey,
                        onPressed: () {},
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
