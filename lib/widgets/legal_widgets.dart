import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';

// Reusable helper widgets for legal documents
Widget buildHeader(String title, bool isDarkMode) {
  return Text(
    title,
    style: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? kWhite : kBlack,
    ),
  );
}

Widget buildLastUpdated(String date, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      'Last updated $date',
      style: TextStyle(
        fontSize: 14,
        color: isDarkMode ? const Color(0xFFa0a8b8) : kGrey,
        fontStyle: FontStyle.italic,
      ),
    ),
  );
}

Widget buildSectionTitle(String title, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? kWhite : kBlack,
      ),
    ),
  );
}

Widget buildSubsectionTitle(String title, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? const Color(0xFFe0e0e0) : const Color(0xFF333333),
      ),
    ),
  );
}

Widget buildParagraph(String text, bool isDarkMode, {bool isItalic = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: isDarkMode ? const Color(0xFFd0d0d0) : const Color(0xFF444444),
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      ),
    ),
  );
}

Widget buildBulletPoint(String text, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            fontSize: 15,
            color: kBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color:
                  isDarkMode
                      ? const Color(0xFFd0d0d0)
                      : const Color(0xFF444444),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildContactInfo(bool isDarkMode, {bool includePhone = false}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDarkMode ? kDarkCard : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDarkMode ? kGlassBorder : const Color(0xFFE0E0E0),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dama Kenya',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? kWhite : kBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Western Heights, Karuna Rd\nWestlands, Nairobi\nKenya',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color:
                isDarkMode ? const Color(0xFFd0d0d0) : const Color(0xFF444444),
          ),
        ),
        if (includePhone) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: kBlue),
              const SizedBox(width: 8),
              Text(
                '+254 797 302 010',
                style: TextStyle(fontSize: 14, color: kBlue),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.email, size: 16, color: kBlue),
            const SizedBox(width: 8),
            Text(
              'info@damakenya.org',
              style: TextStyle(fontSize: 14, color: kBlue),
            ),
          ],
        ),
      ],
    ),
  );
}
