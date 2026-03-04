import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventCard extends StatefulWidget {
  const EventCard({
    super.key,
    required this.heading,
    required this.imageUrl,
    required this.date,
    required this.location,
    required this.price,
    required this.onCardTap,
    required this.onBookPress,
    required this.eventId,
    this.isConfirmed = false,
    this.onViewTicket,
    this.category,
    this.attendees,
    this.showTicketNumber = false,
    this.viewTicketColor,
    this.onViewEvent,
    this.ticketCount = 1,
    this.showConfirmedTag = false,
  });

  final DateTime date;
  final String heading;
  final String imageUrl;
  final int price;
  final String location;
  final String eventId;
  final VoidCallback onCardTap;
  final VoidCallback onBookPress;
  final bool isConfirmed;
  final VoidCallback? onViewTicket;
  final String? category;
  final int? attendees;
  final bool showTicketNumber;
  final Color? viewTicketColor;
  final VoidCallback? onViewEvent;
  final int ticketCount;
  final bool showConfirmedTag;

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hoverAnimation =
        Tween<double>(begin: 1.0, end: 1.05).animate(_hoverController);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _setHovered(bool hovered) {
    setState(() => _isHovered = hovered);
    if (hovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    final localDate =
        widget.date.isUtc ? widget.date.toLocal() : widget.date;
    final now = DateTime.now();
    final isPast = localDate.isBefore(now);

    final isFree = widget.price == 0;
    final month = DateFormat('MMM').format(localDate).toUpperCase();
    final day = localDate.day;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onCardTap,
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? kDarkCard : kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? kGlassBorder.withOpacity(0.3)
                    : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                  blurRadius: _isHovered ? 16 : 8,
                  offset:
                      _isHovered ? const Offset(0, 8) : const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IMAGE SECTION WITH OVERLAYS
                  Stack(
                    children: [
                      ScaleTransition(
                        scale: _hoverAnimation,
                        child: Container(
                          height: 150,
                          color: isDarkMode ? kDarkThemeBg : Colors.grey[100],
                          child: widget.imageUrl.isNotEmpty
                              ? ColorFiltered(
                                  colorFilter: isPast
                                      ? const ColorFilter.matrix(<double>[
                                          0.2126,
                                          0.7152,
                                          0.0722,
                                          0,
                                          0,
                                          0.2126,
                                          0.7152,
                                          0.0722,
                                          0,
                                          0,
                                          0.2126,
                                          0.7152,
                                          0.0722,
                                          0,
                                          0,
                                          0,
                                          0,
                                          0,
                                          1,
                                          0,
                                        ])
                                      : const ColorFilter.mode(
                                          Colors.transparent,
                                          BlendMode.multiply,
                                        ),
                                  child: Image.network(
                                    widget.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildImagePlaceholder(isDarkMode),
                                  ),
                                )
                              : _buildImagePlaceholder(isDarkMode),
                        ),
                      ),

                      // Category Badge (Top-Left)
                      if (widget.category != null &&
                          widget.category!.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPast
                                  ? Colors.grey.withOpacity(0.8)
                                  : kBlue.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.category!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Date Overlay (Bottom-Left)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 52,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isPast ? Colors.grey[300] : kBlue,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  month,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                width: 52,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  '$day',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? kBlack
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // CONTENT SECTION
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Confirmed Tag (for My Events)
                        if (widget.showConfirmedTag && widget.isConfirmed && !isPast)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5CB338),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Confirmed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        // Title
                        Text(
                          widget.heading,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isPast
                                ? (isDarkMode
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.grey[600])
                                : (isDarkMode
                                    ? Colors.white
                                    : Colors.black),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Metadata
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMetadataItem(
                              icon: Icons.calendar_today_outlined,
                              text: DateFormat('MMM dd, yyyy')
                                  .format(localDate),
                              isDarkMode: isDarkMode,
                              isPast: isPast,
                            ),
                            const SizedBox(height: 4),
                            _buildMetadataItem(
                              icon: Icons.location_on_outlined,
                              text: widget.location,
                              isDarkMode: isDarkMode,
                              isPast: isPast,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            if (widget.showTicketNumber)
                              _buildMetadataItem(
                                icon: Icons.confirmation_number_outlined,
                                text: '${widget.ticketCount} ${widget.ticketCount == 1 ? 'ticket' : 'tickets'}',
                                isDarkMode: isDarkMode,
                                isPast: isPast,
                              )
                            else
                              _buildMetadataItem(
                                icon: Icons.people_outlined,
                                text: '${widget.attendees ?? 0} attending',
                                isDarkMode: isDarkMode,
                                isPast: isPast,
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // FOOTER: Button + Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Booking Button / Event Ended (left side for non-confirmed)
                            if (isPast)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Event Ended',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            else if (widget.isConfirmed)
                              // Price on left for confirmed events
                              Text(
                                isFree
                                    ? 'FREE'
                                    : 'KES ${widget.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isFree
                                      ? const Color(0xFF5CB338)
                                      : kBlue,
                                ),
                              )
                            else
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: widget.onBookPress,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0b65c3), // kBlue - explicit
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_offer_outlined,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'RSVP now',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Right side: Buttons (for confirmed) or Price (for non-confirmed)
                            if (widget.isConfirmed && !isPast)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: widget.onViewTicket,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.viewTicketColor ?? const Color(0xFF080D17),
                                        borderRadius: BorderRadius.circular(8),
                                        border: widget.viewTicketColor != null ? null : Border.all(
                                          color: const Color(0xFF3C84F6),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.confirmation_number,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'View Ticket',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (widget.onViewEvent != null) ...[
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: widget.onViewEvent,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D1629),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFF3778E0),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.event_outlined,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'View Event',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            else if (!isPast)
                              // Price on right for non-confirmed events
                              Text(
                                isFree
                                    ? 'FREE'
                                    : 'KES ${widget.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isFree
                                      ? const Color(0xFF5CB338)
                                      : kBlue,
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
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDarkMode) {
    return Center(
      child: Icon(
        Icons.calendar_month,
        size: 48,
        color: isDarkMode ? kBlue.withOpacity(0.3) : Colors.grey[300],
      ),
    );
  }

  Widget _buildMetadataItem({
    required IconData icon,
    required String text,
    required bool isDarkMode,
    required bool isPast,
    int maxLines = 2,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isPast
              ? (isDarkMode
                  ? Colors.white.withOpacity(0.4)
                  : Colors.grey[400])
              : (isDarkMode ? Colors.white : kBlue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isPast
                  ? (isDarkMode
                      ? Colors.white.withOpacity(0.6)
                      : Colors.grey[600])
                  : (isDarkMode ? Colors.white : Colors.black),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}