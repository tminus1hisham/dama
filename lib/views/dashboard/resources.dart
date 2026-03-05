import 'package:dama/controller/get_user_data.dart';
import 'package:dama/controller/resource_controller.dart';
import 'package:dama/services/unified_payment_service.dart';
import 'package:dama/controller/user_resources_controller.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/views/pdf_viewer.dart';
import 'package:dama/views/selected_screens/selected_resource_screen.dart';
import 'package:dama/widgets/buttons/custom_button.dart';
import 'package:dama/widgets/cards/resources_card.dart';
import 'package:dama/widgets/modals/success_bottomsheet.dart';
import 'package:dama/widgets/shimmer/resources_card_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';

class Resources extends StatefulWidget {
  final VoidCallback onMenuTap;

  const Resources({super.key, required this.onMenuTap});

  @override
  State<Resources> createState() => _ResourcesState();
}

class _ResourcesState extends State<Resources>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  final ResourceController _resourceController = Get.put(ResourceController());
  final UserResourceController _userResourceController = Get.put(
    UserResourceController(),
  );
  final GetUserProfileController _getUserProfileController = Get.put(
    GetUserProfileController(),
  );

  bool _isLoading = false;
  int selectedTab = 0;
  String imageUrl = '';
  String firstName = '';
  String lastName = '';
  String title = '';
  String bio = '';
  String memberId = '';
  
  // Payment fields
  String? completePhoneNumber;
  String? countryCode = '+254';
  String phoneNumber = '';
  String? fetchedPhoneNumber;
  String fetchedUserId = '';
  
  // Sorting options
  String _sortBy = 'newest'; // newest, oldest, price_low, price_high, rating
  
  // Scroll controller for pagination
  final ScrollController _allResourcesScrollController = ScrollController();
  final ScrollController _myResourcesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _resourceController.fetchResources();
    _userResourceController.fetchUserResources();
    _loadData();
    _setupScrollListeners();
  }

  void _setupScrollListeners() {
    _allResourcesScrollController.addListener(_onAllResourcesScroll);
    _myResourcesScrollController.addListener(_onMyResourcesScroll);
  }

  void _onAllResourcesScroll() {
    if (_allResourcesScrollController.position.pixels >=
            _allResourcesScrollController.position.maxScrollExtent - 200 &&
        !_resourceController.isLoadingMore.value &&
        _resourceController.hasMore.value) {
      _resourceController.loadMoreResources();
    }
  }

  void _onMyResourcesScroll() {
    // My resources pagination can be added later if needed
  }

  void _loadData() async {
    final url = await StorageService.getData('profile_picture');

    setState(() {
      imageUrl = url;
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    await _resourceController.refreshResources();
    await _userResourceController.fetchUserResources();
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildPillButton(String text, int index) {
    final bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? kBlue : kWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? kBlue : kGrey),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? kWhite : kGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _fetchPhoneNumberAndUser() async {
    fetchedPhoneNumber = await StorageService.getData("phoneNumber");
    fetchedUserId = await StorageService.getData('userId');
    await _getUserProfileController.fetchUserProfile(fetchedUserId);
  }

  void _showPhoneNumberModal(BuildContext context, dynamic resource, bool isDarkMode) {
    // Pre-populate phone number from storage
    String initialPhoneNumber = '';
    if (fetchedPhoneNumber != null && fetchedPhoneNumber!.isNotEmpty) {
      // Extract just the number part (without country code)
      if (fetchedPhoneNumber!.startsWith('+254')) {
        initialPhoneNumber = fetchedPhoneNumber!.substring(4);
      } else if (fetchedPhoneNumber!.startsWith('254')) {
        initialPhoneNumber = fetchedPhoneNumber!.substring(3);
      } else {
        initialPhoneNumber = fetchedPhoneNumber!;
      }
    }
    
    // Local variable to track loading state within the modal
    bool isProcessing = false;
    final isIOS = UnifiedPaymentService.isIOS;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Prevent dismissing during payment
      enableDrag: false,    // Prevent dragging away during payment
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? kDarkThemeBg : kWhite,
      builder: (modalContext) {
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
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        resource.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? kWhite : kGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Amount: KES ${resource.price}',
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
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Phone Number *",
                              style: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                                fontWeight: FontWeight.bold,
                                fontSize: kNormalTextSize,
                              ),
                            ),
                            SizedBox(height: 8),
                            IntlPhoneField(
                              initialValue: initialPhoneNumber, // Autofill phone number
                              enabled: !isProcessing, // Disable during processing
                              decoration: InputDecoration(
                                hintText: "7*******",
                                hintStyle: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
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
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                              dropdownTextStyle: TextStyle(
                                color: isDarkMode ? kWhite : kBlack,
                              ),
                              dropdownIcon: Icon(
                                Icons.arrow_drop_down,
                                color: isDarkMode ? kWhite : kBlack,
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
                                  onTap: () async {
                                    setModalState(() {
                                      isProcessing = true;
                                    });
                                    
                                    final success = await _processPayment(context, resource);
                                    
                                    if (modalContext.mounted) {
                                      Navigator.pop(modalContext);
                                    }
                                    
                                    if (success && context.mounted) {
                                      showSuccessBottomSheet(
                                        context,
                                        resource.title,
                                        'Resource purchased',
                                        'KES ${resource.price}',
                                        isDarkMode,
                                      );
                                      Future.delayed(const Duration(seconds: 3), () {
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PDFViewerPage(
                                                title: resource.title,
                                                pdfUrl: resource.resourceLink,
                                                onBack: () => Navigator.pop(context),
                                              ),
                                            ),
                                          );
                                        }
                                      });
                                    }
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
                                callBackFunction: () async {
                                  if (completePhoneNumber != null &&
                                      completePhoneNumber!.length >= 10) {
                                    phoneNumber = completePhoneNumber!;
                                    
                                    // Show loading state
                                    setModalState(() {
                                      isProcessing = true;
                                    });
                                    
                                    // Process payment while modal stays open
                                    final success = await _processPayment(context, resource);
                                    
                                    // Close modal after payment completes
                                    if (modalContext.mounted) {
                                      Navigator.pop(modalContext);
                                    }
                                    
                                    // Show success UI if payment succeeded
                                    if (success && context.mounted) {
                                      showSuccessBottomSheet(
                                        context,
                                        resource.title,
                                        'Resource purchased',
                                        'KES ${resource.price}',
                                        isDarkMode,
                                      );
                                      // Navigate to PDF viewer after a delay
                                      Future.delayed(const Duration(seconds: 3), () {
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PDFViewerPage(
                                                title: resource.title,
                                                pdfUrl: resource.resourceLink,
                                                onBack: () => Navigator.pop(context),
                                              ),
                                            ),
                                          );
                                        }
                                      });
                                    }
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
    );
  }

  // Process payment and return success status
  Future<bool> _processPayment(BuildContext context, dynamic resource) async {
    // Check if user already has this resource
    final isAlreadyPurchased = _userResourceController.resourceList.any(
      (r) => r.id == resource.id,
    );

    if (isAlreadyPurchased) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have already purchased this resource.')),
        );
      }
      return false;
    }

    final isIOS = UnifiedPaymentService.isIOS;
    
    final result = await UnifiedPaymentService.pay(
      objectId: resource.id,
      model: 'Resource',
      amount: resource.price,
      itemName: resource.title,
      phoneNumber: isIOS ? null : phoneNumber,
    );
    
    final success = result.success;

    if (success) {
      // Refresh user resources list after successful payment
      await _userResourceController.fetchUserResources();
    }

    return success;
  }



  @override
  void dispose() {
    _allResourcesScrollController.dispose();
    _myResourcesScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDark;

    super.build(context);
    return Container(
      color: isDarkMode ? kDarkThemeBg : kBGColor,
      child: Column(
        children: [
          SizedBox(height: 5),
          Container(
            color: isDarkMode ? kBlack : kWhite,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildPillButton("All Resources", 0),
                    const SizedBox(width: 10),
                    _buildPillButton("My Resources", 1),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: [
                // All Resources Tab with Pagination
                RefreshIndicator(
                  color: kWhite,
                  backgroundColor: kBlue,
                  displacement: 40,
                  onRefresh: _fetchData,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 800),
                      child: Obx(() {
                        if (_resourceController.isLoading.value &&
                            _resourceController.resourceList.isEmpty) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: 3,
                            itemBuilder:
                                (context, index) => ResourcesCardShimmer(),
                          );
                        } else if (_resourceController.resourceList.isEmpty) {
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
                                      Icons.folder_copy,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No resource available",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "THe resources will appear here",
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

                        return ListView.builder(
                          controller: _allResourcesScrollController,
                          padding: const EdgeInsets.all(0),
                          itemCount: _resourceController.resourceList.length +
                              (_resourceController.hasMore.value ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the bottom
                            if (index >=
                                _resourceController.resourceList.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: kBlue,
                                  ),
                                ),
                              );
                            }

                            final resource =
                                _resourceController.resourceList[index];
                            // Check if user has purchased this resource
                            final isPurchased = _userResourceController
                                .resourceList
                                .any((r) => r.id == resource.id);

                            return ResourcesCard(
                              heading: resource.title,
                              imageUrl: resource.resourceImageUrl,
                              price: resource.price,
                              isPurchased: isPurchased,
                              onReadNowPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewerPage(
                                      title: resource.title,
                                      pdfUrl: resource.resourceLink,
                                      onBack: () => Navigator.pop(context),
                                    ),
                                  ),
                                );
                              },
                              onPressed: () {
                                // Navigate to resource detail screen
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                    ) => SelectedResourceScreen(
                                      resourceID: resource.id,
                                      isPaid: isPurchased || resource.price == 0,
                                      title: resource.title,
                                      imageUrl: resource.resourceImageUrl,
                                      description: resource.description,
                                      price: resource.price,
                                      viewUrl: resource.resourceLink,
                                      date: resource.createdAt,
                                      rating: resource.averageRating,
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
                        );
                      }),
                    ),
                  ),
                ),
                // My Resources Tab
                RefreshIndicator(
                  color: kWhite,
                  backgroundColor: kBlue,
                  displacement: 40,
                  onRefresh: _fetchData,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 800),
                      child: Obx(() {
                        if (_userResourceController.isLoading.value ||
                            _isLoading) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: 3,
                            itemBuilder:
                                (context, index) => ResourcesCardShimmer(),
                          );
                        } else if (_userResourceController
                            .resourceList
                            .isEmpty) {
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
                                      Icons.folder_copy,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No resource available",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Your resources will appear here",
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

                        return ListView.builder(
                          controller: _myResourcesScrollController,
                          padding: const EdgeInsets.all(0),
                          itemCount:
                              _userResourceController.resourceList.length,
                          itemBuilder: (context, index) {
                            final resource =
                                _userResourceController.resourceList[index];
                            return ResourcesCard(
                              heading: resource.title,
                              imageUrl: resource.resourceImageUrl,
                              price: resource.price,
                              isPurchased: true,
                              onReadNowPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewerPage(
                                      title: resource.title,
                                      pdfUrl: resource.resourceLink,
                                      onBack: () => Navigator.pop(context),
                                    ),
                                  ),
                                );
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
                                        ) => SelectedResourceScreen(
                                          resourceID: resource.id,
                                          isPaid: resource.price > 0,
                                          title: resource.title,
                                          imageUrl: resource.resourceImageUrl,
                                          description: resource.description,
                                          price: resource.price,
                                          viewUrl: resource.resourceLink,
                                          date: resource.createdAt,
                                          rating: resource.averageRating,
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
