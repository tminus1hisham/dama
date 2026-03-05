import 'package:dama/controller/get_user_data.dart';
import 'package:dama/controller/user_event_controller.dart';
import 'package:dama/services/unified_payment_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/cards/selected_event_card.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/modals/success_bottomsheet.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SelectedEventScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final DateTime date;
  final String location;
  final int price;
  final String description;
  final List speakers;
  final bool isPaid;
  final String eventID;
  final bool fromSearch;

  const SelectedEventScreen({
    super.key,
    required this.title,
    required this.price,
    required this.date,
    required this.imageUrl,
    required this.location,
    required this.description,
    required this.speakers,
    required this.isPaid,
    required this.eventID,
    this.fromSearch = false,
  });

  @override
  State<SelectedEventScreen> createState() => _SelectedEventScreenState();
}

class _SelectedEventScreenState extends State<SelectedEventScreen> {
  final GetUserProfileController _getUserProfileController = Get.put(
    GetUserProfileController(),
  );
  final UserEventsController _userEventsController = Get.put(UserEventsController());
  bool _isPaymentProcessing = false;

  late final GlobalKey<ScaffoldState> _scaffoldKey;
  final GlobalKey<FormState> _paymentFormKey = GlobalKey<FormState>();

  String? completePhoneNumber;
  String? countryCode = '+254';
  String phoneNumber = '';
  String? fetchedPhoneNumber;
  String fetchedUserId = '';
  List roles = [];
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';
  bool isUserRegistered = false;

  @override
  void initState() {
    super.initState();
    _fetchPhoneNumberAndUser();
    _scaffoldKey = GlobalKey();
    _checkUserRole();
    _loadData();
    // Check if user is registered for this event
    _checkEventRegistration();
  }

  void _checkEventRegistration() {
    // Defer to after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch user events first if not already loaded
      if (_userEventsController.eventsList.isEmpty) {
        _userEventsController.fetchUserEvents().then((_) {
          if (mounted) {
            setState(() {
              isUserRegistered = _userEventsController.isUserRegisteredForEvent(widget.eventID);
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            isUserRegistered = _userEventsController.isUserRegisteredForEvent(widget.eventID);
          });
        }
      }
    });
  }

  Future<void> _registerForEvent() async {
    final success = await _userEventsController.registerForEvent(widget.eventID);
    if (success) {
      setState(() {
        isUserRegistered = true;
      });
    }
  }

  Future<void> _unregisterFromEvent() async {
    final success = await _userEventsController.unregisterFromEvent(widget.eventID);
    if (success) {
      setState(() {
        isUserRegistered = false;
      });
    }
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');
    final fetchedFirstName = await StorageService.getData('firstName');
    final fetchedLastName = await StorageService.getData('lastName');
    final fetchedTitle = await StorageService.getData('title');
    final fetchedMemberId = await StorageService.getData('memberId');
    String? fetchedBio = await StorageService.getData('brief');

    setState(() {
      imageUrl = url;
      firstName = fetchedFirstName;
      memberId = fetchedMemberId;
      lastName = fetchedLastName;
      title = fetchedTitle;
      bio = fetchedBio ?? '';
    });
  }

  Future<void> _fetchPhoneNumberAndUser() async {
    fetchedPhoneNumber = await StorageService.getData("phoneNumber");
    fetchedUserId = await StorageService.getData('userId');
    await _getUserProfileController.fetchUserProfile(fetchedUserId);
  }

  Future<List<String>> _checkUserRole() async {
    final rolesData = await StorageService.getUserRoles();

    setState(() {
      roles = rolesData;
    });
    return rolesData;
  }

  Future<void> _downloadTicketAsPdf() async {
    final pdf = pw.Document();
    final attendeeName = '$firstName $lastName'.trim();
    final ticketId = widget.eventID.length >= 8 
        ? widget.eventID.substring(0, 8).toUpperCase() 
        : widget.eventID.toUpperCase();

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
                      widget.title,
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(children: [
                      pw.Text('Date: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('EEEE, MMMM dd, yyyy')
                          .format(widget.date)),
                    ]),
                    pw.SizedBox(height: 8),
                    pw.Row(children: [
                      pw.Text('Time: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('h:mm a').format(widget.date)),
                    ]),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Location: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Expanded(child: pw.Text(widget.location)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(children: [
                      pw.Text('Price: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(widget.price == 0 ? 'FREE' : 'Kes ${widget.price}'),
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
              pw.Spacer(),
              pw.Text(
                'Thank you for your registration!',
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
      name: 'DAMA_Ticket_${widget.title.replaceAll(' ', '_')}.pdf',
    );
  }

  void _showPhoneNumberModal(bool isDark) {
    final isIOS = UnifiedPaymentService.isIOS;
    bool isProcessing = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? kDarkThemeBg : kWhite,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Form(
              key: _paymentFormKey,
              child: SafeArea(
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        // Payment method icon - platform specific
                        if (isIOS)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.apple, color: Colors.white, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'Pay',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Image.asset("images/mpesa.png", height: 50),
                        const SizedBox(height: 10),
                        Text(
                          'Amount: KES ${widget.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kBlue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Phone number field - Android only (M-Pesa)
                        if (!isIOS)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Phone Number *",
                                  style: TextStyle(
                                    color: isDark ? kWhite : kBlack,
                                    fontWeight: FontWeight.bold,
                                    fontSize: kNormalTextSize,
                                  ),
                                ),
                                SizedBox(height: 8),
                                IntlPhoneField(
                                  enabled: !isProcessing,
                                  decoration: InputDecoration(
                                    hintText: "7*******",
                                    hintStyle: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                                    ),
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: kBlue, width: 1.0),
                                    ),
                                  ),
                                  disableLengthCheck: true,
                                  validator: (PhoneNumber? phone) {
                                    if (phone == null || phone.number.isEmpty) {
                                      return 'Please enter a phone number';
                                    }
                                    if (phone.number.length != 9) {
                                      return 'Phone number must be exactly 9 digits';
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(phone.number)) {
                                      return 'Phone number must contain only digits';
                                    }
                                    return null;
                                  },
                                  style: TextStyle(
                                    color: isDark ? kWhite : kBlack,
                                  ),
                                  dropdownTextStyle: TextStyle(
                                    color: isDark ? kWhite : kBlack,
                                  ),
                                  dropdownIcon: Icon(
                                    Icons.arrow_drop_down,
                                    color: isDark ? kWhite : kBlack,
                                  ),
                                  initialCountryCode: 'KE',
                                  onChanged: (PhoneNumber phone) {
                                    completePhoneNumber = phone.completeNumber;
                                  },
                                  onCountryChanged: (country) {
                                    countryCode = '+${country.dialCode}';
                                  },
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: SizedBox(
                            width: double.infinity,
                            child: isProcessing
                                ? Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isIOS ? Colors.black.withValues(alpha: 0.7) : kBlue.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: kWhite,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          isIOS ? 'Processing Apple Pay...' : 'Processing Payment...',
                                          style: const TextStyle(
                                            color: kWhite,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : isIOS
                                    // Apple Pay button for iOS
                                    ? GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            isProcessing = true;
                                          });
                                          Navigator.pop(modalContext);
                                          _payForEvent(
                                            context,
                                            widget.title,
                                            widget.date.toLocal().toString().split(' ')[0],
                                            widget.location,
                                            isDark,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.apple, color: Colors.white, size: 24),
                                              SizedBox(width: 8),
                                              Text(
                                                'Pay with Apple Pay',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    // M-Pesa button for Android
                                    : CustomButton(
                                        callBackFunction: () {
                                          if (_paymentFormKey.currentState!.validate()) {
                                            phoneNumber = completePhoneNumber ?? '';
                                            Navigator.pop(modalContext);
                                            _payForEvent(
                                              context,
                                              widget.title,
                                              widget.date.toLocal().toString().split(' ')[0],
                                              widget.location,
                                              isDark,
                                            );
                                          }
                                        },
                                        label: "Confirm Payment",
                                        backgroundColor: kBlue,
                                      ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _payForEvent(
    BuildContext context,
    String title,
    String date,
    String location,
    bool isDark,
  ) async {
    setState(() {
      _isPaymentProcessing = true;
    });
    
    final isIOS = UnifiedPaymentService.isIOS;
    
    final paymentResult = await UnifiedPaymentService.pay(
      objectId: widget.eventID,
      model: 'Event',
      amount: widget.price,
      itemName: widget.title,
      phoneNumber: isIOS ? null : phoneNumber,
    );
    
    setState(() {
      _isPaymentProcessing = false;
    });
    
    if (paymentResult.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _scaffoldKey.currentContext;
        if (context != null && context.mounted) {
          showSuccessBottomSheet(context, title, date, location, isDark);
        } else {
          ScaffoldMessenger.of(
            _scaffoldKey.currentContext!,
          ).showSnackBar(SnackBar(content: Text('Payment successful!')));
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Obx(() {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
        body: Stack(
          children: [
            Column(
              children: [
                TopNavigationbar(title: widget.title),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1500),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (kIsWeb)
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: ProfileCard(
                                isDarkMode: isDarkMode,
                                imageUrl: imageUrl,
                                firstName: firstName,
                                lastName: lastName,
                                title: title,
                                bio: bio,
                              ),
                            ),
                          if (kIsWeb) SizedBox(width: 10),
                          Expanded(
                            child: MediaQuery.removePadding(
                              context: context,
                              removeTop: true,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1200,
                                  ),
                                  child: ListView(
                                    children: [
                                      SelectedEventCard(
                                        onPay:
                                            () => _showPhoneNumberModal(
                                              isDarkMode,
                                            ),
                                        onRegister: _registerForEvent,
                                        onUnregister: _unregisterFromEvent,
                                        isRegistered: isUserRegistered,
                                        isRegistering: _userEventsController.isRegistering.value,
                                        isPaid: widget.isPaid,
                                        description: widget.description,
                                        heading: widget.title,
                                        imageUrl: widget.imageUrl,
                                        date: widget.date,
                                        location: widget.location,
                                        price: '${widget.price}',
                                        onViewTicket: _downloadTicketAsPdf,
                                      ),
                                      Container(
                                        color: isDarkMode ? kBlack : kWhite,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            SizedBox(height: 20),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: kSidePadding,
                                              ),
                                              child: Text(
                                                "Speakers",
                                                style: TextStyle(
                                                  color:
                                                      isDarkMode
                                                          ? kWhite
                                                          : kBlack,
                                                  fontSize: kMidText,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: kSidePadding,
                                              ),
                                              child: SizedBox(
                                                height: 100,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount:
                                                      widget.speakers.length,
                                                  separatorBuilder:
                                                      (_, __) => const SizedBox(
                                                        width: 10,
                                                      ),
                                                  itemBuilder: (
                                                    context,
                                                    index,
                                                  ) {
                                                    final speaker =
                                                        widget.speakers[index];
                                                    final speakerImage =
                                                        widget.fromSearch
                                                            ? speaker['image']
                                                            : speaker.image;
                                                    final speakerName =
                                                        widget.fromSearch
                                                            ? speaker['name']
                                                            : speaker.name;

                                                    final isValidImage =
                                                        speakerImage != null &&
                                                        speakerImage
                                                            .toString()
                                                            .isNotEmpty &&
                                                        Uri.tryParse(
                                                              speakerImage,
                                                            )?.hasAbsolutePath ==
                                                            true;

                                                    return Column(
                                                      children: [
                                                        isValidImage
                                                            ? ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    30,
                                                                  ),
                                                              child: Image.network(
                                                                speakerImage,
                                                                width: 60,
                                                                height: 60,
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                    ) => ProfileAvatar(
                                                                      radius:
                                                                          30,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .grey
                                                                              .shade300,
                                                                      child: const Icon(
                                                                        Icons
                                                                            .person,
                                                                        size:
                                                                            40,
                                                                        color:
                                                                            Colors.white,
                                                                      ),
                                                                    ),
                                                              ),
                                                            )
                                                            : ProfileAvatar(
                                                              radius: 30,
                                                              backgroundColor:
                                                                  Colors
                                                                      .grey
                                                                      .shade300,
                                                              child: const Icon(
                                                                Icons.person,
                                                                size: 40,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                        const SizedBox(
                                                          height: 5,
                                                        ),
                                                        SizedBox(
                                                          width: 70,
                                                          child: Text(
                                                            speakerName ?? "",
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  isDarkMode
                                                                      ? kWhite
                                                                      : kBlack,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),

                                            SizedBox(height: 20),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isPaymentProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(child: customSpinner),
              ),
          ],
        ),
      );
    });
  }
}
