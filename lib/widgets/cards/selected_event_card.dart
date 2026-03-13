import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
    required this.onRegister,
    required this.onUnregister,
    required this.isRegistered,
    required this.isRegistering,
    this.onViewTicket,
  });

  final DateTime date;
  final String heading;
  final String imageUrl;
  final String price;
  final String location;
  final String description;
  final bool isPaid;
  final VoidCallback onPay;
  final VoidCallback onRegister;
  final VoidCallback onUnregister;
  final bool isRegistered;
  final bool isRegistering;
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
            // Event Image
            SizedBox(
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
                  fontSize: 16,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pin_drop_outlined, color: kBlue, size: 20),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: kBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          int.parse(price) == 0 ? 'FREE' : 'KES $price',
                          style: TextStyle(
                            fontSize: kBigTextSize,
                            fontWeight: FontWeight.bold,
                            color:
                                int.parse(price) == 0
                                    ? kGreen
                                    : (isDarkMode ? kWhite : kBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 30),
                    // Button section - different behavior for free vs paid events
                    if (int.parse(price) == 0)
                      // Free event: Register/Unregister button
                      Expanded(
                        child: CustomButton(
                          callBackFunction:
                              isPast
                                  ? null
                                  : (isRegistered ? onUnregister : onRegister),
                          label:
                              isPast
                                  ? "EVENT PAST"
                                  : (isRegistered ? "UNREGISTER" : "RSVP"),
                          backgroundColor:
                              isPast
                                  ? Colors.grey
                                  : (isRegistered ? kRed : kBlue),
                        ),
                      )
                    else
                    // Paid event: Show RSVP button if not registered, ATTENDING if registered
                    if (isPaid)
                      // Paid and attending
                      Expanded(
                        child: CustomButton(
                          callBackFunction: isPast ? null : onUnregister,
                          label: isPast ? "EVENT PAST" : "UNREGISTER",
                          backgroundColor: isPast ? Colors.grey : kRed,
                        ),
                      )
                    else
                      // Paid but not yet purchased
                      Expanded(
                        child: CustomButton(
                          callBackFunction: isPast ? null : onPay,
                          label: isPast ? "EVENT PAST" : "RSVP",
                          backgroundColor: isPast ? Colors.grey : kBlue,
                        ),
                      ),
                  ],
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

            // RSVP / View Ticket button
            if (!isPast)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: kSidePadding),
                child:
                    isRegistered
                        ? GestureDetector(
                          onTap: onViewTicket,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3778E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.confirmation_number,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'View Ticket',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : GestureDetector(
                          onTap:
                              isPaid
                                  ? null
                                  : (int.tryParse(price) ?? 0) > 0
                                  ? onPay
                                  : onRegister,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: kBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.local_offer_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'RSVP now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                  fontSize: 14,
                  color: isDarkMode ? kWhite : kGrey,
                  height: 1.4,
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
