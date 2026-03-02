import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SelectedEventCard extends StatelessWidget {
  const SelectedEventCard({
    super.key,
    required this.heading,
    required this.imageUrl,
    required this.date,
    required this.location,
    required this.price,
    required this.description,
    required this.isPaid,
    required this.onPay,
  });

  final DateTime date;
  final String heading;
  final String imageUrl;
  final String price;
  final String location;
  final String description;
  final bool isPaid;
  final VoidCallback onPay;

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
            // Event Image
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
            const SizedBox(height: 10),

            // Heading (remains bold/larger)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kSidePadding,
                vertical: 10,
              ),
              child: Text(
                heading,
                style: TextStyle(
                  color: isDarkMode ? kWhite : kBlack,
                  fontSize: kMidText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Date + Location (secondary style)
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          location,
                          style: TextStyle(
                            color: kBlue,
                            fontSize: kMidText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kSidePadding,
                vertical: 10,
              ),
              child: Container(
                color: isDarkMode ? kDarkThemeBg : kBGColor,
                height: 2,
              ),
            ),

            const SizedBox(height: 10),

            // Price + Action Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isPaid) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price",
                          style: TextStyle(
                            color: kGrey,
                            fontSize: kNormalTextSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'KES $price',
                          style: TextStyle(
                            fontSize: kBigTextSize,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: CustomButton(
                        callBackFunction: isPast ? null : onPay,
                        label: isPast ? "EVENT PAST" : "RSVP",
                        backgroundColor: isPast ? Colors.grey : kBlue,
                        // If CustomButton supports textStyle, use this:
                        // textStyle: TextStyle(
                        //   fontSize: kNormalTextSize,     // smaller, like date/location
                        //   fontWeight: FontWeight.w600,    // semi-bold, matches secondary text
                        //   color: kWhite,
                        // ),
                      ),
                    ),
                  ],

                  if (isPaid) ...[
                    Expanded(
                      child: CustomButton(
                        callBackFunction: () {},
                        label: "ATTENDING",
                        backgroundColor: kGreen,
                        // textStyle: TextStyle(
                        //   fontSize: kNormalTextSize,
                        //   fontWeight: FontWeight.w600,
                        //   color: kWhite,
                        // ),
                      ),
                    ),
                  ],

                  const SizedBox(width: 10),

                  // Share button
                  GestureDetector(
                    onTap: () {
                      final link = 'https://mydama.damakenya.org/';
                      Share.share(
                        'Check out this event on Dama Kenya: $heading\n$link',
                        subject: 'Dama Kenya',
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: kBlue, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.share, color: kBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // About Event
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Text(
                "About Event",
                style: TextStyle(
                  color: isDarkMode ? kWhite : kBlack,
                  fontSize: kMidText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: kMidText,
                  color: isDarkMode ? kWhite : kGrey,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}