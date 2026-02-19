import 'dart:convert';
import 'dart:typed_data';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:dama/controller/events_controller.dart';
import 'package:dama/controller/get_user_data.dart';
import 'package:dama/controller/user_event_controller.dart';
import 'package:dama/models/event_model.dart';
import 'package:dama/models/user_event_model.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/utils/utils.dart';
import 'package:dama/views/drawer_screen/QRscanner.dart';
import 'package:dama/views/selected_screens/selected_event_screen.dart';
import 'package:dama/widgets/shimmer/events_card_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../widgets/cards/event_card.dart' show EventCard;

class Events extends StatefulWidget {
  final VoidCallback onMenuTap;
  final int initialTab;

  const Events({super.key, required this.onMenuTap, this.initialTab = 0});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String? imageUrl;
  late TabController _tabController;
  final Utils _utils = Utils();

  final EventsController _eventsController = Get.find<EventsController>();
  final UserEventsController _userEventsController =
      Get.find<UserEventsController>();
  final GetUserProfileController _getUserProfileController = Get.put(
    GetUserProfileController(),
  );

  bool _isLoading = false;
  int selectedTab = 0;
  String _currentUserId = '';
  
  // Use controller's filter
  String get selectedFilter => _eventsController.selectedFilter.value;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _eventsController.fetchEvents();
    _userEventsController.fetchUserEvents();
    _loadData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    await _userEventsController.fetchUserEvents();
    await _eventsController.fetchEvents();
    setState(() {
      _isLoading = false;
    });
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    final userId = await StorageService.getData('userId');

    setState(() {
      imageUrl = url;
      _currentUserId = userId;
    });

    // Fetch user profile to get QR codes for tickets
    if (userId != null && userId.isNotEmpty) {
      await _getUserProfileController.fetchUserProfile(userId);
    }
  }

  void _showTicketModal(UserEventModel event, bool isDarkMode) async {
    final userProfile = _getUserProfileController.profile.value;

    // Get user name from storage
    final firstName = await StorageService.getData('firstName') ?? '';
    final lastName = await StorageService.getData('lastName') ?? '';
    final attendeeName = '$firstName $lastName'.trim();
    final ticketId = event.id.substring(0, 8).toUpperCase();

    // Get member ID from storage
    final memberId = await StorageService.getData('memberId') ?? '';

    String? qrCode;
    bool isGeneratedLocally = false;

    if (userProfile?.eventQRCode != null && _currentUserId == userProfile!.id) {
      final matchingQRCode =
          userProfile.eventQRCode
              .where((qr) => qr.eventId == event.id)
              .firstOrNull;

      if (matchingQRCode != null) {
        qrCode = matchingQRCode.qrCode;
      }
    }

    // If no QR code from backend, generate one locally
    if (qrCode == null && memberId.isNotEmpty) {
      // Generate QR code data as expected by verification endpoint
      final qrData = jsonEncode({'memberId': memberId, 'eventId': event.id});

      // Create a data URL for the QR code (we'll render it with QrImage widget)
      qrCode = 'data:image/png;base64,${base64Encode(utf8.encode(qrData))}';
      isGeneratedLocally = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDarkMode ? kDarkThemeBg : kWhite,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Event Ticket',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: kBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Event details card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? kBlack : kBGColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? kGrey.withOpacity(0.2)
                                      : kLightGrey,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Event image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  event.eventImageUrl.isNotEmpty
                                      ? event.eventImageUrl
                                      : DEFAULT_IMAGE_URL,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        height: 150,
                                        color: kGrey.withOpacity(0.2),
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Event title
                              Text(
                                event.eventTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? kWhite : kBlack,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Date
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: kGrey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'EEEE, MMMM dd, yyyy',
                                    ).format(event.eventDate),
                                    style: TextStyle(
                                      color: isDarkMode ? kWhite : kBlack,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Time
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: kGrey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(event.eventDate),
                                    style: TextStyle(
                                      color: isDarkMode ? kWhite : kBlack,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Location
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: kBlue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: TextStyle(
                                        color: kBlue,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Status chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: kGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: kGreen,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Confirmed',
                                      style: TextStyle(
                                        color: kGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // QR Code section
                        if (qrCode != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: kWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kLightGrey),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Scan to check in',
                                  style: TextStyle(color: kGrey, fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                if (isGeneratedLocally) ...[
                                  // Generate QR code locally using qr_flutter
                                  QrImageView(
                                    data: jsonEncode({
                                      'memberId': memberId,
                                      'eventId': event.id,
                                    }),
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    backgroundColor: Colors.white,
                                  ),
                                ] else ...[
                                  // Use backend-provided QR code
                                  Image.memory(
                                    base64Decode(qrCode!.split(',').last),
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDarkMode ? kBlack : kBGColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? kGrey.withOpacity(0.2)
                                        : kLightGrey,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.qr_code_2,
                                  size: 80,
                                  color: kGrey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'QR code not available',
                                  style: TextStyle(color: kGrey, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please contact support if this issue persists.',
                                  style: TextStyle(color: kGrey, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Attendee info section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? kBlack : kBGColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? kGrey.withOpacity(0.2)
                                      : kLightGrey,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Attendee name
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Attendee',
                                    style: TextStyle(
                                      color: kGrey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    attendeeName.isNotEmpty
                                        ? attendeeName
                                        : 'N/A',
                                    style: TextStyle(
                                      color: isDarkMode ? kWhite : kBlack,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: kGrey.withOpacity(0.2), height: 1),
                              const SizedBox(height: 12),
                              // Ticket ID
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ticket ID',
                                    style: TextStyle(
                                      color: kGrey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    ticketId,
                                    style: TextStyle(
                                      color: isDarkMode ? kWhite : kBlack,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Action buttons fixed at bottom
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Add to Calendar button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final calendarEvent = Event(
                                  title: event.eventTitle,
                                  description: event.description,
                                  location: event.location,
                                  startDate: event.eventDate,
                                  endDate: event.eventDate.add(
                                    const Duration(hours: 2),
                                  ),
                                  iosParams: const IOSParams(
                                    reminder: Duration(hours: 1),
                                  ),
                                );
                                Add2Calendar.addEvent2Cal(calendarEvent);
                              },
                              icon: Icon(Icons.calendar_month, color: kBlue),
                              label: Text(
                                'Add to Calendar',
                                style: TextStyle(
                                  color: kBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: kBlue),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Download ticket button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadTicketAsPdf(event, qrCode),
                          icon: Icon(Icons.download, color: kWhite),
                          label: Text(
                            'Download Ticket (PDF)',
                            style: TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadTicketAsPdf(
    UserEventModel event,
    String? qrCode,
  ) async {
    final pdf = pw.Document();

    // Get user info for the PDF
    final firstName = await StorageService.getData('firstName') ?? '';
    final lastName = await StorageService.getData('lastName') ?? '';
    final attendeeName = '$firstName $lastName'.trim();
    final ticketId = event.id.substring(0, 8).toUpperCase();

    Uint8List? qrBytes;
    if (qrCode != null) {
      qrBytes = base64Decode(qrCode.split(',').last);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'DAMA Kenya',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Event Ticket',
                style: pw.TextStyle(fontSize: 20, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      event.eventTitle,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Date: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          DateFormat(
                            'EEEE, MMMM dd, yyyy',
                          ).format(event.eventDate),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Time: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(DateFormat('h:mm a').format(event.eventDate)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Location: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Expanded(child: pw.Text(event.location)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Price: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Kes ${event.price}'),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Attendee: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(attendeeName.isNotEmpty ? attendeeName : 'N/A'),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Ticket ID: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(ticketId),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        'CONFIRMED',
                        style: pw.TextStyle(
                          color: PdfColors.green700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              if (qrBytes != null) ...[
                pw.Text(
                  'Scan QR code to check in',
                  style: pw.TextStyle(color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Image(
                    pw.MemoryImage(qrBytes),
                    height: 180,
                    width: 180,
                  ),
                ),
              ],
              pw.Spacer(),
              pw.Text(
                'Thank you for your purchase!',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'www.damakenya.org',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.blue),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'DAMA_Ticket_${event.eventTitle.replaceAll(' ', '_')}.pdf',
    );
  }

  void _showEventSelectionForScanner(bool isDarkMode) {
    final events = _userEventsController.eventsList;
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No events available to scan'),
          backgroundColor: kRed,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Event to Scan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? kWhite : kBlack,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    leading: Icon(
                      Icons.event,
                      color: isDarkMode ? kWhite : kBlack,
                    ),
                    title: Text(
                      event.eventTitle,
                      style: TextStyle(color: isDarkMode ? kWhite : kBlack),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => QRScannerScreen(eventId: event.id),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _navigateToEvent(EventModel event, bool isPaid) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => SelectedEventScreen(
              isPaid: isPaid,
              eventID: event.id,
              speakers: event.speakers,
              description: event.description,
              title: event.eventTitle,
              price: event.price,
              date: event.createdAt,
              imageUrl:
                  event.eventImageUrl.isNotEmpty
                      ? event.eventImageUrl
                      : DEFAULT_IMAGE_URL,
              location: event.location,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildTrendingCard(EventModel event, bool isDarkMode, bool isPaid) {
    return GestureDetector(
      onTap: () => _navigateToEvent(event, isPaid),
      child: Container(
        width: 150,
        margin: EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1a1f2e) : kWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 75,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _utils.cleanUrl(
                        event.eventImageUrl.isNotEmpty
                            ? event.eventImageUrl
                            : DEFAULT_IMAGE_URL,
                      ),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: isDarkMode ? Color(0xFF2a3040) : kLightGrey,
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: isDarkMode ? Color(0xFF2a3040) : kLightGrey,
                            child: Icon(Icons.event, size: 24, color: kGrey),
                          ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDarkMode ? Color(0xFF1a1f2e) : kWhite)
                                  .withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                event.eventTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? kWhite : kBlack,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<EventModel> _getFilteredEvents(List<EventModel> events) {
    final now = DateTime.now();
    switch (selectedFilter) {
      case 'upcoming':
        return events.where((e) => e.eventDate.isAfter(now)).toList();
      case 'past':
        return events.where((e) => e.eventDate.isBefore(now)).toList();
      case 'free':
        return events.where((e) => e.price == 0).toList();
      case 'paid':
        return events.where((e) => e.price > 0).toList();
      default:
        return events;
    }
  }
  
  List<UserEventModel> _getFilteredUserEvents(List<UserEventModel> events) {
    final now = DateTime.now();
    switch (selectedFilter) {
      case 'upcoming':
        return events.where((e) => e.eventDate.isAfter(now)).toList();
      case 'past':
        return events.where((e) => e.eventDate.isBefore(now)).toList();
      case 'free':
        return events.where((e) => e.price == 0).toList();
      case 'paid':
        return events.where((e) => e.price > 0).toList();
      default:
        return events;
    }
  }

  Widget _buildPillButton(String text, int index, bool isDarkMode) {
    final bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
        _eventsController.setFilter('all'); // Reset filter when switching tabs
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? kBlue : (isDarkMode ? Color(0xFF1a1f2e) : kWhite),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color:
                isSelected ? kBlue : (isDarkMode ? Color(0xFF2a3040) : kGrey),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? kWhite : (isDarkMode ? kWhite : kGrey),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String text, String filter, bool isDarkMode) {
    final bool isSelected = selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        _eventsController.setFilter(filter);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? kBlue.withOpacity(0.15)
                  : (isDarkMode ? Color(0xFF1a1f2e) : kWhite),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? kBlue
                    : (isDarkMode ? Color(0xFF2a3040) : kLightGrey),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? kBlue : (isDarkMode ? kWhite : kGrey),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    return Container(
      color: isDarkMode ? kDarkThemeBg : kBGColor,
      child: Column(
        children: [
          SizedBox(height: 3),
          // Tab selector (All Events / My Events)
          Container(
            color: isDarkMode ? kBlack : kWhite,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildPillButton("All Events", 0, isDarkMode),
                    const SizedBox(width: 10),
                    _buildPillButton("My Events and Tickets", 1, isDarkMode),
                  ],
                ),
              ),
            ),
          ),
          // Filter chips
          Obx(() => Container(
            color: isDarkMode ? kBlack : kWhite,
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All", "all", isDarkMode),
                  const SizedBox(width: 8),
                  _buildFilterChip("Upcoming", "upcoming", isDarkMode),
                  const SizedBox(width: 8),
                  _buildFilterChip("Past", "past", isDarkMode),
                  const SizedBox(width: 8),
                  _buildFilterChip("Free", "free", isDarkMode),
                  const SizedBox(width: 8),
                  _buildFilterChip("Paid", "paid", isDarkMode),
                ],
              ),
            ),
          )),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: [
                // All Events Tab
                RefreshIndicator(
                  color: kWhite,
                  backgroundColor: kBlue,
                  displacement: 40,
                  onRefresh: _fetchData,
                  child: Obx(() {
                    if (_eventsController.isLoading.value || _isLoading) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(0),
                        itemCount: 3,
                        itemBuilder: (context, index) => EventCardShimmer(),
                      );
                    } else if (_eventsController.eventsList.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No event available",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "The events will appear here",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    final paidEventIds =
                        _userEventsController.eventsList
                            .map((e) => e.id)
                            .toSet();

                    return CustomScrollView(
                      slivers: [
                        // Trending Events Section
                        if (_eventsController.trendingEvents.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Container(
                              color: isDarkMode ? kBlack : kWhite,
                              padding: EdgeInsets.only(bottom: 12, top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: kOrange.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '🔥',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Trending Events',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? kWhite : kBlack,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 130,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      itemCount:
                                          _eventsController
                                              .trendingEvents
                                              .length,
                                      itemBuilder: (context, index) {
                                        final event =
                                            _eventsController
                                                .trendingEvents[index];
                                        final isPaid = paidEventIds.contains(
                                          event.id,
                                        );
                                        return _buildTrendingCard(
                                          event,
                                          isDarkMode,
                                          isPaid,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Divider
                        SliverToBoxAdapter(
                          child: Container(
                            height: 8,
                            color: isDarkMode ? kDarkThemeBg : kBGColor,
                          ),
                        ),

                        // Events List
                        Builder(
                          builder: (context) {
                            final filteredEvents = _getFilteredEvents(
                              _eventsController.eventsList,
                            );
                            if (filteredEvents.isEmpty) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "No events available",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final event = filteredEvents[index];
                                final isPaid = paidEventIds.contains(event.id);

                                return Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 800),
                                    child: EventCard(
                                      heading: event.eventTitle,
                                      imageUrl:
                                          event.eventImageUrl.isNotEmpty
                                              ? event.eventImageUrl
                                              : DEFAULT_IMAGE_URL,
                                      date: event.createdAt,
                                      location: event.location,
                                      price: event.price,
                                      onPressed:
                                          () => _navigateToEvent(event, isPaid),
                                    ),
                                  ),
                                );
                              }, childCount: filteredEvents.length),
                            );
                          },
                        ),
                      ],
                    );
                  }),
                ),
                RefreshIndicator(
                  color: kWhite,
                  backgroundColor: kBlue,
                  displacement: 40,
                  onRefresh: _fetchData,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 800),
                      child: Obx(() {
                        if (_userEventsController.isLoading.value ||
                            _isLoading) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: 3,
                            itemBuilder: (context, index) => EventCardShimmer(),
                          );
                        } else if (_userEventsController.eventsList.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2,
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.confirmation_number_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 24),
                                      Text(
                                        "No event tickets yet",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDarkMode
                                                  ? kWhite
                                                  : Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        "You haven't booked any events yet. Browse our upcoming events and join the DAMA Kenya community!",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedTab = 0;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kBlue,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Browse Events',
                                          style: TextStyle(
                                            color: kWhite,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        final filteredUserEvents = _getFilteredUserEvents(
                          _userEventsController.eventsList,
                        );
                        if (filteredUserEvents.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No events match this filter",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: Column(
                            children: [
                              // Scan Tickets Button
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        () => _showEventSelectionForScanner(
                                          isDarkMode,
                                        ),
                                    icon: Icon(
                                      Icons.qr_code_scanner,
                                      color: kBlue,
                                    ),
                                    label: Text(
                                      'Scan Tickets',
                                      style: TextStyle(color: kBlue),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: kBlue),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredUserEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = filteredUserEvents[index];
                                    return EventCard(
                                      heading: event.eventTitle,
                                      imageUrl:
                                          event.eventImageUrl.isNotEmpty
                                              ? event.eventImageUrl
                                              : DEFAULT_IMAGE_URL,
                                      date: event.createdAt,
                                      location: event.location,
                                      price: event.price,
                                      isConfirmed: true,
                                      onViewTicket: () {
                                        _showTicketModal(event, isDarkMode);
                                      },
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                ) => SelectedEventScreen(
                                                  isPaid: true,
                                                  eventID: event.id,
                                                  speakers: event.speakers,
                                                  description:
                                                      event.description,
                                                  title: event.eventTitle,
                                                  price: event.price,
                                                  date: event.createdAt,
                                                  imageUrl:
                                                      event
                                                              .eventImageUrl
                                                              .isNotEmpty
                                                          ? event.eventImageUrl
                                                          : DEFAULT_IMAGE_URL,
                                                  location: event.location,
                                                ),
                                            transitionsBuilder: (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                            transitionDuration: const Duration(
                                              milliseconds: 200,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
