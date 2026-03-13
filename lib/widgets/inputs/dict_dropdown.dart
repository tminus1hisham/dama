import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme_provider.dart';

class DictDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> items;
  final bool isRequired;
  final Function(String?) onChanged;

  const DictDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: isDarkMode ? kBlack : kWhite,
        iconEnabledColor: isDarkMode ? kWhite : kBlack,
        style: TextStyle(color: isDarkMode ? kWhite : kBlack, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDarkMode ? kWhite : kGrey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? kGrey : kGrey.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kBlue, width: 2),
          ),
          filled: true,
          fillColor: isDarkMode ? kDarkThemeBg : kBGColor,
          contentPadding: const EdgeInsets.all(16),
        ),
        items:
            items.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.value,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: isDarkMode ? kWhite : kBlack, // ✅ Fix here
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
