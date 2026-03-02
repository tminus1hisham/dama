import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.heading,
    required this.imageUrl,
    required this.date,
    required this.location,
    required this.price,
    required this.onPressed,
    this.isConfirmed = false,
    this.onViewTicket,
  });

  final DateTime date;
  final String heading;
  final String imageUrl;
  final int price;
  final String location;
  final VoidCallback onPressed;
  final bool isConfirmed;
  final VoidCallback? onViewTicket;

  Uri _mapsUrl(String location) => Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
      );

  Future<void> _openMaps(BuildContext context, String location) async {
    final uri = _mapsUrl(location);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  Event _calendarEvent(DateTime start, String title, String location) {
    final end = start.add(const Duration(hours: 2));
    return Event(
      title: title,
      description: 'Event from the Dama Kenya app',
      location: location,
      startDate: start,
      endDate: end,
      iosParams: const IOSParams(reminder: Duration(hours: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    final isPast = date.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        color: isDarkMode ? kBlack : kWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title + Confirmed badge
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kSidePadding,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      heading,
                      style: TextStyle(
                        fontSize: kMidText,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? kWhite : kBlack,
                      ),
                    ),
                  ),
                  if (isConfirmed) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kGreen),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: kGreen, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Confirmed',
                            style: TextStyle(
                              color: kGreen,
                              fontSize: 12,               // smaller, like secondary text
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Date + Location row – secondary style
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final event = _calendarEvent(date, heading, location);
                      Add2Calendar.addEvent2Cal(event);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, color: kGrey),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(date),
                          style: TextStyle(
                            color: kGrey,
                            fontSize: kMidText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      Icon(Icons.pin_drop_outlined, color: kBlue),
                      const SizedBox(width: 10),
                      Text(
                        location,
                        style: TextStyle(
                          color: kBlue,
                          fontSize: kMidText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Image + overlays
            GestureDetector(
              onTap: onPressed,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 250,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),

                  // View Details button
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton.icon(
                        onPressed: onPressed,
                        icon: const Icon(Icons.info_outline,
                            color: kWhite, size: 18),
                        label: const Text(
                          'View Details',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),

                  // Price tag – smaller font, matches surrounding secondary text
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        price > 0 ? 'KES $price' : 'FREE',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 13,                   // smaller to match date/location style
                          fontWeight: FontWeight.w600,    // semi-bold, not heavy
                        ),
                      ),
                    ),
                  ),

                  // PAST EVENT badge – also smaller font
                  if (isPast)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: const Text(
                          'PAST EVENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,                   // smaller
                            fontWeight: FontWeight.w600,    // matches secondary text
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Confirmed event action buttons
            if (isConfirmed) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: kSidePadding,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPressed,
                        icon: const Icon(Icons.event, color: kBlue, size: 18),
                        label: const Text(
                          'View Event',
                          style: TextStyle(
                            color: kBlue,
                            fontSize: 14,              // slightly smaller
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onViewTicket,
                        icon: const Icon(
                          Icons.confirmation_number,
                          color: kWhite,
                          size: 18,
                        ),
                        label: const Text(
                          'View Ticket',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 14,              // smaller
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}