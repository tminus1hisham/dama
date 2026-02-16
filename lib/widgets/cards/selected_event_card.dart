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

  Future<void> _openMaps(BuildContext context, location) async {
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
    bool isDarkMode = themeProvider.isDark;

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Container(
        color: isDarkMode ? kBlack : kWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child:
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Center(
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
            ),
            SizedBox(height: 10),
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
                        SizedBox(width: 10),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(date),
                          style: TextStyle(color: kGrey, fontSize: kMidText),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Row(
                    children: [
                      Icon(Icons.pin_drop_outlined, color: kBlue),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          location,
                          style: TextStyle(color: kBlue, fontSize: kMidText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: kSidePadding),
              child: Row(
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
                          ),
                        ),
                        Text(
                          'KES $price',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: kBigTextSize,
                            color: isDarkMode ? kWhite : kBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      child: CustomButton(
                        callBackFunction: onPay,
                        label: "RSVP",
                        backgroundColor: kBlue,
                      ),
                    ),
                  ],
                  if (isPaid) ...[
                    Expanded(
                      child: CustomButton(
                        callBackFunction: () {},
                        label: "ATTENDING",
                        backgroundColor: kGreen,
                      ),
                    ),
                  ],
                  SizedBox(width: 10),
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
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.share, color: kBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
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
            SizedBox(height: 10),
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
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
