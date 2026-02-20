import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dama/controller/get_user_data.dart';
import 'package:dama/controller/payment_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/drawer_screen/QRscanner.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/cards/selected_event_card.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:dama/widgets/modals/success_bottomsheet.dart';
import 'package:dama/widgets/profile_avatar.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final PaymentController _paymentController = Get.put(PaymentController());
  final GetUserProfileController _getUserProfileController = Get.put(
    GetUserProfileController(),
  );

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

  @override
  void initState() {
    super.initState();
    _fetchPhoneNumberAndUser();
    _scaffoldKey = GlobalKey();
    _checkUserRole();
    _loadData();
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

  void _showPhoneNumberModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? kDarkThemeBg : kWhite,
      builder: (context) {
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
                    Image.asset("images/mpesa.png", height: 50),
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
                        child: CustomButton(
                          callBackFunction: () {
                            if (_paymentFormKey.currentState!.validate()) {
                              phoneNumber = completePhoneNumber ?? '';
                              Navigator.pop(context);
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
  }

  void _payForEvent(
    BuildContext context,
    String title,
    String date,
    String location,
    bool isDark,
  ) async {
    _paymentController
      ..amountToPay.value = widget.price
      ..model.value = 'Event'
      ..object_id.value = widget.eventID
      ..phoneNumber.value = phoneNumber;

    final result = await _paymentController.pay(context);

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

  void _showQRCodeModal(BuildContext context, String qrCode, bool isDarkMode) {
    final Uint8List qrBytes = base64Decode(qrCode.split(',').last);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: isDarkMode ? kBlack : kWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Event Ticket',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? kGrey : kGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.memory(
                      qrBytes,
                      height: 250,
                      width: 250,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareQRCode(qrBytes),
                          icon: Icon(Icons.share, color: kBlue),
                          label: Text('Share', style: TextStyle(color: kBlue)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: kBlue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadQRCode(qrBytes),
                          icon: Icon(Icons.download, color: kWhite),
                          label: Text(
                            'Download',
                            style: TextStyle(color: kWhite),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
    );
  }

  Future<void> _downloadQRCode(Uint8List qrBytes) async {
    try {
      if (kIsWeb) {
        Get.snackbar(
          'Info',
          'Use the Share option on web to save the QR code',
          backgroundColor: kBlue.withOpacity(0.9),
          colorText: kWhite,
          margin: const EdgeInsets.all(15),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'ticket_${widget.eventID}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(qrBytes);

      Get.snackbar(
        'Success',
        'QR code saved to $fileName',
        backgroundColor: kGreen.withOpacity(0.9),
        colorText: kWhite,
        margin: const EdgeInsets.all(15),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save QR code',
        backgroundColor: kRed.withOpacity(0.9),
        colorText: kWhite,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  Future<void> _shareQRCode(Uint8List qrBytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'event_ticket_${widget.eventID}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(qrBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My ticket for ${widget.title}');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share QR code',
        backgroundColor: kRed.withOpacity(0.9),
        colorText: kWhite,
        margin: const EdgeInsets.all(15),
      );
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
      final userProfile = _getUserProfileController.profile.value;

      bool showQRCode = false;
      String? qrCode;

      if (userProfile?.eventQRCode != null &&
          fetchedUserId == userProfile!.id) {
        final matchingQRCode =
            userProfile.eventQRCode
                .where((qr) => qr.eventId == widget.eventID)
                .firstOrNull;

        if (matchingQRCode != null) {
          showQRCode = true;
          qrCode = matchingQRCode.qrCode;
        }
      }

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
                                        isPaid: widget.isPaid,
                                        description: widget.description,
                                        heading: widget.title,
                                        imageUrl: widget.imageUrl,
                                        date: widget.date,
                                        location: widget.location,
                                        price: '${widget.price}',
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
                                      if (showQRCode && qrCode != null) ...[
                                        Container(
                                          color:
                                              isDarkMode
                                                  ? kDarkThemeBg
                                                  : kBGColor,
                                          height: 3,
                                        ),
                                        Container(
                                          color: isDarkMode ? kBlack : kWhite,
                                          child: Center(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                SizedBox(height: 20),
                                                Text(
                                                  "Ticket",
                                                  style: TextStyle(
                                                    color:
                                                        isDarkMode
                                                            ? kWhite
                                                            : kBlack,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: kBigTextSize,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  "Scan to view details",
                                                  style: TextStyle(
                                                    color:
                                                        isDarkMode
                                                            ? kWhite
                                                            : kBlack,
                                                    fontSize: kNormalTextSize,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                SizedBox(height: 10),
                                                if (roles.contains(
                                                  'event_verify',
                                                )) ...[
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 15,
                                                        ),
                                                    child: CustomButton(
                                                      callBackFunction: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => QRScannerScreen(
                                                                  eventId:
                                                                      widget
                                                                          .eventID,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      label: "Verify Ticket",
                                                      backgroundColor: kBlue,
                                                    ),
                                                  ),
                                                ] else ...[
                                                  GestureDetector(
                                                    onTap:
                                                        () => _showQRCodeModal(
                                                          context,
                                                          qrCode!,
                                                          isDarkMode,
                                                        ),
                                                    child: Column(
                                                      children: [
                                                        Image.memory(
                                                          base64Decode(
                                                            qrCode
                                                                .split(',')
                                                                .last,
                                                          ),
                                                          height: 200,
                                                          width: 200,
                                                          fit: BoxFit.contain,
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          'Tap to enlarge',
                                                          style: TextStyle(
                                                            color: kBlue,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 40,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton.icon(
                                                            onPressed:
                                                                () => _shareQRCode(
                                                                  base64Decode(
                                                                    qrCode!
                                                                        .split(
                                                                          ',',
                                                                        )
                                                                        .last,
                                                                  ),
                                                                ),
                                                            icon: Icon(
                                                              Icons.share,
                                                              color: kBlue,
                                                              size: 18,
                                                            ),
                                                            label: Text(
                                                              'Share',
                                                              style: TextStyle(
                                                                color: kBlue,
                                                              ),
                                                            ),
                                                            style: OutlinedButton.styleFrom(
                                                              side: BorderSide(
                                                                color: kBlue,
                                                              ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical:
                                                                        10,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: ElevatedButton.icon(
                                                            onPressed:
                                                                () => _downloadQRCode(
                                                                  base64Decode(
                                                                    qrCode!
                                                                        .split(
                                                                          ',',
                                                                        )
                                                                        .last,
                                                                  ),
                                                                ),
                                                            icon: Icon(
                                                              Icons.download,
                                                              color: kWhite,
                                                              size: 18,
                                                            ),
                                                            label: Text(
                                                              'Download',
                                                              style: TextStyle(
                                                                color: kWhite,
                                                              ),
                                                            ),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  kBlue,
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical:
                                                                        10,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],

                                                SizedBox(height: 30),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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
            if (_paymentController.isLoading.value)
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
