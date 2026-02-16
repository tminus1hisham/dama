import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatCard extends StatelessWidget {
  const ChatCard({
    super.key,
    required this.profileImageUrl,
    required this.onTap,
    required this.name,
    required this.message,
    required this.time,
    this.unreadCount = 0,
    this.isSentByMe = false,
  });

  final String profileImageUrl;
  final VoidCallback onTap;
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    String formatChatTime(String isoTime) {
      try {
        final dateTime =
            DateTime.parse(isoTime).toLocal(); // Convert to local timezone
        final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final period = dateTime.hour >= 12 ? 'PM' : 'AM';

        return "${hour.toString().padLeft(2, '0')}:$minute $period";
      } catch (e) {
        return "";
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            color: isDarkMode ? kBlack : kWhite,
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: kLightGrey,
                              backgroundImage:
                                  profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                              child:
                                  profileImageUrl.isEmpty
                                      ? Icon(
                                        Icons.person,
                                        size: 30,
                                        color: kGrey,
                                      )
                                      : null,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: kRed,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: TextStyle(
                                        color: kWhite,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: isDarkMode ? kWhite : kBlack,
                                  fontSize: kNormalTextSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  if (isSentByMe)
                                    Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.done_all,
                                        size: 14,
                                        color: kBlue,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        color:
                                            unreadCount > 0
                                                ? (isDarkMode ? kWhite : kBlack)
                                                : kGrey,
                                        fontWeight:
                                            unreadCount > 0
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatChatTime(time),
                        style: TextStyle(
                          color: unreadCount > 0 ? kBlue : kGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: isDarkMode ? kBlack : kWhite,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                height: 2,
                color: isDarkMode ? kDarkThemeBg : kBGColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
