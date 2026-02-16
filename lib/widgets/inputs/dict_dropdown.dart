import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DictDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> items;
  final Function(String?) onChanged;
  final bool isRequired;

  const DictDropdown({
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

    final dropdownItems = items.entries.map((entry) {
      final display = entry.key;
      final realValue = entry.value;
      final isPlaceholder = realValue.isEmpty;

      return DropdownMenuItem<String>(
        value: isPlaceholder ? null : realValue,
        enabled: !isPlaceholder,
        child: Text(
          display,
          style: TextStyle(
            color: isPlaceholder
                ? (isDarkMode ? Colors.grey[600] : kGrey)
                : (isDarkMode ? Colors.white : Colors.black),
          ),
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSidePadding, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? kWhite : kBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: value?.isEmpty ?? true ? null : value,
            items: dropdownItems,
            onChanged: onChanged,
            validator: isRequired
                ? (val) {
              if (val == null || val.isEmpty) {
                return 'This field is required';
              }
              return null;
            }
                : null,
            dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            decoration: InputDecoration(
              fillColor: isDarkMode ? kDarkThemeBg : Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0, horizontal: kSidePadding),
              hintText: items.keys.first,
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[500] : kGrey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide:
                BorderSide(color: isDarkMode ? kBlue : kBlue, width: 1.0),
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            icon: Icon(Icons.arrow_drop_down,
                color: isDarkMode ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }
}
