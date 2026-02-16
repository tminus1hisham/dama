import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomIconButton extends StatefulWidget {
  const CustomIconButton({super.key, 
    required this.callBackFunction,
    required this.label,
    required this.icon,
  });

  final VoidCallback callBackFunction;
  final String label;
  final IconData icon;

  @override
  _CustomIconButtonState createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return ElevatedButton(
      onPressed: () {
        widget.callBackFunction();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:  isDarkMode ? kDarkThemeBg : kWhite,
        side: BorderSide(color: kBlue, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: isDarkMode ? kWhite : kBlue, size: 25),
            SizedBox(width: 5),
            Text(widget.label, style: TextStyle(color: isDarkMode ? kWhite : kBlue, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
