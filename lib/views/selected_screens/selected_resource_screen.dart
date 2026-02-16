import 'package:dama/controller/payment_controller.dart';
import 'package:dama/controller/rating_controller.dart';
import 'package:dama/models/rating_model.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/pdf_viewer.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/cards/profile_card.dart';
import 'package:dama/widgets/cards/selected_resource.dart';
import 'package:dama/widgets/custom_spinner.dart';
import 'package:dama/widgets/inputs/custom_input.dart';
import 'package:dama/widgets/modals/rating_dialog.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SelectedResourceScreen extends StatefulWidget {
  final String title;
  final int price;
  final DateTime date;
  final String imageUrl;
  final double rating;
  final String description;
  final String viewUrl;
  final bool isPaid;
  final String resourceID;

  const SelectedResourceScreen({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.date,
    required this.rating,
    required this.description,
    required this.viewUrl,
    required this.isPaid,
    required this.resourceID,
    super.key,
  });

  @override
  State<SelectedResourceScreen> createState() => _SelectedResourceScreenState();
}

class _SelectedResourceScreenState extends State<SelectedResourceScreen> {
  final PaymentController _paymentController = Get.put(PaymentController());
  final TextEditingController _phoneController = TextEditingController();
  final RatingController _ratingController = Get.put(RatingController());
  late final GlobalKey<ScaffoldState> _resourceKey;

  String phoneNumber = '';
  String? fetchedPhoneNumber;
  double _currentRating = 0;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';

  void _payForEvent(BuildContext context, title, price, isDark) async {
    _paymentController.amountToPay.value = widget.price;
    _paymentController.model.value = 'Resource';
    _paymentController.object_id.value = widget.resourceID;
    _paymentController.phoneNumber.value = phoneNumber;
    final success = await _paymentController.pay(context);

    if (success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _resourceKey.currentContext;
        if (context != null && context.mounted) {
          showSuccessResource(context, title, price, isDark);
        } else {
          ScaffoldMessenger.of(
            _resourceKey.currentContext!,
          ).showSnackBar(SnackBar(content: Text('Payment successful!')));
        }
      });
    }
  }

  void showSuccessResource(
    BuildContext context,
    String? title,
    int price,
    bool isDark,
  ) {
    if (!context.mounted) {
      return;
    }

    showModalBottomSheet(
      backgroundColor: isDark ? kBlack : kWhite,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 100),
                  SizedBox(height: 20),
                  Text(
                    'Purchase Confirmed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? kWhite : kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Thank you for purchasing $title. Please find the resource in your resources tab",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? kWhite : kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  SizedBox(height: 8),
                  Text(
                    'KES: $price',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? kWhite : kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
    );
  }

  String formatPhoneNumber(String input) {
    input = input.trim();
    if (input.startsWith('0') && input.length == 10) {
      return '254${input.substring(1)}';
    } else if (input.startsWith('254') && input.length == 12) {
      return input;
    } else {
      throw FormatException("Invalid phone number format");
    }
  }

  void _showPhoneNumberModal(bool isDark, title, price) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? kDarkThemeBg : kWhite,
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10),
                  Image.asset("images/mpesa.png", height: 50),
                  InputField(
                    controller: _phoneController,
                    hintText: "eg: 07XXXXXXXX",
                    label: "Phone Number *",
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        callBackFunction: () {
                          Navigator.pop(context);
                          phoneNumber = formatPhoneNumber(
                            _phoneController.text,
                          );
                          _payForEvent(context, title, price, isDark);
                        },
                        label: "Confirm Payment",
                        backgroundColor: kBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String reformatPhoneNumber(String input) {
    input = input.trim();
    if (input.startsWith('254') && input.length == 12) {
      return '0${input.substring(3)}';
    } else if (input.startsWith('0') && input.length == 10) {
      return input;
    } else {
      throw FormatException("Invalid phone number format");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPhoneNumber();
    _resourceKey = GlobalKey();
    _loadData();
  }

  void _fetchPhoneNumber() async {
    fetchedPhoneNumber = await StorageService.getData("phoneNumber");
    _phoneController.text = reformatPhoneNumber(fetchedPhoneNumber!);
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

  void _showRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(),
    );

    if (rating != null) {
      setState(() {
        _currentRating = rating;
      });

      final ratingModel = RatingModel(rating: rating);

      await _ratingController.submitRating(widget.resourceID, ratingModel);

      if (_ratingController.success.value) {
        // Show success popup
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Thank you!'),
                content: Text('Your rating has been submitted.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        Get.snackbar('Error', _ratingController.errorMessage.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;
    bool kIsWeb = MediaQuery.of(context).size.width > 1100;

    return Obx(
      () => Stack(
        children: [
          Scaffold(
            key: _resourceKey,
            backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
            body: Column(
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
                              child: ListView(
                                children: [
                                  Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: 1200,
                                      ),
                                      child: SelectedResource(
                                        onRatingUpdated: _showRatingDialog,
                                        isPaid: true,
                                        onViewPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => PDFViewerPage(
                                                    title: widget.title,
                                                    pdfUrl: widget.viewUrl,
                                                  ),
                                            ),
                                          );
                                        },
                                        heading: widget.title,
                                        imageUrl: widget.imageUrl,
                                        rating: widget.rating,
                                        price: '${widget.price}',
                                        description: widget.description,
                                        onPressed:
                                            () => _showPhoneNumberModal(
                                              isDarkMode,
                                              widget.title,
                                              widget.price,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
          if (_paymentController.isLoading.value)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(child: customSpinner),
            ),
        ],
      ),
    );
  }
}
