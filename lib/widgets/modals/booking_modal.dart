import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:dama/models/event_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:dama/utils/theme_provider.dart';

enum BookingState { idle, awaiting, success, failed }

class BookingModal extends StatefulWidget {
  final EventModel? event;
  final bool isOpen;
  final VoidCallback onClose;
  final Function(String eventId) onSuccess;

  const BookingModal({
    required this.event,
    required this.isOpen,
    required this.onClose,
    required this.onSuccess,
  }) : super();

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  BookingState _bookingState = BookingState.idle;
  String _phoneNumber = '';
  int _quantity = 1;
  String? _errorMessage;
  String? _ticketNumber;
  final _apiService = Get.find<ApiService>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(BookingModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
        _resetForm();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _bookingState = BookingState.idle;
      _phoneNumber = '';
      _quantity = 1;
      _errorMessage = null;
      _ticketNumber = null;
      _isLoading = false;
    });
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    } else if (!cleaned.startsWith('254')) {
      cleaned = '254$cleaned';
    }
    return cleaned;
  }

  bool _validatePhoneNumber(String phone) {
    final formatted = _formatPhoneNumber(phone);
    return formatted.length >= 12 && formatted.startsWith('254');
  }

  bool _isPhoneValid() {
    return _phoneNumber.isNotEmpty && _validatePhoneNumber(_phoneNumber);
  }

  String _formatEventDate(DateTime date) {
    return DateFormat('EEEE, MMMM dd, yyyy').format(date);
  }

  Future<void> _handleBookNow() async {
    final isFree = widget.event?.price == null || widget.event!.price == 0;

    if (!isFree && !_validatePhoneNumber(_phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Kenyan phone number'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    setState(() {
      _bookingState = BookingState.awaiting;
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      if (isFree) {
        final response =
            await _apiService.registerForEvent(widget.event!.id);
        debugPrint('registerForEvent response: $response');
        if (response != null) {
          setState(() {
            _ticketNumber = response['ticketNumber'] ??
                response['ticket']?['number'] ??
                response['reference'] ??
                response['reference_number'] ??
                'SUCCESS';
            _bookingState = BookingState.success;
          });
        } else {
          throw Exception('Server error: No response received');
        }
      } else {
        final response = await _apiService.initiatePayment(
          objectId: widget.event!.id,
          amount: widget.event!.price,
          phoneNumber: _formatPhoneNumber(_phoneNumber),
          model: 'Event',
        );
        debugPrint('initiatePayment response: $response');
        if (response != null) {
          setState(() {
            _ticketNumber = response['ticketNumber'] ??
                response['ticket']?['number'] ??
                response['reference'] ??
                response['reference_number'] ??
                'PAYMENT_INITIATED';
            _bookingState = BookingState.success;
          });
        } else {
          throw Exception('Server error: No response received');
        }
      }
    } catch (err) {
      debugPrint('Booking failed: $err');
      String errorMsg = err.toString();
      
      // Extract clean error message from Exception
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      
      // Try to extract JSON message from error response
      if (errorMsg.contains('"message":"')) {
        try {
          final startIdx = errorMsg.indexOf('"message":"') + 11;
          final endIdx = errorMsg.indexOf('"', startIdx);
          if (endIdx > startIdx) {
            errorMsg = errorMsg.substring(startIdx, endIdx);
          }
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      }
      
      // Remove HTTP status codes
      errorMsg = errorMsg.replaceAll(RegExp(r' \d{3} -'), '');
      errorMsg = errorMsg.replaceAll(RegExp(r'\d{3}'), '');
      
      // Handle specific error cases
      if (errorMsg.contains('already registered')) {
        errorMsg = 'You are already registered for this event.';
      } else if (errorMsg.contains('Payment required')) {
        errorMsg = 'This is a paid event. Please provide a phone number to proceed with payment.';
      } else if (errorMsg.contains('no response')) {
        errorMsg = 'Server error. Please try again later.';
      }
      
      setState(() {
        _bookingState = BookingState.failed;
        _errorMessage = errorMsg.trim();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleRetry() {
    setState(() {
      _bookingState = BookingState.idle;
      _errorMessage = null;
      _ticketNumber = null;
    });
  }

  void _handleClose() {
    if (_bookingState != BookingState.awaiting) {
      widget.onClose();
    }
  }

  void _handleSuccessClose() {
    final isFree = widget.event?.price == null || widget.event!.price == 0;
    if (isFree || _ticketNumber != null) {
      widget.onSuccess(widget.event!.id);
    }
    widget.onClose();
  }

  void _addToCalendar() {
    if (widget.event == null) return;
    final calendarEvent = Event(
      title: widget.event!.eventTitle,
      description: widget.event!.description,
      location: widget.event!.location,
      startDate: widget.event!.eventDate,
      endDate: widget.event!.eventDate.add(const Duration(hours: 2)),
      iosParams: const IOSParams(reminder: Duration(hours: 1)),
    );
    Add2Calendar.addEvent2Cal(calendarEvent);
  }

  Widget _buildSuccessState(bool isDarkMode) {
    final isFree = widget.event?.price == null || widget.event!.price == 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reserved Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: kGreen, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'EVENT RESERVED',
                        style: TextStyle(
                          color: kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kGreen.withValues(alpha: 0.2),
                        kGreen.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: kGreen,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),

                // Success title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        isFree ? 'Your RSVP is Confirmed!' : 'Booking Confirmed!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: _handleClose,
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Success message
                Text(
                  isFree
                      ? 'You are now registered for this event. Check your email for event details.'
                      : 'Your booking has been recorded. Check your transaction history for details.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Event details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kGreen.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event title
                      Text(
                        widget.event?.eventTitle ?? 'Event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: kGreen.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatEventDate(widget.event!.eventDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: kGreen.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.event?.location ?? 'TBA',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Ticket info (if available)
                if (_ticketNumber != null)
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ticket Reference',
                              style: TextStyle(
                                fontSize: 11,
                                color: kGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _ticketNumber!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                                color: kBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Action buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _addToCalendar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Add to Calendar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _handleSuccessClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAwaitingState(bool isDarkMode) {
    final isFree = widget.event?.price == null || widget.event!.price == 0;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Phone icon with pulse animation
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smartphone,
                  color: kBlue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      isFree ? 'Confirming RSVP...' : 'Check Your Phone',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _handleClose,
                      icon: Icon(
                        Icons.close,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Message
              if (isFree)
                Text(
                  'Please wait while we confirm your reservation...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        children: [
                          const TextSpan(text: 'An M-PESA prompt has been sent to '),
                          TextSpan(
                            text: _phoneNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your M-PESA PIN to complete the payment',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Warning
              Text(
                'Please do not close this window',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Loading spinner
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: kBlue,
                  strokeWidth: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailedState(bool isDarkMode) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: kRed,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Title with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Booking Failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _handleClose,
                      icon: Icon(
                        Icons.close,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Error message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kRed.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage ??
                      'Unable to complete your booking. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: kRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _handleClose,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState(bool isDarkMode) {
    if (widget.event == null) return const SizedBox.shrink();

    final event = widget.event!;
    final isFree = event.price == 0;
    final price = event.price;
    final totalPrice = price * _quantity;

    debugPrint('🎫 BookingModal - Event: ${event.eventTitle}, Price: $price, IsFree: $isFree');

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    isFree ? 'RSVP for Event' : 'Book Event',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      onPressed: _handleClose,
                      icon: Icon(
                        Icons.close,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            // Content - scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Event Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: kBlue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatEventDate(event.eventDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: kBlue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Price section with border
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDarkMode
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                          bottom: BorderSide(
                            color: isDarkMode
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Ticket Price',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isFree ? 'FREE' : 'KES ${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isFree ? kGreen : kBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Phone number input (for paid events only)
                    if (!isFree) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'M-PESA Phone Number',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _phoneNumber = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: '0712345678',
                          prefixIcon: const Icon(Icons.phone, size: 18),
                          suffixIcon: _phoneNumber.isNotEmpty
                              ? Icon(
                                  _isPhoneValid()
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isPhoneValid() ? kGreen : kRed,
                                  size: 20,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _phoneNumber.isNotEmpty
                                  ? (_isPhoneValid()
                                      ? kGreen.withValues(alpha: 0.5)
                                      : kRed.withValues(alpha: 0.3))
                                  : (isDarkMode
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _phoneNumber.isNotEmpty
                                  ? (_isPhoneValid() ? kGreen : kRed)
                                  : kBlue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.transparent
                              : Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "You'll receive an M-PESA prompt on this number",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_phoneNumber.isNotEmpty && !_isPhoneValid())
                            Text(
                              'Invalid phone',
                              style: TextStyle(
                                fontSize: 10,
                                color: kRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // M-PESA Badge
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: kGreen.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: kGreen.withValues(alpha: 0.08),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 36,
                              decoration: BoxDecoration(
                                color: kGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'M-PESA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lipa na M-PESA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Instant mobile payment',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'KES ${totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),

            // Footer with button(s)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isLoading || (widget.event != null && (widget.event!.price != null && widget.event!.price != 0) && !_isPhoneValid()) ? null : _handleBookNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_offer,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  isFree
                                      ? 'Confirm RSVP'
                                      : 'Pay KES ${totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (!isFree) ...[
                    const SizedBox(height: 12),
                    Text(
                      '🔒 Secure payment powered by Safaricom M-PESA',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen || widget.event == null) {
      return const SizedBox.shrink();
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    switch (_bookingState) {
      case BookingState.success:
        return _buildSuccessState(isDarkMode);
      case BookingState.awaiting:
        return _buildAwaitingState(isDarkMode);
      case BookingState.failed:
        return _buildFailedState(isDarkMode);
      case BookingState.idle:
        return _buildIdleState(isDarkMode);
    }
  }
}
