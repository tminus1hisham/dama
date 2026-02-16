import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/views/selected_screens/selected_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventSearchCard extends StatelessWidget {
  final Map<String, dynamic>? event;

  EventSearchCard({super.key, required this.event});

  final Utils _utils = Utils();

  String truncateText(String? text, [int maxLength = 60]) {
    if (text == null || text.isEmpty) return '';
    return text.length <= maxLength
        ? text
        : '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final eventTitle = event?['event_title'] ?? 'No Title';
    final description = event?['description'] ?? 'No Description';
    final imageUrl = event?['event_image_url'];
    final createdAtString = event?['created_at'];
    final createdAt =
    createdAtString != null ? DateTime.tryParse(createdAtString) : null;
    final eventId = event?['_id'] ?? '';
    final speakers = event?['speakers'] ?? [];
    final price = event?['price'] ?? 0;
    final location = event?['location'] ?? 'No Location';

    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return GestureDetector(
      onTap: () {
        if (createdAt != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SelectedEventScreen(
                eventID: eventId,
                isPaid: false,
                speakers: speakers,
                description: description,
                title: eventTitle,
                price: price,
                date: createdAt,
                imageUrl: imageUrl ?? '',
                location: location,
                fromSearch: true,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid blog data')),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? kBlack : kWhite,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null && imageUrl.toString().isNotEmpty
                  ? Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTitle,
                    style: TextStyle(
                      color: isDarkMode ? kWhite : kBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    truncateText(description, 80),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _utils.timeAgo(createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
