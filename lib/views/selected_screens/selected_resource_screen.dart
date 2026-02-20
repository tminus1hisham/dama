import 'package:dama/controller/get_user_data.dart';
import 'package:dama/controller/payment_controller.dart';
import 'package:dama/controller/rating_controller.dart';
import 'package:dama/controller/transaction_controller.dart';
import 'package:dama/models/rating_model.dart';
import 'package:dama/models/transaction_model.dart';
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
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
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
  final bool autoShowPayment;
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
    this.autoShowPayment = false,
    required this.resourceID,
    super.key,
  });

  @override
  State<SelectedResourceScreen> createState() => _SelectedResourceScreenState();
}

class _SelectedResourceScreenState extends State<SelectedResourceScreen> {
  final GetUserProfileController _getUserProfileController = Get.put(GetUserProfileController());
  final TransactionController _transactionController = Get.put(TransactionController());
  bool _hasPurchased = false;
  final PaymentController _paymentController = Get.put(PaymentController());
  final RatingController _ratingController = Get.put(RatingController());
  late final GlobalKey<ScaffoldState> _resourceKey;
  final GlobalKey<FormState> _paymentFormKey = GlobalKey<FormState>();
  
  // Flag to prevent multiple modal shows
  bool _hasShownPaymentModal = false;

  String? completePhoneNumber;
  String? countryCode = '+254';
  String phoneNumber = '';
  String? fetchedPhoneNumber;
  String fetchedUserId = '';
  double _currentRating = 0;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';
  bool _hasCheckedPurchase = false;

  void _payForResource(BuildContext context, String title, int price, bool isDark) async {
    debugPrint('=== _payForResource DEBUG ===');
    debugPrint('Resource ID: ${widget.resourceID}');
    debugPrint('Price: ${widget.price}');
    debugPrint('Phone: $phoneNumber');
    debugPrint('Has Purchased (before): $_hasPurchased');
    
    _paymentController
      ..amountToPay.value = widget.price
      ..model.value = 'Resource'
      ..object_id.value = widget.resourceID
      ..phoneNumber.value = phoneNumber;

    final result = await _paymentController.pay(context);
    
    debugPrint('Payment result: $result');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resourceKey.currentContext;
      if (result && context != null && context.mounted) {
        // Refresh purchase status after successful payment
        _checkIfPurchased(fetchedUserId);
        showSuccessResource(context, title, price, isDark);
      }
    });
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

  void _showPhoneNumberModal(bool isDark, title, price) {
    // Prevent showing multiple modals
    if (_hasShownPaymentModal) return;
    _hasShownPaymentModal = true;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
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
                    SizedBox(height: 10),
                    Image.asset("images/mpesa.png", height: 50),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
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
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          callBackFunction: () {
                            if (_paymentFormKey.currentState!.validate()) {
                              phoneNumber = completePhoneNumber ?? '';
                              Navigator.pop(context);
                              _payForResource(context, title, price, isDark);
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
    ).then((_) {
      // Reset flag when modal is closed
      _hasShownPaymentModal = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchPhoneNumberAndUser();
    _resourceKey = GlobalKey();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If caller requested automatic payment flow, show the payment modal
    // after purchase check is complete (called in initState via _fetchPhoneNumberAndUser)
    // Use flag to prevent multiple calls
    if (widget.autoShowPayment && _hasCheckedPurchase && !_hasShownPaymentModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (!mounted) return;
        if (!_hasPurchased) {
          _showPhoneNumberModal(isDark, widget.title, widget.price);
        }
      });
    }
  }

  /// Check if resource is purchased - uses user profile (like events use QR codes)
  /// Also checks transactions as fallback since backend may not update resources array
  void _checkIfPurchased(String userId) async {
    try {
      debugPrint('=== Checking if resource is purchased ===');
      debugPrint('Resource ID: ${widget.resourceID}');
      
      bool hasResource = false;
      
      // PRIMARY CHECK: Fetch user profile to get resources list (like events use eventQRCode)
      await _getUserProfileController.fetchUserProfile(userId);
      final userProfile = _getUserProfileController.profile.value;
      
      if (userProfile != null && fetchedUserId == userProfile.id) {
        // Check if resource ID is in user's resources list
        hasResource = userProfile.resources.contains(widget.resourceID);
        
        debugPrint('User resources: ${userProfile.resources}');
        debugPrint('Found in user resources: $hasResource');
      }
      
      // FALLBACK CHECK: Also check completed transactions
      // This handles cases where backend doesn't update the resources array
      if (!hasResource) {
        await _transactionController.fetchTransactions();
        final transactions = _transactionController.transactionList;
        
        debugPrint('Total transactions: ${transactions.length}');
        
        final foundInTransactions = transactions.any((tx) {
          final isResource = tx.onModel == 'Resource';
          final isCompleted = tx.status.toLowerCase() == 'completed';
          
          // Check both object ID and raw object_id
          bool objectIdMatch = false;
          
          // Try object ID if object is populated
          if (tx.object is ResourceTransactionModel) {
            objectIdMatch = (tx.object as ResourceTransactionModel).id == widget.resourceID;
          }
          
          // Also check raw object_id as fallback (object_id from API response)
          final rawIdMatch = tx.rawObjectId == widget.resourceID;
          
          final matches = isResource && isCompleted && (objectIdMatch || rawIdMatch);
          debugPrint('Transaction: ${tx.id}, onModel: ${tx.onModel}, status: ${tx.status}, objectMatch: $objectIdMatch, rawIdMatch: $rawIdMatch, combinedMatch: $matches');
          
          return matches;
        });
        
        debugPrint('Found in completed transactions: $foundInTransactions');
        hasResource = foundInTransactions;
      }
      
      setState(() {
        _hasPurchased = hasResource;
      });
      
      debugPrint('Final _hasPurchased: $_hasPurchased');
    } catch (e) {
      debugPrint('Error checking purchase status: $e');
      // Don't change _hasPurchased on error - keep existing state
    }
  }

  Future<void> _fetchPhoneNumberAndUser() async {
    fetchedPhoneNumber = await StorageService.getData("phoneNumber");
    fetchedUserId = await StorageService.getData('userId');
    // Check purchase status after getting user ID (only once)
    if (!_hasCheckedPurchase) {
      _hasCheckedPurchase = true;
      _checkIfPurchased(fetchedUserId);
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
                                        isPaid: _hasPurchased,
                                        onPressed: (_hasPurchased || widget.price == 0)
                                            ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => PDFViewerPage(
                                                      title: widget.title,
                                                      pdfUrl: widget.viewUrl,
                                                    ),
                                                  ),
                                                );
                                              }
                                            : () => _showPhoneNumberModal(
                                                  isDarkMode,
                                                  widget.title,
                                                  widget.price,
                                                ),
                                        heading: widget.title,
                                        imageUrl: widget.imageUrl,
                                        rating: widget.rating,
                                        price: '${widget.price}',
                                        description: widget.description,
                                        priceInt: widget.price,
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
