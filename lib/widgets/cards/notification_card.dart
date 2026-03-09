import 'package:dama/utils/constants.dart';
import 'package:dama/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/theme_provider.dart';

class NotoficationCard extends StatelessWidget {
  NotoficationCard({super.key, 
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
    this.priority = NotificationPriority.normal,
    this.onTap,
    this.onDismiss,
    this.showActions = true,
  });

  final String title;
  final String body;
  final String date;
  final bool isRead;
  final NotificationPriority priority;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showActions;

  final Utils _utils = Utils();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Container(
      margin: EdgeInsets.only(bottom: 3, top: 3),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkBG : kWhite,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: _getBorderColor(isDarkMode), width: 1),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with priority indicator and timestamp
                Row(
                  children: [
                    // Priority indicator
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Title with read/unread indicator
                    Expanded(
                      child: Row(
                        children: [
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: kBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: _getTitleColor(isDarkMode),
                                fontSize: 15,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Timestamp
                    Text(
                      _utils.formatUtcToLocal(date),
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Body text with better formatting
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTitleColor(bool isDarkMode) {
    if (isDarkMode) {
      return isRead ? Colors.grey[300]! : Colors.white;
    }
    return isRead ? Colors.grey[600]! : Colors.black87;
  }

  Color _getPriorityColor() {
    switch (priority) {
      case NotificationPriority.high:
        return Colors.red;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.low:
        return Colors.green;
      case NotificationPriority.normal:
        return kBlue;
    }
  }
}

// Enum for notification priorities
enum NotificationPriority { low, normal, medium, high }

// Alternative compact version for dense layouts
class CompactNotificationCard extends StatelessWidget {
  CompactNotificationCard({super.key, 
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
    this.onTap,
  });

  final String title;
  final String body;
  final String date;
  final bool isRead;
  final VoidCallback? onTap;

  final Utils _utils = Utils();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkBG : kWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Read/unread indicator
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isRead ? Colors.transparent : kBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isRead ? FontWeight.w400 : FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _utils.formatUtcToLocal(date),
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationDetailModal extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final Utils _utils = Utils();

  NotificationDetailModal({super.key, 
    required this.title,
    required this.body,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkCard : kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                // color: ,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Priority indicator
                  Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      color: kBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(width: 12),

                  // Title and close button
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Notification Details",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section

                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      _utils.formatUtcToLocal(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Body
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        body,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer actions
          ],
        ),
      ),
    );
  }
}
