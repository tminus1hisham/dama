import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopNavigationbar extends StatelessWidget {
  const TopNavigationbar({
    required this.title,
    this.onBack,
    this.actions,
    super.key,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  String _truncateTitle(String text) {
    List<String> words = text.split(' ');
    if (words.length <= 4) {
      return text;
    } else {
      return '${words.sublist(0, 4).join(' ')} ...';
    }
  }

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
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (onBack != null) {
                    onBack!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: Icon(Icons.arrow_back_ios),
                color: kGrey,
              ),
              Expanded(
                child: Text(
                  _truncateTitle(title),
                  style: TextStyle(
                    fontSize: kMidText,
                    color: isDarkMode ? kWhite : kBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
