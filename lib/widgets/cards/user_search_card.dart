import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/other_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserSearchCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserSearchCard({super.key, required this.user});

  String _getFullName(String? firstName, String? lastName) {
    final fn = firstName ?? '';
    final ln = lastName ?? '';
    return ('$fn $ln').trim().isEmpty ? 'Unknown User' : '$fn $ln';
  }

  @override
  Widget build(BuildContext context) {
    final String userId = user['_id']?.toString() ?? '';
    final String fullName = _getFullName(user['firstName'], user['lastName']);
    final String title = user['title']?.toString() ?? 'No title';
    final String profilePicture = user['profile_picture']?.toString() ?? '';

    final bool hasValidProfilePicture =
        profilePicture.isNotEmpty &&
        Uri.tryParse(profilePicture)?.hasAbsolutePath == true;

    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return GestureDetector(
      onTap:
          userId.isNotEmpty
              ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherUserProfile(userID: userId),
                  ),
                );
              }
              : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? kBlack : kWhite,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child:
                  hasValidProfilePicture
                      ? Image.network(
                        profilePicture,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.person, color: Colors.white70),
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      color: isDarkMode ? kWhite : kBlack,
                      fontSize: kTitleTextSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: kNormalTextSize,
                      color: isDarkMode ? kWhite : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
