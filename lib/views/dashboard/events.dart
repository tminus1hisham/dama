import 'dart:convert';
import 'dart:typed_data';
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

import '../../widgets/cards/event_card.dart' show EventCard;
import '../../widgets/modals/booking_modal.dart';

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
  bool _hasEventVerifyRole = false;
  EventModel? _bookingEvent;
  bool _isBookingModalOpen = false;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    _tabController = TabController(
      length: 6,
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
    
    // Use the proper getUserRoles() method for consistent role retrieval
    final roles = await StorageService.getUserRoles();
    
    debugPrint('🎫 Events: Loaded user roles: $roles');
    final canScan = roles.contains('event_verify') || 
                    roles.contains('admin') ||
                    roles.contains('manager');
    debugPrint('🎫 Events: Can scan tickets: $canScan');

    setState(() {
      imageUrl = url;
      _currentUserId = userId ?? '';
      // Allow event_verify role OR admin role to scan tickets
      _hasEventVerifyRole = canScan;
    });

    if (userId != null && userId.isNotEmpty) {
      await _getUserProfileController.fetchUserProfile(userId);
    }
  }

  Future<void> _downloadTicketAsPdf(
      UserEventModel event, String? qrCode) async {
    final pdf = pw.Document();

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
                          fontSize: 22, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(children: [
                      pw.Text('Date: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('EEEE, MMMM dd, yyyy')
                          .format(event.eventDate)),
                    ]),
                    pw.SizedBox(height: 8),
                    pw.Row(children: [
                      pw.Text('Time: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('h:mm a').format(event.eventDate)),
                    ]),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Location: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Expanded(child: pw.Text(event.location)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(children: [
                      pw.Text('Price: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Kes ${event.price}'),
                    ]),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 16),
                    pw.Row(children: [
                      pw.Text('Attendee: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(attendeeName.isNotEmpty ? attendeeName : 'N/A'),
                    ]),
                    pw.SizedBox(height: 8),
                    pw.Row(children: [
                      pw.Text('Ticket ID: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(ticketId),
                    ]),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                pw.Text('Scan QR code to check in',
                    style: pw.TextStyle(color: PdfColors.grey600)),
                pw.SizedBox(height: 15),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Image(pw.MemoryImage(qrBytes),
                      height: 180, width: 180),
                ),
              ],
              pw.Spacer(),
              pw.Text(
                'Thank you for your purchase!',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 5),
              pw.Text('www.damakenya.org',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.blue)),
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
            backgroundColor: kRed),
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
                    fontSize: 16,
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
                    leading: Icon(Icons.event,
                        color: isDarkMode ? kWhite : kBlack),
                    title: Text(event.eventTitle,
                        style: TextStyle(
                            color: isDarkMode ? kWhite : kBlack)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QRScannerScreen(eventId: event.id),
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

  void _showBookingModal(EventModel event) {
    setState(() {
      _bookingEvent = event;
      _isBookingModalOpen = true;
    });
  }

  void _closeBookingModal() {
    setState(() {
      _isBookingModalOpen = false;
      _bookingEvent = null;
    });
  }

  void _handleBookingSuccess(String eventId) {
    // Refresh user events to update the status
    _userEventsController.fetchUserEvents();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event booked successfully!'),
        backgroundColor: kGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToEvent(EventModel event, bool isPaid) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SelectedEventScreen(
          isPaid: isPaid,
          eventID: event.id,
          speakers: event.speakers,
          description: event.description,
          title: event.eventTitle,
          price: event.price,
          // date: event.createdAt,
          date: event.eventDate,
          imageUrl: event.eventImageUrl.isNotEmpty
              ? event.eventImageUrl
              : DEFAULT_IMAGE_URL,
          location: event.location,
        ),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildTrendingCard(
      EventModel event, bool isDarkMode, bool isPaid) {
    return GestureDetector(
      onTap: () => _navigateToEvent(event, isPaid),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1a1f2e) : kWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
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
                          color: isDarkMode
                              ? const Color(0xFF2a3040)
                              : kLightGrey,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                        color: isDarkMode
                            ? const Color(0xFF2a3040)
                            : kLightGrey,
                        child:
                            Icon(Icons.event, size: 24, color: kGrey),
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
                              (isDarkMode
                                      ? const Color(0xFF1a1f2e)
                                      : kWhite)
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
              padding: const EdgeInsets.all(10),
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

  List<EventModel> _filterEventsByType(
      List<EventModel> events, String filter) {
    final now = DateTime.now();
    switch (filter) {
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

  Widget _buildEventsTab(bool isDarkMode,
      {String? filter, bool showPopular = false}) {
    return RefreshIndicator(
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
                  height: MediaQuery.of(context).size.height * 0.3),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text("No event available",
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text("The events will appear here",
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          );
        }

        final paidEventIds =
            _userEventsController.eventsList.map((e) => e.id).toSet();
        final filteredEvents = filter != null
            ? _filterEventsByType(_eventsController.eventsList, filter)
            : _eventsController.eventsList;

        return CustomScrollView(
          slivers: [
            if (showPopular &&
                _eventsController.popularEvents.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  color: isDarkMode ? kBlack : kWhite,
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: kBlue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_up,
                                  size: 18, color: kBlue),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Popular Events',
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          itemCount:
                              _eventsController.popularEvents.length,
                          itemBuilder: (context, index) {
                            final event = _eventsController
                                .popularEvents[index];
                            final isPaid =
                                paidEventIds.contains(event.id);
                            return _buildTrendingCard(
                                event, isDarkMode, isPaid);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Container(
                  height: 8,
                  color: isDarkMode ? kDarkThemeBg : kBGColor),
            ),
            Builder(
              builder: (context) {
                if (filteredEvents.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            filter != null
                                ? "No $filter events available"
                                : "No events available",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = filteredEvents[index];
                        final isPaid = paidEventIds.contains(event.id);
                        final isReserved = _userEventsController.eventsList
                            .any((e) => e.id == event.id);
                        
                        return EventCard(
                          heading: event.eventTitle,
                          imageUrl: event.eventImageUrl.isNotEmpty
                              ? event.eventImageUrl
                              : DEFAULT_IMAGE_URL,
                          date: event.eventDate,
                          location: event.location,
                          price: event.price,
                          eventId: event.id,
                          isConfirmed: isReserved,
                          attendees: event.attendees.length,
                          onCardTap: () => _navigateToEvent(event, isPaid),
                          onBookPress: () => _showBookingModal(event),
                          onViewTicket: () {
                            // Navigate to My Events tab
                            setState(() {
                              selectedTab = 1;
                            });
                          },
                        );
                      },
                      childCount: filteredEvents.length,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMyEventsTab(bool isDarkMode) {
    return RefreshIndicator(
      color: kWhite,
      backgroundColor: kBlue,
      displacement: 40,
      onRefresh: _fetchData,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Obx(() {
            if (_userEventsController.isLoading.value || _isLoading) {
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
                          MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.confirmation_number_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 24),
                          Text(
                            "No event tickets yet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? kWhite
                                  : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "You haven't booked any events yet. Browse our upcoming events and join the DAMA Kenya community!",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedTab = 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Browse Events',
                              style: TextStyle(
                                  color: kWhite,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
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
                  // Scan Tickets Button — only visible to event_verify role
                  if (_hasEventVerifyRole)
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showEventSelectionForScanner(isDarkMode),
                          icon: Icon(Icons.qr_code_scanner,
                              color: kBlue),
                          label: Text('Scan Tickets',
                              style: TextStyle(color: kBlue)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: kBlue),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 12,
                      ),
                      itemCount:
                          _userEventsController.eventsList.length,
                      itemBuilder: (context, index) {
                        final event =
                            _userEventsController.eventsList[index];
                        return EventCard(
                          heading: event.eventTitle,
                          imageUrl: event.eventImageUrl.isNotEmpty
                              ? event.eventImageUrl
                              : DEFAULT_IMAGE_URL,
                          date: event.eventDate,
                          location: event.location,
                          price: event.price,
                          isConfirmed: true,
                          onViewTicket: () async {
                            // Download ticket as PDF in My Events tab
                            final userProfile = _getUserProfileController.profile.value;
                            String? qrCode;
                            
                            if (userProfile?.eventQRCode != null && _currentUserId == userProfile!.id) {
                              final matchingQRCode = userProfile.eventQRCode
                                  .where((qr) => qr.eventId == event.id)
                                  .firstOrNull;
                              if (matchingQRCode != null) {
                                qrCode = matchingQRCode.qrCode;
                              }
                            }
                            
                            if (qrCode == null) {
                              final memberId = await StorageService.getData('memberId') ?? '';
                              if (memberId.isNotEmpty) {
                                final qrData = jsonEncode({'memberId': memberId, 'eventId': event.id});
                                qrCode = 'data:image/png;base64,${base64Encode(utf8.encode(qrData))}';
                              }
                            }
                            
                            await _downloadTicketAsPdf(event, qrCode);
                          },
                          onCardTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                    SelectedEventScreen(
                                  isPaid: true,
                                  eventID: event.id,
                                  speakers: event.speakers,
                                  description: event.description,
                                  title: event.eventTitle,
                                  price: event.price,
                                  date: event.eventDate,
                                  imageUrl: event
                                          .eventImageUrl.isNotEmpty
                                      ? event.eventImageUrl
                                      : DEFAULT_IMAGE_URL,
                                  location: event.location,
                                ),
                                transitionsBuilder: (context,
                                    animation,
                                    secondaryAnimation,
                                    child) {
                                  return FadeTransition(
                                      opacity: animation,
                                      child: child);
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 200),
                              ),
                            );
                          },
                          onBookPress: () {},
                          eventId: event.id,
                          showTicketNumber: true,
                          showConfirmedTag: true,
                          viewTicketColor: const Color(0xFF3778E0),
                          onViewEvent: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                    SelectedEventScreen(
                                  isPaid: true,
                                  eventID: event.id,
                                  speakers: event.speakers,
                                  description: event.description,
                                  title: event.eventTitle,
                                  price: event.price,
                                  date: event.eventDate,
                                  imageUrl: event
                                          .eventImageUrl.isNotEmpty
                                      ? event.eventImageUrl
                                      : DEFAULT_IMAGE_URL,
                                  location: event.location,
                                ),
                                transitionsBuilder: (context,
                                    animation,
                                    secondaryAnimation,
                                    child) {
                                  return FadeTransition(
                                      opacity: animation,
                                      child: child);
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 200),
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
    );
  }

  Widget _buildTabButton(String text, int index, bool isDarkMode) {
    final bool isSelected = selectedTab == index;
    final bool isMyEvents = index == 1; // "My Events"

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMyEvents ? 20 : 16,
          vertical: isMyEvents ? 11 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? kBlue
              : (isDarkMode ? const Color(0xFF1a1f2e) : kWhite),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? kBlue
                : (isDarkMode ? const Color(0xFF2a3040) : kGrey),
            width: isMyEvents && !isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected && isMyEvents
              ? [
                  BoxShadow(
                    color: kBlue.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? kWhite : (isDarkMode ? kWhite : kGrey),
            fontWeight: isMyEvents ? FontWeight.w700 : FontWeight.w600,
            fontSize: isMyEvents ? 14 : 13,
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

    return Stack(
      children: [
        Container(
          color: isDarkMode ? kDarkThemeBg : kBGColor,
          child: Column(
            children: [
              const SizedBox(height: 3),
              // Single horizontal scrollable tab bar
              Container(
                color: isDarkMode ? kBlack : kWhite,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTabButton("All", 0, isDarkMode),
                      const SizedBox(width: 8),
                      _buildTabButton("My Events", 1, isDarkMode),
                      const SizedBox(width: 8),
                      _buildTabButton("Upcoming", 2, isDarkMode),
                      const SizedBox(width: 8),
                      _buildTabButton("Past", 3, isDarkMode),
                      const SizedBox(width: 8),
                      _buildTabButton("Free", 4, isDarkMode),
                      const SizedBox(width: 8),
                      _buildTabButton("Paid", 5, isDarkMode),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: selectedTab,
                  children: [
                    _buildEventsTab(isDarkMode, showPopular: true),
                    _buildMyEventsTab(isDarkMode),
                    _buildEventsTab(isDarkMode, filter: 'upcoming'),
                    _buildEventsTab(isDarkMode, filter: 'past'),
                    _buildEventsTab(isDarkMode, filter: 'free'),
                    _buildEventsTab(isDarkMode, filter: 'paid'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Booking Modal
        BookingModal(
          event: _bookingEvent,
          isOpen: _isBookingModalOpen,
          onClose: _closeBookingModal,
          onSuccess: _handleBookingSuccess,
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}