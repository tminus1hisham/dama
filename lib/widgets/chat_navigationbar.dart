import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatNavigationAppbar extends StatelessWidget {
  const ChatNavigationAppbar({super.key, required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Container(
      color: isDarkMode ? kBlack : kWhite,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios),
              color: kGrey,
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: kLightGrey,
              backgroundImage:
                  (imageUrl == null || imageUrl!.isEmpty)
                      ? null
                      : NetworkImage(imageUrl!),
              child:
                  (imageUrl == null || imageUrl!.isEmpty)
                      ? Icon(Icons.person, size: 30, color: kGrey)
                      : null,
            ),
            const SizedBox(width: 10),
            Text(name, style: TextStyle(color: isDarkMode ? kWhite : kBlack),),
          ],
        ),
      ),
    );
  }
}
