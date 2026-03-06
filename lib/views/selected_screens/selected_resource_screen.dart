import 'package:dama/controller/get_user_data.dart';
import 'package:dama/controller/rating_controller.dart';
import 'package:dama/services/unified_payment_service.dart';
import 'package:dama/controller/resource_controller.dart';
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
  final ResourceController _resourceController = Get.put(ResourceController());
  bool _hasPurchased = false;
  bool _isPaymentProcessing = false;
  final RatingController _ratingController = Get.put(RatingController());
  late final GlobalKey<ScaffoldState> _resourceKey;
  // Flag to prevent multiple modal shows
  bool _hasShownPaymentModal = false;
  
  // Local rating state that can be updated after user rates
  late double _currentRating;

  String? completePhoneNumber;
  String? countryCode = '+254';
  String phoneNumber = '';
  String? fetchedPhoneNumber;
  String fetchedUserId = '';
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
    
    setState(() {
      _isPaymentProcessing = true;
    });
    
    final isIOS = UnifiedPaymentService.isIOS;
    
    final paymentResult = await UnifiedPaymentService.pay(
      objectId: widget.resourceID,
      model: 'Resource',
      amount: widget.price,
      itemName: widget.title,
      phoneNumber: isIOS ? null : phoneNumber,
    );
    
    setState(() {
      _isPaymentProcessing = false;
    });
    
    final result = paymentResult.success;
    
    debugPrint('Payment result: $result');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resourceKey.currentContext;
      if (result && context != null && context.mounted) {
        // Refresh purchase status after successful payment
        _checkIfPurchased(fetchedUserId);
        // Show simple success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase successful! You can now access the resource.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _showPhoneNumberModal(bool isDark, title, price) {
    // Prevent showing multiple modals
    if (_hasShownPaymentModal) return;
    _hasShownPaymentModal = true;
    
    final isIOS = UnifiedPaymentService.isIOS;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? kDarkThemeBg : kWhite,
      builder: (modalContext) {
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      const SizedBox(height: 20),
                      Text(
                        'Purchase Resource',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? kWhite : kBlack,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? kWhite : kGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Amount: KES $price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      // Phone number field - Android only (M-Pesa)
                      if (!isIOS)
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
                      if (!isIOS) const SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
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
                                      onTap: () async {
                                        setModalState(() {
                                          isProcessing = true;
                                        });
                                        Navigator.pop(modalContext);
                                        _payForResource(context, title, price, isDark);
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
                                        if (completePhoneNumber != null &&
                                            completePhoneNumber!.length >= 10) {
                                          phoneNumber = completePhoneNumber!;
                                          Navigator.pop(modalContext);
                                          _payForResource(context, title, price, isDark);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Please enter a valid phone number'),
                                              backgroundColor: Colors.red,
                                            ),
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
            );
          }
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
    _currentRating = widget.rating;  // Initialize with widget value
    _fetchPhoneNumberAndUser();
    _resourceKey = GlobalKey();
    _loadData();
    // Fetch related resources for this resource
    _resourceController.fetchRelatedResources(widget.resourceID);
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

  /// Check if resource is purchased - uses user profile and transactions
  void _checkIfPurchased(String userId) async {
    try {
      debugPrint('=== Checking if resource is purchased ===');
      debugPrint('Resource ID: ${widget.resourceID}');
      
      bool hasResource = false;
      
      // PRIMARY CHECK: Fetch user profile to get resources list
      await _getUserProfileController.fetchUserProfile(userId);
      final userProfile = _getUserProfileController.profile.value;
      
      if (userProfile != null && fetchedUserId == userProfile.id) {
        // Check if resource ID is in user's resources list
        hasResource = userProfile.resources.contains(widget.resourceID);
        
        debugPrint('User resources: ${userProfile.resources}');
        debugPrint('Found in user resources: $hasResource');
      }
      
      // FALLBACK CHECK: Also check completed transactions
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
          
          // Also check raw object_id as fallback
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
    // Only allow rating if resource has been purchased
    if (!_hasPurchased && widget.price != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please purchase this resource first to leave a rating'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final rating = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(),
    );

    if (rating != null) {
      final ratingModel = RatingModel(rating: rating);

      debugPrint('[SelectedResourceScreen] Submitting rating: $rating for resource: ${widget.resourceID}');
      
      final newAvgRating = await _ratingController.submitRating(widget.resourceID, ratingModel);

      if (_ratingController.success.value) {
        debugPrint('[SelectedResourceScreen] Rating submitted successfully. API returned: $newAvgRating');
        
        // Refresh resources from the server to get the updated averageRating
        await _resourceController.refreshResources();
        
        // Get the updated resource from the refreshed list
        final updatedResource = _resourceController.resourceList
            .firstWhereOrNull((r) => r.id == widget.resourceID);
        
        // Use server-returned rating, fallback to API response, then user's rating
        final serverRating = updatedResource?.averageRating;
        final updatedRating = serverRating ?? newAvgRating ?? rating;
        
        debugPrint('[SelectedResourceScreen] Server rating: $serverRating, Final rating: $updatedRating');
        
        if (!mounted) return;
        
        setState(() {
          _currentRating = updatedRating;
        });
        
        // Update the resource in the controller for consistency
        _resourceController.updateResourceRating(widget.resourceID, updatedRating);
        
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

    return Stack(
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
                                      child: GetBuilder<ResourceController>(
                                        init: _resourceController,
                                        builder: (controller) {
                                          // Access the list directly from the controller
                                          final relatedResources = controller.relatedResources.toList();
                                          final isLoadingRelated = controller.isLoadingRelated.value;
                                          debugPrint('GetBuilder rebuild: relatedResources=${relatedResources.length}, isLoadingRelated=$isLoadingRelated');
                                          return SelectedResource(
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
                                                          onBack: () => Navigator.pop(context),
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
                                            rating: _currentRating,
                                            price: '${widget.price}',
                                            description: widget.description,
                                            priceInt: widget.price,
                                            relatedResources: relatedResources,
                                          onRelatedResourceTap: (resource) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => SelectedResourceScreen(
                                                  title: resource.title,
                                                  price: resource.price,
                                                  imageUrl: resource.resourceImageUrl,
                                                  date: resource.createdAt,
                                                  rating: resource.averageRating,
                                                  description: resource.description,
                                                  viewUrl: resource.resourceLink,
                                                  isPaid: false,
                                                  resourceID: resource.id,
                                                ),
                                              ),
                                            );
                                          },
                                          );
                                        },
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
          if (_isPaymentProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(child: customSpinner),
            ),
        ],
    );
  }
}
