import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final bool isRequired;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    final dropdownItems =
        items.asMap().entries.map((entry) {
          final index = entry.key;
          final choice = entry.value;
          final isPlaceholder = index == 0;

          return DropdownMenuItem<String>(
            value: isPlaceholder ? null : choice,
            enabled: !isPlaceholder,
            child: Text(
              choice,
              style: TextStyle(
                color:
                    isPlaceholder
                        ? (isDarkMode ? Colors.white : kGrey)
                        : (isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          );
        }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSidePadding,
        vertical: 5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDarkMode ? kWhite : kBlack)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: value == items[0] ? null : value,
            items: dropdownItems,
            onChanged: onChanged,
            validator:
                isRequired
                    ? (val) {
                      if (val == null || val.isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    }
                    : null,
            dropdownColor: isDarkMode ? kBlack : kWhite,
            decoration: InputDecoration(
              fillColor: isDarkMode ? kDarkThemeBg : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: kSidePadding,
              ),
              hintText: items[0],
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[600] : kGrey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: kBlue, width: 1.0),
              ),
            ),
            style: TextStyle(
              color:
                  (value == null || value == items[0])
                      ? (isDarkMode ? Colors.grey[400] : kGrey)
                      : (isDarkMode ? Colors.white : Colors.black),
              fontSize: kTitleTextSize,
              fontWeight: FontWeight.w400,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: isDarkMode ? kWhite : kBlack,
            ),
          ),
        ],
      ),
    );
  }
}
